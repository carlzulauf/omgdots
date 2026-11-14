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
    expect(seat_buttons).to eq(
      1 => { pressed: "true", disabled: "true" },
      2 => { pressed: "false", disabled: "true" },
      0 => { pressed: "false", disabled: "true" }
    )
    expect(page.css(".name.editable").size).to eq(2)
  end

  it "shows a single-device game to another session as spectating" do
    DotsGame.new(id: id, mode: "single_device").tap { |g| g.claim_device("someone-else") }.save
    get "/games/#{id}"
    expect(seat_buttons).to eq(
      1 => { pressed: "false", disabled: "true" },
      2 => { pressed: "false", disabled: "true" },
      0 => { pressed: "true", disabled: "true" }
    )
    expect(page.at_css(".seat-button-1")["title"]).to include("single device")
    expect(page.css(".name.editable")).to be_empty
  end

  it "shows the share button, seat buttons and share popover on a network game" do
    get "/games/#{id}"
    expect(page.css(".game-menu .menu-button").map { |b| b["aria-label"] || b.text.strip })
      .to eq(["Share", "Player 1", "Player 2", "Spectator"])
    expect(seat_buttons.values).to all(include(disabled: "false"))
    expect(seat_buttons[0][:pressed]).to eq("true")
    popover = page.at_css(".share-popover[popover]")
    expect(page.at_css(".share-button")["popovertarget"]).to eq(popover["id"])
    expect(popover.at_css(".share-url")["value"]).to eq("http://www.example.com/games/#{id}")
  end

  def page
    Nokogiri::HTML(response.body)
  end

  def seat_buttons
    page.css(".seat-button").to_h do |button|
      [button["data-number"].to_i, { pressed: button["aria-pressed"], disabled: button["aria-disabled"] }]
    end
  end
end
