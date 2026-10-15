# BACKEND - Gorev Listesi

> Modeller, durum makinesi, zaman kurallari, slot hesaplama, arka plan isleri

---

## GUN 1 (Persembe 15 Ekim)

### BE-01: User Modeli (Genisletme)
- [ ] Rails 8 authentication zaten User olusturuyor; ustune migration ekle:
  ```ruby
  add_column :users, :slug, :string, null: false
  add_column :users, :name, :string, null: false
  add_index :users, :slug, unique: true
  ```
- [ ] `User` modeline:
  ```ruby
  has_many :event_types, dependent: :destroy
  has_many :availability_rules, dependent: :destroy
  has_many :bookings, dependent: :destroy

  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/ }
  validates :name, presence: true

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug ||= name&.parameterize
  end
  ```

### BE-02: EventType Modeli
- [ ] Migration olustur:
  ```ruby
  create_table :event_types do |t|
    t.references :user, null: false, foreign_key: true
    t.string :name, null: false
    t.integer :duration_minutes, null: false, default: 30
    t.boolean :requires_approval, null: false, default: true
    t.integer :approval_window_hours, default: 24
    t.string :slug, null: false
    t.timestamps
  end
  add_index :event_types, [:user_id, :slug], unique: true
  ```
- [ ] Model validasyonlari:
  ```ruby
  belongs_to :user
  has_many :bookings, dependent: :destroy

  validates :name, presence: true
  validates :duration_minutes, inclusion: { in: [15, 30, 45, 60] }
  validates :slug, presence: true, uniqueness: { scope: :user_id }
  validates :approval_window_hours, numericality: { greater_than: 0 }, allow_nil: true

  before_validation :generate_slug, on: :create
  ```

### BE-03: AvailabilityRule Modeli
- [ ] Migration olustur:
  ```ruby
  create_table :availability_rules do |t|
    t.references :user, null: false, foreign_key: true
    t.integer :day_of_week, null: false  # 1=Pzt, 7=Paz
    t.time :start_time, null: false
    t.time :end_time, null: false
    t.timestamps
  end
  add_index :availability_rules, [:user_id, :day_of_week], unique: true
  ```
- [ ] Model validasyonlari:
  ```ruby
  belongs_to :user

  validates :day_of_week, inclusion: { in: 1..7 },
            uniqueness: { scope: :user_id }
  validates :start_time, :end_time, presence: true
  validate :end_after_start

  private

  def end_after_start
    return unless start_time && end_time
    errors.add(:end_time, "baslangictan sonra olmali") if end_time <= start_time
  end
  ```

### BE-04: Booking Modeli + Durum Makinesi
- [ ] Migration olustur:
  ```ruby
  create_table :bookings do |t|
    t.references :user, null: false, foreign_key: true
    t.references :event_type, null: false, foreign_key: true
    t.string :invitee_name, null: false
    t.string :invitee_email, null: false
    t.datetime :starts_at, null: false
    t.datetime :ends_at, null: false
    t.string :status, null: false, default: "pending"
    t.datetime :approval_deadline_at
    t.string :token, null: false
    t.timestamps
  end
  add_index :bookings, :token, unique: true
  add_index :bookings, [:user_id, :starts_at],
            unique: true,
            where: "status IN ('pending', 'confirmed')",
            name: "idx_bookings_no_double"
  ```
- [ ] Durum makinesi (gem yok, acik kod):
  ```ruby
  class Booking < ApplicationRecord
    belongs_to :user
    belongs_to :event_type

    STATUSES = %w[pending confirmed declined canceled completed no_show expired].freeze

    TRANSITIONS = {
      "pending"   => %w[confirmed declined canceled expired],
      "confirmed" => %w[canceled completed no_show],
    }.freeze

    validates :status, inclusion: { in: STATUSES }
    validates :invitee_name, :invitee_email, :starts_at, :ends_at, presence: true
    validates :token, presence: true, uniqueness: true

    before_validation :set_token, on: :create

    class InvalidTransition < StandardError; end

    TRANSITIONS.each do |from, to_list|
      to_list.each do |to|
        define_method(:"#{to}!") do
          raise InvalidTransition, "#{status} -> #{to} izin verilmiyor" unless status == from
          update!(status: to)
        end
      end
    end

    scope :active, -> { where(status: %w[pending confirmed]) }
    scope :pending_expired, -> {
      where(status: "pending")
        .where("approval_deadline_at <= ?", Time.current)
    }

    private

    def set_token
      self.token ||= SecureRandom.urlsafe_base64(16)
    end
  end
  ```
- [ ] **DIKKAT:** `confirm!` hem `pending->confirmed` hem diger gecislerde kullaniliyor. `define_method` dongusu `from` degerine gore metot tanimi yapiyor. Her `to` degeri icin son tanimli `from` gecerli olacak. Ayni `to` icin birden fazla `from` varsa (ornegin `canceled` hem pending hem confirmed'dan geliyor) bunu handle et:
  ```ruby
  # canceled icin ozel durum: hem pending hem confirmed'dan gecilebilir
  def cancel!
    raise InvalidTransition, "#{status} -> canceled" unless %w[pending confirmed].include?(status)
    update!(status: "canceled")
  end
  ```

### BE-05: SchedulingRules (3 Zaman Kurali)
- [ ] `app/models/scheduling_rules.rb` olustur:
  ```ruby
  class SchedulingRules
    MINIMUM_NOTICE_HOURS = 2
    NO_SHOW_THRESHOLD = 2
    NO_SHOW_MARKING_DELAY_MINUTES = 15

    # Kural 1: En az 2 saat onceden rezervasyon
    def self.bookable?(starts_at)
      starts_at >= MINIMUM_NOTICE_HOURS.hours.from_now
    end

    # Kural 2: Onay suresi hesaplama
    def self.approval_deadline_for(booking)
      event_window = booking.created_at + booking.event_type.approval_window_hours.hours
      meeting_cutoff = booking.starts_at - 1.hour
      [event_window, meeting_cutoff].min
    end

    # Kural 3: Gelmeme kontrolu
    def self.repeat_no_show?(user, invitee_email)
      Booking.where(user: user, invitee_email: invitee_email, status: "no_show").count >= NO_SHOW_THRESHOLD
    end

    # Kural 3 devami: no_show isaretlenebilir mi?
    def self.can_mark_no_show?(booking)
      booking.status == "confirmed" &&
        Time.current >= booking.ends_at + NO_SHOW_MARKING_DELAY_MINUTES.minutes
    end

    # Kural 3 devami: bu davetli icin onay zorunlu mu?
    def self.force_approval?(user, invitee_email, event_type)
      event_type.requires_approval || repeat_no_show?(user, invitee_email)
    end
  end
  ```

### BE-06: SlotFinder (Bos Saat Hesaplama)
- [ ] `app/models/slot_finder.rb` olustur:
  ```ruby
  class SlotFinder
    def initialize(user, event_type, date)
      @user = user
      @event_type = event_type
      @date = date
    end

    def available_slots
      rule = @user.availability_rules.find_by(day_of_week: @date.cwday)
      return [] unless rule

      duration = @event_type.duration_minutes.minutes
      slots = []
      current = @date.in_time_zone("Istanbul").change(
        hour: rule.start_time.hour,
        min: rule.start_time.min
      )
      day_end = @date.in_time_zone("Istanbul").change(
        hour: rule.end_time.hour,
        min: rule.end_time.min
      )

      while current + duration <= day_end
        slot_end = current + duration
        if slot_available?(current, slot_end)
          slots << { starts_at: current, ends_at: slot_end }
        end
        current += duration
      end

      slots
    end

    private

    def slot_available?(starts_at, ends_at)
      return false unless SchedulingRules.bookable?(starts_at)

      !@user.bookings
        .where(event_type: @event_type)
        .active_or_unexpired_pending
        .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
        .exists?
    end
  end
  ```
- [ ] `active_or_unexpired_pending` scope'u Booking'e ekle:
  ```ruby
  scope :active_or_unexpired_pending, -> {
    where(status: "confirmed")
      .or(where(status: "pending").where("approval_deadline_at > ?", Time.current))
  }
  ```

### BE-07: Bookings::Create (Service Object)
- [ ] `app/models/bookings/create.rb` olustur:
  ```ruby
  module Bookings
    class Create
      Result = Data.define(:booking, :success?, :error)

      def initialize(user:, event_type:, params:)
        @user = user
        @event_type = event_type
        @params = params
      end

      def call
        booking = @user.bookings.new(
          event_type: @event_type,
          invitee_name: @params[:invitee_name],
          invitee_email: @params[:invitee_email],
          starts_at: @params[:starts_at],
          ends_at: @params[:starts_at].to_datetime + @event_type.duration_minutes.minutes
        )

        unless SchedulingRules.bookable?(booking.starts_at)
          return Result.new(booking: booking, success?: false, error: "En az 2 saat onceden rezervasyon yapilmali")
        end

        force_pending = SchedulingRules.force_approval?(@user, booking.invitee_email, @event_type)
        booking.status = force_pending ? "pending" : "confirmed"

        if booking.status == "pending"
          booking.approval_deadline_at = SchedulingRules.approval_deadline_for(booking)
        end

        if booking.save
          Result.new(booking: booking, success?: true, error: nil)
        else
          Result.new(booking: booking, success?: false, error: booking.errors.full_messages.join(", "))
        end
      end
    end
  end
  ```

---

## GUN 2 (Cuma 16 Ekim)

### BE-08: ExpirePendingBookingsJob
- [ ] `app/jobs/expire_pending_bookings_job.rb` olustur:
  ```ruby
  class ExpirePendingBookingsJob < ApplicationJob
    def perform
      Booking.pending_expired.find_each do |booking|
        booking.expire!
      end
    end
  end
  ```

### BE-09: Panel Controller'lari
- [ ] `app/controllers/panel/dashboard_controller.rb`:
  - `index` action: onay bekleyen (geri sayimla), yaklasan, gecmis booking'leri getir
  - Sayfa acildiginda `Booking.pending_expired` kontrol et ve expire et (Render uyku stratejisi)
- [ ] `app/controllers/panel/bookings_controller.rb`:
  - `confirm`, `decline`, `cancel`, `complete`, `no_show` action'lari
  - Her action ilgili `booking.confirm!` vb. cagirir
  - InvalidTransition hatasini yakalar, flash mesaji gosterir
- [ ] `app/controllers/panel/event_types_controller.rb`:
  - CRUD islemleri
- [ ] `app/controllers/panel/availability_rules_controller.rb`:
  - `index`: 7 gun goster, mevcut kurallari doldur
  - `create` / `update` / `destroy`

### BE-10: PublicBookings Controller
- [ ] `app/controllers/public_bookings_controller.rb`:
  ```ruby
  class PublicBookingsController < ApplicationController
    allow_unauthenticated_access

    def new
      @user = User.find_by!(slug: params[:slug])
      @event_type = @user.event_types.find_by!(slug: params[:event_type])
      @date = params[:date]&.to_date || Date.current
      @slots = SlotFinder.new(@user, @event_type, @date).available_slots
    end

    def create
      @user = User.find_by!(slug: params[:slug])
      @event_type = @user.event_types.find_by!(slug: params[:event_type])

      result = Bookings::Create.new(
        user: @user,
        event_type: @event_type,
        params: booking_params
      ).call

      if result.success?
        redirect_to booking_status_path(result.booking.token)
      else
        flash.now[:alert] = result.error
        @date = booking_params[:starts_at]&.to_date || Date.current
        @slots = SlotFinder.new(@user, @event_type, @date).available_slots
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @booking = Booking.find_by!(token: params[:token])
    end

    private

    def booking_params
      params.require(:booking).permit(:invitee_name, :invitee_email, :starts_at)
    end
  end
  ```

---

## GUN 3 (Cumartesi 17 Ekim)

### BE-11: No-Show Kuralinin Entegrasyonu (100 Puanlik Pas)
- [ ] `Bookings::Create#call` icinde `force_approval?` kontrolunun dogru calistigini dogrula
- [ ] Panel'de `no_show` butonunun sadece `SchedulingRules.can_mark_no_show?` true oldugunda gorunmesini sagla
- [ ] Edge case: davetli farkli event_type'larda no-show olursa da sayilsin (user bazinda)

### BE-12: Panel Dashboard Expire-on-Load
- [ ] Dashboard acildiginda suresi dolmus pending'leri expire et:
  ```ruby
  def index
    expire_overdue_bookings
    @pending = current_user.bookings.where(status: "pending").order(starts_at: :asc)
    @upcoming = current_user.bookings.where(status: "confirmed").where("starts_at > ?", Time.current).order(starts_at: :asc)
    @past = current_user.bookings.where(status: %w[completed no_show canceled declined expired]).order(starts_at: :desc).limit(20)
  end

  private

  def expire_overdue_bookings
    current_user.bookings.pending_expired.find_each(&:expire!)
  end
  ```
