Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  resources :masjids, only: %i[index show] do
    resources :fundraisers, only: [:show] do
      resources :donations, only: %i[new create] do
        collection do
          get :review
          get :payment_confirmation
          post :create_payment_intent
        end
      end
    end
  end
  post '/webhooks/stripe', to: 'webhooks#stripe'
  root 'masjids#index'
end
