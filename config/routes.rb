Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  post "telegram/webhook", to: "telegram_webhook#create"

  # REST API
  namespace :api do
    namespace :v1 do
      resources :bookings, only: [:index, :show, :create] do
        member do
          patch :confirm
          patch :decline
          patch :cancel
          get :ics
        end
      end
      resources :event_types, only: [:index, :show] do
        member do
          get :available_slots
        end
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # Root route redirects to panel
  root to: "panel/dashboard#index"

  # Ev sahibi paneli (Host dashboard) - Rotalar önceliklidir
  namespace :panel do
    root to: "dashboard#index"
    resources :bookings, only: [:index, :show] do
      member do
        patch :confirm
        patch :decline
        patch :cancel
        patch :expire
        patch :complete
        patch :no_show
      end
    end
    resources :event_types
    resources :availability_rules, only: [:index, :create]
    get "api", to: "api_info#show", as: :api_info
    patch "api/regenerate", to: "api_info#regenerate_token", as: :regenerate_api_token
  end

  # Davetli durum ekranı ve iptal
  get "/b/:token", to: "public_bookings#show", as: :booking_status
  get "/b/:token/ics", to: "public_bookings#show", as: :booking_ics, defaults: { format: :ics }
  patch "/b/:token/cancel", to: "public_bookings#cancel", as: :cancel_booking

  # Davetli rezervasyon rotası (Wildcard rota en sonda olmalıdır)
  get "/:slug/:event_type", to: "public_bookings#new", as: :new_public_booking
  post "/:slug/:event_type", to: "public_bookings#create", as: :public_booking
end
