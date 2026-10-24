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

      booking = Booking.find_by!(invitee_email: "yeni@example.com")
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

  test "should create booking with notes" do
    monday = Date.current.next_occurring(:monday)
    slot_time = monday.in_time_zone("Istanbul").change(hour: 14, min: 0)

    travel_to (monday - 2.days).beginning_of_day do
      post public_booking_url(slug: @user.slug, event_type: @event_type.slug), params: {
        booking: {
          invitee_name: "Notlu Davetli",
          invitee_email: "notlu@example.com",
          starts_at: slot_time.iso8601,
          notes: "Görüşmede proje hedeflerini konuşmak istiyorum."
        }
      }

      booking = Booking.find_by!(invitee_email: "notlu@example.com")
      assert_redirected_to booking_status_url(booking.token)
      assert_equal "Görüşmede proje hedeflerini konuşmak istiyorum.", booking.notes
    end
  end

  test "invitee can request reschedule and view form" do
    booking = bookings(:pending_booking)

    get reschedule_booking_url(booking.token)
    assert_response :success
    assert_includes response.body, "Tarih / Saat Değiştirme"

    monday = Date.current.next_occurring(:monday)
    new_slot = monday.in_time_zone("Istanbul").change(hour: 15, min: 0)

    travel_to (monday - 2.days).beginning_of_day do
      patch submit_reschedule_booking_url(booking.token), params: {
        starts_at: new_slot.iso8601,
        reschedule_note: "Toplantı saatini kaydırmak istiyorum"
      }

      assert_redirected_to booking_status_url(booking.token)
      booking.reload
      assert booking.reschedule_pending?
      assert_equal "client", booking.rescheduled_by
    end
  end

  test "counterparty can accept and reject reschedule" do
    booking = bookings(:pending_booking)
    monday = Date.current.next_occurring(:monday)
    new_slot = monday.in_time_zone("Istanbul").change(hour: 16, min: 0)

    travel_to (monday - 2.days).beginning_of_day do
      booking.request_reschedule!(starts_at: new_slot, by: "host", note: "Doktor önerisi")

      patch accept_reschedule_booking_url(booking.token)
      assert_redirected_to booking_status_url(booking.token)
      assert_equal "accepted", booking.reload.reschedule_status
      assert_equal new_slot, booking.starts_at
      assert_equal "confirmed", booking.status
    end
  end
end
