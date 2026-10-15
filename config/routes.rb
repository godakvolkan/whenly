Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check

  # Root route redirects to panel
  root to: "panel/dashboard#index"

  # Davetli ekranları (Public booking)
  get "/b/:token", to: "public_bookings#show", as: :booking_status
  patch "/b/:token/cancel", to: "public_bookings#cancel", as: :cancel_booking
  get "/:slug/:event_type", to: "public_bookings#new", as: :new_public_booking
  post "/:slug/:event_type", to: "public_bookings#create", as: :public_booking

  # Ev sahibi paneli (Host dashboard)
  namespace :panel do
    root to: "dashboard#index"
    resources :bookings, only: [:index, :show] do
      member do
        patch :confirm
        patch :decline
        patch :cancel
        patch :complete
        patch :no_show
      end
    end
    resources :event_types
    resources :availability_rules, only: [:index, :create]
  end
end
