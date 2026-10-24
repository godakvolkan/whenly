require "test_helper"

class TelegramBotServiceTest < ActiveSupport::TestCase
  class FakeApi
    attr_reader :sent_messages, :edited_messages

    def initialize
      @sent_messages = []
      @edited_messages = []
    end

    def send_message(**args)
      @sent_messages << args
    end

    def edit_message_text(**args)
      @edited_messages << args
    end

    def send_document(**args)
      @sent_messages << args
    end

    def answer_callback_query(**args)
    end
  end

  class FakeBot
    attr_reader :api

    def initialize
      @api = FakeApi.new
    end
  end

  FakeMessage = Struct.new(:chat, :text)
  FakeChat = Struct.new(:id)
  FakeCallback = Struct.new(:id, :message, :data)
  FakeCallbackMessage = Struct.new(:chat, :message_id)

  setup do
    @fake_bot = FakeBot.new
    @service = TelegramBotService.new(@fake_bot)
    @user = users(:one)
    @user.update!(telegram_chat_id: 99887766)
    @event_type = event_types(:one)
  end

  test "/profil displays user profile details" do
    msg = FakeMessage.new(FakeChat.new(99887766), "/profil")
    @service.handle_message(msg)

    assert_not_empty @fake_bot.api.sent_messages
    last_msg = @fake_bot.api.sent_messages.last
    assert_includes last_msg[:text], @user.name
    assert_includes last_msg[:text], @user.slug
    assert_includes last_msg[:text], @user.email_address
    assert_not_nil last_msg[:reply_markup]
  end

  test "profile editing via telegram updates name and slug" do
    session = TelegramSession.for(99887766)

    # 1. Update name
    session.transition_to!("edit_profile_name")
    msg1 = FakeMessage.new(FakeChat.new(99887766), "Doktor Ahmet")
    @service.handle_message(msg1)
    assert_equal "Doktor Ahmet", @user.reload.name

    # 2. Update slug
    session.transition_to!("edit_profile_slug")
    msg2 = FakeMessage.new(FakeChat.new(99887766), "doktor-ahmet")
    @service.handle_message(msg2)
    assert_equal "doktor-ahmet", @user.reload.slug
  end

  test "accept reschedule callback updates booking starts_at and status" do
    booking = bookings(:pending_booking)
    new_starts = 4.days.from_now.change(hour: 10, min: 0)

    @user.availability_rules.find_or_create_by!(day_of_week: new_starts.in_time_zone("Istanbul").to_date.cwday) do |r|
      r.start_time = "09:00"
      r.end_time = "18:00"
    end

    booking.request_reschedule!(starts_at: new_starts, by: "client", note: "İşim uzadı")

    cb = FakeCallback.new(
      "cb_1",
      FakeCallbackMessage.new(FakeChat.new(99887766), 123),
      "accept_reschedule_#{booking.id}"
    )

    @service.handle_callback(cb)

    booking.reload
    assert_equal "accepted", booking.reschedule_status
    assert_equal new_starts, booking.starts_at
    assert_equal "confirmed", booking.status
  end

  test "reject reschedule callback marks reschedule rejected" do
    booking = bookings(:pending_booking)
    orig_starts = booking.starts_at
    new_starts = 4.days.from_now.change(hour: 14, min: 0)

    @user.availability_rules.find_or_create_by!(day_of_week: new_starts.in_time_zone("Istanbul").to_date.cwday) do |r|
      r.start_time = "09:00"
      r.end_time = "18:00"
    end

    booking.request_reschedule!(starts_at: new_starts, by: "client", note: "Saat kaydırma")

    cb = FakeCallback.new(
      "cb_2",
      FakeCallbackMessage.new(FakeChat.new(99887766), 124),
      "reject_reschedule_#{booking.id}"
    )

    @service.handle_callback(cb)

    booking.reload
    assert_equal "rejected", booking.reschedule_status
    assert_equal orig_starts, booking.starts_at
  end
end
