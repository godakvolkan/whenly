# TEST - Gorev Listesi

> Birim testler, travel_to zaman testleri, entegrasyon testleri, CI

---

## GUN 1 (Persembe 15 Ekim)

### T-01: Test Altyapisi
- [ ] `test/test_helper.rb` duzenle:
  ```ruby
  ENV["RAILS_ENV"] ||= "test"
  require_relative "../config/environment"
  require "rails/test_help"

  class ActiveSupport::TestCase
    fixtures :all
    include ActiveSupport::Testing::TimeHelpers
  end
  ```
- [ ] Fixture dosyalari olustur:
  - `test/fixtures/users.yml`
  - `test/fixtures/event_types.yml`
  - `test/fixtures/availability_rules.yml`
  - `test/fixtures/bookings.yml`

### T-02: Fixture Verileri
- [ ] `test/fixtures/users.yml`:
  ```yaml
  host:
    name: Test Host
    email_address: host@test.com
    password_digest: <%= BCrypt::Password.create("password") %>
    slug: test-host
  ```
- [ ] `test/fixtures/event_types.yml`:
  ```yaml
  mentorluk:
    user: host
    name: Mentorluk
    duration_minutes: 30
    requires_approval: true
    approval_window_hours: 24
    slug: mentorluk

  tanitim:
    user: host
    name: Tanitim
    duration_minutes: 15
    requires_approval: false
    approval_window_hours:
    slug: tanitim
  ```
- [ ] `test/fixtures/availability_rules.yml`:
  ```yaml
  monday:
    user: host
    day_of_week: 1
    start_time: "09:00"
    end_time: "17:00"

  tuesday:
    user: host
    day_of_week: 2
    start_time: "09:00"
    end_time: "17:00"
  ```
- [ ] `test/fixtures/bookings.yml`:
  ```yaml
  pending_meeting:
    user: host
    event_type: mentorluk
    invitee_name: Davetli Test
    invitee_email: davetli@test.com
    starts_at: <%= 2.days.from_now.change(hour: 10) %>
    ends_at: <%= 2.days.from_now.change(hour: 10, min: 30) %>
    status: pending
    approval_deadline_at: <%= 1.day.from_now %>
    token: test-token-pending

  confirmed_meeting:
    user: host
    event_type: mentorluk
    invitee_name: Onaylanmis Davetli
    invitee_email: onaylanmis@test.com
    starts_at: <%= 3.days.from_now.change(hour: 14) %>
    ends_at: <%= 3.days.from_now.change(hour: 14, min: 30) %>
    status: confirmed
    approval_deadline_at:
    token: test-token-confirmed
  ```

### T-03: Booking Durum Gecisleri Testi
- [ ] `test/models/booking_test.rb`:
  ```ruby
  class BookingTest < ActiveSupport::TestCase
    # --- Gecerli gecisler ---
    test "pending -> confirmed gecisi basarili" do
      booking = bookings(:pending_meeting)
      booking.confirm!
      assert_equal "confirmed", booking.status
    end

    test "pending -> declined gecisi basarili" do
      booking = bookings(:pending_meeting)
      booking.decline!
      assert_equal "declined", booking.status
    end

    test "pending -> canceled gecisi basarili" do
      booking = bookings(:pending_meeting)
      booking.cancel!
      assert_equal "canceled", booking.status
    end

    test "pending -> expired gecisi basarili" do
      booking = bookings(:pending_meeting)
      booking.expire!
      assert_equal "expired", booking.status
    end

    test "confirmed -> completed gecisi basarili" do
      booking = bookings(:confirmed_meeting)
      booking.complete!
      assert_equal "completed", booking.status
    end

    test "confirmed -> no_show gecisi basarili" do
      booking = bookings(:confirmed_meeting)
      booking.no_show!
      assert_equal "no_show", booking.status
    end

    test "confirmed -> canceled gecisi basarili" do
      booking = bookings(:confirmed_meeting)
      booking.cancel!
      assert_equal "canceled", booking.status
    end

    # --- Yasak gecisler ---
    test "expired -> confirmed gecisi InvalidTransition firlatir" do
      booking = bookings(:pending_meeting)
      booking.expire!
      assert_raises(Booking::InvalidTransition) { booking.confirm! }
    end

    test "completed -> canceled gecisi InvalidTransition firlatir" do
      booking = bookings(:confirmed_meeting)
      booking.complete!
      assert_raises(Booking::InvalidTransition) { booking.cancel! }
    end

    test "declined -> confirmed gecisi InvalidTransition firlatir" do
      booking = bookings(:pending_meeting)
      booking.decline!
      assert_raises(Booking::InvalidTransition) { booking.confirm! }
    end

    test "canceled -> confirmed gecisi InvalidTransition firlatir" do
      booking = bookings(:pending_meeting)
      booking.cancel!
      assert_raises(Booking::InvalidTransition) { booking.confirm! }
    end

    test "no_show -> confirmed gecisi InvalidTransition firlatir" do
      booking = bookings(:confirmed_meeting)
      booking.no_show!
      assert_raises(Booking::InvalidTransition) { booking.confirm! }
    end

    # --- Token ---
    test "token otomatik olusturulur" do
      booking = Booking.new(
        user: users(:host),
        event_type: event_types(:mentorluk),
        invitee_name: "Yeni",
        invitee_email: "yeni@test.com",
        starts_at: 3.days.from_now,
        ends_at: 3.days.from_now + 30.minutes
      )
      booking.valid?
      assert_not_nil booking.token
    end
  end
  ```

### T-04: SchedulingRules Zaman Testleri (travel_to)
- [ ] `test/models/scheduling_rules_test.rb`:
  ```ruby
  class SchedulingRulesTest < ActiveSupport::TestCase
    # === KURAL 1: En az 2 saat onceden rezervasyon ===

    test "2 saat sonrasi icin rezervasyon yapilabilir" do
      future_time = 3.hours.from_now
      assert SchedulingRules.bookable?(future_time)
    end

    test "1 saat sonrasi icin rezervasyon yapilamaz" do
      near_time = 1.hour.from_now
      assert_not SchedulingRules.bookable?(near_time)
    end

    test "gecmis saat icin rezervasyon yapilamaz" do
      past_time = 1.hour.ago
      assert_not SchedulingRules.bookable?(past_time)
    end

    test "tam 2 saat sonrasi sinir durumu" do
      # travel_to ile sabit zamanda test et
      travel_to Time.zone.parse("2026-10-15 10:00:00") do
        boundary = Time.zone.parse("2026-10-15 12:00:00")
        assert SchedulingRules.bookable?(boundary)

        too_soon = Time.zone.parse("2026-10-15 11:59:59")
        assert_not SchedulingRules.bookable?(too_soon)
      end
    end

    # === KURAL 2: Onay suresi (auto-expire) ===

    test "onay suresi: approval_window_hours sonra dolar" do
      travel_to Time.zone.parse("2026-10-15 10:00:00") do
        booking = bookings(:pending_meeting)
        booking.update!(
          created_at: Time.current,
          starts_at: 3.days.from_now,
          ends_at: 3.days.from_now + 30.minutes
        )
        booking.event_type.update!(approval_window_hours: 24)

        deadline = SchedulingRules.approval_deadline_for(booking)
        assert_equal Time.current + 24.hours, deadline
      end
    end

    test "onay suresi: toplantidan 1 saat once dolar (daha erken)" do
      travel_to Time.zone.parse("2026-10-15 10:00:00") do
        booking = bookings(:pending_meeting)
        booking.update!(
          created_at: Time.current,
          starts_at: Time.current + 2.hours,  # toplantidan 1 saat once = +1 saat
          ends_at: Time.current + 2.hours + 30.minutes
        )
        booking.event_type.update!(approval_window_hours: 24)

        deadline = SchedulingRules.approval_deadline_for(booking)
        # 24 saat sonra = yarin 10:00, ama toplantidan 1 saat once = bugun 11:00
        # hangisi once geliyorsa o: bugun 11:00
        assert_equal Time.current + 1.hour, deadline
      end
    end

    test "pending randevu suresi dolunca expired olur" do
      booking = bookings(:pending_meeting)
      booking.update!(approval_deadline_at: 1.hour.from_now)

      travel_to 2.hours.from_now do
        assert booking.approval_deadline_at <= Time.current
        booking.expire!
        assert_equal "expired", booking.status
      end
    end

    test "pending randevu suresi dolmadan expire edilemez (is mantigi)" do
      booking = bookings(:pending_meeting)
      booking.update!(approval_deadline_at: 25.hours.from_now)

      travel_to 1.hour.from_now do
        # Deadline henuz gecmedi, job bunu expire etmemeli
        assert booking.approval_deadline_at > Time.current
        assert_not Booking.pending_expired.include?(booking)
      end
    end

    # === KURAL 3: Gelmeme kurali (no-show) ===

    test "2 kez gelmeyen davetlinin sonraki rezervasyonu pending olur" do
      user = users(:host)
      email = "noshow@test.com"

      # 2 adet no_show booking olustur
      2.times do |i|
        Booking.create!(
          user: user,
          event_type: event_types(:mentorluk),
          invitee_name: "No Show",
          invitee_email: email,
          starts_at: (i + 10).days.from_now,
          ends_at: (i + 10).days.from_now + 30.minutes,
          status: "no_show",
          token: "noshow-token-#{i}"
        )
      end

      assert SchedulingRules.repeat_no_show?(user, email)
      assert SchedulingRules.force_approval?(user, email, event_types(:tanitim))
    end

    test "1 kez gelmeyen davetli henuz esik altinda" do
      user = users(:host)
      email = "once-noshow@test.com"

      Booking.create!(
        user: user,
        event_type: event_types(:mentorluk),
        invitee_name: "Bir Kez",
        invitee_email: email,
        starts_at: 10.days.from_now,
        ends_at: 10.days.from_now + 30.minutes,
        status: "no_show",
        token: "once-noshow-token"
      )

      assert_not SchedulingRules.repeat_no_show?(user, email)
    end

    test "no_show isareti toplantidan 15 dk sonra acilir" do
      travel_to Time.zone.parse("2026-10-15 10:00:00") do
        booking = bookings(:confirmed_meeting)
        booking.update!(
          starts_at: Time.zone.parse("2026-10-15 09:00:00"),
          ends_at: Time.zone.parse("2026-10-15 09:30:00")
        )

        # 09:44 -> henuz 15 dk gecmedi
        travel_to Time.zone.parse("2026-10-15 09:44:00") do
          assert_not SchedulingRules.can_mark_no_show?(booking)
        end

        # 09:45 -> 15 dk gecti
        travel_to Time.zone.parse("2026-10-15 09:45:00") do
          assert SchedulingRules.can_mark_no_show?(booking)
        end
      end
    end
  end
  ```

---

## GUN 2 (Cuma 16 Ekim)

### T-05: SlotFinder Testi
- [ ] `test/models/slot_finder_test.rb`:
  ```ruby
  class SlotFinderTest < ActiveSupport::TestCase
    test "musait gunde slotlar donuyor" do
      travel_to Time.zone.parse("2026-10-12 08:00:00") do  # Pazartesi
        user = users(:host)
        event_type = event_types(:mentorluk)  # 30 dk
        date = Date.parse("2026-10-13")       # Sali (availability var)

        slots = SlotFinder.new(user, event_type, date).available_slots
        assert_not_empty slots
        assert slots.all? { |s| s[:starts_at].to_date == date }
      end
    end

    test "musaitlik olmayan gunde bos doner" do
      user = users(:host)
      event_type = event_types(:mentorluk)
      sunday = Date.parse("2026-10-18")  # Pazar, availability yok

      slots = SlotFinder.new(user, event_type, sunday).available_slots
      assert_empty slots
    end

    test "dolu slot listede gorunmez" do
      travel_to Time.zone.parse("2026-10-12 08:00:00") do
        user = users(:host)
        event_type = event_types(:mentorluk)
        date = Date.parse("2026-10-13")  # Sali

        # 10:00-10:30 dolu booking olustur
        Booking.create!(
          user: user,
          event_type: event_type,
          invitee_name: "Dolu",
          invitee_email: "dolu@test.com",
          starts_at: date.in_time_zone("Istanbul").change(hour: 10),
          ends_at: date.in_time_zone("Istanbul").change(hour: 10, min: 30),
          status: "confirmed",
          token: "dolu-token"
        )

        slots = SlotFinder.new(user, event_type, date).available_slots
        occupied = slots.find { |s| s[:starts_at].hour == 10 && s[:starts_at].min == 0 }
        assert_nil occupied, "10:00 slotu dolu olmali"
      end
    end

    test "suresi dolmus pending booking slotu bloklamaz" do
      travel_to Time.zone.parse("2026-10-12 08:00:00") do
        user = users(:host)
        event_type = event_types(:mentorluk)
        date = Date.parse("2026-10-13")

        # Suresi gecmis pending booking
        Booking.create!(
          user: user,
          event_type: event_type,
          invitee_name: "Expired",
          invitee_email: "expired@test.com",
          starts_at: date.in_time_zone("Istanbul").change(hour: 11),
          ends_at: date.in_time_zone("Istanbul").change(hour: 11, min: 30),
          status: "pending",
          approval_deadline_at: 1.hour.ago,
          token: "expired-pending-token"
        )

        slots = SlotFinder.new(user, event_type, date).available_slots
        available_11 = slots.find { |s| s[:starts_at].hour == 11 && s[:starts_at].min == 0 }
        assert_not_nil available_11, "Suresi dolmus pending, slotu bloklamamamali"
      end
    end
  end
  ```

### T-06: Bookings::Create Service Testi
- [ ] `test/models/bookings/create_test.rb`:
  ```ruby
  class Bookings::CreateTest < ActiveSupport::TestCase
    test "basarili rezervasyon olusturur" do
      travel_to Time.zone.parse("2026-10-15 08:00:00") do
        user = users(:host)
        event_type = event_types(:mentorluk)

        result = Bookings::Create.new(
          user: user,
          event_type: event_type,
          params: {
            invitee_name: "Yeni Davetli",
            invitee_email: "yeni@test.com",
            starts_at: 1.day.from_now.change(hour: 10)
          }
        ).call

        assert result.success?
        assert_equal "pending", result.booking.status
        assert_not_nil result.booking.approval_deadline_at
      end
    end

    test "2 saatten yakin rezervasyonu reddeder" do
      result = Bookings::Create.new(
        user: users(:host),
        event_type: event_types(:mentorluk),
        params: {
          invitee_name: "Acil",
          invitee_email: "acil@test.com",
          starts_at: 30.minutes.from_now
        }
      ).call

      assert_not result.success?
      assert_match(/2 saat/, result.error)
    end

    test "requires_approval false ise direkt confirmed olur" do
      travel_to Time.zone.parse("2026-10-15 08:00:00") do
        result = Bookings::Create.new(
          user: users(:host),
          event_type: event_types(:tanitim),  # requires_approval: false
          params: {
            invitee_name: "Hizli",
            invitee_email: "hizli@test.com",
            starts_at: 1.day.from_now.change(hour: 14)
          }
        ).call

        assert result.success?
        assert_equal "confirmed", result.booking.status
      end
    end

    test "repeat no-show davetli icin onay zorunlu olur" do
      travel_to Time.zone.parse("2026-10-15 08:00:00") do
        user = users(:host)
        email = "badguest@test.com"

        2.times do |i|
          Booking.create!(
            user: user, event_type: event_types(:mentorluk),
            invitee_name: "Bad", invitee_email: email,
            starts_at: (i + 20).days.from_now, ends_at: (i + 20).days.from_now + 30.minutes,
            status: "no_show", token: "bad-#{i}"
          )
        end

        result = Bookings::Create.new(
          user: user,
          event_type: event_types(:tanitim),  # normalde onay istemez
          params: {
            invitee_name: "Bad Guest",
            invitee_email: email,
            starts_at: 5.days.from_now.change(hour: 10)
          }
        ).call

        assert result.success?
        assert_equal "pending", result.booking.status, "No-show gecmisi olan davetli pending olmali"
      end
    end
  end
  ```

### T-07: ExpirePendingBookingsJob Testi
- [ ] `test/jobs/expire_pending_bookings_job_test.rb`:
  ```ruby
  class ExpirePendingBookingsJobTest < ActiveSupport::TestCase
    test "suresi dolmus pending bookingleri expire eder" do
      booking = bookings(:pending_meeting)
      booking.update!(approval_deadline_at: 1.hour.ago)

      ExpirePendingBookingsJob.perform_now

      booking.reload
      assert_equal "expired", booking.status
    end

    test "suresi dolmamis pending bookinglere dokunmaz" do
      booking = bookings(:pending_meeting)
      booking.update!(approval_deadline_at: 1.day.from_now)

      ExpirePendingBookingsJob.perform_now

      booking.reload
      assert_equal "pending", booking.status
    end

    test "confirmed bookinglere dokunmaz" do
      booking = bookings(:confirmed_meeting)
      original_status = booking.status

      ExpirePendingBookingsJob.perform_now

      booking.reload
      assert_equal original_status, booking.status
    end
  end
  ```

---

## GUN 3 (Cumartesi 17 Ekim)

### T-08: Entegrasyon Testleri (Controller)
- [ ] `test/controllers/public_bookings_controller_test.rb`:
  ```ruby
  class PublicBookingsControllerTest < ActionDispatch::IntegrationTest
    test "davetli slot secim sayfasini gorebilir" do
      get new_public_booking_path(slug: users(:host).slug, event_type: event_types(:mentorluk).slug)
      assert_response :success
    end

    test "gecersiz slug 404 doner" do
      assert_raises(ActiveRecord::RecordNotFound) do
        get new_public_booking_path(slug: "yok", event_type: "yok")
      end
    end

    test "basarili booking sonrasi token sayfasina yonlendirir" do
      travel_to Time.zone.parse("2026-10-15 08:00:00") do
        post public_booking_path(
          slug: users(:host).slug,
          event_type: event_types(:mentorluk).slug
        ), params: {
          booking: {
            invitee_name: "Controller Test",
            invitee_email: "ctrl@test.com",
            starts_at: 1.day.from_now.change(hour: 10)
          }
        }
        assert_response :redirect
        follow_redirect!
        assert_response :success
      end
    end

    test "booking durumu token ile gorulebilir" do
      get booking_status_path(token: bookings(:pending_meeting).token)
      assert_response :success
    end
  end
  ```

- [ ] `test/controllers/panel/bookings_controller_test.rb`:
  ```ruby
  class Panel::BookingsControllerTest < ActionDispatch::IntegrationTest
    setup do
      post session_path, params: {
        email_address: users(:host).email_address,
        password: "password"
      }
    end

    test "panel dashboard acilir" do
      get panel_root_path
      assert_response :success
    end

    test "booking onaylanir" do
      patch confirm_panel_booking_path(bookings(:pending_meeting))
      assert_redirected_to panel_root_path
      assert_equal "confirmed", bookings(:pending_meeting).reload.status
    end

    test "booking reddedilir" do
      patch decline_panel_booking_path(bookings(:pending_meeting))
      assert_redirected_to panel_root_path
      assert_equal "declined", bookings(:pending_meeting).reload.status
    end
  end
  ```

### T-09: CI'da Tum Testlerin Gectigini Dogrula
- [ ] `bin/rails test` lokal calistir, hepsi yesil
- [ ] Push et, GitHub Actions'ta yesil rozet
- [ ] Rubocop ve Brakeman da yesil

### T-10: Veritabani Kisitlama Testi
- [ ] Ayni saate iki aktif booking olusturmayi dene, unique index hatasi beklenir:
  ```ruby
  test "ayni saate iki aktif booking veritabani hatasi verir" do
    travel_to Time.zone.parse("2026-10-15 08:00:00") do
      user = users(:host)
      event_type = event_types(:mentorluk)
      time = 2.days.from_now.change(hour: 10)

      Booking.create!(
        user: user, event_type: event_type,
        invitee_name: "Birinci", invitee_email: "bir@test.com",
        starts_at: time, ends_at: time + 30.minutes,
        status: "confirmed", token: "double-1"
      )

      assert_raises(ActiveRecord::RecordNotUnique) do
        Booking.create!(
          user: user, event_type: event_type,
          invitee_name: "Ikinci", invitee_email: "iki@test.com",
          starts_at: time, ends_at: time + 30.minutes,
          status: "pending", token: "double-2",
          approval_deadline_at: 1.day.from_now
        )
      end
    end
  end
  ```
