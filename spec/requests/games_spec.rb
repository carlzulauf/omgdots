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

  it "shows the back, share and seat buttons above the scoreboard on a network game" do
    get "/games/#{id}"
    expect(page.css(".game-menu .menu-button").map { |b| b["aria-label"] || b.text.strip })
      .to eq(["Back to home", "Share", "Player 1", "Player 2", "Spectator"])
    expect(page.at_css(".game-menu .back-button")["href"]).to eq("/")
    expect(page.css(".game-ui > *").map { |e| e["class"] }.first(2)).to eq(["game-menu", "scoreboard"])
    expect(seat_buttons.values).to all(include(disabled: "false"))
    expect(seat_buttons[0][:pressed]).to eq("true")
    popover = page.at_css(".share-popover[popover]")
    expect(page.at_css(".share-button")["popovertarget"]).to eq(popover["id"])
    expect(popover.at_css(".share-url")["value"]).to eq("http://www.example.com/games/#{id}")
  end

  it "keeps dots in a game id instead of reading them as a format" do
    dotted = "#{id}.v1.2"
    get "/games/#{dotted}"

    expect(response).to have_http_status(:ok)
    expect(page.at_css(".game-container")["id"]).to eq("game-#{dotted}")
  ensure
    DotsGame.find(dotted)&.destroy
  end

  it "routes only the actions the app has" do
    expect(Rails.application.routes.recognize_path("/games/x", method: :get)).to include(action: "show")
    expect { Rails.application.routes.recognize_path("/games/x", method: :delete) }
      .to raise_error(ActionController::RoutingError)
    expect { Rails.application.routes.recognize_path("/games/x/restart", method: :post) }
      .to raise_error(ActionController::RoutingError)
  end

  it "points the game-over Restart link nowhere, leaving it to the channel" do
    get "/games/#{id}"
    expect(page.at_css(".page-overlay .restart-link")["href"]).to eq("#")
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
