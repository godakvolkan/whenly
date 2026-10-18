# Whenly — 5 Dakikalık Sunum ve Kod Yeri Rehberi (Kopya Kağıdı)

Bu belge, sınıfta tahtaya çıktığında 5 dakikayı kusursuz yönetmen ve hocanın soracağı **"kod yeri"** sorularına saniyesinde dosya ve satır göstererek **100 tam puanı** garantilemen için hazırlanmıştır.

---

## 1. Sunum Kronometresi (5 Dakika Akışı)

### [00:00 - 00:30] 1. Giriş: SaaS, Aort Dilimi ve Para Ödeyenler (30 sn)
- **Cümle:**  
  > *"Hocam projemin adı **Whenly**, ilham kaynağım **Calendly**. Fortune 500'de Hewlett Packard Enterprise (HPE) ve US Foods gibi şirketler yıllık en az 15.000$ ödeyerek kurumsal planda bu sistemi kullanıyor. Klonladığım **aort dilimi**: Ev sahibinin haftalık müsaitliğini tanımlaması, davetlinin uygun saati seçerek randevu alması, ev sahibinin onay/ret vermesi ve randevunun tamamlanmasıdır."*

---

### [00:30 - 02:30] 2. Canlı Uygulama Demosu (2 dk)
Canlı URL üzerinden (`https://0732941c31d4b7.lhr.life`) sırasıyla yapacakların:
1. **Davetli Ekranı:** `/volkan/mentorluk` sayfasına git.
   - Yarın için bir saat seç (dolu saatlerin kırmızı çizili **DOLU** olduğunu göster).
   - `volkangodak@gmail.com` adıyla randevu oluştur. Ekranın **"Onay Bekliyor"** durumuna geçtiğini göster.
2. **Ev Sahibi Paneli:** `/panel` sekmesine geç.
   - **Onay Bekleyenler** sekmesinde randevunun düştüğünü, altında geri sayım sayacının (`⏳ Kalan süre: ...`) çalıştığını göster.
   - İstersen sarı **"Süreyi Doldur (Simüle Et)"** butonuna basarak SLA dolunca randevunun kendiliğinden düşüp saatin boşa çıktığını göster, ya da yeşil **"Onayla"** butonuna bas.
3. **No-Show Kuralı Demosu (Vurucu Darbe):**
   - Panelde **"Geçmiş"** sekmesine tıkla.
   - Listede `bayulgen5546@gmail.com` için 2 tane randevu göreceksin. Kırmızı **"Gelmedi Olarak İşaretle (No-Show)"** butonlarına bas.
   - Yanında **"⚠️ Tekrar eden no-show"** rozetinin yandığını göster.
   - Sonra gizli sekmeden `/volkan/tanitim` adresine git (bu etkinlik normalde anında onaylanır). `bayulgen5546@gmail.com` ile randevu al; sistemin onu cezalandırıp **zorla onay kuyruğuna düşürdüğünü** hocaya göster!

---

### [02:30 - 03:30] 3. Kod Gösterme: Durum Geçişi ve Zaman Kuralı (1 dk)
Editöründe şu iki dosyayı açıp göstereceksin:

1. **Durum Geçişleri (State Machine):**
   - Dosya: `app/models/booking.rb` (Satır 7 - 13)
   - *"Hocam harici gem kullanmadık. `TRANSITIONS` tablosunda `pending -> confirmed`, `pending -> declined`, `pending -> expired` gibi 7 durum ve izin verilen geçişler tanımlıdır."*
2. **Zaman Kuralları:**
   - Dosya: `app/models/scheduling_rules.rb`
   - *"Hocam zaman kurallarımız 4 ana kuraldan oluşur: En az 2 saat önceden randevu alma (`bookable?`), onay son tarihi penceresi (`approval_deadline_for`), 15 dk sonra no-show işaretleme ve aynı gün mükerrer randevu engeli (`has_booking_on_day?`)."*

---

### [03:30 - 04:30] 4. Çözülen Acı ve Yapamadıklarımız (1 dk)
- **100 Puanlık Acı:**
  > *"Calendly'de randevular ev sahibinin onayı olmadan doğrudan takvime işlenir. 21 Temmuz 2026'da Calendly Topluluk Yöneticisi Allie M forumda 'Yerel bir onay bekleme özelliğimiz yok' diyerek bu eksikliği kabul etmiştir. Whenly'de randevu onay bekler; süresi dolarsa saat kilitli kalmaz, otomatik düşer (`expired`); 2 kez gelmeyenler ise otomatik olarak zorunlu onaya tabi tutulur."*
- **Yapamadıklarım:**
  > *"Google Calendar API (OAuth 2.0) iki yönlü senkronizasyonu eklemedik; randevuları kendi veritabanımızda yönetip bildirimleri Gmail SMTP ile e-posta olarak iletiyoruz."*

---

### [04:30 - 05:00] 5. HOCANIN SORACAĞI KOD YERİ SORULARI (30 sn)

Hoca tahtada: *"Şu kuralı değiştirmek istesem kodda nereye dokunacaksın?"* diyecek.  
İşte karşına çıkabilecek tüm senaryolar ve kesin dosya/satır cevapları:

---

#### 📌 Soru 1: "SLA süresi hafta sonunu saymasın" veya "Onay süresi 24 saat değil 48 saat olsun"
- **Dosya:** `app/models/scheduling_rules.rb`
- **Metot:** `def self.approval_deadline_for(booking)` (Satır 13 - 19)
- **Cevap:** *"Hocam buradaki `approval_hours` hesabına bakarız. Hafta sonunu saymamak için `booking.created_at` üzerine eklerken `business_days` (iş günleri) mantığı ekleriz veya Cumartesi/Pazar'a denk geliyorsa Pazartesi sabahına öteleriz."*

---

#### 📌 Soru 2: "2 saat önceden randevu alma kuralını 24 saat yap veya aynı güne randevu alınamasın"
- **Dosya:** `app/models/scheduling_rules.rb`
- **Metot:** `def self.bookable?(starts_at)` (Satır 7 - 10)
- **Sabit:** `MINIMUM_NOTICE_HOURS = 2` (Satır 2)
- **Cevap:** *"Hocam en tepedeki `MINIMUM_NOTICE_HOURS = 2` sabitini `24` yaparız; ya da `starts_at.to_date > Date.current` kontrolü ekleriz."*

---

#### 📌 Soru 3: "2 kez gelmeyen değil de 3 kez gelmeyen zorunlu onaya düşsün"
- **Dosya:** `app/models/scheduling_rules.rb`
- **Sabit:** `NO_SHOW_THRESHOLD = 2` (Satır 3)
- **Metot:** `def self.repeat_no_show?(user, invitee_email)` (Satır 22 - 26)
- **Cevap:** *"Hocam `NO_SHOW_THRESHOLD` sabitini 3 yaparız. Sayma sorgusu `Booking.where(status: 'no_show').count >= NO_SHOW_THRESHOLD` satırında çalışır."*

---

#### 📌 Soru 4: "Toplantı bittikten 15 dakika sonra değil de 1 saat sonra No-Show işaretlenebilsin"
- **Dosya:** `app/models/scheduling_rules.rb`
- **Sabit:** `NO_SHOW_MARKING_DELAY_MINUTES = 15` (Satır 4)
- **Metot:** `def self.can_mark_no_show?(booking)` (Satır 29 - 32)
- **Cevap:** *"Hocam `NO_SHOW_MARKING_DELAY_MINUTES` değerini 60 yaparız."*

---

#### 📌 Soru 5: "Aynı gün içinde mükerrer randevu engeli nerede kontrol ediliyor?"
- **Kural Fonksiyonu:** `app/models/scheduling_rules.rb` -> `def self.has_booking_on_day?` (Satır 40 - 48)
- **Rezervasyon Oluşturulurken Engellendiği Yer:** `app/models/bookings/create.rb` (Satır 65 - 71)
- **Cevap:** *"Hocam kural tanımı `scheduling_rules.rb` içinde, rezervasyon oluşturma sırasındaki validasyon kontrolü ise `Bookings::Create` servisindedir."*

---

#### 📌 Soru 6: "Müsait saatler (slotlar) nerede hesaplanıyor? Dolu saatleri nerede eliyoruz?"
- **Dosya:** `app/models/slot_finder.rb`
- **Metotlar:**
  - `def all_slots` (Satır 8 - 36): Çalışma saatlerini etkinlik süresine (örn: 30 dk) böler.
  - `def slot_available?(starts_at, ends_at)` (Satır 44 - 51): O saatte aktif veya onay bekleyen randevu var mı diye bakar.
- **Cevap:** *"Hocam `SlotFinder` sınıfı içinde `all_slots` çalışma saatleri aralığını üretir, `slot_available?` ise veritabanındaki aktif rezervasyonlara bakarak slotu dolu veya boş olarak işaretler."*

---

#### 📌 Soru 7: "Yeni bir randevu türü (örneğin 45 dakikalık 'Teknik Mülakat') eklemek istesek nereden eklenir?"
- **Arayüzden:** Ev sahibi panelinde sol menüdeki **"Etkinlik Türleri"** (`/panel/event_types`) -> **"Yeni Etkinlik Türü"** butonundan.
- **Veritabanı / Seed Kodundan:** `db/seeds.rb` (Satır 10 - 22)
- **Model:** `app/models/event_type.rb`
- **Cevap:** *"Hocam hem paneldeki `/panel/event_types` arayüzünden form doldurarak hem de `seeds.rb` içinden `user.event_types.create!(name: 'Teknik Mülakat', duration_minutes: 45, requires_approval: true)` şeklinde eklenir."*

---

#### 📌 Soru 8: "Ev sahibinin çalışma saatleri (müsaitlik kuralı) nerede tutuluyor ve nereden değişir?"
- **Arayüzden:** Panelde **"Müsaitlik Ayarları"** (`/panel/availability_rules`).
- **Veritabanı Tablosu:** `availability_rules` tablosu (`day_of_week`, `start_time`, `end_time`).
- **Model:** `app/models/availability_rule.rb`
- **Controller:** `app/controllers/panel/availability_rules_controller.rb`
- **Cevap:** *"Hocam `availability_rules` tablosunda haftanın günleri (1=Pazartesi .. 5=Cuma) ve başlangıç/bitiş saatleri tutulur. Panelden güncellenir."*

---

#### 📌 Soru 9: "Ev sahibi bir randevuyu nereden onaylar veya reddeder? Hangi controller çalışır?"
- **Dosya:** `app/controllers/panel/bookings_controller.rb`
- **Eylemler (Actions):**
  - `def confirm` (Satır 11): `@booking.confirm!` çağırır ve onay maili atar.
  - `def decline` (Satır 17): `@booking.decline!` çağırır ve ret maili atar.
  - `def expire` (Satır 27): `@booking.expire!` çağırır (SLA simülasyonu).
  - `def no_show` (Satır 37): `@booking.no_show!` çağırır.

---

#### 📌 Soru 10: "E-posta şablonları nerede? Mail gönderme kodları nerede?"
- **Mailer Sınıfı:** `app/mailers/booking_mailer.rb`
- **HTML E-posta Şablonları:** `app/views/booking_mailer/`
  - `pending_approval.html.erb` (Davetliye: Onay bekliyor)
  - `new_booking_request.html.erb` (Ev sahibine: Yeni randevu talebi var)
  - `booking_confirmed.html.erb` (Her iki tarafa: Randevu onaylandı)
  - `booking_declined.html.erb` (Davetliye: Randevu reddedildi)
  - `booking_expired.html.erb` (Davetliye: Randevu süresi doldu)
- **SMTP Ayarları:** `config/environments/development.rb` (Satır 44-54) ve `production.rb` (Satır 63-76)

---

## Özet Hatırlatma:
Bu kopya kağıdı cebinde veya masanda açık dursun. Hoca kural sorduğu an tek kelimeyle:
👉 **`app/models/scheduling_rules.rb`** diyeceksin! Başarılar!
