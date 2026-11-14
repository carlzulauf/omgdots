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
end
