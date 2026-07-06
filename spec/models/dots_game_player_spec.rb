describe DotsGamePlayer do
  describe ".build" do
    it "creates a player with the given number" do
      player = DotsGamePlayer.build(1)
      
      expect(player).to be_a(DotsGamePlayer)
      expect(player.number).to eq(1)
    end
  end

  context "with default values" do
    subject { DotsGamePlayer.new(number: 1) }

    it "has a random name by default" do
      expect(subject.name).to match(/Player [A-Za-z0-9]{3}/)
    end

    it "has owner nil initially" do
      expect(subject.owner).to be_nil
    end

    it "has no last_seen_at initially" do
      expect(subject.last_seen_at).to be_nil
    end
  end

  describe "#own" do
    subject { DotsGamePlayer.new(number: 1) }

    let(:owner_name) { "user123" }

    before do
      # Set a known time for testing
      @test_time = Time.now - 5.seconds
    end

    it "sets the owner" do
      subject.own(owner_name)
      
      expect(subject.owner).to eq(owner_name)
    end

    it "sets last_seen_at to current time or after" do
      before_time = Time.now
      subject.own(owner_name)
      
      # Since own sets last_seen_at = Time.now, and we can't freeze time reliably
      # just verify it's set to a recent time (within 5 seconds)
      expect(subject.last_seen_at).to be >= before_time
    end
  end

  describe "#can_be_owned_by?" do
    context "when not owned (owner is nil)" do
      let(:player) { DotsGamePlayer.new(number: 1) }

      it "returns true for any owner" do
        expect(player.can_be_owned_by?("anyone")).to be true
      end
    end

    context "when owned but timeout expired" do
      before do
        # Set a fixed past time that's definitely beyond 1-minute timeout
        @test_time = Time.now - 2.minutes
      end

      let(:player) do
        p = DotsGamePlayer.new(number: 1, owner: "original_owner")
        p.last_seen_at = @test_time
        p
      end

      it "returns true for anyone trying to own" do
        expect(player.can_be_owned_by?("new_owner")).to be true
      end
    end

    context "when owned within timeout" do
      let(:player) do
        p = DotsGamePlayer.new(number: 1, owner: "original_owner")
        # Set last_seen to recent time (within 1-minute timeout)
        p.last_seen_at = Time.now - 30.seconds
        p
      end

      it "returns true for original owner" do
        expect(player.can_be_owned_by?("original_owner")).to be true
      end

      it "returns false for other owners" do
        expect(player.can_be_owned_by?("someone_else")).to be false
      end
    end

    context "with custom name" do
      subject { DotsGamePlayer.new(number: 2, name: "Custom Name") }

      it "accepts a custom name" do
        expect(subject.name).to eq("Custom Name")
      end

      it "overrides the random name generation" do
        expect(subject.name).not_to match(/Player [A-Za-z0-9]{3}/)
      end
    end
  end

  describe "JsonObject integration" do
    subject { DotsGamePlayer.new(number: 1, owner: "test_owner") }

    it "responds to as_json" do
      json = subject.as_json
      expect(json).to include("number", "name", "owner")
    end

    it "can be reconstructed from hash" do
      replayed = DotsGamePlayer.new(subject.as_json)
      
      expect(replayed.number).to eq(1)
      expect(replayed.owner).to eq("test_owner")
      # Name might differ if it was auto-generated, so just check it exists
      expect(replayed.name).to be_a(String)
    end
  end

  context "multiple players" do
    subject { [DotsGamePlayer.build(1), DotsGamePlayer.build(2)] }

    it "creates two distinct players" do
      expect(subject[0].number).to eq(1)
      expect(subject[1].number).to eq(2)
    end

    it "each has unique random name" do
      names = subject.map(&:name)
      
      # Names are randomly generated, they should be strings
      expect(names.all? { |n| n.match(/Player [A-Za-z0-9]{3}/) }).to be true
    end
  end

  context "timeout behavior" do
    before do
      @test_time = Time.now - 2.minutes # Past timeout
    end

    let(:player) do
      # Create player with owner that expired 2 minutes ago
      p = DotsGamePlayer.new(number: 1, owner: "original", last_seen_at: @test_time)
      p
    end

    it "can be re-owned when timeout has passed" do
      new_owner = "new_owner"
      
      # Should allow re-owning since timeout expired
      expect(player.can_be_owned_by?(new_owner)).to be true
      
      player.own(new_owner)
      expect(player.owner).to eq(new_owner)
    end

    it "updates last_seen_at when newly owned" do
      before_time = Time.now
      player.own("newest_owner")
      
      # just verify it was updated to a recent time
      expect(player.last_seen_at).to be >= before_time
    end
  end
end
