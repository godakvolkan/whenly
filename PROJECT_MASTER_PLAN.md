# Proje Planı: Whenly

| Alan | Bilgi |
| :--- | :--- |
| Ders | YZM379 – Ruby ve Ruby on Rails |
| Öğretim üyesi | Nurettin Şenyer |
| Teslim ve sunum | 19 Ekim 2026 Pazartesi, ders saati, 5 dakika canlı sunum |
| Ödev türü | Bireysel; puan sınav notu olarak işlenir |
| Ürün adı | Whenly |
| İlham kaynağı | Calendly |
| Teknoloji | Ruby on Rails 8.1, Hotwire, PostgreSQL, Solid Queue, Render, GitHub Actions |

---

## 1. Ödevin gereksinimleri

### Puanlama

Yalnızca üç puan verilir: 0, 85 ve 100+.

| Puan | Koşul |
| :--- | :--- |
| 0 | Aşağıdakilerden biri yeterlidir: canlı URL yok; ana iş akışı uçtan uca çalışmıyor; sunumda "var" denip çalışmayan bir özellik; çalıştırılmamış bir test raporu veya sonuç; orijinal marka adı veya logosu uygulamada. |
| 85 | Tamamı gerekir: README'de kaynaklı Fortune 500 kanıtı ile Faz 1 ve Faz 2; ana iş akışı canlıda uçtan uca çalışıyor; testler GitHub Actions'ta çalışıyor ve başarılı (rozet README'de); zaman kuralı ve durum geçişi için `travel_to` testleri; AGENT.md; README'de "Yapamadıklarım" bölümü. |
| 100+ | 85 puanın tamamı ve gerçek kullanıcı yorumlarından belirlenen bir problemin uygulamada çözülmesi. |

### Teslim edilecekler

- Canlı uygulama URL'si
- GitHub deposu bağlantısı (README, AGENT.md, CI rozeti)

### Açık nokta

Ödev metni "en az bir zaman kuralı" isterken ders slaytı 35, 85 puan için "3 zaman kuralı `travel_to` testli" ve "G1–G5" belgelerini sayıyor. Uygulamada üç zaman kuralı ve testleri bulunduğundan zaman kuralı şartı her iki yoruma göre karşılanır. G1–G5 belgeleri için öğretim üyesine danışılmalıdır.

---

## 2. Faz 1: Fortune 500 genel tablosu

Ayrıntılar ve kaynaklar README'dedir.

| Gösterge | Değer |
| :--- | :--- |
| Değerleme aralığı | ~2 milyar $ – 4,2 trilyon $ (piyasa değeri olmayan şirketler de var) |
| Çalışan sayısı aralığı | ~600 – ~2,1 milyon |
| Şirket başına SaaS ürünü | ~650 (10.000+ çalışanlı şirketler) |
| Yıllık SaaS harcaması | 123,5 – 375,5 milyon $ (10.000+ çalışanlı şirketler) |

---

## 3. SaaS seçimi

- **Ürün:** Calendly
- **Fortune 500 kanıtı:** Calendly'nin Eylül 2023 basın bülteni (Fortune 500'ün %86'sı) ve kurumsal sayfası ("over 4 out of 5"). Bültende müşteri olarak adı geçen Hewlett Packard Enterprise ve US Foods 2026 Fortune 500 listesindedir.
- **Seçim gerekçesi:** Ürünün merkezinde doğal bir zaman kuralı ve durum akışı bulunması; kullanıcı probleminin Calendly ekibinin kendi yanıtlarıyla belgelenebilmesi; Calendly'nin Rails ile geliştirilmiş bir ürün olması.
- **Değerlendirilen diğer adaylar:** Zendesk, PagerDuty, Docebo, Envoy, Sentry, Procore, Samsara, SAP Concur, Ironclad, Jira Service Management.

---

## 4. Faz 2: Maliyet tahmini

| Kalem | Değer | Yöntem |
| :--- | :--- | :--- |
| Ürünün satır sayısı | ~300.000 | Cal.com `cloc` ölçümü: testler hariç ~324.400 satır |
| Çekirdeği ajanla üretme maliyeti | ~1.260 $ (500 – 3.000 $) | 3 milyon çıktı + 90 milyon girdi token, ×3 düzeltme turu, Claude Opus 5.5 fiyatı |
| Çekirdek için süre | 2 – 4 hafta | Darboğaz: doğrulama |
| Ana iş akışı için süre | 2 – 3 gün | |
| Ana iş akışı satır sayısı (gerçekleşen) | 3.060 | `cloc`, 15.10.2026 |

Gerçekleşen maliyet ve süre, sunum öncesinde README'ye işlenecektir.

---

## 5. Kullanıcı problemi

Calendly'de rezervasyonlar ev sahibinin onayı olmadan takvime işlenir. Calendly ekibi bu özelliğin bulunmadığını 2023–2026 arasında beş ayrı forum başlığında belirtmiştir (son yanıt: 21.07.2026). Kaynaklar `aci-kanit-dosyasi.md` ve README'dedir.

**Whenly'deki çözüm:**

1. Onay kuyruğu: talep `pending` olarak oluşur; ev sahibi onaylar veya reddeder.
2. Otomatik düşme: onay süresi geçen talep `expired` olur ve saat yeniden açılır.
3. Katılımsızlık kuralı: iki kez katılmayan davetlinin sonraki talebi onaya düşer.

**Kapsam dışı:** Spam engelleme ve yapay zekâ özeti. Bu özellikler Calendly'de mevcuttur.

---

## 6. Mimari

| Konu | Karar |
| :--- | :--- |
| Yapı | Tek Rails uygulaması; ayrı ön yüz projesi yok |
| Arayüz | Hotwire (Turbo, Stimulus), importmap; JS derleme adımı yok |
| Kimlik doğrulama | Rails 8 `authentication` üreticisi |
| Arka plan işi | Solid Queue, Puma içinde (`plugin :solid_queue`) |
| Saat dilimi | Uygulama Europe/Istanbul, veritabanı UTC |
| Veritabanı | Tek PostgreSQL (Render ücretsiz plan) |

### Veri modeli

| Model | Alanlar |
| :--- | :--- |
| `User` | ad, e-posta, şifre, `slug` |
| `EventType` | ad, süre, `requires_approval`, `approval_window_hours`, `slug` |
| `AvailabilityRule` | haftanın günü, başlangıç, bitiş |
| `Booking` | davetli adı ve e-postası, başlangıç, bitiş, `status`, `approval_deadline_at`, `token` |

### Durum akışı

```
pending ──confirm──▶ confirmed ──complete──▶ completed
   │                     ├──no_show──▶ no_show
   ├──decline──▶ declined└──cancel───▶ canceled
   ├──expire───▶ expired
   └──cancel───▶ canceled
```

### Zaman kuralları (`app/models/scheduling_rules.rb`)

1. En az 2 saat önceden rezervasyon (`bookable?`)
2. Onay son tarihi: onay penceresi ile toplantıdan 1 saat öncesinin erken olanı (`approval_deadline_for`)
3. Katılmadı işareti toplantı bitişinden 15 dakika sonra açılır (`can_mark_no_show?`); iki kez katılmayan davetliye onay zorunluluğu (`force_approval?`)

### Ekranlar

| Yol | Kullanıcı | İşlev |
| :--- | :--- | :--- |
| `/:slug/:event_type` | Davetli | Tarih ve saat seçimi, rezervasyon formu |
| `/b/:token` | Davetli | Durum takibi, iptal |
| `/panel` | Ev sahibi | Onay bekleyen, yaklaşan ve geçmiş randevular |
| `/panel/event_types` | Ev sahibi | Randevu türleri |
| `/panel/availability_rules` | Ev sahibi | Haftalık müsaitlik |

---

## 7. Sunum akışı (5 dakika)

| Süre | Bölüm | İçerik |
| :--- | :--- | :--- |
| 0:00 – 0:30 | Ürün | Whenly ve ilham kaynağı Calendly; Fortune 500 kullanımı; seçilen ana iş akışı |
| 0:30 – 2:30 | Canlı demo | Davetli sayfasından rezervasyon → durum sayfası → ev sahibi panelinde onay. Katılımsızlık kuralı: demo verisindeki davetlinin yeni talebinin onaya düşmesi |
| 2:30 – 3:30 | Kod | `app/models/booking.rb` (geçiş tablosu), `app/models/scheduling_rules.rb` (onay süresi), `travel_to` testi |
| 3:30 – 4:30 | Kullanıcı problemi | Calendly forumundaki 21.07.2026 tarihli yanıt ve Whenly'deki çözüm; "Yapamadıklarım" bölümü |
| 4:30 – 5:00 | Kod yeri sorusu | Örnek: "Onay süresi hafta sonunu saymasın" → `SchedulingRules.approval_deadline_for` |

---

## 8. Zaman planı

| Gün | İş |
| :--- | :--- |
| Çarşamba 14 Ekim | Ödev analizi, araştırma, SaaS seçimi, proje iskeleti |
| Perşembe 15 Ekim | Modeller, kurallar, ekranlar, testler; kod incelemesi |
| Cuma 16 Ekim | İnceleme bulgularının düzeltilmesi, GitHub, CI, Render yayını |
| Cumartesi 17 Ekim | Canlı ortamda uçtan uca deneme, README ve AGENT.md son hâli |
| Pazar 18 Ekim | Yedek gün, sunum provası |
| Pazartesi 19 Ekim | Sunum |

---

## 9. Riskler

| Risk | Önlem |
| :--- | :--- |
| Render ücretsiz planında ilk açılış ~1 dakika sürer | Sunumdan 5 dakika önce uygulama açılır |
| Ücretsiz PostgreSQL 30 gün sonra silinir | "Yapamadıklarım"da belirtildi |
| Testler göreli tarihler nedeniyle belirli günlerde başarısız olabilir | Test verileri sabit tarihlere çekilecek |
| AGENT.md bölüm 7'deki açık maddeler | Sunum öncesi kapatılacak; kapatılamayanlar "Yapamadıklarım"a yazılacak |
