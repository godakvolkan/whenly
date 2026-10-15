require "test_helper"

class PublicBookingsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @user = users(:one)
    @event_type = event_types(:one)
    # Pazartesi için çalışma saati kuralı oluştur
    @user.availability_rules.destroy_all
    @user.availability_rules.create!(
      day_of_week: 1,
      start_time: "09:00:00",
      end_time: "17:00:00"
    )
  end

  test "should get new booking page" do
    monday = Date.current.next_occurring(:monday)
    get new_public_booking_url(slug: @user.slug, event_type: @event_type.slug, date: monday.to_s)
    assert_response :success
    assert_select "h1", text: /#{@event_type.name}/
  end

  test "should create booking and redirect to status page" do
    monday = Date.current.next_occurring(:monday)
    slot_time = monday.in_time_zone("Istanbul").change(hour: 11, min: 0)

    travel_to (monday - 2.days).beginning_of_day do
      assert_difference("Booking.count", 1) do
        post public_booking_url(slug: @user.slug, event_type: @event_type.slug), params: {
          booking: {
            invitee_name: "Yeni Davetli",
            invitee_email: "yeni@example.com",
            starts_at: slot_time.iso8601
          }
        }
      end

      booking = Booking.order(created_at: :desc).first
      assert_redirected_to booking_status_url(booking.token)
      assert_equal "pending", booking.status
    end
  end

  test "should show booking status by token" do
    booking = bookings(:pending_booking)
    get booking_status_url(booking.token)
    assert_response :success
    assert_select ".booking-title", text: /Randevu Talebiniz Alındı/
    assert_includes response.body, booking.invitee_name
  end

  test "invitee should be able to cancel booking" do
    booking = bookings(:pending_booking)
    patch cancel_booking_url(booking.token)
    assert_redirected_to booking_status_url(booking.token)
    assert_equal "canceled", booking.reload.status
  end
end
