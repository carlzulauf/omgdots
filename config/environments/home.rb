# The home deployment runs like production, apart from its Action Cable origin.
require_relative "production"

Rails.application.configure do
  config.action_cable.allowed_request_origins = [
    ENV.fetch("BASE_URL", "https://omgdots.home.mrks.io")
  ]
end
