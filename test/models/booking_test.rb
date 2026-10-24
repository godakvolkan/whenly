require "test_helper"

class BookingTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @event_type = event_types(:one)
    @booking = Booking.create!(
      user: @user,
      event_type: @event_type,
      invitee_name: "Test Davetli",
      invitee_email: "davetli@example.com",
      starts_at: 1.day.from_now.change(hour: 14, min: 0),
      ends_at: 1.day.from_now.change(hour: 14, min: 30),
      status: "pending",
      approval_deadline_at: 1.day.from_now - 1.hour
    )
  end

  test "initial status is pending and token is generated automatically" do
    assert @booking.pending?
    assert_not_nil @booking.token
    assert_equal 22, @booking.token.length # urlsafe_base64(16) produces 22 chars
  end

  # --- İzin Verilen Durum Geçişleri ---

  test "pending to confirmed transition" do
    @booking.confirm!
    assert @booking.confirmed?
    assert_equal "confirmed", @booking.reload.status
  end

  test "pending to declined transition" do
    @booking.decline!
    assert @booking.declined?
    assert_equal "declined", @booking.reload.status
  end

  test "pending to expired transition" do
    @booking.expire!
    assert @booking.expired?
    assert_equal "expired", @booking.reload.status
  end

  test "pending to canceled transition" do
    @booking.cancel!
    assert @booking.canceled?
    assert_equal "canceled", @booking.reload.status
  end

  test "confirmed to completed transition" do
    @booking.confirm!
    @booking.complete!
    assert @booking.completed?
    assert_equal "completed", @booking.reload.status
  end

  test "confirmed to no_show transition" do
    @booking.confirm!
    @booking.no_show!
    assert @booking.no_show?
    assert_equal "no_show", @booking.reload.status
  end

  test "confirmed to canceled transition" do
    @booking.confirm!
    @booking.cancel!
    assert @booking.canceled?
    assert_equal "canceled", @booking.reload.status
  end

  # --- Yasak Durum Geçişleri (InvalidTransition) ---

  test "expired to confirmed transition is strictly forbidden" do
    @booking.expire!
    assert_raises(Booking::InvalidTransition) do
      @booking.confirm!
    end
    assert @booking.expired?
  end

  test "completed to canceled transition is strictly forbidden" do
    @booking.confirm!
    @booking.complete!
    assert_raises(Booking::InvalidTransition) do
      @booking.cancel!
    end
    assert @booking.completed?
  end

  test "declined to confirmed transition is strictly forbidden" do
    @booking.decline!
    assert_raises(Booking::InvalidTransition) do
      @booking.confirm!
    end
    assert @booking.declined?
  end

  test "no_show to confirmed transition is strictly forbidden" do
    @booking.confirm!
    @booking.no_show!
    assert_raises(Booking::InvalidTransition) do
      @booking.confirm!
    end
    assert @booking.no_show?
  end

  test "cannot double book the exact same slot while active" do
    # Partial unique index test
    duplicate = Booking.new(
      user: @user,
      event_type: @event_type,
      invitee_name: "Ikinci Davetli",
      invitee_email: "ikinci@example.com",
      starts_at: @booking.starts_at,
      ends_at: @booking.ends_at,
      status: "pending",
      token: "second_unique_token"
    )

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate.save(validate: false)
    end
  end

  test "cannot confirm an expired pending booking" do
    @booking.update!(approval_deadline_at: 1.hour.ago)
    assert_raises(Booking::InvalidTransition) do
      @booking.confirm!
    end
    assert @booking.reload.expired?
  end

  test "normalizes invitee email to lowercase" do
    b = Booking.create!(
      user: @user,
      event_type: @event_type,
      invitee_name: "Büyük Harf",
      invitee_email: "  BUYUK_HARF@EXAMPLE.COM  ",
      starts_at: 2.days.from_now.change(hour: 16, min: 0),
      ends_at: 2.days.from_now.change(hour: 16, min: 30)
    )
    assert_equal "buyuk_harf@example.com", b.invitee_email
  end

  test "supports notes when creating booking" do
    b = Booking.create!(
      user: @user,
      event_type: @event_type,
      invitee_name: "Not Bırakan Davetli",
      invitee_email: "not@example.com",
      starts_at: 3.days.from_now.change(hour: 10, min: 0),
      ends_at: 3.days.from_now.change(hour: 10, min: 30),
      notes: "Görüşmede yeni proje mimarisini değerlendirmek istiyorum."
    )
    assert_equal "Görüşmede yeni proje mimarisini değerlendirmek istiyorum.", b.reload.notes
  end

  test "reschedule lifecycle: request, accept and reject" do
    # Ensure user has availability rule for the day
    new_starts = 4.days.from_now.change(hour: 11, min: 0)
    @user.availability_rules.find_or_create_by!(day_of_week: new_starts.in_time_zone("Istanbul").to_date.cwday) do |r|
      r.start_time = "09:00"
      r.end_time = "18:00"
    end

    assert @booking.can_reschedule?
    assert_not @booking.reschedule_pending?

    # 1. Request reschedule
    @booking.request_reschedule!(starts_at: new_starts, by: "client", note: "İşim çıktı")
    assert @booking.reschedule_pending?
    assert_equal "client", @booking.rescheduled_by
    assert_equal new_starts, @booking.reschedule_starts_at
    assert_equal "İşim çıktı", @booking.reschedule_note

    # 2. Accept reschedule
    @booking.accept_reschedule!
    assert_equal "accepted", @booking.reschedule_status
    assert_equal new_starts, @booking.starts_at
    assert_equal "confirmed", @booking.status

    # 3. Request again and reject
    another_slot = 5.days.from_now.change(hour: 15, min: 0)
    @user.availability_rules.find_or_create_by!(day_of_week: another_slot.in_time_zone("Istanbul").to_date.cwday) do |r|
      r.start_time = "09:00"
      r.end_time = "18:00"
    end

    @booking.request_reschedule!(starts_at: another_slot, by: "host", note: "Doktor başka bir saat önerdi")
    assert @booking.reschedule_pending?

    @booking.reject_reschedule!
    assert_equal "rejected", @booking.reschedule_status
    assert_equal new_starts, @booking.starts_at # original slot maintained
  end
end
