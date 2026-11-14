require "rails_helper"

RSpec.describe PlayGameChannel, type: :channel do
  let(:game_id) { "channel-spec-#{SecureRandom.hex(4)}" }
  let(:notification_key) { "game:#{game_id}:alice" }

  before { subscribe(id: game_id, user: "alice") }
  after { DotsGame.find(game_id)&.destroy }

  def notifications_to(key)
    broadcasts(PlayGameChannel.broadcasting_for(key))
      .map { |raw| JSON.parse(raw) }
      .select { |message| message["type"] == "notification" }
      .map { |message| message["data"] }
  end

  def last_notification
    notifications_to(notification_key).last
  end

  def game
    DotsGame.find(game_id)
  end

  def game_broadcasts
    broadcasts(PlayGameChannel.broadcasting_for("game:#{game_id}"))
      .map { |raw| JSON.parse(raw) }
      .select { |message| message["type"] == "game" }
  end

  def give_seat(number, owner, last_seen_at: Time.now)
    DotsGame.for_update(game_id) do |g|
      g.get_player(number).own(owner)
      g.get_player(number).last_seen_at = last_seen_at
    end
  end

  def long_ago
    (DotsGamePlayer::TIMEOUT * 5).ago
  end

  # A second app server: its own Redis connection.
  def other_connection
    client = Redis.new(url: ENV["REDIS_URL"])
    ns = ENV["REDIS_NAMESPACE"]
    ns.present? ? Redis::Namespace.new(ns, redis: client) : client
  end

  it "streams the game and the owner's notifications" do
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from(PlayGameChannel.broadcasting_for("game:#{game_id}"))
    expect(subscription).to have_stream_from(PlayGameChannel.broadcasting_for(notification_key))
  end

  describe "#select_player" do
    it "sends a success notification when taking a free seat" do
      perform :select_player, number: 1

      expect(last_notification).to include("level" => "success", "message" => "Successfully became Player 1")
    end

    it "sends an info notification when becoming a spectator" do
      perform :select_player, number: 0

      expect(last_notification).to include("level" => "info", "message" => "You are now spectating")
    end

    it "sends an error notification when the seat is owned by someone else" do
      DotsGame.for_update(game_id) { |game| game.get_player(2).own("bob") }

      perform :select_player, number: 2

      expect(last_notification).to include("level" => "error", "message" => "Player 2 is already owned by someone else")
    end

    it "keeps the current seat when the requested one is taken" do
      perform :select_player, number: 1
      give_seat(2, "bob")

      perform :select_player, number: 2

      expect(game.player_1.owner).to eq("alice")
      expect(game.player_2.owner).to eq("bob")
      expect(last_notification).to include("level" => "error", "message" => "Player 2 is already owned by someone else")
    end

    it "moves to a free seat, giving up the old one" do
      perform :select_player, number: 1
      perform :select_player, number: 2

      expect(game.players.map(&:owner)).to eq([nil, "alice"])
    end

    it "gives up the seat when becoming a spectator" do
      perform :select_player, number: 1
      perform :select_player, number: 0

      expect(game.players.map(&:owner)).to eq([nil, nil])
    end

    it "takes over a seat whose owner has been quiet for longer than the timeout" do
      give_seat(2, "bob", last_seen_at: (DotsGamePlayer::TIMEOUT + 1.second).ago)

      perform :select_player, number: 2

      expect(game.player_2.owner).to eq("alice")
      expect(last_notification).to include("level" => "success")
    end

    it "sends only the outcome of the attempt that saved when the update retries" do
      first = true
      allow(DotsGame).to receive(:for_update).and_wrap_original do |original, id, &block|
        original.call(id) do |g|
          if first
            # Another server takes seat 2 after this attempt read the game.
            first = false
            other = DotsGame.find(id)
            other.get_player(2).own("bob")
            other_connection.set(other.key, other.to_json)
          end
          block.call(g)
        end
      end

      perform :select_player, number: 2

      expect(game.player_2.owner).to eq("bob")
      expect(notifications_to(notification_key).map { |n| n["level"] }).to eq(%w[error])
    end
  end

  describe "seat presence" do
    it "runs the heartbeat on a periodic timer, well inside the takeover window" do
      callback, options = described_class.periodic_timers.sole
      expect(options[:every]).to eq(DotsGamePlayer::HEARTBEAT)
      expect(DotsGamePlayer::HEARTBEAT * 3).to be <= DotsGamePlayer::TIMEOUT

      give_seat(1, "alice", last_seen_at: long_ago)
      subscription.instance_exec(&callback)

      expect(game.player_1.last_seen_at).to be_within(2.seconds).of(Time.now)
    end

    it "refreshes the owner's seat on subscribe and clears away" do
      DotsGame.for_update(game_id) do |g|
        g.get_player(1).own("alice")
        g.get_player(1).left!
        g.get_player(1).last_seen_at = long_ago
      end

      subscribe(id: game_id, user: "alice")

      expect(game.player_1.last_seen_at).to be_within(2.seconds).of(Time.now)
      expect(game.player_1.away).to be false
    end

    it "refreshes the owner's seat on every action" do
      give_seat(2, "alice", last_seen_at: long_ago)

      perform :move, x: 1, y: 0 # refused: not alice's turn, but she is here

      expect(game.player_2.last_seen_at).to be_within(2.seconds).of(Time.now)
    end

    it "refreshes on heartbeat without broadcasting the game" do
      give_seat(1, "alice", last_seen_at: long_ago)

      expect { perform :heartbeat }.not_to change { game_broadcasts.size }
      expect(game.player_1.last_seen_at).to be_within(2.seconds).of(Time.now)
    end

    it "writes nothing on heartbeat for a spectator" do
      expect { perform :heartbeat }.not_to change { game.updated_at }
    end

    it "keeps a seat claimed long ago while its owner stays connected" do
      give_seat(2, "bob", last_seen_at: long_ago)
      subscribe(id: game_id, user: "bob")
      perform :heartbeat

      subscribe(id: game_id, user: "alice")
      perform :select_player, number: 2

      expect(game.player_2.owner).to eq("bob")
      expect(last_notification).to include("level" => "error")
    end

    it "marks the seat away on unsubscribe but keeps it reserved" do
      perform :select_player, number: 1

      expect { unsubscribe }.to change { game_broadcasts.size }.by(1)
      expect(game.player_1.owner).to eq("alice")
      expect(game.player_1.away).to be true

      subscribe(id: game_id, user: "bob")
      perform :select_player, number: 1
      expect(game.player_1.owner).to eq("alice")
    end
  end

  describe "notifications" do
    # Two actions on one connection, interleaved so that both finish their
    # game update before either sends its toast.
    it "delivers each concurrent action's own toast" do
      give_seat(1, "bob")
      give_seat(2, "alice")
      barrier = Concurrent::CyclicBarrier.new(2)
      allow(subscription).to receive(:broadcast).and_wrap_original do |original, obj|
        barrier.wait(5) if obj.is_a?(DotsGame)
        original.call(obj)
      end

      threads = [
        Thread.new { perform :move, x: 1, y: 0 },         # bob's turn: warning
        Thread.new { perform :select_player, number: 1 }  # bob's seat: error
      ]
      threads.each { |t| expect(t.join(10)).to be_truthy }

      levels = notifications_to(notification_key).map { |n| n["level"] }
      expect(levels).to contain_exactly("warning", "error")
    end

    it "sends an error toast when the update keeps conflicting" do
      allow(DotsGame).to receive(:for_update).and_raise(RedisJsonModel::ConflictError)

      perform :move, x: 1, y: 0

      expect(last_notification).to include("level" => "error", "message" => /too busy/)
    end
  end

  describe "#update_player" do
    it "sends a success notification" do
      perform :select_player, number: 1
      perform :update_player, name: "Alice"

      expect(last_notification).to include("level" => "success", "message" => "Player details updated")
      expect(DotsGame.find(game_id).get_player(1).name).to eq("Alice")
    end
  end

  describe "#move" do
    it "sends a warning notification when it is not the owner's turn" do
      perform :select_player, number: 2
      perform :move, x: 1, y: 0

      expect(last_notification).to include("level" => "warning", "message" => "Not your turn")
    end
  end

  context "in a single-device game held by alice" do
    before do
      DotsGame.for_update(game_id) do |game|
        game.mode = "single_device"
        game.player = 1
        game.claim_device("alice")
      end
    end

    it "moves for whichever player's turn it is, keeping the turn after a box" do
      perform :move, x: 1, y: 0
      expect(game.player).to eq(2)
      perform :move, x: 0, y: 1
      perform :move, x: 2, y: 1
      expect(game.player).to eq(2)

      perform :move, x: 1, y: 2
      expect(game.score(2)).to eq(1)
      expect(game.player).to eq(2)

      perform :move, x: 3, y: 0
      expect(game.player).to eq(1)
      expect(game.board.get(3, 0)).to eq(DotsGameBoard::HLINE_CLOSE)
      expect(notifications_to(notification_key)).to be_empty
    end

    it "names either player" do
      perform :update_player, name: "Bea", number: 2
      perform :update_player, name: "Al", number: 1

      expect([game.player_1.name, game.player_2.name]).to eq(%w[Al Bea])
    end

    it "keeps both seats when the device tries to switch seats" do
      perform :select_player, number: 0

      expect(game.players.map(&:owner)).to eq(%w[alice alice])
      expect(last_notification).to include("level" => "info")
    end

    it "keeps the mode and seats on restart" do
      perform :move, x: 1, y: 0
      perform :restart

      expect(game).to be_single_device
      expect(game.players.map(&:owner)).to eq(%w[alice alice])
      expect(game.board.get(1, 0)).to eq(DotsGameBoard::HLINE_OPEN)
    end

    it "keeps both seats fresh on heartbeat" do
      DotsGame.for_update(game_id) { |g| g.players.each { |p| p.last_seen_at = long_ago } }

      perform :heartbeat

      expect(game.players.map(&:last_seen_at)).to all(be_within(2.seconds).of(Time.now))
    end

    it "keeps both seats when the device disconnects" do
      unsubscribe

      expect(game.players.map(&:owner)).to eq(%w[alice alice])
      expect(game.players.map(&:away)).to eq([true, true])
    end

    context "watched from another session" do
      let(:bob_key) { "game:#{game_id}:bob" }

      before do
        unsubscribe
        subscribe(id: game_id, user: "bob")
      end

      it "can't move" do
        perform :move, x: 1, y: 0

        expect(game.board.get(1, 0)).to eq(DotsGameBoard::HLINE_OPEN)
        expect(notifications_to(bob_key).last).to include("level" => "warning", "message" => "Not your turn")
      end

      it "can't take a seat" do
        perform :select_player, number: 1

        expect(game.players.map(&:owner)).to eq(%w[alice alice])
        expect(notifications_to(bob_key).last["message"]).to match(/single device/)
      end

      it "can't rename a player" do
        perform :update_player, name: "Bob", number: 1

        expect(game.player_1.name).not_to eq("Bob")
      end

      it "can't restart" do
        perform :move, x: 1, y: 0 # refused, so make a real move first
        DotsGame.for_update(game_id) { |g| g.move(x: 1, y: 0) }
        perform :restart

        expect(game.board.get(1, 0)).to eq(DotsGameBoard::HLINE_CLOSE)
      end
    end
  end
end
