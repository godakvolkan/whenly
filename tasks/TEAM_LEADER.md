# TEAM LEADER - Gorev Listesi

> Koordinasyon, iskelet, CI/CD, deploy, dokumantasyon

---

## GUN 1 (Persembe 15 Ekim)

### TL-01: Rails Projesi Iskelet Olusturma
- [ ] `rails new slotwise --database=postgresql --css=propshaft --skip-javascript --skip-jbuilder`
- [ ] Rails 8.1 versiyonunu Gemfile'da sabitle
- [ ] `config/application.rb` icinde `config.time_zone = "Istanbul"` ayarla
- [ ] `config/database.yml` PostgreSQL ayarlari (development: slotwise_dev, test: slotwise_test)
- [ ] `.ruby-version` dosyasi olustur (3.3.x)
- [ ] Gereksiz gem'leri Gemfile'dan cikar (importmap yerine pin kullanilacaksa kontrol et)

### TL-02: Solid Queue Yapilandirmasi
- [ ] `Gemfile`'a `solid_queue` ekle, `bundle install`
- [ ] `bin/rails solid_queue:install` calistir
- [ ] `config/puma.rb` icine `plugin :solid_queue` ekle
- [ ] `config/recurring.yml` olustur:
  ```yaml
  expire_pending_bookings:
    class: ExpirePendingBookingsJob
    schedule: every minute
  ```
- [ ] Development ortaminda Solid Queue'nun Puma icinde calistigini dogrula

### TL-03: Authentication (Rails 8 Yerlesik)
- [ ] `bin/rails generate authentication` calistir
- [ ] Uretilen User modeline `slug` alani ekle (migration)
- [ ] Session controller'i incele, gereksiz endpoint'leri kaldir
- [ ] `/panel` altindaki tum route'lari `authenticate` ile koru

### TL-04: GitHub Repo & CI Pipeline
- [ ] GitHub'da repo olustur (public)
- [ ] `.github/workflows/ci.yml` olustur:
  ```yaml
  name: CI
  on: [push, pull_request]
  jobs:
    test:
      runs-on: ubuntu-latest
      services:
        postgres:
          image: postgres:16
          env:
            POSTGRES_PASSWORD: password
          ports: ["5432:5432"]
          options: --health-cmd pg_isready
      steps:
        - uses: actions/checkout@v4
        - uses: ruby/setup-ruby@v1
          with:
            bundler-cache: true
        - run: bin/rails db:setup
        - run: bin/rails test
    lint:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: ruby/setup-ruby@v1
          with:
            bundler-cache: true
        - run: bundle exec rubocop
    security:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: ruby/setup-ruby@v1
          with:
            bundler-cache: true
        - run: bundle exec brakeman --no-pager
  ```
- [ ] Gemfile'a `rubocop-rails-omakase` ve `brakeman` ekle
- [ ] Ilk commit & push, CI'in yesil yandigini dogrula

### TL-05: Route Yapisi
- [ ] `config/routes.rb` duzenle:
  ```ruby
  # Davetli ekranlari
  get "/:slug/:event_type", to: "public_bookings#new", as: :new_public_booking
  post "/:slug/:event_type", to: "public_bookings#create"
  get "/b/:token", to: "public_bookings#show", as: :booking_status

  # Ev sahibi paneli
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
    resources :availability_rules, only: [:index, :create, :update, :destroy]
  end
  ```

---

## GUN 2 (Cuma 16 Ekim)

### TL-06: Render Deploy
- [ ] `Dockerfile` olustur (Rails 8 varsayilan Dockerfile'i temel al)
- [ ] `render.yaml` (Blueprint) olustur:
  ```yaml
  services:
    - type: web
      name: slotwise
      runtime: ruby
      plan: free
      buildCommand: bundle install; bin/rails db:migrate
      startCommand: bin/rails server
      envVars:
        - key: RAILS_MASTER_KEY
          sync: false
        - key: DATABASE_URL
          fromDatabase:
            name: slotwise-db
            property: connectionString
  databases:
    - name: slotwise-db
      plan: free
  ```
- [ ] Render'da repo bagla, ilk deploy
- [ ] Canli URL'de uygulamanin acildigini dogrula
- [ ] `RAILS_MASTER_KEY` environment variable olarak ekle

### TL-07: Seed Data (Demo Verisi)
- [ ] `db/seeds.rb` olustur:
  ```ruby
  # Demo ev sahibi
  user = User.create!(
    name: "Volkan Godak",
    email_address: "demo@slotwise.dev",
    password: "password123",
    slug: "volkan"
  )

  # Randevu turleri
  mentorluk = user.event_types.create!(
    name: "Mentorluk",
    duration_minutes: 30,
    requires_approval: true,
    approval_window_hours: 24
  )

  user.event_types.create!(
    name: "Tanitim Gorusmesi",
    duration_minutes: 15,
    requires_approval: false,
    approval_window_hours: nil
  )

  # Musaitlik kurallari (Pzt-Cum 09:00-17:00)
  (1..5).each do |day|
    user.availability_rules.create!(
      day_of_week: day,
      start_time: "09:00",
      end_time: "17:00"
    )
  end
  ```

---

## GUN 3 (Cumartesi 17 Ekim)

### TL-08: README.md
- [ ] CI rozeti (GitHub Actions badge)
- [ ] Canli URL linki
- [ ] Faz 1: Fortune 500 verileri (kaynakli)
- [ ] Faz 2: Kod olcegi & maliyet
- [ ] Calendly Community kaniti (Allie M alintisi, tarih, link)
- [ ] SlotWise'in cozumu (onay kuyrugu + auto-expire + no-show kurali)
- [ ] Kurulum talimatlari (clone, bundle, db:setup, rails s)
- [ ] Ekran goruntuleri
- [ ] **Yapamadiklarim** bolumu:
  - E-posta bildirimi yok
  - Render 30 gun sonra DB siliyor
  - Soguk acilis ~1 dk
  - Takvim entegrasyonu (Google/Outlook) yok
  - Coklu zaman dilimi destegi yok

### TL-09: AGENT.md
- [ ] Her gunku calisma ozeti (hangi dosya, hangi karar, neden)
- [ ] Ajanla yapilan diyalog ornekleri
- [ ] Degisen kararlar ve nedenleri (ornegin AI Brief neden cikarildi)
- [ ] Ogrenilenler

---

## GUN 4 (Pazar 18 Ekim)

### TL-10: Canli Prova
- [ ] Render'da son deploy
- [ ] Uctan uca senaryo:
  1. `/volkan/mentorluk` ac, saat sec, form doldur -> booking olusur
  2. `/b/:token` sayfasinda "onay bekliyor" gorunur
  3. `/panel` ac, pending booking gorunur, onayla
  4. `/b/:token` sayfasinda "onaylandi" gorunur
  5. Toplanti gecmis saati icin `complete` yap
  6. Ayni davetli icin 2. kez `no_show` yap, 3. rezervasyonda otomatik `pending` geldigini dogrula
- [ ] Sunumdan 5 dk once Render linkini acip uyandirmak icin hatirlatma koy
- [ ] Sunum notlarini hazirla (5 dk, kronometreli)
