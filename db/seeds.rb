# Demo ev sahibi (Host)
user = User.find_or_initialize_by(slug: "volkan")
user.update!(
  name: "Volkan Godak",
  email_address: "godakvolkan@gmail.com",
  password: "password123"
)

# Randevu Türleri (Event Types)
mentorluk = user.event_types.find_or_create_by!(slug: "mentorluk") do |et|
  et.name = "Mentorluk"
  et.duration_minutes = 30
  et.requires_approval = true
  et.approval_window_hours = 24
  et.location = "https://meet.google.com/abc-defg-hij"
end
mentorluk.update!(location: "https://meet.google.com/abc-defg-hij") if mentorluk.location.blank?

tanitim = user.event_types.find_or_create_by!(slug: "tanitim") do |et|
  et.name = "Tanitim Gorusmesi"
  et.duration_minutes = 15
  et.requires_approval = false
  et.approval_window_hours = nil
  et.location = "Samsun Universitesi, B Blok, Oda 204"
end
tanitim.update!(location: "Samsun Universitesi, B Blok, Oda 204") if tanitim.location.blank?

# Müsaitlik Kuralları (Pzt-Cum 09:00 - 17:00)
(1..5).each do |day|
  user.availability_rules.find_or_create_by!(day_of_week: day) do |ar|
    ar.start_time = "09:00"
    ar.end_time = "17:00"
  end
end

# Önceden oluşturulmuş randevuları temizle
user.bookings.destroy_all

now = Time.current.in_time_zone("Istanbul")

# ============================================================
# SENARYO 1: bayulgen5546@gmail.com — Kronik No-Show kuralı
# 2 adet geçmiş randevu, ikisi de no_show olarak işaretli.
# Demo: bayulgen "Tanitim" (normalde onay gerektirmez) için
# randevu almaya çalışınca force_approval devreye girer → pending.
# ============================================================

# 3 gün öncesinin Pazartesi-Cuma arasında bir güne düşmesini garanti et
past_day_1 = (now - 5.days).change(hour: 10, min: 0, sec: 0)
past_day_2 = (now - 3.days).change(hour: 14, min: 0, sec: 0)

user.bookings.create!(
  event_type: mentorluk,
  invitee_name: "Bayulgen Test",
  invitee_email: "bayulgen5546@gmail.com",
  starts_at: past_day_1,
  ends_at: past_day_1 + 30.minutes,
  status: "no_show"
)

user.bookings.create!(
  event_type: mentorluk,
  invitee_name: "Bayulgen Test",
  invitee_email: "bayulgen5546@gmail.com",
  starts_at: past_day_2,
  ends_at: past_day_2 + 30.minutes,
  status: "no_show"
)

# ============================================================
# SENARYO 2: volkangodak@gmail.com — Normal onay akışı
# 1 adet pending randevu (Mentorluk, onay gerektirir).
# Demo: Admin panelden onaylama veya reddetme gösterilir.
# ============================================================

# Yarından itibaren en yakın hafta içi günü bul
future_day = now + 1.day
future_day += 1.day while [6, 0].include?(future_day.wday)
future_slot = future_day.change(hour: 11, min: 0, sec: 0)

pending_booking = user.bookings.create!(
  event_type: mentorluk,
  invitee_name: "Volkan Godak",
  invitee_email: "volkangodak@gmail.com",
  starts_at: future_slot,
  ends_at: future_slot + 30.minutes,
  status: "pending",
  approval_deadline_at: future_slot - 1.hour
)

# ============================================================
# SENARYO 3: 231118058@samsun.edu.tr — Onaylı randevu + expire testi
# 1 adet confirmed randevu (gelecekte) + 1 adet expired randevu.
# Demo: Tamamlanan akış ve süresi dolmuş randevu görünümü.
# ============================================================

future_day_2 = future_day + 1.day
future_day_2 += 1.day while [6, 0].include?(future_day_2.wday)
future_slot_2 = future_day_2.change(hour: 14, min: 0, sec: 0)

user.bookings.create!(
  event_type: tanitim,
  invitee_name: "Ogrenci Test",
  invitee_email: "231118058@samsun.edu.tr",
  starts_at: future_slot_2,
  ends_at: future_slot_2 + 15.minutes,
  status: "confirmed"
)

# Expired randevu: geçmişte oluşturulmuş ama onaylanmamış
expired_slot = (now - 2.days).change(hour: 15, min: 0, sec: 0)
user.bookings.create!(
  event_type: mentorluk,
  invitee_name: "Ogrenci Test",
  invitee_email: "231118058@samsun.edu.tr",
  starts_at: expired_slot,
  ends_at: expired_slot + 30.minutes,
  status: "expired",
  approval_deadline_at: expired_slot - 1.hour
)

puts "=" * 60
puts "SEED TAMAMLANDI"
puts "=" * 60
puts ""
puts "Host: godakvolkan@gmail.com / password123"
puts "Panel: /panel"
puts ""
puts "bayulgen5546@gmail.com  → 2x no_show (Mentorluk)"
puts "  → Tanitim'da yeni randevu alırsa force_approval → pending"
puts ""
puts "volkangodak@gmail.com   → 1x pending (Mentorluk, #{future_slot.strftime('%d/%m %H:%M')})"
puts "  → Panelden onayla/reddet gösterisi"
puts ""
puts "231118058@samsun.edu.tr → 1x confirmed (Tanitim, #{future_slot_2.strftime('%d/%m %H:%M')})"
puts "                        → 1x expired (Mentorluk, geçmiş)"
puts "=" * 60
