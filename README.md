<p align="center"><img src="app/assets/images/whenly-logo.svg" alt="Whenly" width="320"></p>

# Whenly

Whenly, ev sahibinin gelen randevu taleplerini onaylayıp reddedebildiği, süresi içinde yanıtlanmayan talepleri otomatik olarak düşüren ve tekrar eden katılımsızlıklara kural uygulayan bir randevu planlama uygulamasıdır. Ruby on Rails 8.1 ile geliştirilmiştir.

İlham kaynağı Calendly'dir. Calendly adı ve logosu uygulama arayüzünde kullanılmaz; yalnızca bu belgede ilham kaynağı olarak anılır.

[![CI](https://github.com/godakvolkan/whenly/actions/workflows/ci.yml/badge.svg)](https://github.com/godakvolkan/whenly/actions/workflows/ci.yml)

**Canlı uygulama:** https://whenly-cpyy.onrender.com

**Kaynak kod:** https://github.com/godakvolkan/whenly

---

## İçindekiler

1. [Faz 1: Fortune 500 Genel Tablosu](#faz-1-fortune-500-genel-tablosu)
2. [SaaS Seçimi ve Fortune 500 Kanıtı](#saas-seçimi-ve-fortune-500-kanıtı)
3. [Faz 2: Maliyet Tahmini](#faz-2-maliyet-tahmini)
4. [Kullanıcı Problemi ve Çözüm](#kullanıcı-problemi-ve-çözüm)
5. [Uygulama Mimarisi](#uygulama-mimarisi)
6. [Testler](#testler)
7. [Yapamadıklarım](#yapamadıklarım)
8. [Kurulum ve Çalıştırma](#kurulum-ve-çalıştırma)

---

## Faz 1: Fortune 500 Genel Tablosu

Fortune 500, ABD merkezli şirketleri yıllık toplam gelire göre sıralar. 2026 listesine giriş eşiği 7,5 milyar dolar gelirdir ([Fortune, 03.06.2026](https://fortunemedia.mediaroom.com/2026-06-03-Amazon-Claims-No-1-Spot-on-the-Fortune-500)). Piyasa değeri bir giriş kriteri olmadığından şirketler arasındaki değerleme farkı çok büyüktür.

| Gösterge | Yaklaşık değer | Kaynak |
| :--- | :--- | :--- |
| Değerleme aralığı | 2 milyar $ – 4,2 trilyon $. En yüksek: Nvidia (4,24 trilyon $). Düşük uca örnek: Kohl's (~2,14 milyar $, Ekim 2026). Karşılıklı (mutual) sigorta şirketleri (State Farm, New York Life) ve borsadan çıkmış QVC Group'un piyasa değeri yoktur. Listenin toplam piyasa değeri 55 trilyon $'dır. | [Fortune](https://fortunemedia.mediaroom.com/2026-06-03-Amazon-Claims-No-1-Spot-on-the-Fortune-500), [Someka](https://www.someka.net/blog/2026-fortune-500-list-insights/), [CompaniesMarketCap](https://companiesmarketcap.com/kohls/marketcap/), [DemandSage](https://www.demandsage.com/fortune-500-companies/), [Vista Today](https://vista.today/2026/06/qvc-group-fortune-500-2026/) |
| Çalışan sayısı aralığı | ~600 – ~2,1 milyon. En az: BitGo Holdings (603). En çok: Walmart (~2,1 milyon). Listenin toplam çalışan sayısı 30,5 milyondur. | [Fortune](https://fortune.com/2026/06/19/fortune-500-employment-profits-revenue-hiring-jobs-ai/), [US500](https://us500.com/fortune-500-companies) |
| Şirket başına SaaS ürünü | ~650 uygulama (10.000+ çalışanlı şirketler; tüm şirketlerin ortalaması 305) | [Zylo](https://zylo.com/blog/trends-saas-spend-best-practices-saas-management), [Zylo 2026 SaaS Management Index](https://www.zylo.com/blog/saas-statistics/) |
| Yıllık SaaS harcaması | 123,5 – 375,5 milyon $ (10.000+ çalışanlı şirketler; tüm şirketlerin ortalaması 55,7 milyon $; çalışan başına medyan 9.455 $) | [Zylo 2026 SaaS Management Index](https://www.zylo.com/blog/saas-statistics/), [Zylo basın bülteni](https://zylo.com/news/2026-saas-management-index) |

**Yöntem notu:** SaaS ürünü sayısı ve harcaması için Fortune 500'e özel kamuya açık bir veri bulunmamaktadır. Fortune 500 şirketlerinin büyük çoğunluğu 10.000'den fazla çalışana sahip olduğundan Zylo'nun "10.000+ çalışan" kategorisi bu grubu temsil eden yaklaşık değer olarak kullanılmıştır.

---

## SaaS Seçimi ve Fortune 500 Kanıtı

**Seçilen ürün:** Calendly (toplantı ve randevu planlama platformu)

- Calendly, Eylül 2023'te Fortune 500 şirketlerinin %86'sının ve en büyük 15 Fortune 500 finans şirketinden 14'ünün Calendly kullandığını açıklamıştır ([Calendly basın bülteni, Eylül 2023](https://calendly.com/newsroom/press-release/calendly-achieves-61-yoy-increase-in-enterprise-growth)).
- Calendly'nin kurumsal sayfasında bu oran *"over 4 out of 5 Fortune 500 companies"* olarak verilmektedir ([calendly.com/for-enterprise](https://calendly.com/for-enterprise), erişim: 15.10.2026; sayfada tarih bulunmamaktadır).
- Aynı basın bülteninde müşteri olarak adı geçen ve 2026 Fortune 500 listesinde yer alan şirketler:
  - **Hewlett Packard Enterprise** ([Fortune şirket sayfası](https://fortune.com/company/hewlett-packard-enterprise/fortune500/))
  - **US Foods** ([Fortune şirket sayfası](https://fortune.com/company/us-foods-holding/fortune500/))
- Calendly'nin kurumsal (Enterprise) planı yıllık 15.000 $'dan başlamakta ve en az 50 kullanıcı lisansı gerektirmektedir ([calendly.com/pricing](https://calendly.com/pricing)).

**Klonlanan ana iş akışı (aort dilimi):** Ev sahibi haftalık müsaitliğini tanımlar → davetli uygun bir saat seçer → randevu talebi oluşur → ev sahibi talebi onaylar veya reddeder → görüşme gerçekleşir ya da davetli katılmaz.

---

## Faz 2: Maliyet Tahmini

### Satır sayısı tahmini

Calendly kapalı kaynaklı bir üründür ve kod büyüklüğü açıklanmamıştır. Aynı işlevi sunan açık kaynaklı **Cal.com** projesinin kodu `cloc` aracıyla sayılmıştır (14.10.2026, commit `54343aa`; `node_modules`, `public`, `dist` ve `locales` klasörleri hariç):

| Kapsam | Satır sayısı |
| :--- | ---: |
| Toplam kod | ~472.500 |
| Test dosyaları | ~148.100 |
| Testler hariç kod | ~324.400 |

**Tahmin:** Calendly ölçeğinde bir randevu planlama ürünü yaklaşık 300.000 satır koddan oluşur.

### Çekirdeği yapay zekâ kodlama ajanıyla üretmenin maliyeti

Varsayımlar:

- Satır başına ortalama 10 token (ders slaytı 28). 300.000 satır için yaklaşık 3 milyon çıktı token'ı gerekir.
- Kodlama ajanı, yazdığı koddan yaklaşık 30 kat fazla içerik okur (kaynak dosyalar, test çıktıları, hata kayıtları). Bu da yaklaşık 90 milyon girdi token'ı eder.
- Hata düzeltme ve yeniden yazma turları için 3 kat çarpan uygulanmıştır.
- Fiyat: Claude Opus 5.5; girdi 4 $/milyon token, çıktı 20 $/milyon token ([Anthropic fiyat sayfası](https://platform.claude.com/docs/en/about-claude/pricing), erişim: 17.10.2026).

| Kalem | Hesap | Tutar |
| :--- | :--- | ---: |
| Çıktı | 3 milyon × 20 $ | 60 $ |
| Girdi | 90 milyon × 4 $ | 360 $ |
| Tek tur | | 420 $ |
| Düzeltme turları dahil (×3) | | ~1.260 $ |

Sonuç varsayımlara duyarlıdır; makul aralık 500 – 3.000 $'dır.

**Süre:** Asıl darboğaz kod üretimi değil, üretilen kodun doğrulanmasıdır . Tek geliştirici ve bir kodlama ajanıyla ürünün çekirdeği için 2–4 hafta, ana iş akışı için 2–3 gün öngörülmüştür.

### Gerçekleşen değerler

| Kalem | Tahmin | Gerçekleşen |
| :--- | :--- | :--- |
| Ana iş akışı satır sayısı | 3.000 – 6.000 | 3.060 satır (`cloc`, `app` + `config` + `db` + `test`, 15.10.2026) |
| Maliyet | 500 – 3.000 $ | ~$2.50 token/API harcaması (öğrenci API kredisi), ek ücret yok, Render Free Hosting ($0) |
| Süre | 2 – 3 gün | 2 gün (14 Ekim araştırma/mimari, 15 Ekim geliştirme ve test) |

---

## Kullanıcı Problemi ve Çözüm

### Özet

Calendly'de her rezervasyon, ev sahibinin onayı alınmadan doğrudan takvime işlenir. Calendly ekibi bu özelliğin bulunmadığını 2023'ten Temmuz 2026'ya kadar beş ayrı forum başlığında teyit etmiştir. Whenly'de randevu talepleri "onay bekliyor" durumunda oluşur. Ev sahibi süresi içinde onaylamazsa talep otomatik olarak düşer ve ilgili saat yeniden açılır. İki kez katılmayan bir davetlinin sonraki talebi, randevu türü anında onaylı olsa bile ev sahibinin onayına düşer.

### Kaynaklar: Calendly ekibinin yanıtları

| Tarih | Yanıtlayan | Alıntı | Görüntülenme | Kaynak |
| :--- | :--- | :--- | ---: | :--- |
| 29.10.2023 | Kelsi (CalPal Emeritus) | *"Unfortunately, Calendly does not currently support manual confirmations."* (Maalesef Calendly şu anda elle onaylamayı desteklemiyor.) | 5.474 | [Approving before accepting](https://community.calendly.com/how-do-i-40/approving-before-accepting-277) |
| 21.11.2023 | Kelsi (CalPal Emeritus) | Aynı ifade | 3.904 | [Approve bookings](https://community.calendly.com/how-do-i-40/approve-bookings-415) |
| 19.02.2024 | Kelsi (CalPal Emeritus) | Aynı ifade | 1.028 | [Manual confirmations](https://community.calendly.com/how-do-i-40/does-calendly-support-manual-confirmations-reconfirmations-of-bookings-908) |
| 01.12.2025 | David (Community Manager) | *"Right now there is not a way to manually confirm events that are scheduled through Calendly."* (Şu anda Calendly üzerinden planlanan etkinlikleri elle onaylamanın bir yolu yok.) | 145 | [Manual approval for internal use](https://community.calendly.com/api-webhook-help-61/manual-approval-feature-for-internal-company-use-5071) |
| 21.07.2026 | Allie M (Community Manager) | *"Right now, there isn't a native "pending approval" feature in Calendly."* (Şu anda Calendly'de yerel bir "onay bekleme" özelliği bulunmuyor.) | 162 | [Approve bookings](https://community.calendly.com/how-do-i-40/approve-bookings-5906) |

Calendly'nin 2023 ve 2024 yanıtlarında belirttiği gerekçe: *"We've found that manual confirmation increases the steps you have to take to book meetings."* (Elle onaylamanın, toplantı planlamak için atmanız gereken adımları artırdığını tespit ettik.)


Kullanıcı talepleri (21.07.2026 tarihli başlık):

- JeffreyLebowski, 26.07.2026: *"That's EXACTLY what I need - the ability to accept or decline a booking"* (Tam da ihtiyacım olan şey bu — bir randevuyu kabul etme veya reddetme imkânı). Kullanıcı, onay e-postasının davetliye etkinliği ev sahibi karar vermeden takvimine ekleme imkânı verdiğini ve bunun müşteri ilişkisine zarar verebileceğini belirtmektedir.
- Lee73645, 30.07.2026: *"I would desperately like to have this ability as well."* (Bu özelliğe çok ihtiyacım var, ben de istiyorum.)

### İlgili diğer kaynaklar

| Tarih | Konu | Calendly'nin yanıtı | Kaynak |
| :--- | :--- | :--- | :--- |
| 04.03.2024 | Yeniden onay akışı, onaylanmayan randevuyu iptal etmiyor | *"there is no functionality that allows for an event to be automatically cancelled"* (Bir etkinliğin otomatik olarak iptal edilmesini sağlayan bir işlev bulunmuyor.) | [Reconfirm does not cancel](https://community.calendly.com/how-do-i-40/reconfirm-does-not-cancel-appointments-998) |
| 06.03.2024 | Sürekli randevu alıp katılmayan kişiyi engelleme (11 yanıt, 7.907 görüntülenme) | O tarihte engelleme özelliği yoktu. Günümüzde elle engelleme mevcuttur ([yardım sayfası](https://calendly.com/help/how-to-block-someone-from-booking-with-you.html)); tekrar eden katılımsızlığa otomatik uygulanan bir kural yardım sayfalarında yer almamaktadır. | [Block a person](https://community.calendly.com/how-do-i-40/block-a-person-from-scheduling-1009) |
| 25.11.2025 | Özel ders veren bir eğitmen, öğrenci derse gelmediğinde randevu alındığını gösteren bir kaydının olmadığını belirtiyor | — | [Capterra](https://www.capterra.com/p/148036/Calendly/reviews/) |

### Kapsam

Calendly'de bugün e-posta doğrulaması, reCAPTCHA v3, kişiyi elle engelleme, katılmayanı elle işaretleme ve yapay zekâ destekli toplantı hazırlığı (Callie, 19.08.2026) bulunmaktadır ([Abuse prevention](https://calendly.com/help/abuse-prevention), [Mark no-shows](https://calendly.com/help/how-to-mark-no-shows-for-meetings), [Calendly AI duyurusu](https://calendly.com/newsroom/press-release/calendly-new-ai-product-suite)). Bu nedenle Whenly spam engelleme veya yapay zekâ özetleme alanında bir iddiada bulunmaz. Whenly'nin odağı onay kuyruğu ve buna bağlı zaman kurallarıdır.

### Karşılaştırma

| Özellik | Calendly | Whenly |
| :--- | :--- | :--- |
| Ev sahibi onayı (onay bekliyor → onayla / reddet) | ❌ Yok ([21.07.2026](https://community.calendly.com/how-do-i-40/approve-bookings-5906)) | ✅ Var |
| Süresi içinde onaylanmayan talebin düşmesi ve saatin yeniden açılması | ❌ Yok ([04.03.2024](https://community.calendly.com/how-do-i-40/reconfirm-does-not-cancel-appointments-998)) | ✅ Var |
| İki kez katılmayan davetlinin sonraki talebinin onaya düşmesi | ❌ Elle engelleme var; otomatik kural yardım sayfalarında yer almıyor | ✅ Var |
| Aynı davetlinin aynı gün içinde birden fazla randevu almasını engelleme | ❌ Yok ([28.07.2025](https://community.calendly.com/how-do-i-40/how-can-i-prevent-duplicate-bookings-e-g-same-email-booking-multiple-times-in-one-day-in-calendly-4351)) | ✅ Var |

---

## Uygulama Mimarisi

| Katman | Tercih |
| :--- | :--- |
| Çatı | Ruby on Rails 8.1.4 |
| Veritabanı | PostgreSQL |
| Arayüz | Hotwire (Turbo Drive, Stimulus), Propshaft, importmap |
| Kimlik doğrulama | Rails 8 `authentication` üreticisi |
| Arka plan işleri | Solid Queue (`ExpirePendingBookingsJob`, `config/recurring.yml`) |
| Saat dilimi | Uygulama: Europe/Istanbul, veritabanı: UTC |
| Yayın ortamı | Render (web servisi + PostgreSQL, ücretsiz plan) |

### Veri modeli

| Model | Görevi |
| :--- | :--- |
| `User` | Ev sahibi. Herkese açık rezervasyon bağlantısı `slug` alanından oluşur (ör. `/volkan/mentorluk`). |
| `EventType` | Randevu türü: süre, onay gerekip gerekmediği, onay penceresi (saat). |
| `AvailabilityRule` | Haftanın her günü için çalışma saatleri. |
| `Booking` | Randevu talebi: davetli bilgileri, başlangıç ve bitiş zamanı, durum, onay son tarihi, durum takip bağlantısı (`token`). |

Aynı ev sahibine aynı başlangıç saatinde iki aktif randevu oluşması, `bookings` tablosundaki kısmi tekil indeks (`[user_id, starts_at]`, yalnızca `pending` ve `confirmed` durumları için) ile veritabanı düzeyinde engellenir.

### Durum akışı

```
pending ──confirm──▶ confirmed ──complete──▶ completed
   │                     ├──no_show──▶ no_show
   ├──decline──▶ declined└──cancel───▶ canceled
   ├──expire───▶ expired
   └──cancel───▶ canceled
```

Geçişler [`app/models/booking.rb`](app/models/booking.rb) içindeki `TRANSITIONS` tablosunda tanımlıdır. İzin verilmeyen bir geçiş `Booking::InvalidTransition` hatası üretir. Harici bir durum makinesi kütüphanesi kullanılmamıştır.

### Zaman kuralları

Tüm zaman kuralları [`app/models/scheduling_rules.rb`](app/models/scheduling_rules.rb) dosyasında toplanmıştır:

1. **Asgari ön süre:** Randevu, başlangıcından en az 2 saat önce alınmalıdır (`bookable?`).
2. **Onay süresi:** Onay son tarihi, talebin oluşturulmasından itibaren onay penceresi (varsayılan 24 saat) ile toplantıdan 1 saat öncesinin erken olanıdır (`approval_deadline_for`). Bu süre içinde onaylanmayan talep `expired` durumuna geçer.
3. **Katılımsızlık kuralı:** Bir randevu, bitişinden 15 dakika sonra "katılmadı" olarak işaretlenebilir (`can_mark_no_show?`). İki kez katılmayan davetlinin yeni talebi onaya düşer (`force_approval?`).
4. **Mükerrer randevu engeli:** Aynı davetli (e-posta), aynı gün içinde yalnızca bir aktif randevu oluşturabilir (`has_booking_on_day?`).

### Süresi dolan taleplerin işlenmesi

Bulut platformlarının ücretsiz veya başlangıç planlarında uygulama trafik almadığında uyku moduna geçebilir ve bu sürede zamanlanmış arka plan işleri gecikebilir. Bu nedenle süre kontrolü iki noktada yapılır:

1. **Okuma anında:** Müsait saat hesaplanırken (`SlotFinder`) onay süresi geçmiş talepler dolu sayılmaz. Ev sahibi paneli açıldığında da süresi geçmiş talepler `expired` durumuna alınır.
2. **Arka planda:** `ExpirePendingBookingsJob`, `config/recurring.yml` içinde her dakika çalışacak şekilde tanımlıdır.

### İş mantığının konumu

Rezervasyon oluşturma kuralları model geri çağrılarında (callback) değil, [`app/models/bookings/create.rb`](app/models/bookings/create.rb) servis nesnesinde yer alır. Modellerdeki geri çağrılar yalnızca `token` ve `slug` üretimiyle sınırlıdır.

---

## Testler

Testler Minitest ile yazılmıştır. Zaman kuralları ActiveSupport'un `travel_to` yardımcısıyla test edilir. Testler her `push` işleminde GitHub Actions üzerinde PostgreSQL ile çalıştırılır; güncel sonuç sayfanın başındaki CI rozetinde görülür.

**Güncel Doğrulanmış Test Raporu (18.10.2026):**
```text
Run options: --seed 54791

# Running:
....................................................

Finished in 17.406365s, 2.9874 runs/s, 9.0771 assertions/s.
52 runs, 158 assertions, 0 failures, 0 errors, 0 skips
```

| Dosya | Kapsam |
| :--- | :--- |
| `test/models/booking_test.rb` | İzin verilen geçişler, yasak geçişler, aynı saate çift rezervasyon, süresi dolmuş onayın reddi, e-posta normalizasyonu |
| `test/models/scheduling_rules_test.rb` | Dört zaman kuralı, katılımsızlık kuralı (`travel_to`), aynı gün mükerrer randevu engeli (`travel_to`), büyük/küçük harf duyarsız no-show tespiti |
| `test/models/slot_finder_test.rb` | Müsait saat hesaplama, süresi dolan talebin saati serbest bırakması |
| `test/models/bookings/create_test.rb` | Rezervasyon oluşturma servisi, çalışma saatleri kontrolü, çakışma kontrolü, aynı gün mükerrer engel, süresi dolan talebin otomatik düşmesi |
| `test/jobs/expire_pending_bookings_job_test.rb` | Süresi dolan taleplerin işlenmesi |
| `test/controllers/public_bookings_controller_test.rb` | Davetli ekranları, token ile durum takibi, davetli iptali |

Yerel çalıştırma: `bin/rails test`

---

## Yapamadıklarım

1. **Google Takvim (OAuth 2.0) iki yönlü senkronizasyonu yok.** Randevular Whenly veritabanında yönetilir, onay/durum e-postaları ActionMailer (Gmail SMTP) ile iletilir ve durum takibi `/b/:token` ekranından yapılır; doğrudan Google Calendar API senkronizasyonu dahil edilmemiştir.
2. **Herkese açık yeni ev sahibi kaydı ekranı yok.** Uygulama kurumsal demo odaklıdır; ev sahibi hesabı `db/seeds.rb` ile oluşturulan yönetici hesabı (`godakvolkan@gmail.com`) ile çalışır.
3. **Arka plan işinin yayın ortamında çalışması:** Süre kontrolü okuma anında yapıldığından iş akışının doğruluğu arka plan işine bağlı değildir.

---

## Kurulum ve Çalıştırma

**Gereksinimler:** Ruby 3.3, PostgreSQL 14 veya üzeri

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails test
bin/rails server
```

**Demo hesapları ve canlı erişim bağlantıları**

| Alan | Değer |
| :--- | :--- |
| Canlı Uygulama | https://whenly-cpyy.onrender.com |
| Ev sahibi paneli | https://whenly-cpyy.onrender.com/panel (`/session/new`) |
| Yönetici e-postası | `godakvolkan@gmail.com` |
| Şifre | `password123` |
| Davetli rezervasyon sayfası | https://whenly-cpyy.onrender.com/volkan/mentorluk |
| Onay bekleyen davetli (SMTP testi) | `volkangodak@gmail.com` (canlı test için) |
| 2 kez gelmeyen kronik no-show davetlisi | `bayulgen5546@gmail.com` (`seeds.rb` ile geçmişe eklenen 2 onaylı randevusu panelde No-Show işaretlenmeye hazır) |

