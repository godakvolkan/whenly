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

# Önceden oluşturulmuş randevuları temizle (Kullanıcı talebiyle sıfırdan canlı test için)
user.bookings.destroy_all

puts "Seed tamamlandı: Host 'godakvolkan@gmail.com' (Volkan Godak), 2 Event Type (mentorluk, tanitim), 5 Müsaitlik Kuralı eklendi. Randevu tablosu sıfırlandı."
