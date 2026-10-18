# Demo ev sahibi (Host)
user = User.find_or_initialize_by(slug: "volkan")
user.update!(
  name: "Volkan Godak",
  email_address: "godakvolkan@gmail.com",
  password: "password123"
)

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

# Önceden oluşturulmuş randevuları temizle
user.bookings.destroy_all

# bayulgen5546@gmail.com için geçmişte 2 adet onaylı randevu ekle (Ev sahibi canlı olarak 'Gelmedi' işaretleyebilsin)
mentorluk = user.event_types.find_by!(slug: "mentorluk")

# 1. Randevu: Dün sabah (10:00 - 10:30)
yesterday_morning = (Time.current - 1.day).in_time_zone("Istanbul").change(hour: 10, min: 0, sec: 0)
user.bookings.create!(
  event_type: mentorluk,
  invitee_name: "Bayülgen Test",
  invitee_email: "bayulgen5546@gmail.com",
  starts_at: yesterday_morning,
  ends_at: yesterday_morning + 30.minutes,
  status: "confirmed"
)

# 2. Randevu: Bu sabah (09:00 - 09:30)
today_morning = Time.current.in_time_zone("Istanbul").change(hour: 9, min: 0, sec: 0)
# Eğer şu an saat 09:30'dan önceyse 2 gün öncesine alalım ki süresi geçmiş olsun
if Time.current < today_morning + 30.minutes
  today_morning = (Time.current - 2.days).in_time_zone("Istanbul").change(hour: 11, min: 0, sec: 0)
end

user.bookings.create!(
  event_type: mentorluk,
  invitee_name: "Bayülgen Test",
  invitee_email: "bayulgen5546@gmail.com",
  starts_at: today_morning,
  ends_at: today_morning + 30.minutes,
  status: "confirmed"
)

puts "Seed tamamlandı: Host 'godakvolkan@gmail.com', bayulgen5546@gmail.com için geçmişe 2 adet onaylı randevu eklendi (Geçmiş sekmesinden 'Gelmedi / No-Show' işaretlenmeye hazır)."
