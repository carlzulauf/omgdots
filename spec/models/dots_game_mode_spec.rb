require "rails_helper"

describe DotsGame, "mode" do
  let(:id) { "mode-spec-#{SecureRandom.hex(4)}" }
  after { DotsGame.find(id)&.destroy }

  it "defaults to a network game" do
    game = DotsGame.new
    expect(game.mode).to eq("network")
    expect(game).not_to be_single_device
  end

  it "stores a single-device game and exposes the mode in its JSON" do
    DotsGame.create(id: id, mode: "single_device")
    game = DotsGame.find(id)
    expect(game).to be_single_device
    expect(game.as_typed_json[:data]["mode"]).to eq("single_device")
  end

  it "falls back to a network game for an unknown mode" do
    expect(DotsGame.new(mode: "bogus").mode).to eq("network")
  end

  it "reads games saved before modes existed as network games" do
    DotsGame.create(id: id)
    DotsGame.redis.set(DotsGame.key_for(id), DotsGame.find(id).as_json.except("mode").to_json)
    expect(DotsGame.find(id).mode).to eq("network")
  end

  it "keeps the mode on restart" do
    game = DotsGame.new(mode: "single_device")
    game.move(x: 1, y: 0)
    game.restart
    expect(game).to be_single_device
  end

  context "with one device holding both seats" do
    subject(:game) { DotsGame.new(mode: "single_device").tap { |g| g.claim_device("dev") } }

    it "owns both seats" do
      expect(game.players.map(&:owner)).to eq(%w[dev dev])
    end

    it "plays from whoever's turn it is" do
      expect(game.seat_for("dev")).to eq(game.player_1)
      game.player = 2
      expect(game.seat_for("dev")).to eq(game.player_2)
    end

    it "moves for the current player every turn, without switching seats" do
      expect(game.owner_move("dev", x: 1, y: 0)).to be(true)
      expect(game.player).to eq(2)
      expect(game.owner_move("dev", x: 0, y: 1)).to be(true)
      expect(game.player).to eq(1)
    end

    it "keeps the turn with the player who completes a box" do
      # The top-left box's four sides, alternating turns until the last one.
      [[1, 0], [0, 1], [2, 1]].each { |x, y| game.owner_move("dev", x: x, y: y) }
      expect(game.player).to eq(2)

      expect(game.owner_move("dev", x: 1, y: 2)).to be(true)
      expect(game.score(2)).to eq(1)
      expect(game.player).to eq(2)
      expect(game.seat_for("dev")).to eq(game.player_2)

      expect(game.owner_move("dev", x: 3, y: 0)).to be(true)
      expect(game.player).to eq(1)
    end

    it "refuses moves from other sessions" do
      expect(game.owner_move("someone", x: 1, y: 0)).to be(false)
      expect(game.seat_for("someone")).to be_nil
      expect(game.seat_for(nil)).to be_nil
    end
  end

  context "in a network game" do
    subject(:game) { DotsGame.new.tap { |g| g.player_1.own("alice") } }

    it "only moves on the owner's turn" do
      game.player = 2
      expect(game.seat_for("alice")).to eq(game.player_1)
      expect(game.owner_move("alice", x: 1, y: 0)).to be(false)
      game.player = 1
      expect(game.owner_move("alice", x: 1, y: 0)).to be(true)
    end
  end
end
