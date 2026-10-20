class TelegramBotService
  attr_reader :bot

  def initialize(bot = nil)
    @bot = bot || Telegram::Bot::Client.new(token)
  end

  def handle_message(message)
    chat_id = message.chat.id
    text = message.text.to_s.strip
    session = TelegramSession.for(chat_id)

    case text
    when "/start"
      send_welcome(chat_id, session)
    when "/randevu"
      start_booking_flow(chat_id, session)
    when "/bagla"
      send_text(chat_id, "Hesabınızı bağlamak için e-posta adresinizi yazın:\nÖrnek: /bagla godakvolkan@gmail.com")
    when /\A\/bagla\s+(.+)/i
      connect_host_account(chat_id, $1.strip, session)
    when "/randevularim"
      show_host_bookings(chat_id)
    when "/iptal"
      session.reset!
      send_text(chat_id, "İşlem iptal edildi.")
    else
      handle_state_input(chat_id, text, session)
    end
  end

  def handle_callback(callback)
    chat_id = callback.message.chat.id
    data = callback.data
    session = TelegramSession.for(chat_id)

    case data
    when /\Ahost_(\d+)\z/
      select_host(chat_id, $1.to_i, session)
    when /\Aet_(\d+)\z/
      select_event_type(chat_id, $1.to_i, session)
    when /\Adate_(.+)\z/
      select_date(chat_id, $1, session)
    when /\Aslot_(.+)\z/
      select_slot(chat_id, $1, session)
    when /\Aapprove_(\d+)\z/
      approve_booking(chat_id, $1.to_i, callback)
    when /\Adecline_(\d+)\z/
      decline_booking(chat_id, $1.to_i, callback)
    end

    answer_callback(callback.id)
  end

  def notify_host_new_booking(booking)
    user = booking.user
    return unless user.telegram_chat_id

    text = "📋 *Yeni Randevu Talebi*\n\n" \
           "👤 *Davetli:* #{booking.invitee_name}\n" \
           "📧 *E-posta:* #{booking.invitee_email}\n" \
           "📅 *Tarih:* #{booking.starts_at.in_time_zone('Istanbul').strftime('%d.%m.%Y')}\n" \
           "🕐 *Saat:* #{booking.starts_at.in_time_zone('Istanbul').strftime('%H:%M')} - #{booking.ends_at.in_time_zone('Istanbul').strftime('%H:%M')}\n" \
           "📌 *Tür:* #{booking.event_type.name}\n" \
           "📊 *Durum:* #{booking.status == 'pending' ? 'Onay Bekliyor' : 'Onaylandı'}"

    kb = nil
    if booking.pending?
      kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(
        inline_keyboard: [
          [
            Telegram::Bot::Types::InlineKeyboardButton.new(text: "✅ Onayla", callback_data: "approve_#{booking.id}"),
            Telegram::Bot::Types::InlineKeyboardButton.new(text: "❌ Reddet", callback_data: "decline_#{booking.id}")
          ]
        ]
      )
    end

    send_text(user.telegram_chat_id, text, parse_mode: "Markdown", reply_markup: kb)
  end

  def notify_invitee_status(booking, status_text)
    session = TelegramSession.find_by("data->>'booking_id' = ?", booking.id.to_s)
    return unless session

    text = "📋 *Randevu Güncelleme*\n\n" \
           "📅 #{booking.starts_at.in_time_zone('Istanbul').strftime('%d.%m.%Y %H:%M')}\n" \
           "📌 #{booking.event_type.name}\n" \
           "📊 *Durum:* #{status_text}"

    send_text(session.chat_id, text, parse_mode: "Markdown")
  end

  def send_reminder(booking)
    user = booking.user
    time_str = booking.starts_at.in_time_zone("Istanbul").strftime("%H:%M")

    if user.telegram_chat_id
      send_text(user.telegram_chat_id,
        "⏰ *Hatırlatma:* 1 saat sonra randevunuz var!\n\n" \
        "👤 #{booking.invitee_name}\n" \
        "🕐 #{time_str}\n" \
        "📌 #{booking.event_type.name}",
        parse_mode: "Markdown")
    end

    session = TelegramSession.find_by("data->>'booking_id' = ?", booking.id.to_s)
    if session
      send_text(session.chat_id,
        "⏰ *Hatırlatma:* 1 saat sonra randevunuz var!\n\n" \
        "👤 #{user.name} ile #{booking.event_type.name}\n" \
        "🕐 #{time_str}",
        parse_mode: "Markdown")
    end
  end

  private

  def token
    ENV.fetch("TELEGRAM_BOT_TOKEN")
  end

  def send_welcome(chat_id, session)
    session.reset!
    send_text(chat_id,
      "👋 *Whenly Randevu Sistemine Hoş Geldiniz!*\n\n" \
      "Bu bot ile kolayca randevu alabilirsiniz.\n\n" \
      "📌 *Komutlar:*\n" \
      "/randevu — Yeni randevu al\n" \
      "/bagla — Ev sahibi hesabınızı bağlayın (bildirim almak için)\n" \
      "/randevularim — Bekleyen randevularınızı görün\n" \
      "/iptal — Mevcut işlemi iptal et",
      parse_mode: "Markdown")
  end

  def start_booking_flow(chat_id, session)
    hosts = User.all
    if hosts.empty?
      send_text(chat_id, "Şu anda kayıtlı ev sahibi bulunmuyor.")
      return
    end

    if hosts.count == 1
      select_host(chat_id, hosts.first.id, session)
      return
    end

    buttons = hosts.map do |h|
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: h.name, callback_data: "host_#{h.id}")]
    end
    kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
    send_text(chat_id, "👤 *Kimin için randevu almak istiyorsunuz?*", parse_mode: "Markdown", reply_markup: kb)
    session.transition_to!("select_host")
  end

  def select_host(chat_id, host_id, session)
    user = User.find_by(id: host_id)
    return send_text(chat_id, "Kullanıcı bulunamadı.") unless user

    session.set(:host_id, host_id)
    event_types = user.event_types
    if event_types.empty?
      send_text(chat_id, "Bu ev sahibinin randevu türü bulunmuyor.")
      session.reset!
      return
    end

    buttons = event_types.map do |et|
      [Telegram::Bot::Types::InlineKeyboardButton.new(
        text: "#{et.name} (#{et.duration_minutes} dk)",
        callback_data: "et_#{et.id}"
      )]
    end
    kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
    send_text(chat_id, "📋 *#{user.name}* için hangi randevu türü?\n", parse_mode: "Markdown", reply_markup: kb)
    session.transition_to!("select_event_type")
  end

  def select_event_type(chat_id, et_id, session)
    et = EventType.find_by(id: et_id)
    return send_text(chat_id, "Randevu türü bulunamadı.") unless et

    session.set(:event_type_id, et_id)
    show_date_picker(chat_id, session)
  end

  def show_date_picker(chat_id, session)
    today = Date.current
    buttons = (0..6).map do |offset|
      d = today + offset.days
      next if [6, 0].include?(d.cwday) && offset > 0
      label = offset == 0 ? "Bugün (#{d.strftime('%d/%m')})" : d.strftime("%A %d/%m")
      label = label.gsub("Monday", "Pzt").gsub("Tuesday", "Sal").gsub("Wednesday", "Çar")
                    .gsub("Thursday", "Per").gsub("Friday", "Cum").gsub("Saturday", "Cmt").gsub("Sunday", "Paz")
      Telegram::Bot::Types::InlineKeyboardButton.new(text: label, callback_data: "date_#{d.iso8601}")
    end.compact.map { |b| [b] }

    kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
    send_text(chat_id, "📅 *Hangi gün için randevu almak istersiniz?*", parse_mode: "Markdown", reply_markup: kb)
    session.transition_to!("select_date")
  end

  def select_date(chat_id, date_str, session)
    date = Date.parse(date_str)
    session.set(:date, date_str)

    host = User.find(session.get("host_id"))
    et = EventType.find(session.get("event_type_id"))
    slots = SlotFinder.new(host, et, date).available_slots

    if slots.empty?
      send_text(chat_id, "😔 Bu tarihte müsait saat bulunmuyor. Başka bir gün seçin.")
      show_date_picker(chat_id, session)
      return
    end

    buttons = slots.map do |s|
      time_label = "#{s[:starts_at].in_time_zone('Istanbul').strftime('%H:%M')} - #{s[:ends_at].in_time_zone('Istanbul').strftime('%H:%M')}"
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: "🕐 #{time_label}", callback_data: "slot_#{s[:starts_at].iso8601}")]
    end
    kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
    send_text(chat_id,
      "🕐 *#{date.strftime('%d.%m.%Y')} tarihinde müsait saatler:*\n" \
      "#{et.name} (#{et.duration_minutes} dk)",
      parse_mode: "Markdown", reply_markup: kb)
    session.transition_to!("select_slot")
  end

  def select_slot(chat_id, starts_at_str, session)
    session.set(:starts_at, starts_at_str)
    send_text(chat_id, "👤 *Adınızı ve soyadınızı yazın:*", parse_mode: "Markdown")
    session.transition_to!("enter_name")
  end

  def handle_state_input(chat_id, text, session)
    case session.state
    when "enter_name"
      if text.length < 2
        send_text(chat_id, "Lütfen geçerli bir ad girin.")
        return
      end
      session.set(:invitee_name, text)
      send_text(chat_id, "📧 *E-posta adresinizi yazın:*", parse_mode: "Markdown")
      session.transition_to!("enter_email")
    when "enter_email"
      unless text.match?(URI::MailTo::EMAIL_REGEXP)
        send_text(chat_id, "Lütfen geçerli bir e-posta adresi girin.")
        return
      end
      session.set(:invitee_email, text)
      create_booking_from_session(chat_id, session)
    else
      handle_natural_language(chat_id, text, session)
    end
  end

  def handle_natural_language(chat_id, text, session)
    lower = text.downcase.gsub(/[İı]/, "i")

    if lower.match?(/randevu|rezervasyon|yer\s*var|müsait|boş|saat/)
      host = User.first
      return send_text(chat_id, "Kayıtlı ev sahibi yok.") unless host

      et = if lower.match?(/mentorluk|mentor/)
             host.event_types.find_by(slug: "mentorluk")
           elsif lower.match?(/tanıtım|tanitim|görüşme|gorusme/)
             host.event_types.find_by(slug: "tanitim")
           end

      if et
        session.set(:host_id, host.id)
        session.set(:event_type_id, et.id)
        show_date_picker(chat_id, session)
      else
        start_booking_flow(chat_id, session)
      end
    else
      send_text(chat_id,
        "🤖 Komutları kullanabilirsiniz:\n\n" \
        "/randevu — Yeni randevu al\n" \
        "/bagla — Hesap bağla\n\n" \
        "Ya da doğal dille yazın:\n" \
        "\"Mentorluk için yer var mı?\"\n" \
        "\"Tanıtım randevusu almak istiyorum\"")
    end
  end

  def create_booking_from_session(chat_id, session)
    host = User.find(session.get("host_id"))
    et = EventType.find(session.get("event_type_id"))

    result = Bookings::Create.new(
      user: host,
      event_type: et,
      params: {
        invitee_name: session.get("invitee_name"),
        invitee_email: session.get("invitee_email"),
        starts_at: session.get("starts_at")
      }
    ).call

    if result.success?
      booking = result.booking
      session.set(:booking_id, booking.id)

      status_text = booking.pending? ? "⏳ Onay Bekliyor" : "✅ Onaylandı"
      send_text(chat_id,
        "🎉 *Randevunuz oluşturuldu!*\n\n" \
        "👤 *Ev Sahibi:* #{host.name}\n" \
        "📌 *Tür:* #{et.name}\n" \
        "📅 *Tarih:* #{booking.starts_at.in_time_zone('Istanbul').strftime('%d.%m.%Y')}\n" \
        "🕐 *Saat:* #{booking.starts_at.in_time_zone('Istanbul').strftime('%H:%M')} - #{booking.ends_at.in_time_zone('Istanbul').strftime('%H:%M')}\n" \
        "📊 *Durum:* #{status_text}\n\n" \
        "#{booking.pending? ? 'Ev sahibi onayladığında bildirim alacaksınız.' : 'Randevunuz kesinleşti!'}",
        parse_mode: "Markdown")

      TelegramNotifyJob.perform_later(booking.id, "new_booking")
      TelegramReminderJob.set(wait_until: booking.starts_at - 1.hour).perform_later(booking.id) if booking.starts_at > 1.hour.from_now

      session.update!(state: "idle")
    else
      send_text(chat_id, "❌ *Hata:* #{result.error}\n\nTekrar denemek için /randevu yazın.", parse_mode: "Markdown")
      session.reset!
    end
  end

  def connect_host_account(chat_id, email, session)
    user = User.find_by(email_address: email.downcase)
    if user
      user.update!(telegram_chat_id: chat_id)
      send_text(chat_id,
        "✅ *Hesap bağlandı!*\n\n" \
        "Merhaba #{user.name}! Artık yeni randevu talepleri ve hatırlatmalar Telegram'dan gelecek.\n\n" \
        "/randevularim — Bekleyen randevuları gör",
        parse_mode: "Markdown")
    else
      send_text(chat_id, "❌ Bu e-posta ile kayıtlı bir hesap bulunamadı.")
    end
  end

  def show_host_bookings(chat_id)
    user = User.find_by(telegram_chat_id: chat_id)
    unless user
      send_text(chat_id, "Hesabınız bağlı değil. Önce /bagla komutu ile bağlayın.")
      return
    end

    pending = user.bookings.where(status: "pending").order(:starts_at).limit(10)
    upcoming = user.bookings.where(status: "confirmed").where("starts_at > ?", Time.current).order(:starts_at).limit(10)

    if pending.empty? && upcoming.empty?
      send_text(chat_id, "📭 Bekleyen veya yaklaşan randevunuz bulunmuyor.")
      return
    end

    text = ""
    if pending.any?
      text += "⏳ *Onay Bekleyen (#{pending.count}):*\n\n"
      pending.each do |b|
        text += "• #{b.invitee_name} — #{b.event_type.name}\n" \
                "  📅 #{b.starts_at.in_time_zone('Istanbul').strftime('%d.%m %H:%M')}\n\n"
      end

      buttons = pending.map do |b|
        [
          Telegram::Bot::Types::InlineKeyboardButton.new(text: "✅ #{b.invitee_name}", callback_data: "approve_#{b.id}"),
          Telegram::Bot::Types::InlineKeyboardButton.new(text: "❌ #{b.invitee_name}", callback_data: "decline_#{b.id}")
        ]
      end
      kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
      send_text(chat_id, text, parse_mode: "Markdown", reply_markup: kb)
      text = ""
    end

    if upcoming.any?
      text += "📅 *Yaklaşan (#{upcoming.count}):*\n\n"
      upcoming.each do |b|
        text += "• #{b.invitee_name} — #{b.event_type.name}\n" \
                "  📅 #{b.starts_at.in_time_zone('Istanbul').strftime('%d.%m %H:%M')}\n\n"
      end
      send_text(chat_id, text, parse_mode: "Markdown")
    end
  end

  def approve_booking(chat_id, booking_id, callback)
    booking = Booking.find_by(id: booking_id)
    return unless booking

    user = User.find_by(telegram_chat_id: chat_id)
    return send_text(chat_id, "Bu işlem için yetkiniz yok.") unless user&.id == booking.user_id

    begin
      booking.confirm!
      edit_message(chat_id, callback.message.message_id,
        "✅ *Randevu Onaylandı*\n\n" \
        "👤 #{booking.invitee_name}\n" \
        "📅 #{booking.starts_at.in_time_zone('Istanbul').strftime('%d.%m.%Y %H:%M')}\n" \
        "📌 #{booking.event_type.name}",
        parse_mode: "Markdown")
      notify_invitee_status(booking, "✅ Onaylandı")
      TelegramReminderJob.set(wait_until: booking.starts_at - 1.hour).perform_later(booking.id) if booking.starts_at > 1.hour.from_now
    rescue Booking::InvalidTransition => e
      send_text(chat_id, "❌ #{e.message}")
    end
  end

  def decline_booking(chat_id, booking_id, callback)
    booking = Booking.find_by(id: booking_id)
    return unless booking

    user = User.find_by(telegram_chat_id: chat_id)
    return send_text(chat_id, "Bu işlem için yetkiniz yok.") unless user&.id == booking.user_id

    begin
      booking.decline!
      edit_message(chat_id, callback.message.message_id,
        "❌ *Randevu Reddedildi*\n\n" \
        "👤 #{booking.invitee_name}\n" \
        "📅 #{booking.starts_at.in_time_zone('Istanbul').strftime('%d.%m.%Y %H:%M')}\n" \
        "📌 #{booking.event_type.name}",
        parse_mode: "Markdown")
      notify_invitee_status(booking, "❌ Reddedildi")
    rescue Booking::InvalidTransition => e
      send_text(chat_id, "❌ #{e.message}")
    end
  end

  def send_text(chat_id, text, **opts)
    bot.api.send_message(chat_id: chat_id, text: text, **opts)
  rescue Telegram::Bot::Exceptions::ResponseError => e
    Rails.logger.error("Telegram send error: #{e.message}")
  end

  def edit_message(chat_id, message_id, text, **opts)
    bot.api.edit_message_text(chat_id: chat_id, message_id: message_id, text: text, **opts)
  rescue Telegram::Bot::Exceptions::ResponseError => e
    Rails.logger.error("Telegram edit error: #{e.message}")
  end

  def answer_callback(callback_id)
    bot.api.answer_callback_query(callback_query_id: callback_id)
  rescue Telegram::Bot::Exceptions::ResponseError => e
    Rails.logger.error("Telegram callback error: #{e.message}")
  end
end
