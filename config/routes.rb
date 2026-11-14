Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :games do
    member do
      post :restart
    end
  end
  resources :tests
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
