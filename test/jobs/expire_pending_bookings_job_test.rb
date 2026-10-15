require "test_helper"

class ExpirePendingBookingsJobTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @user = users(:one)
    @event_type = event_types(:one)
  end

  test "expires bookings whose approval deadline has passed" do
    base = Time.zone.parse("2026-10-15 09:00:00")
    travel_to base do
      booking = Booking.create!(
        user: @user, event_type: @event_type,
        invitee_name: "Suresi Dolan", invitee_email: "dolan@example.com",
        starts_at: base + 24.hours, ends_at: base + 24.hours + 30.minutes,
        status: "pending", approval_deadline_at: base + 2.hours
      )

      travel 3.hours
      ExpirePendingBookingsJob.perform_now

      assert_equal "expired", booking.reload.status
    end
  end

  test "does not expire bookings whose deadline has not passed" do
    base = Time.zone.parse("2026-10-15 09:00:00")
    travel_to base do
      booking = Booking.create!(
        user: @user, event_type: @event_type,
        invitee_name: "Henuz Bekleyen", invitee_email: "bekle@example.com",
        starts_at: base + 24.hours, ends_at: base + 24.hours + 30.minutes,
        status: "pending", approval_deadline_at: base + 10.hours
      )

      travel 3.hours
      ExpirePendingBookingsJob.perform_now

      assert_equal "pending", booking.reload.status
    end
  end

  test "does not touch confirmed bookings" do
    confirmed = bookings(:confirmed_booking)
    ExpirePendingBookingsJob.perform_now
    assert_equal "confirmed", confirmed.reload.status
  end
end
