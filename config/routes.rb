Rails.application.routes.draw do
  get "machines/index"
  get "machines/show"
  get "machines/new"
  get "machines/create"
  get "machines/edit"
  get "machines/update"
  get "machines/destroy"
  get "home/index"
  root to: "home#index"
  resource :session
  resource :registration, only: [ :new, :create ]
  resources :passwords, param: :token

  resources :products do
    resources :ingredients, except: [ :show ]
  end

  resources :prepares do
    member do
      patch :check
      get :checking
      patch :update_check
      patch :cancel
      patch :complete
    end
  end

  resources :produces do
    member do
      patch :start_production
      patch :complete_production
      get :machine_checking
      patch :update_machine_checking
      patch :select_machine
    end
  end

  patch "produces/move_to_produce/:unit_batch_id", to: "produces#move_to_produce", as: :move_to_produce

  resources :machines

  resources :unit_batches

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
