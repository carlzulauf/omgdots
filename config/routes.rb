Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :games do
    member do
      post :restart
    end
  end
  resources :tests
  root to: "games#new"
end
