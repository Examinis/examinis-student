Rails.application.routes.draw do
  resources :members

  resources :exams, only: [ :index, :show ] do
    post "submit", on: :member
    get "answered", on: :collection
    get "answered/:id", to: "exams#answered_show", on: :collection, as: "answered_show"
  end

  resources :question_answers do
    member do
      post :request_ai_correction
    end
  end

  devise_for :users, controllers: {
    registrations: "users/registrations"
  }
  get "home/index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
