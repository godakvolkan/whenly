require "test_helper"

class SlotFinderTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @user = users(:one)
    @event_type = event_types(:one) # 30 min duration
    # Pazartesi için çalışma saati kuralı oluştur: 09:00 - 12:00
    @user.availability_rules.destroy_all
    @user.availability_rules.create!(
      day_of_week: 1, # Pazartesi
      start_time: "09:00:00",
      end_time: "12:00:00"
    )
  end

  test "calculates correct slot intervals within working hours" do
    # Bir sonraki Pazartesi gününü hedefleyelim
    monday = Date.current.next_occurring(:monday)
    # 2 günden daha uzak bir zamandayız gibi simüle edelim ki 2 saat kuralı engellemesin
    travel_to (monday - 2.days).beginning_of_day do
      finder = SlotFinder.new(@user, @event_type, monday)
      slots = finder.available_slots

      # 09:00 - 12:00 arası 30 dakikalık periyotlar:
      # 09:00, 09:30, 10:00, 10:30, 11:00, 11:30 -> toplam 6 slot
      assert_equal 6, slots.size
      assert_equal "09:00", slots.first[:starts_at].in_time_zone("Istanbul").strftime("%H:%M")
      assert_equal "11:30", slots.last[:starts_at].in_time_zone("Istanbul").strftime("%H:%M")
    end
  end

  test "removes booked slots from available list" do
    monday = Date.current.next_occurring(:monday)
    travel_to (monday - 2.days).beginning_of_day do
      # 10:00 - 10:30 arasına onaylı randevu ekle
      slot_start = monday.in_time_zone("Istanbul").change(hour: 10, min: 0)
      @user.bookings.create!(
        event_type: @event_type,
        invitee_name: "Dolu Slot",
        invitee_email: "dolu@example.com",
        starts_at: slot_start,
        ends_at: slot_start + 30.minutes,
        status: "confirmed"
      )

      slots = SlotFinder.new(@user, @event_type, monday).available_slots

      # Toplam slot sayısı 6'dan 5'e düşmeli
      assert_equal 5, slots.size
      # 10:00 slotu listede OLMAMALI
      assert_not slots.any? { |s| s[:starts_at].in_time_zone("Istanbul").strftime("%H:%M") == "10:00" }
    end
  end

  test "freed slot reappears when pending booking is expired" do
    monday = Date.current.next_occurring(:monday)
    base_time = (monday - 2.days).beginning_of_day
    travel_to base_time do
      slot_start = monday.in_time_zone("Istanbul").change(hour: 10, min: 0)
      booking = @user.bookings.create!(
        event_type: @event_type,
        invitee_name: "Gecici Slot",
        invitee_email: "gecici@example.com",
        starts_at: slot_start,
        ends_at: slot_start + 30.minutes,
        status: "pending",
        approval_deadline_at: base_time + 4.hours
      )

      # Deadline öncesinde (2 saat sonra): Slot dolu sayılır
      travel 2.hours
      slots_during_pending = SlotFinder.new(@user, @event_type, monday).available_slots
      assert_equal 5, slots_during_pending.size

      # Deadline sonrasında (5 saat sonra): Solid Queue veya okuma anında slot otomatik serbest kalır!
      travel 3.hours
      slots_after_expiry = SlotFinder.new(@user, @event_type, monday).available_slots
      assert_equal 6, slots_after_expiry.size
      assert slots_after_expiry.any? { |s| s[:starts_at].in_time_zone("Istanbul").strftime("%H:%M") == "10:00" }
    end
  end
end
