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
end
