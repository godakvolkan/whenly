Rails.application.routes.draw do
  resource :session
  resource :registration, only: [:new, :create]
  get "signup", to: "registrations#new", as: :signup
  get "login", to: "sessions#new", as: :login
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

  # Root route: Kullanıcı rolüne göre dinamik yönlendirme
  root to: "home#index"

  # Müşteri / Davetli Paneli (Client dashboard)
  namespace :client do
    root to: "bookings#index"
    resources :bookings, only: [:index, :show] do
      member do
        patch :cancel
        get :reschedule
        patch :request_reschedule
        patch :accept_reschedule
        patch :reject_reschedule
      end
    end
  end

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
        get :reschedule
        patch :request_reschedule
        patch :accept_reschedule
        patch :reject_reschedule
      end
    end
    resources :event_types
    resources :availability_rules, only: [:index, :create]
    resource :profile, only: [:edit, :update], controller: "profile"
    get "api", to: "api_info#show", as: :api_info
    patch "api/regenerate", to: "api_info#regenerate_token", as: :regenerate_api_token
  end

  # Davetli durum ekranı, tarih değiştirme ve iptal
  get "/b/:token", to: "public_bookings#show", as: :booking_status
  get "/b/:token/ics", to: "public_bookings#show", as: :booking_ics, defaults: { format: :ics }
  patch "/b/:token/cancel", to: "public_bookings#cancel", as: :cancel_booking
  get "/b/:token/reschedule", to: "public_bookings#reschedule_form", as: :reschedule_booking
  patch "/b/:token/reschedule", to: "public_bookings#request_reschedule", as: :submit_reschedule_booking
  patch "/b/:token/accept_reschedule", to: "public_bookings#accept_reschedule", as: :accept_reschedule_booking
  patch "/b/:token/reject_reschedule", to: "public_bookings#reject_reschedule", as: :reject_reschedule_booking

  # Davetli profil ve rezervasyon rotaları (Wildcard rotalar en sonda olmalıdır)
  get "/:slug", to: "public_profiles#show", as: :public_profile
  get "/:slug/:event_type", to: "public_bookings#new", as: :new_public_booking
  post "/:slug/:event_type", to: "public_bookings#create", as: :public_booking
end
