require "rails_helper"

RSpec.describe "Games", type: :request do
  let(:id) { "games-spec-#{SecureRandom.hex(4)}" }
  after { DotsGame.find(id)&.destroy }

  it "offers both modes on the new game form" do
    get "/games/new"
    expect(response.body).to include('value="network"', 'value="single_device"')
  end

  it "creates a network game by default" do
    post "/games", params: { dots_game: { id: id, width: 3, height: 3 } }
    game = DotsGame.find(id)
    expect(game.mode).to eq("network")
    expect(game.players.map(&:owner)).to all(be_nil)
  end

  it "creates a single-device game with both seats on the creating session" do
    post "/games", params: { dots_game: { id: id, width: 3, height: 3, mode: "single_device" } }
    expect(response).to redirect_to("http://www.example.com/games/#{id}")

    game = DotsGame.find(id)
    expect(game).to be_single_device
    expect(game.player_1.owner).to be_present
    expect(game.player_2.owner).to eq(game.player_1.owner)

    get "/games/#{id}"
    expect(response.body).to include("single-device", "Single device · Player #{game.player}&#39;s turn")
  end

  it "shows a single-device game to another session as spectating" do
    DotsGame.new(id: id, mode: "single_device").tap { |g| g.claim_device("someone-else") }.save
    get "/games/#{id}"
    expect(response.body).to include("single-device", "Spectating · Player 1&#39;s turn")
  end
end
