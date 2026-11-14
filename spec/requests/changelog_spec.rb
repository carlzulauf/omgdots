require "rails_helper"

RSpec.describe "Changelog", type: :request do
  it "is not routed outside development" do
    expect(Rails.application.routes.recognize_path("/changelog")).to be_nil
  rescue ActionController::RoutingError
    # expected: the route only exists in development
  end

  it "returns 404 outside development" do
    get "/changelog"
    expect(response).to have_http_status(:not_found)
  end

  context "with the development routes drawn" do
    around do |example|
      with_routing do |set|
        set.draw do
          get "changelog" => "changelog#show", as: :changelog
          get "changelog/media/:filename" => "changelog#media", as: :changelog_media,
            constraints: { filename: %r{[^/]+} }, format: false
        end
        example.run
      end
    end

    it "is still guarded by the controller outside development" do
      get "/changelog"
      expect(response).to have_http_status(:not_found)
    end

    context "in development" do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("development")) }

      it "renders the page" do
        get "/changelog"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Changelog", "Queue", "Done")
      end

      it "serves media inline and 404s for anything else" do
        file = Changelog.load.entries.flat_map(&:media).map(&:file).find { |f| f.end_with?(".png") && Changelog::MEDIA_DIR.join(f).file? }
        get "/changelog/media/#{file}"
        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Disposition"]).to start_with("inline")
        expect(response.media_type).to eq "image/png"

        get "/changelog/media/nope.png"
        expect(response).to have_http_status(:not_found)

        get "/changelog/media/..%2Fchangelog.yml"
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
