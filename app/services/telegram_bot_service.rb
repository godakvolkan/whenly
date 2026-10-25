require "telegram/bot"
require "faraday"

class TelegramBotService
  LANGS = {
    "tr" => {
      welcome: "👋 *Whenly Randevu Sistemine Hoş Geldiniz!*\n\nBu bot ile kolayca randevu alabilir ve profilinizi yönetebilirsiniz.\n\n📌 *Komutlar:*\n/randevu — Yeni randevu al\n/bagla — Ev sahibi hesabınızı bağlayın\n/randevularim — Randevuları ve tarih değişikliklerini inceleyin\n/profil — Profil bilgilerinizi görün ve düzenleyin\n/lang — Dil değiştir (TR/EN)\n/iptal — Mevcut işlemi iptal et",
      cancel: "İşlem iptal edildi.",
      enter_name: "👤 *Adınızı ve soyadınızı yazın:*",
      enter_email: "📧 *E-posta adresinizi yazın:*",
      invalid_name: "Lütfen geçerli bir ad girin.",
      invalid_email: "Lütfen geçerli bir e-posta adresi girin.",
      no_host: "Şu anda kayıtlı ev sahibi bulunmuyor.",
      select_host: "👤 *Kimin için randevu almak istiyorsunuz?*",
      select_event: "📋 *%{name}* için hangi randevu türü?\n",
      no_event_types: "Bu ev sahibinin randevu türü bulunmuyor.",
      select_date: "📅 *Hangi gün için randevu almak istersiniz?*",
      no_days: "😔 Önümüzdeki 2 hafta içinde müsait gün bulunmuyor.",
      no_slots: "😔 Bu tarihte müsait saat bulunmuyor. Başka bir gün seçin.",
      available_slots: "🕐 *%{date} tarihinde müsait saatler:*\n%{name} (%{dur} dk)",
      booking_created: "🎉 *Randevunuz oluşturuldu!*",
      approved: "✅ *Randevu Onaylandı*",
      declined: "❌ *Randevu Reddedildi*",
      no_pending: "📭 Bekleyen veya yaklaşan randevunuz bulunmuyor.",
      not_linked: "Hesabınız bağlı değil. Önce /bagla komutu ile bağlayın.",
      linked: "✅ *Hesap bağlandı!*\n\nMerhaba %{name}! Artık yeni randevu talepleri ve hatırlatmalar Telegram'dan gelecek.",
      not_found: "Bu e-posta ile kayıtlı bir hesap bulunamadı.",
      unauthorized: "Bu işlem için yetkiniz yok.",
      lang_changed: "Dil Türkçe olarak ayarlandı.",
      status_pending: "⏳ Onay Bekliyor",
      status_confirmed: "✅ Onaylandı",
      today: "Bugün"
    },
    "en" => {
      welcome: "👋 *Welcome to Whenly Booking System!*\n\nBook appointments and manage your profile.\n\n📌 *Commands:*\n/randevu — Book an appointment\n/bagla — Link your host account\n/randevularim — View bookings and reschedule requests\n/profil — View and edit profile\n/lang — Change language (TR/EN)\n/iptal — Cancel current operation",
      cancel: "Operation cancelled.",
      enter_name: "👤 *Enter your full name:*",
      enter_email: "📧 *Enter your email address:*",
      invalid_name: "Please enter a valid name.",
      invalid_email: "Please enter a valid email address.",
      no_host: "No registered hosts available.",
      select_host: "👤 *Who would you like to book with?*",
      select_event: "📋 Which appointment type for *%{name}*?\n",
      no_event_types: "This host has no appointment types.",
      select_date: "📅 *Which day would you like to book?*",
      no_days: "😔 No available days in the next 2 weeks.",
      no_slots: "😔 No available slots on this date. Try another day.",
      available_slots: "🕐 *Available slots on %{date}:*\n%{name} (%{dur} min)",
      booking_created: "🎉 *Your appointment has been created!*",
      approved: "✅ *Appointment Confirmed*",
      declined: "❌ *Appointment Declined*",
      no_pending: "📭 No pending or upcoming appointments.",
      not_linked: "Your account is not linked. Use /bagla first.",
      linked: "✅ *Account linked!*\n\nHello %{name}! You will now receive booking notifications via Telegram.",
      not_found: "No account found with this email.",
      unauthorized: "You are not authorized for this action.",
      lang_changed: "Language set to English.",
      status_pending: "⏳ Pending Approval",
      status_confirmed: "✅ Confirmed",
      today: "Today"
    }
  }.freeze

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
    when "/profil", "/profile"
      show_profile(chat_id, session)
    when "/lang", "/lang tr", "/lang en"
      switch_language(chat_id, text, session)
    when "/iptal"
      session.reset!
      send_text(chat_id, t(session, :cancel))
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
    when "prof_name"
      send_text(chat_id, "✏️ *Yeni Adınızı ve Soyadınızı yazın:*", parse_mode: "Markdown")
      session.transition_to!("edit_profile_name")
    when "prof_slug"
      send_text(chat_id, "🔗 *Yeni sayfa adresinizi (slug) yazın:*\n(Örn: `dr-volkan`)", parse_mode: "Markdown")
      session.transition_to!("edit_profile_slug")
    when "prof_pwd"
      send_text(chat_id, "🔑 *Yeni şifrenizi yazın:* (En az 6 karakter)", parse_mode: "Markdown")
      session.transition_to!("edit_profile_password")
    when /\Aaccept_reschedule_(\d+)\z/
      accept_reschedule_callback(chat_id, $1.to_i, callback)
    when /\Areject_reschedule_(\d+)\z/
      reject_reschedule_callback(chat_id, $1.to_i, callback)
    end

    answer_callback(callback.id)
  end

  def notify_host_new_booking(booking)
    user = booking.user
    return unless user.telegram_chat_id

    note_line = booking.notes.present? ? "\n📝 *Davetli Notu:* #{booking.notes}" : ""

    text = "📋 *Yeni Randevu Talebi*\n\n" \
           "👤 *Davetli:* #{booking.invitee_name}\n" \
           "📧 *E-posta:* #{booking.invitee_email}\n" \
           "📅 *Tarih:* #{booking.starts_at.in_time_zone('Istanbul').strftime('%d.%m.%Y')}\n" \
           "🕐 *Saat:* #{booking.starts_at.in_time_zone('Istanbul').strftime('%H:%M')} - #{booking.ends_at.in_time_zone('Istanbul').strftime('%H:%M')}\n" \
           "📌 *Tür:* #{booking.event_type.name}#{note_line}\n" \
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

    location = booking.event_type.location
    loc_line = location.present? ? "\n📍 *Konum:* #{location}" : ""

    text = "📋 *Randevu Güncelleme*\n\n" \
           "📅 #{booking.starts_at.in_time_zone('Istanbul').strftime('%d.%m.%Y %H:%M')}\n" \
           "📌 #{booking.event_type.name}\n" \
           "📊 *Durum:* #{status_text}#{loc_line}"

    send_text(session.chat_id, text, parse_mode: "Markdown")
  end

  def send_reminder(booking)
    user = booking.user
    time_str = booking.starts_at.in_time_zone("Istanbul").strftime("%H:%M")

    location = booking.event_type.location
    loc_line = location.present? ? "\n📍 *Konum:* #{location}" : ""

    if user.telegram_chat_id
      send_text(user.telegram_chat_id,
        "⏰ *Hatırlatma:* 1 saat sonra randevunuz var!\n\n" \
        "👤 #{booking.invitee_name}\n" \
        "🕐 #{time_str}\n" \
        "📌 #{booking.event_type.name}#{loc_line}",
        parse_mode: "Markdown")
    end

    session = TelegramSession.find_by("data->>'booking_id' = ?", booking.id.to_s)
    if session
      send_text(session.chat_id,
        "⏰ *Hatırlatma:* 1 saat sonra randevunuz var!\n\n" \
        "👤 #{user.name} ile #{booking.event_type.name}\n" \
        "🕐 #{time_str}#{loc_line}",
        parse_mode: "Markdown")
    end
  end

  private

  def token
    ENV.fetch("TELEGRAM_BOT_TOKEN")
  end

  def t(session, key, **vars)
    lang = session.respond_to?(:get) ? (session.get("lang") || "tr") : "tr"
    text = LANGS.dig(lang, key) || LANGS.dig("tr", key) || key.to_s
    vars.each { |k, v| text = text.gsub("%{#{k}}", v.to_s) }
    text
  end

  def switch_language(chat_id, text, session)
    lang = text.strip.split.last
    lang = lang == "en" ? "en" : "tr"
    session.set(:lang, lang)
    send_text(chat_id, t(session, :lang_changed), parse_mode: "Markdown")
  end

  def send_welcome(chat_id, session)
    session.reset!
    send_text(chat_id, t(session, :welcome), parse_mode: "Markdown")
  end

  def start_booking_flow(chat_id, session)
    hosts = User.where(role: "host")
    if hosts.empty?
      send_text(chat_id, t(session, :no_host))
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
    send_text(chat_id, t(session, :select_host), parse_mode: "Markdown", reply_markup: kb)
    session.transition_to!("select_host")
  end

  def select_host(chat_id, host_id, session)
    user = User.find_by(id: host_id)
    return send_text(chat_id, "Kullanıcı bulunamadı.") unless user

    session.set(:host_id, host_id)
    event_types = user.event_types
    if event_types.empty?
      send_text(chat_id, t(session, :no_event_types))
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
    send_text(chat_id, t(session, :select_event, name: user.name), parse_mode: "Markdown", reply_markup: kb)
    session.transition_to!("select_event_type")
  end

  def select_event_type(chat_id, et_id, session)
    et = EventType.find_by(id: et_id)
    return send_text(chat_id, "Randevu türü bulunamadı.") unless et

    session.set(:event_type_id, et_id)
    show_date_picker(chat_id, session)
  end

  def show_date_picker(chat_id, session)
    host = User.find(session.get("host_id"))
    et = EventType.find(session.get("event_type_id"))
    available_days = host.availability_rules.pluck(:day_of_week)

    today = Date.current
    day_names = { 1 => "Pzt", 2 => "Sal", 3 => "Çar", 4 => "Per", 5 => "Cum", 6 => "Cmt", 7 => "Paz" }

    buttons = (0..13).filter_map do |offset|
      d = today + offset.days
      next unless available_days.include?(d.cwday)
      next if SlotFinder.new(host, et, d).available_slots.empty?

      label = offset == 0 ? "#{t(session, :today)} (#{d.strftime('%d/%m')})" : "#{day_names[d.cwday]} #{d.strftime('%d/%m')}"
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: label, callback_data: "date_#{d.iso8601}")]
    end

    if buttons.empty?
      send_text(chat_id, t(session, :no_days))
      session.reset!
      return
    end

    kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
    send_text(chat_id, t(session, :select_date), parse_mode: "Markdown", reply_markup: kb)
    session.transition_to!("select_date")
  end

  def select_date(chat_id, date_str, session)
    date = Date.parse(date_str)
    session.set(:date, date_str)

    host = User.find(session.get("host_id"))
    et = EventType.find(session.get("event_type_id"))
    slots = SlotFinder.new(host, et, date).available_slots

    if slots.empty?
      send_text(chat_id, t(session, :no_slots))
      show_date_picker(chat_id, session)
      return
    end

    buttons = slots.map do |s|
      time_label = "#{s[:starts_at].in_time_zone('Istanbul').strftime('%H:%M')} - #{s[:ends_at].in_time_zone('Istanbul').strftime('%H:%M')}"
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: "🕐 #{time_label}", callback_data: "slot_#{s[:starts_at].iso8601}")]
    end
    kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
    send_text(chat_id,
      t(session, :available_slots, date: date.strftime('%d.%m.%Y'), name: et.name, dur: et.duration_minutes),
      parse_mode: "Markdown", reply_markup: kb)
    session.transition_to!("select_slot")
  end

  def select_slot(chat_id, starts_at_str, session)
    session.set(:starts_at, starts_at_str)
    send_text(chat_id, t(session, :enter_name), parse_mode: "Markdown")
    session.transition_to!("enter_name")
  end

  def handle_state_input(chat_id, text, session)
    case session.state
    when "enter_name"
      if text.length < 2
        send_text(chat_id, t(session, :invalid_name))
        return
      end
      session.set(:invitee_name, text)
      send_text(chat_id, t(session, :enter_email), parse_mode: "Markdown")
      session.transition_to!("enter_email")
    when "enter_email"
      unless text.match?(URI::MailTo::EMAIL_REGEXP)
        send_text(chat_id, t(session, :invalid_email))
        return
      end
      session.set(:invitee_email, text)
      send_text(chat_id, "📝 *Randevu Notu / Açıklama:*\nVarsa hekime/uzmana iletmek istediğiniz notu yazın.\n\n_Not eklemek istemiyorsanız_ *geç* _yazabilirsiniz._", parse_mode: "Markdown")
      session.transition_to!("enter_notes")
    when "enter_notes"
      clean_note = text.downcase.strip.in?(%w[geç gec /gec - yok hayır hayir]) ? nil : text
      session.set(:notes, clean_note)
      create_booking_from_session(chat_id, session)
    when "edit_profile_name"
      if text.length < 2
        send_text(chat_id, "Lütfen en az 2 karakterden oluşan geçerli bir ad girin.")
        return
      end
      user = User.find_by(telegram_chat_id: chat_id)
      if user
        user.update!(name: text)
        session.reset!
        send_text(chat_id, "✅ Adınız başarıyla güncellendi: *#{user.name}*", parse_mode: "Markdown")
        show_profile(chat_id, session)
      end
    when "edit_profile_slug"
      clean_slug = text.strip.downcase.parameterize
      if clean_slug.blank?
        send_text(chat_id, "Lütfen geçerli bir sayfa adresi (slug) girin.")
        return
      end
      user = User.find_by(telegram_chat_id: chat_id)
      if user
        if User.where.not(id: user.id).exists?(slug: clean_slug)
          send_text(chat_id, "❌ Bu sayfa adı (`#{clean_slug}`) zaten başkası tarafından kullanılıyor. Lütfen farklı bir slug deneyin.")
          return
        end
        user.update!(slug: clean_slug)
        session.reset!
        send_text(chat_id, "✅ Rezervasyon bağlantı adresiniz güncellendi:\n*#{clean_slug}*", parse_mode: "Markdown")
        show_profile(chat_id, session)
      end
    when "edit_profile_password"
      if text.length < 6
        send_text(chat_id, "❌ Şifre en az 6 karakter olmalıdır. Lütfen tekrar deneyin:")
        return
      end
      user = User.find_by(telegram_chat_id: chat_id)
      if user
        user.update!(password: text, password_confirmation: text)
        session.reset!
        send_text(chat_id, "✅ Giriş şifreniz başarıyla güncellendi!", parse_mode: "Markdown")
      end
    else
      handle_natural_language(chat_id, text, session)
    end
  end

  def handle_natural_language(chat_id, text, session)
    lower = text.downcase.gsub(/[İı]/, "i")

    if lower.match?(/randevu|rezervasyon|yer\s*var|müsait|boş|saat/)
      host = User.where(role: "host").first
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
        "/bagla — Hesap bağla\n" \
        "/profil — Profil ve hesap yönetimi\n\n" \
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
        starts_at: session.get("starts_at"),
        notes: session.get("notes")
      }
    ).call

    if result.success?
      booking = result.booking
      session.set(:booking_id, booking.id)

      invitee_email = session.get("invitee_email")
      no_show_forced = !et.requires_approval && booking.pending? && SchedulingRules.repeat_no_show?(host, invitee_email)

      status_text = booking.pending? ? t(session, :status_pending) : t(session, :status_confirmed)
      reason = if no_show_forced
                 "⚠️ Daha önce 2 kez katılmadığınız tespit edildiğinden randevunuz ev sahibi onayına düşmüştür."
               elsif booking.pending?
                 "Ev sahibi onayladığında bildirim alacaksınız."
               else
                 "Randevunuz kesinleşti!"
               end
      location = et.location
      loc_line = location.present? && booking.confirmed? ? "\n📍 *Konum:* #{location}" : ""
      note_line = booking.notes.present? ? "\n📝 *Not:* #{booking.notes}" : ""

      send_text(chat_id,
        "#{t(session, :booking_created)}\n\n" \
        "👤 *Ev Sahibi:* #{host.name}\n" \
        "📌 *Tür:* #{et.name}\n" \
        "📅 *Tarih:* #{booking.starts_at.in_time_zone('Istanbul').strftime('%d.%m.%Y')}\n" \
        "🕐 *Saat:* #{booking.starts_at.in_time_zone('Istanbul').strftime('%H:%M')} - #{booking.ends_at.in_time_zone('Istanbul').strftime('%H:%M')}\n" \
        "📊 *Durum:* #{status_text}#{loc_line}#{note_line}\n\n" \
        "#{reason}",
        parse_mode: "Markdown")

      send_ics_file(chat_id, booking) if booking.confirmed?

      TelegramReminderJob.set(wait_until: booking.starts_at - 1.hour).perform_later(booking.id) if booking.starts_at > 1.hour.from_now

      session.update!(state: "idle")
    else
      error_msg = result.error
      tip = case error_msg
            when /aynı gün/i then "\n💡 Aynı gün içinde yalnızca bir randevu alabilirsiniz. Farklı bir gün seçin."
            when /2 saat|onceden/i then "\n💡 Randevu en az 2 saat öncesinden alınmalıdır."
            when /çalışma saatleri/i then "\n💡 Seçtiğiniz saat ev sahibinin çalışma saatleri dışındadır."
            when /aktif randevu|başka bir/i then "\n💡 Bu saatte zaten bir randevu bulunuyor. Başka bir saat deneyin."
            else ""
            end
      send_text(chat_id, "❌ *Hata:* #{error_msg}#{tip}\n\nTekrar denemek için /randevu yazın.", parse_mode: "Markdown")
      session.reset!
    end
  end

  def connect_host_account(chat_id, email, session)
    user = User.find_by(email_address: email.downcase)
    if user
      user.update!(telegram_chat_id: chat_id)
      send_text(chat_id, t(session, :linked, name: user.name), parse_mode: "Markdown")
    else
      send_text(chat_id, "❌ #{t(session, :not_found)}")
    end
  end

  def show_host_bookings(chat_id)
    session = TelegramSession.for(chat_id)
    user = User.find_by(telegram_chat_id: chat_id)
    unless user
      send_text(chat_id, t(session, :not_linked))
      return
    end

    pending = user.bookings.where(status: "pending").order(:starts_at).limit(10)
    upcoming = user.bookings.where(status: "confirmed").where("starts_at > ?", Time.current).order(:starts_at).limit(10)
    rescheduling = user.bookings.where(reschedule_status: "pending").order(:starts_at).limit(10)

    if pending.empty? && upcoming.empty? && rescheduling.empty?
      send_text(chat_id, "📭 Bekleyen, yaklaşan veya tarih değişikliği bekleyen randevunuz bulunmuyor.")
      return
    end

    if rescheduling.any?
      text = "🔄 *Tarih Değişikliği Bekleyenler (#{rescheduling.count}):*\n\n"
      rescheduling.each do |b|
        by_label = b.rescheduled_by == "client" ? "Danışan talep etti" : "Siz teklif ettiniz"
        text += "• #{b.invitee_name} — #{b.event_type.name} (#{by_label})\n" \
                "  Mevcut: #{b.starts_at.in_time_zone('Istanbul').strftime('%d.%m %H:%M')}\n" \
                "  👉 Yeni: #{b.reschedule_starts_at.in_time_zone('Istanbul').strftime('%d.%m %H:%M')}\n\n"
      end

      buttons = rescheduling.select { |b| b.rescheduled_by == "client" }.map do |b|
        [
          Telegram::Bot::Types::InlineKeyboardButton.new(text: "✅ Yeni Saati Onayla: #{b.invitee_name}", callback_data: "accept_reschedule_#{b.id}"),
          Telegram::Bot::Types::InlineKeyboardButton.new(text: "❌ Reddet: #{b.invitee_name}", callback_data: "reject_reschedule_#{b.id}")
        ]
      end
      kb = buttons.any? ? Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons) : nil
      send_text(chat_id, text, parse_mode: "Markdown", reply_markup: kb)
    end

    text = ""
    if pending.any?
      text += "⏳ *Onay Bekleyen (#{pending.count}):*\n\n"
      pending.each do |b|
        note_str = b.notes.present? ? " (Not: #{b.notes})" : ""
        text += "• #{b.invitee_name} — #{b.event_type.name}#{note_str}\n" \
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

  def show_profile(chat_id, session)
    user = User.find_by(telegram_chat_id: chat_id)
    unless user
      send_text(chat_id, "⚠️ Hesabınız henüz bağlı değil.\n\nÖnce `/bagla eposta@adresiniz.com` komutu ile hesabınızı bağlayın.", parse_mode: "Markdown")
      return
    end

    booking_url = "https://whenly-cpyy.onrender.com/#{user.slug}/#{user.event_types.first&.slug}"

    text = "👤 *Kullanıcı Profil Bilgileri*\n\n" \
           "• *Ad Soyad:* #{user.name}\n" \
           "• *E-posta:* #{user.email_address}\n" \
           "• *Sayfa Adresi (Slug):* `#{user.slug}`\n" \
           "• *Randevu Sayfanız:* #{booking_url}\n" \
           "• *Telegram Chat ID:* `#{chat_id}`\n\n" \
           "Aşağıdaki butonlarla profil bilgilerinizi güncelleyebilirsiniz:"

    kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: [
        [
          Telegram::Bot::Types::InlineKeyboardButton.new(text: "✏️ Adı Değiştir", callback_data: "prof_name"),
          Telegram::Bot::Types::InlineKeyboardButton.new(text: "🔗 Slug Değiştir", callback_data: "prof_slug")
        ],
        [
          Telegram::Bot::Types::InlineKeyboardButton.new(text: "🔑 Şifre Değiştir", callback_data: "prof_pwd")
        ]
      ]
    )

    send_text(chat_id, text, parse_mode: "Markdown", reply_markup: kb)
  end

  def notify_host_reschedule_request(booking)
    user = booking.user
    return unless user.telegram_chat_id

    old_time = booking.starts_at.in_time_zone("Istanbul").strftime("%d.%m.%Y %H:%M")
    new_time = booking.reschedule_starts_at.in_time_zone("Istanbul").strftime("%d.%m.%Y %H:%M")
    note_line = booking.reschedule_note.present? ? "\n📝 *Danışan Açıklaması:* #{booking.reschedule_note}" : ""

    text = "🔄 *Tarih/Saat Değişikliği Talebi!*\n\n" \
           "👤 *Davetli:* #{booking.invitee_name}\n" \
           "📌 *Tür:* #{booking.event_type.name}\n\n" \
           "📅 *Mevcut Randevu:* #{old_time}\n" \
           "👉 *Talep Edilen Yeni Tarih:* #{new_time}#{note_line}\n\n" \
           "Bu saat değişikliğini onaylıyor musunuz?"

    kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: [
        [
          Telegram::Bot::Types::InlineKeyboardButton.new(text: "✅ Yeni Saati Onayla", callback_data: "accept_reschedule_#{booking.id}"),
          Telegram::Bot::Types::InlineKeyboardButton.new(text: "❌ Reddet", callback_data: "reject_reschedule_#{booking.id}")
        ]
      ]
    )

    send_text(user.telegram_chat_id, text, parse_mode: "Markdown", reply_markup: kb)
  end

  def notify_reschedule_accepted(booking)
    user = booking.user
    time_str = booking.starts_at.in_time_zone("Istanbul").strftime("%d.%m.%Y %H:%M")

    invitee_session = TelegramSession.find_by("data->>'booking_id' = ?", booking.id.to_s)
    if invitee_session
      send_text(invitee_session.chat_id,
        "🎉 *Randevu Tarihiniz Başarıyla Güncellendi!*\n\n" \
        "👤 *Ev Sahibi:* #{user.name}\n" \
        "📅 *Yeni Randevu Saati:* #{time_str}\n" \
        "📌 *Tür:* #{booking.event_type.name}",
        parse_mode: "Markdown")
      send_ics_file(invitee_session.chat_id, booking)
    end

    if user.telegram_chat_id
      send_text(user.telegram_chat_id,
        "✅ *Tarih Değişikliği Tamamlandı*\n\n" \
        "👤 #{booking.invitee_name}\n" \
        "📅 Yeni Randevu Saati: #{time_str}",
        parse_mode: "Markdown")
      send_ics_file(user.telegram_chat_id, booking)
    end
  end

  def notify_reschedule_rejected(booking)
    user = booking.user
    invitee_session = TelegramSession.find_by("data->>'booking_id' = ?", booking.id.to_s)
    if invitee_session
      send_text(invitee_session.chat_id,
        "❌ *Tarih Değişikliği Talebi Onaylanmadı*\n\n" \
        "Mevcut randevunuz korunmaktadır:\n" \
        "📅 #{booking.starts_at.in_time_zone('Istanbul').strftime('%d.%m.%Y %H:%M')}",
        parse_mode: "Markdown")
    end
  end

  def accept_reschedule_callback(chat_id, booking_id, callback)
    booking = Booking.find_by(id: booking_id)
    return unless booking

    user = User.find_by(telegram_chat_id: chat_id)
    return send_text(chat_id, "Bu işlem için yetkiniz yok.") unless user&.id == booking.user_id

    begin
      booking.accept_reschedule!
      time_str = booking.starts_at.in_time_zone("Istanbul").strftime("%d.%m.%Y %H:%M")
      edit_message(chat_id, callback.message.message_id,
        "✅ *Tarih Değişikliği Onaylandı*\n\n" \
        "👤 #{booking.invitee_name}\n" \
        "📅 Yeni Tarih: #{time_str}\n" \
        "📌 #{booking.event_type.name}",
        parse_mode: "Markdown")

      notify_reschedule_accepted(booking)
    rescue Booking::InvalidTransition => e
      send_text(chat_id, "❌ #{e.message}")
    end
  end

  def reject_reschedule_callback(chat_id, booking_id, callback)
    booking = Booking.find_by(id: booking_id)
    return unless booking

    user = User.find_by(telegram_chat_id: chat_id)
    return send_text(chat_id, "Bu işlem için yetkiniz yok.") unless user&.id == booking.user_id

    begin
      booking.reject_reschedule!
      edit_message(chat_id, callback.message.message_id,
        "❌ *Tarih Değişikliği Talebi Reddedildi*\n\n" \
        "👤 #{booking.invitee_name}\n" \
        "📅 Mevcut Randevu Geçerli: #{booking.starts_at.in_time_zone('Istanbul').strftime('%d.%m.%Y %H:%M')}",
        parse_mode: "Markdown")

      notify_reschedule_rejected(booking)
    rescue Booking::InvalidTransition => e
      send_text(chat_id, "❌ #{e.message}")
    end
  end

  def approve_booking(chat_id, booking_id, callback)
    booking = Booking.find_by(id: booking_id)
    return unless booking

    user = User.find_by(telegram_chat_id: chat_id)
    return send_text(chat_id, "Bu işlem için yetkiniz yok.") unless user&.id == booking.user_id

    begin
      booking.confirm!
      BookingMailer.booking_confirmed(booking).deliver_later rescue nil
      location = booking.event_type.location
      loc_line = location.present? ? "\n📍 *Konum:* #{location}" : ""
      edit_message(chat_id, callback.message.message_id,
        "✅ *Randevu Onaylandı*\n\n" \
        "👤 #{booking.invitee_name}\n" \
        "📅 #{booking.starts_at.in_time_zone('Istanbul').strftime('%d.%m.%Y %H:%M')}\n" \
        "📌 #{booking.event_type.name}#{loc_line}",
        parse_mode: "Markdown")
      notify_invitee_status(booking, "✅ Onaylandı")

      invitee_session = TelegramSession.find_by("data->>'booking_id' = ?", booking.id.to_s)
      send_ics_file(invitee_session.chat_id, booking) if invitee_session
      send_ics_file(chat_id, booking)

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
      BookingMailer.booking_declined(booking).deliver_later rescue nil
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
  rescue => e
    puts "SEND ERROR: #{e.class}: #{e.message}"
    retry_without_markdown(chat_id, text, opts) if opts[:parse_mode]
  end

  def edit_message(chat_id, message_id, text, **opts)
    bot.api.edit_message_text(chat_id: chat_id, message_id: message_id, text: text, **opts)
  rescue => e
    puts "EDIT ERROR: #{e.class}: #{e.message}"
  end

  def answer_callback(callback_id)
    bot.api.answer_callback_query(callback_query_id: callback_id)
  rescue => e
    puts "CALLBACK ERROR: #{e.class}: #{e.message}"
  end

  def send_ics_file(chat_id, booking)
    ics = IcsGenerator.new(booking)
    file = ics.to_file
    bot.api.send_document(
      chat_id: chat_id,
      document: Faraday::UploadIO.new(file.path, "text/calendar", "randevu_#{booking.token}.ics"),
      caption: "📅 Takvim dosyanız (.ics) — Google Calendar veya Outlook'a ekleyebilirsiniz."
    )
  rescue => e
    puts "ICS SEND ERROR: #{e.class}: #{e.message}"
  ensure
    file&.close
    file&.unlink
  end

  def retry_without_markdown(chat_id, text, opts)
    clean = text.gsub("*", "").gsub("_", "")
    bot.api.send_message(chat_id: chat_id, text: clean, **opts.except(:parse_mode))
  rescue => e
    puts "RETRY SEND ERROR: #{e.class}: #{e.message}"
  end
end
