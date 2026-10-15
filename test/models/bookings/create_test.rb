require "test_helper"

class Bookings::CreateTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @user = users(:one)
    @approval_event = event_types(:one)   # requires_approval: true
    @instant_event = event_types(:instant) # requires_approval: false
    @user.availability_rules.destroy_all
    @user.availability_rules.create!(day_of_week: 1, start_time: "09:00:00", end_time: "17:00:00")
  end

  test "creates a pending booking for approval-required event type" do
    monday = Date.current.next_occurring(:monday)
    travel_to (monday - 2.days).beginning_of_day do
      slot = monday.in_time_zone("Istanbul").change(hour: 10, min: 0)
      result = Bookings::Create.new(
        user: @user,
        event_type: @approval_event,
        params: { invitee_name: "Ali Kaya", invitee_email: "ali@example.com", starts_at: slot.iso8601 }
      ).call

      assert result.success?
      assert_equal "pending", result.booking.status
      assert_not_nil result.booking.approval_deadline_at
      assert_equal slot + 30.minutes, result.booking.ends_at
    end
  end

  test "creates a confirmed booking for instant event type" do
    monday = Date.current.next_occurring(:monday)
    travel_to (monday - 2.days).beginning_of_day do
      slot = monday.in_time_zone("Istanbul").change(hour: 10, min: 0)
      result = Bookings::Create.new(
        user: @user,
        event_type: @instant_event,
        params: { invitee_name: "Zeynep Arslan", invitee_email: "zeynep@example.com", starts_at: slot.iso8601 }
      ).call

      assert result.success?
      assert_equal "confirmed", result.booking.status
      assert_nil result.booking.approval_deadline_at
    end
  end

  test "rejects booking less than 2 hours in advance" do
    travel_to Time.zone.parse("2026-10-15 10:00:00") do
      too_soon = Time.current + 1.hour
      result = Bookings::Create.new(
        user: @user,
        event_type: @instant_event,
        params: { invitee_name: "Erken", invitee_email: "erken@example.com", starts_at: too_soon.iso8601 }
      ).call

      assert_not result.success?
      assert_includes result.error, "2 saat"
    end
  end

  test "calculates ends_at from event type duration" do
    monday = Date.current.next_occurring(:monday)
    travel_to (monday - 2.days).beginning_of_day do
      slot = monday.in_time_zone("Istanbul").change(hour: 14, min: 0)
      result = Bookings::Create.new(
        user: @user,
        event_type: @instant_event,
        params: { invitee_name: "Sure Testi", invitee_email: "sure@example.com", starts_at: slot.iso8601 }
      ).call

      assert result.success?
      assert_equal slot + @instant_event.duration_minutes.minutes, result.booking.ends_at
    end
  end

  test "force_approval overrides instant event type for repeat no-show invitee" do
    monday = Date.current.next_occurring(:monday)
    travel_to (monday - 2.days).beginning_of_day do
      2.times do |i|
        Booking.create!(
          user: @user, event_type: @approval_event,
          invitee_name: "Kronik", invitee_email: "kronik@example.com",
          starts_at: (10 + i).days.ago, ends_at: (10 + i).days.ago + 30.minutes,
          status: "no_show"
        )
      end

      slot = monday.in_time_zone("Istanbul").change(hour: 11, min: 0)
      result = Bookings::Create.new(
        user: @user,
        event_type: @instant_event,
        params: { invitee_name: "Kronik", invitee_email: "kronik@example.com", starts_at: slot.iso8601 }
      ).call

      assert result.success?
      assert_equal "pending", result.booking.status
    end
  end
end
