Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  # A game id is whatever the player typed, dots included: /games/v1.2 is
  # game "v1.2", not game "v1" as format "2".
  resources :games, only: %i[new create show], constraints: { id: %r{[^/]+} }, format: false
  root to: "games#new"

  # Health check: 200 if the app boots without exceptions, 500 otherwise.
  get "up" => "rails/health#show", as: :rails_health_check

  # Development-only change log (doc/changelog). Never drawn in production.
  if Rails.env.development?
    get "changelog" => "changelog#show", as: :changelog
    get "changelog/media/:filename" => "changelog#media", as: :changelog_media,
      constraints: { filename: %r{[^/]+} }, format: false
  end
end
