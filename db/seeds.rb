# Demo ev sahibi (Host)
user = User.find_or_create_by!(email_address: "demo@slotwise.dev") do |u|
  u.name = "Volkan Godak"
  u.password = "password123"
  u.slug = "volkan"
end

# Randevu Türleri (Event Types)
user.event_types.find_or_create_by!(slug: "mentorluk") do |et|
  et.name = "Mentorluk"
  et.duration_minutes = 30
  et.requires_approval = true
  et.approval_window_hours = 24
end

user.event_types.find_or_create_by!(slug: "tanitim") do |et|
  et.name = "Tanitim Gorusmesi"
  et.duration_minutes = 15
  et.requires_approval = false
  et.approval_window_hours = nil
end

# Müsaitlik Kuralları (Pzt-Cum 09:00 - 17:00)
(1..5).each do |day|
  user.availability_rules.find_or_create_by!(day_of_week: day) do |ar|
    ar.start_time = "09:00"
    ar.end_time = "17:00"
  end
end

# Örnek Rezervasyonlar (Demo için)
mentorluk = user.event_types.find_by!(slug: "mentorluk")
tanitim = user.event_types.find_by!(slug: "tanitim")

# 1. Onay Bekleyen Randevu (Geri sayım sayacı görünür)
user.bookings.find_or_create_by!(token: "demo_pending_token") do |b|
  b.event_type = mentorluk
  b.invitee_name = "Ali Kaya"
  b.invitee_email = "ali@example.com"
  b.starts_at = 1.day.from_now.change(hour: 14, min: 0)
  b.ends_at = 1.day.from_now.change(hour: 14, min: 30)
  b.status = "pending"
  b.approval_deadline_at = 1.day.from_now - 2.hours
end

# 2. Yaklaşan Onaylanmış Randevu
user.bookings.find_or_create_by!(token: "demo_confirmed_token") do |b|
  b.event_type = tanitim
  b.invitee_name = "Zeynep Arslan"
  b.invitee_email = "zeynep@example.com"
  b.starts_at = 2.days.from_now.change(hour: 11, min: 0)
  b.ends_at = 2.days.from_now.change(hour: 11, min: 15)
  b.status = "confirmed"
end

# 3. Geçmişte 2 kez gelmeyen (No-Show) davetli (100 Puanlık Özellik Demosu)
user.bookings.find_or_create_by!(token: "demo_noshow_1") do |b|
  b.event_type = mentorluk
  b.invitee_name = "Mert Demir (Gelmeyen)"
  b.invitee_email = "mert@kronik.dev"
  b.starts_at = 5.days.ago.change(hour: 10, min: 0)
  b.ends_at = 5.days.ago.change(hour: 10, min: 30)
  b.status = "no_show"
end

user.bookings.find_or_create_by!(token: "demo_noshow_2") do |b|
  b.event_type = mentorluk
  b.invitee_name = "Mert Demir (Gelmeyen)"
  b.invitee_email = "mert@kronik.dev"
  b.starts_at = 3.days.ago.change(hour: 15, min: 0)
  b.ends_at = 3.days.ago.change(hour: 15, min: 30)
  b.status = "no_show"
end

# Ve bu kişinin onay bekleyen yeni talebi (Üzerinde ⚠️ Tekrar eden no-show uyarısı yanacak!)
user.bookings.find_or_create_by!(token: "demo_noshow_pending") do |b|
  b.event_type = tanitim # Tanıtım normalde anında onaylanır, ama bu kişi için zorunlu pending!
  b.invitee_name = "Mert Demir (Gelmeyen)"
  b.invitee_email = "mert@kronik.dev"
  b.starts_at = 1.day.from_now.change(hour: 16, min: 0)
  b.ends_at = 1.day.from_now.change(hour: 16, min: 15)
  b.status = "pending"
  b.approval_deadline_at = 1.day.from_now - 1.hour
end

puts "Seed data yüklendi: Host 'volkan', 2 Event Type, 5 Müsaitlik Kuralı ve 5 Örnek Rezervasyon (No-Show demosu dahil)."

