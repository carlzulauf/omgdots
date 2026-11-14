require "rails_helper"

RSpec.describe RedisJsonModel do
  # Run every example on a plain client and on a namespaced one, whatever
  # REDIS_NAMESPACE says, since redis-namespace wraps WATCH and MULTI.
  [nil, "omgdots-lock-spec"].each do |namespace|
    context(namespace ? "through Redis::Namespace" : "on a plain client") do
      define_method(:new_connection) do
        client = Redis.new(url: ENV["REDIS_URL"])
        namespace ? Redis::Namespace.new(namespace, redis: client) : client
      end

      let(:game_id) { "lock-spec-#{SecureRandom.hex(4)}" }
      let(:key) { DotsGame.key_for(game_id) }

      around do |example|
        original = DotsGame.redis
        DotsGame.redis = new_connection
        example.run
      ensure
        DotsGame.find(game_id)&.destroy
        DotsGame.redis = original
      end

      before { DotsGame.find_or_create(game_id) }

      def game
        DotsGame.find(game_id)
      end

      # Another process: its own connection, writing straight to the key.
      def write_elsewhere
        other = DotsGame.find(game_id)
        yield other
        new_connection.set(key, other.to_json)
      end

      def closed?(x, y)
        game.board.get(x, y) == DotsGameBoard::HLINE_CLOSE
      end

      describe ".for_update" do
        it "saves the block's changes" do
          DotsGame.for_update(game_id) { |g| g.move(x: 1, y: 0) }

          expect(closed?(1, 0)).to be true
        end

        it "re-runs the block on a fresh read when the key changes before EXEC" do
          runs = 0
          DotsGame.for_update(game_id) do |g|
            runs += 1
            write_elsewhere { |other| other.move(x: 3, y: 0) } if runs == 1
            g.move(x: 1, y: 0)
          end

          expect(runs).to eq(2)
          expect(closed?(1, 0)).to be true
          expect(closed?(3, 0)).to be true
        end

        it "raises after five aborted attempts, leaving the other writer's data" do
          runs = 0
          expect {
            DotsGame.for_update(game_id) do |g|
              runs += 1
              write_elsewhere { |other| other.width = 9 }
              g.move(x: 1, y: 0)
            end
          }.to raise_error(RedisJsonModel::ConflictError, /gave up after 5 attempts/)

          expect(runs).to eq(5)
          expect(closed?(1, 0)).to be false
          expect(game.width).to eq(9)
        end

        it "applies two concurrent updates from separate connections" do
          barrier = Concurrent::CyclicBarrier.new(2)
          runs = Concurrent::AtomicFixnum.new

          threads = [[1, 0], [3, 0]].map do |x, y|
            Thread.new do
              updater = DotsGame.new(id: game_id)
              connection = new_connection
              updater.define_singleton_method(:redis) { connection }
              first = true
              updater.with_lock do |g|
                runs.increment
                # Both threads have WATCHed and read before either writes, so
                # one EXEC must abort and retry.
                barrier.wait(5) if first
                first = false
                g.move(x: x, y: y)
                true
              end
            end
          end
          threads.each { |t| expect(t.join(10)).to be_truthy }
          threads.each(&:value)

          expect(closed?(1, 0)).to be true
          expect(closed?(3, 0)).to be true
          expect(runs.value).to eq(3)
        end

        it "keeps both lines when two threads share the app's client" do
          threads = [[1, 0], [3, 0]].map do |x, y|
            Thread.new { DotsGame.for_update(game_id) { |g| g.move(x: x, y: y) } }
          end
          threads.each { |t| expect(t.join(10)).to be_truthy }

          expect(closed?(1, 0)).to be true
          expect(closed?(3, 0)).to be true
        end
      end

      describe "expiry" do
        let(:ttl) { RedisJsonModel::TTL.to_i }

        it "sets the TTL on save" do
          new_connection.persist(key)
          game.save

          expect(new_connection.ttl(key)).to be_within(5).of(ttl)
        end

        it "refreshes the TTL on every update inside the transaction" do
          new_connection.expire(key, 60)
          DotsGame.for_update(game_id) { |g| g.move(x: 1, y: 0) }

          expect(new_connection.ttl(key)).to be_within(5).of(ttl)
          expect(closed?(1, 0)).to be true
        end
      end

      describe "#with_lock" do
        it "writes nothing when the block returns false" do
          before = game.updated_at
          updater = DotsGame.new(id: game_id)

          expect(updater.with_lock { |g| g.move(x: 1, y: 0) && false }).to be false
          expect(closed?(1, 0)).to be false
          expect(game.updated_at).to eq(before)
        end

        it "returns true once saved" do
          expect(DotsGame.new(id: game_id).with_lock { true }).to be true
        end
      end
    end
  end
end
