Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  resources :masjids, only: [:index, :show] do
    resources :fundraisers, only: [:show] do
      resources :donations, only: [:new, :create] do
        collection do
          get :payment_confirmation
        end
      end
    end
  end
  post '/webhooks/stripe', to: 'webhooks#stripe'
  root "masjids#index"
end
