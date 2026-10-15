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
end
