require "test_helper"

class SchedulingRulesTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @user = users(:one)
    @approval_event = event_types(:one)   # requires_approval: true
    @instant_event = event_types(:instant) # requires_approval: false
  end

  # --- Kural 1: En Az 2 Saat Önceden Rezervasyon ---

  test "rule 1: cannot book slots starting less than 2 hours in advance" do
    reference_time = Time.zone.parse("2026-10-15 10:00:00")
    travel_to reference_time do
      # 1 saat sonra (yasak)
      too_soon = reference_time + 1.hour
      assert_not SchedulingRules.bookable?(too_soon)

      # 1 saat 59 dakika sonra (yasak)
      almost_two = reference_time + 1.hour + 59.minutes
      assert_not SchedulingRules.bookable?(almost_two)

      # Tam 2 saat sonra (izin verilir)
      exactly_two = reference_time + 2.hours
      assert SchedulingRules.bookable?(exactly_two)

      # 1 gün sonra (izin verilir)
      future_time = reference_time + 1.day
      assert SchedulingRules.bookable?(future_time)
    end
  end

  # --- Kural 2: Onay Süresi ve travel_to ile Süre Aşımı Testi ---

  test "rule 2: approval deadline is minimum of window and 1 hour before meeting" do
    reference_time = Time.zone.parse("2026-10-15 10:00:00")
    travel_to reference_time do
      # Toplantı 5 saat sonra, pencere 24 saat -> deadline = toplantıdan 1 saat öncesi (reference_time + 4 saat)
      short_notice_booking = Booking.new(
        user: @user,
        event_type: @approval_event,
        starts_at: reference_time + 5.hours,
        created_at: reference_time
      )
      assert_equal reference_time + 4.hours, SchedulingRules.approval_deadline_for(short_notice_booking)

      # Toplantı 3 gün sonra, pencere 24 saat -> deadline = oluşturulmadan 24 saat sonra
      long_notice_booking = Booking.new(
        user: @user,
        event_type: @approval_event,
        starts_at: reference_time + 3.days,
        created_at: reference_time
      )
      assert_equal reference_time + 24.hours, SchedulingRules.approval_deadline_for(long_notice_booking)
    end
  end

  test "rule 2: expired pending bookings are caught by pending_expired scope via travel_to" do
    base_time = Time.zone.parse("2026-10-15 09:00:00")
    travel_to base_time do
      booking = Booking.create!(
        user: @user,
        event_type: @approval_event,
        invitee_name: "Zaman Testi",
        invitee_email: "zaman@example.com",
        starts_at: base_time + 24.hours,
        ends_at: base_time + 24.hours + 30.minutes,
        status: "pending",
        approval_deadline_at: base_time + 6.hours
      )

      # 2 saat sonra: Henüz onay süresi dolmadı
      travel 2.hours
      assert_empty Booking.pending_expired.where(id: booking.id)
      assert Booking.active_or_unexpired_pending.where(id: booking.id).exists?

      # 7 saat sonra: Onay süresi doldu!
      travel 5.hours # toplam 7 saat gecti
      assert_includes Booking.pending_expired, booking
      assert_not Booking.active_or_unexpired_pending.where(id: booking.id).exists?

      # Süresi dolanı expire! yapabiliriz
      booking.expire!
      assert booking.expired?
    end
  end

  # --- Kural 3: 100 Puanlık Kullanıcı Acısı (Gelmeme / No-Show Kuralı) ---

  test "rule 3: cannot mark no-show before meeting ends plus 15 minutes buffer" do
    meeting_start = Time.zone.parse("2026-10-15 14:00:00")
    meeting_end = meeting_start + 30.minutes

    booking = Booking.create!(
      user: @user,
      event_type: @approval_event,
      invitee_name: "Erken Test",
      invitee_email: "erken@example.com",
      starts_at: meeting_start,
      ends_at: meeting_end,
      status: "confirmed"
    )

    # Toplantı anı (14:15) -> İşaretlenemez
    travel_to meeting_start + 15.minutes do
      assert_not SchedulingRules.can_mark_no_show?(booking)
    end

    # Toplantı bitiş anı (14:30) -> İşaretlenemez
    travel_to meeting_end do
      assert_not SchedulingRules.can_mark_no_show?(booking)
    end

    # Toplantı bitişinden 10 dakika sonra (14:40) -> İşaretlenemez
    travel_to meeting_end + 10.minutes do
      assert_not SchedulingRules.can_mark_no_show?(booking)
    end

    # Toplantı bitişinden 16 dakika sonra (14:46) -> İşaretlenebilir!
    travel_to meeting_end + 16.minutes do
      assert SchedulingRules.can_mark_no_show?(booking)
      booking.no_show!
      assert booking.no_show?
    end
  end

  test "rule 3 (100 PUAN): invitee with 2 or more no-shows is forced into pending status even for instant booking types" do
    spammer_email = "kronik_gelmeyen@example.com"

    # Başlangıçta bu e-posta için tekrar eden no-show yok
    assert_not SchedulingRules.repeat_no_show?(@user, spammer_email)
    assert_not SchedulingRules.force_approval?(@user, spammer_email, @instant_event)

    # 1. Gelmedi (No-Show) kaydı
    Booking.create!(
      user: @user,
      event_type: @approval_event,
      invitee_name: "Kronik Davetli",
      invitee_email: spammer_email,
      starts_at: 5.days.ago,
      ends_at: 5.days.ago + 30.minutes,
      status: "no_show"
    )
    assert_not SchedulingRules.repeat_no_show?(@user, spammer_email)

    # 2. Gelmedi (No-Show) kaydı -> Eşik değere ulaşıldı!
    Booking.create!(
      user: @user,
      event_type: @approval_event,
      invitee_name: "Kronik Davetli",
      invitee_email: spammer_email,
      starts_at: 3.days.ago,
      ends_at: 3.days.ago + 30.minutes,
      status: "no_show"
    )

    # Artık sistem bu kullanıcıyı tekrar eden no-show olarak tanıyor
    assert SchedulingRules.repeat_no_show?(@user, spammer_email)

    # Olay tipi "anında kesinleşen" (requires_approval: false) olsa bile kural onay ZORUNLU kılıyor!
    assert SchedulingRules.force_approval?(@user, spammer_email, @instant_event)

    # Bookings::Create servisimiz ile rezervasyon yaptığında durum otomatik 'pending' olmalı
    future_slot = 1.day.from_now.change(hour: 15, min: 0)
    result = Bookings::Create.new(
      user: @user,
      event_type: @instant_event,
      params: {
        invitee_name: "Kronik Davetli",
        invitee_email: spammer_email,
        starts_at: future_slot.iso8601
      }
    ).call

    assert result.success?, "Rezervasyon olusturulmaliydi ama hata alindi: #{result.error}"
    created_booking = result.booking

    # Normalde instant_event -> "confirmed" olurdu; ancak no-show kuralı nedeniyle "pending" oldu!
    assert_equal "pending", created_booking.status
    assert_not_nil created_booking.approval_deadline_at
  end

  test "rule 3: repeat no-show detection is case-insensitive" do
    email = "deneme_vaka@example.com"
    2.times do |i|
      Booking.create!(
        user: @user,
        event_type: @approval_event,
        invitee_name: "Büyük Küçük Vaka",
        invitee_email: email.upcase,
        starts_at: (5 + i).days.ago,
        ends_at: (5 + i).days.ago + 30.minutes,
        status: "no_show"
      )
    end

    # Karışık harfle sorgulansa bile tanımalı
    assert SchedulingRules.repeat_no_show?(@user, "DeNeMe_VaKa@ExAmPlE.cOm")
    assert SchedulingRules.force_approval?(@user, "DENEME_VAKA@EXAMPLE.COM", @instant_event)
  end

  # --- Kural 4: Aynı Davetlinin Aynı Gün Mükerrer Randevu Almasını Engelleme ---

  test "rule 4: prevents duplicate bookings by same invitee on the same day" do
    reference_time = Time.zone.parse("2026-10-20 10:00:00")
    travel_to reference_time do
      email = "ayni_gun@example.com"
      slot1 = reference_time + 4.hours # 14:00
      slot2 = reference_time + 6.hours # 16:00

      # İlk randevu oluşturulur
      result1 = Bookings::Create.new(
        user: @user,
        event_type: @approval_event,
        params: {
          invitee_name: "Tekrarlı Davetli",
          invitee_email: email,
          starts_at: slot1.iso8601
        }
      ).call
      assert result1.success?

      # Aynı gün farklı bir saate ikinci randevu denenir -> reddedilmeli
      result2 = Bookings::Create.new(
        user: @user,
        event_type: @approval_event,
        params: {
          invitee_name: "Tekrarlı Davetli",
          invitee_email: email.upcase, # büyük/küçük harf duyarsız olmalı
          starts_at: slot2.iso8601
        }
      ).call
      assert_not result2.success?
      assert_includes result2.error, "Aynı gün içinde yalnızca bir randevu"

      # Ancak ertesi güne randevu alabilir -> izin verilmeli
      next_day_slot = slot1 + 1.day
      result3 = Bookings::Create.new(
        user: @user,
        event_type: @approval_event,
        params: {
          invitee_name: "Tekrarlı Davetli",
          invitee_email: email,
          starts_at: next_day_slot.iso8601
        }
      ).call
      assert result3.success?
    end
  end
end
