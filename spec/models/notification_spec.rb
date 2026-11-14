describe Notification do
  describe ".new" do
    it "initializes with no arguments" do
      notification = Notification.new
      
      expect(notification).to be_a(Notification)
      expect(notification.level).to eq("info") # default from model
    end

    it "initializes with attributes" do
      attrs = {
        game_id: "abc123",
        owner: "player1",
        level: "info",
        message: "Test notification"
      }
      
      notification = Notification.new(attrs)
      
      expect(notification.game_id).to eq("abc123")
      expect(notification.owner).to eq("player1")
      expect(notification.level).to eq("info")
      expect(notification.message).to eq("Test notification")
    end
  end

  context "with defaults" do
    subject { Notification.new }

    it "has info level by default" do
      expect(subject.level).to eq("info")
    end

    it "generates created_at timestamp" do
      expect(subject.created_at).to be_a(Time)
    end
  end

  describe "LEVELS" do
    it "lists the levels the client knows how to style" do
      expect(Notification::LEVELS).to eq(%w[success info warning error])
    end

    it "includes the default level" do
      expect(Notification::LEVELS).to include(Notification::DEFAULT_LEVEL)
    end
  end

  describe "level predicates" do
    it "is true only for the notification's own level" do
      notification = Notification.new(level: "success")

      expect(notification).to be_success
      expect(notification).not_to be_info
      expect(notification).not_to be_warning
      expect(notification).not_to be_error
    end
  end

  describe "#channel_key" do
    subject { Notification.new(game_id: "game123", owner: "player1") }

    it "generates the correct channel key format" do
      expect(subject.channel_key).to eq("game:game123:player1")
    end

    it "handles different game IDs" do
      subject.game_id = "another_game"
      expect(subject.channel_key).to eq("game:another_game:player1")
    end

    it "handles different owners" do
      subject.owner = "different_owner"
      expect(subject.channel_key).to eq("game:game123:different_owner")
    end

    context "with multiple owner segments" do
      subject { Notification.new(game_id: "game1", owner: "user/sub/user") }
      
      it "includes all owner path segments" do
        expect(subject.channel_key).to eq("game:game1:user/sub/user")
      end
    end
  end

  describe "#as_typed_json" do
    subject do
      Notification.new(
        game_id: "game456",
        owner: "player2",
        level: "success",
        message: "Game over!"
      )
    end

    it "wraps data with type" do
      json = subject.as_typed_json
      
      expect(json[:type]).to eq("notification")
      expect(json[:data]).to be_a(Hash)
    end

    it "contains all notification fields in data" do
      data = subject.as_typed_json[:data]
      
      expect(data["game_id"]).to eq("game456")
      expect(data["owner"]).to eq("player2")
      expect(data["level"]).to eq("success")
      expect(data["message"]).to eq("Game over!")
    end

    it "includes created_at timestamp" do
      data = subject.as_typed_json[:data]
      
      # The JSON serializer converts Time to ISO8601 string
      expect(data["created_at"]).to be_a(String)
    end
  end

  context "with JSON serialization" do
    subject { Notification.new(game_id: "game789", owner: "player3") }

    it "can convert to JSON string" do
      json_str = subject.to_json
      
      expect(json_str).to be_a(String)
      expect(json_str.include?(subject.game_id)).to be true
      expect(json_str.include?(subject.owner)).to be true
    end

    it "round-trips through JSON" do
      original_data = subject.as_typed_json
      json_str = subject.to_json
      parsed = JSON.parse(json_str, symbolize_names: false)
      
      # to_json only returns the data portion, not typed wrapper
      expect(parsed["game_id"]).to eq(subject.game_id)
    end
  end

  describe "variable field handling" do
    it "accepts arbitrary hash fields" do
      notification = Notification.new(
        game_id: "g1",
        owner: "o1",
        extra_field: "extra_value"
      )
      
      # Extra fields should be stored in object
      expect(notification.object["extra_field"]).to eq("extra_value")
    end

    it "handles empty message" do
      notification = Notification.new(
        game_id: "game",
        owner: "owner",
        message: ""
      )
      
      expect(notification.message).to eq("")
    end

    it "handles nil message gracefully" do
      notification = Notification.new(game_id: "g", owner: "o")
      
      # message field should be nil
      expect(notification.message).to be_nil
    end
  end

  context "with different severity levels" do
    subject { Notification.new }

    it "accepts any level string" do
      %w[debug info warn error fatal].each do |level|
        subject.level = level
        expect(subject.level).to eq(level)
      end
    end

    it "accepts level from constructor" do
      subject.level = "warning"
      expect(subject.level).to eq("warning")
    end
  end

  describe "as_json integration" do
    subject do
      Notification.new(
        game_id: "test_game",
        owner: "test_owner",
        message: "Test message",
        created_at: Time.utc(2023, 1, 15, 10, 30, 0)
      )
    end

    it "formats time consistently" do
      json = subject.as_json
      
      expect(json["created_at"]).to be_a(String) # JSON serializes to ISO8601 string
    end

    it "preserves all fields" do
      data = subject.as_typed_json[:data]
      
      expect(data.keys.sort).to eq(%w[created_at game_id level message owner])
    end
  end

  context "multiple notifications for same game" do
    let(:notifications) do
      [
        Notification.new(game_id: "g1", owner: "o1", message: "First"),
        Notification.new(game_id: "g1", owner: "o2", message: "Second"),
        Notification.new(game_id: "g2", owner: "o1", message: "Third")
      ]
    end

    it "each has unique channel keys" do
      keys = notifications.map(&:channel_key)
      
      expect(keys.uniq.length).to eq(3)
    end

    it "same game different owners have different channels" do
      game_notifications = notifications.select { |n| n.game_id == "g1" }
      
      expect(game_notifications[0].channel_key).not_to eq(game_notifications[1].channel_key)
    end

    it "same owner different games have different channels" do
      owner_notifications = notifications.select { |n| n.owner.start_with?("o1") }
      
      # Select returns 2 items: o1 in g1 and o1 in g2
      expect(owner_notifications.length).to eq(2)
      expect(owner_notifications[0].channel_key).not_to eq(owner_notifications[1].channel_key)
    end
  end
end
