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

    def game
      DotsGame.find(game_id)
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
