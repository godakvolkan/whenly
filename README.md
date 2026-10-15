# Slotla

> Randevu planlamada ev sahibine onay yetkisi veren, onaylanmayan randevuyu kendiliğinden düşüren ve gelmeyen davetliye otomatik kural uygulayan bir Rails 8 uygulaması.  
> **İlham kaynağı:** Calendly Enterprise. *(Orijinal marka adı ve logosu uygulama arayüzünde kullanılmaz).*

<!-- CI rozeti: GitHub Actions ilk kez yeşil yandıktan sonra eklenecek -->
[![CI](https://github.com/vgodak/slot/actions/workflows/ci.yml/badge.svg)](https://github.com/vgodak/slot/actions/workflows/ci.yml)

---

## Faz 1 — Fortune 500 Genel Tablosu (2026 Listesi)

Fortune 500, ABD şirketlerini yıllık toplam gelire göre sıralar. 2026 listesine girme eşiği **7,5 milyar $** gelirdir ([Fortune basın bülteni, 03.06.2026](https://fortunemedia.mediaroom.com/2026-06-03-Amazon-Claims-No-1-Spot-on-the-Fortune-500)). Değerleme (piyasa değeri) bir giriş kriteri değildir; bu yüzden şirketler arasındaki değerleme aralığı çok geniştir.

| Soru | Yaklaşık Değer | Kaynak |
| :--- | :--- | :--- |
| **a. Değerleme aralığı** | **~2 milyar $ → ~4,2 trilyon $**. En büyük: Nvidia (4,24 trilyon $). Düşük uca örnek: Kohl's (~2,14 milyar $, Ekim 2026). Bazı şirketlerin piyasa değeri hiç yoktur: karşılıklı (mutual) sigortacılar (State Farm, New York Life) ve borsadan çıkmış QVC Group. Listenin toplam piyasa değeri 55 trilyon $. | [Fortune](https://fortunemedia.mediaroom.com/2026-06-03-Amazon-Claims-No-1-Spot-on-the-Fortune-500), [Someka](https://www.someka.net/blog/2026-fortune-500-list-insights/), [CompaniesMarketCap](https://companiesmarketcap.com/kohls/marketcap/), [DemandSage](https://www.demandsage.com/fortune-500-companies/), [QVC Group](https://vista.today/2026/06/qvc-group-fortune-500-2026/) |
| **b. Çalışan sayısı aralığı** | **~600 → ~2,1 milyon**. En az: BitGo Holdings (603). En çok: Walmart (~2,1 milyon). Listenin toplam çalışan sayısı 30,5 milyon kişidir. | [Fortune](https://fortune.com/2026/06/19/fortune-500-employment-profits-revenue-hiring-jobs-ai/), [US500](https://us500.com/fortune-500-companies) |
| **c. Şirket başına SaaS ürünü** | **~650 uygulama** (10.000+ çalışanlı kurumsal şirketler; tüm şirketlerin ortalaması 305). | [Zylo](https://zylo.com/blog/trends-saas-spend-best-practices-saas-management), [Zylo 2026 SaaS Management Index](https://www.zylo.com/blog/saas-statistics/) |
| **d. Yıllık SaaS harcaması** | **~123,5 milyon $ → 375,5 milyon $** (10.000+ çalışanlı şirketler; tüm şirketlerin ortalaması 55,7 milyon $; çalışan başına medyan harcama 9.455 $). | [Zylo 2026 SaaS Management Index](https://www.zylo.com/blog/saas-statistics/), [Zylo basın bülteni](https://zylo.com/news/2026-saas-management-index) |

> **Not:** (c) ve (d) maddeleri için doğrudan Fortune 500'e özel ayrıştırılmış bir kamu verisi bulunmamaktadır. Fortune 500 şirketlerinin ezici çoğunluğu 10.000'den fazla çalışana sahip kurumsal devler olduğundan, Zylo'nun *"10.000+ çalışan"* dilimi vekil (proxy) olarak kullanılmıştır.

---

## SaaS Seçimi ve Fortune 500 Kanıtı

* **İlham Kaynağı:** **Calendly** (Toplantı ve randevu planlama platformu).
* **Piyasa Hakimiyeti:** Calendly, Eylül 2023 resmi duyurusunda Fortune 500 şirketlerinin **%86'sının** ve en büyük 15 Fortune 500 finans şirketinden 14'ünün Calendly kullandığını açıkladı ([Calendly basın bülteni, Eylül 2023](https://calendly.com/newsroom/press-release/calendly-achieves-61-yoy-increase-in-enterprise-growth)). Calendly'nin bugünkü kurumsal sayfası da bu oranı *"over 4 out of 5 Fortune 500 companies"* olarak teyit etmektedir ([calendly.com/for-enterprise](https://calendly.com/for-enterprise), erişim 15.10.2026).
* **Resmi Fortune 500 Müşterileri:**
  1. **Hewlett Packard Enterprise (HPE)** ([Fortune şirket sayfası](https://fortune.com/company/hewlett-packard-enterprise/fortune500/))
  2. **US Foods** ([Fortune şirket sayfası](https://fortune.com/company/us-foods-holding/fortune500/))
* **Fiyatlandırma / Gelir Modeli:** Calendly'nin kurumsal (Enterprise) planı yıllık **15.000 $'dan** başlamakta ve en az 50 kişilik kullanıcı lisansı şartı koşmaktadır ([calendly.com/pricing](https://calendly.com/pricing)).
* **Klonlanan Aort Dilimi:**  
  Ev sahibi haftalık müsaitliğini tanımlar $\rightarrow$ davetli takvimden boş bir saat seçer $\rightarrow$ randevu oluşur $\rightarrow$ ev sahibi onaylar/reddeder $\rightarrow$ toplantı gerçekleşir ya da davetli gelmez (no-show).

---

## Faz 2 — Maliyet Tahmini

### 1. Satır Sayısı Nasıl Tahmin Edildi?
Calendly kapalı kaynak kodlu ticari bir yazılımdır; net kod büyüklüğü kamuya açıklanmamıştır. Aynı işlevselliği sunan açık kaynaklı pazar alternatifi **Cal.com** kaynak kodu `cloc` aracı ile sayılmıştır (14.10.2026, commit `54343aa`, `node_modules`, `public`, `dist`, `locales` hariç):

| Kapsam | Satır Sayısı (LOC) |
| :--- | :--- |
| **Toplam Kod** | ~472.500 |
| **Test Dosyaları** | ~148.100 |
| **Testler Hariç Çekirdek** | ~324.400 |

* **Tahmin:** Kurumsal özellikleriyle birlikte tam ölçekli bir randevu SaaS'ı **~300.000 satır koddur**.

### 2. Ürünün Çekirdeğini Coding Agent ile Üretmenin Maliyeti
Varsayımlar (sonuç girdilere son derece duyarlıdır):
* Satır başına ~10 token (ders slaytı 28) $\rightarrow$ 300 bin satır $\approx$ **3 milyon çıktı token**.
* Ajan yazdığından ~30 kat fazla okur (dosyalar, test çıktıları, terminal logları, şemalar) $\rightarrow$ **~90 milyon girdi token**.
* Hata düzeltme, refactoring ve test turları için **$\times 3$ çarpanı**.
* Fiyatlandırma: Claude Opus 5.5 / Sonnet model tarifesi baz alınarak girdi 4 $ / milyon token, çıktı 20 $ / milyon token:

| Kalem | Hesaplama | Tutar |
| :--- | :--- | :--- |
| **Çıktı Token** | 3 Milyon $\times$ 20 $ | 60 $ |
| **Girdi Token** | 90 Milyon $\times$ 4 $ | 360 $ |
| **Tek Tur Maliyeti** | $60 + $360 | **420 $** |
| **Düzeltme Turlarıyla ($\times 3$)** | $420 \times 3$ | **~1.260 $** *(Beklenen aralık: 500 $ – 3.000 $)* |

* **Süre:** Asıl darboğaz kodu üretmek değil, doğrulamak ve test etmektir (ders slaytı 29). Çekirdek ürün için tek mühendis + ajanla **2–4 hafta**, aort dilimi için **2–3 gün**.

### 3. Gerçekte Harcanan (Ölçülen Değerler)

| Kalem | Tahmin | Gerçekleşen |
| :--- | :--- | :--- |
| **Aort Dilimi Satır Sayısı** | 3.000 – 6.000 satır | **3.294 satır** *(app, config, db, test dizinleri toplamı)* |
| **Para (Maliyet)** | ~10 $ – 25 $ token maliyeti | **~$2.50 token/API harcaması** + Render Free Hosting ($0) |
| **Süre** | 2 – 3 gün | **2 gün** *(Mimari, modeller, arayüz, testler ve doğrulama)* |

---

## 100 Puanlık Kullanıcı Acısı ve Çözümüm (Kullanılabilir Pas)

### Tek Cümlelik Savunma
> **"Calendly'de her rezervasyon ev sahibinin onayı olmadan doğrudan takvime düşüyor; Calendly bunu 2023'ten 21 Temmuz 2026'ya kadar beş ayrı forum konusunda 'desteklemiyoruz' diye yanıtladı. Slotla'da randevu onay bekliyor olarak gelir, süresinde onaylanmazsa kendiliğinden düşer ve o saat yeniden açılır, iki kez gelmeyen davetlinin sonraki randevusu otomatik olarak onaya düşer."**

### Kanıt: Calendly Topluluk Yöneticilerinin ve Personelinin Cevapları

| Tarih | Calendly Personeli | Resmi Alıntı | Görüntülenme | Kaynak Bağlantısı |
| :--- | :--- | :--- | :---: | :--- |
| **29.10.2023** | Kelsi *(CalPal Emeritus)* | *"Unfortunately, Calendly does not currently support manual confirmations."* | 5.474 | [Approving before accepting](https://community.calendly.com/how-do-i-40/approving-before-accepting-277) |
| **21.11.2023** | Kelsi | *"Unfortunately, Calendly does not currently support manual confirmations."* | 3.904 | [Approve bookings](https://community.calendly.com/how-do-i-40/approve-bookings-415) |
| **19.02.2024** | Kelsi | *"Unfortunately, Calendly does not currently support manual confirmations."* | 1.028 | [Manual confirmations](https://community.calendly.com/how-do-i-40/does-calendly-support-manual-confirmations-reconfirmations-of-bookings-908) |
| **01.12.2025** | David *(Community Manager)* | *"Right now there is not a way to manually confirm events that are scheduled through Calendly."* | 145 | [Manual approval for internal use](https://community.calendly.com/api-webhook-help-61/manual-approval-feature-for-internal-company-use-5071) |
| **21.07.2026** | Allie M *(Community Manager)* | *"Right now, there isn't a native 'pending approval' feature in Calendly."* | 162 | [Approve bookings (2026)](https://community.calendly.com/how-do-i-40/approve-bookings-5906) |

* **Calendly'nin Savunma Gerekçesi (2023 ve 2024 cevaplarında):**  
  *"We've found that manual confirmation increases the steps you have to take to book meetings."* (Manuel onayın toplantı adımlarını artırdığını düşündükleri için bilerek eklemediklerini belirtiyorlar).
* **Kullanıcıların İsyanı ve İhtiyacı (21.07.2026 konusundan alıntılar):**  
  * **JeffreyLebowski (26.07.2026):** *"That's EXACTLY what I need - the ability to accept or decline a booking."* (Onay e-postasının, ev sahibi karar vermeden davetlinin etkinliği takvimine eklemesine izin verdiği için müşteri ilişkilerine ve satış görüşmelerine zarar verdiğini yazıyor).  
  * **Lee73645 (30.07.2026):** *"I would desperately like to have this ability as well."*

### Destekleyici Kanıtlar (Tekrarlı ve Sahte Rezervasyonlar)

| Tarih | Sorun / İhtiyaç | Calendly'nin Resmi Cevabı | Kaynak |
| :--- | :--- | :--- | :--- |
| **04.03.2024** | Onay akışı onaylanmayan randevuyu iptal etmiyor | Personel: *"there is no functionality that allows for an event to be automatically cancelled"* | [Reconfirm does not cancel](https://community.calendly.com/how-do-i-40/reconfirm-does-not-cancel-appointments-998) |
| **06.03.2024** | Sürekli rezervasyon yapıp gelmeyen kişiyi engelleme *(7.907 görüntülenme, 11 yanıt)* | O tarihte engelleme yoktu. Bugün elle engelleme var ([yardım sayfası](https://calendly.com/help/how-to-block-someone-from-booking-with-you.html)), ancak **tekrar eden gelmemelere (no-show) uygulanan otomatik bir kural yok**. | [Block a person](https://community.calendly.com/how-do-i-40/block-a-person-from-scheduling-1009) |
| **25.11.2025** | Özel ders veren eğitmen: öğrenci gelmediğinde randevu aldığına dair kanıtı yok | — | [Capterra Kullanıcı İncelemesi](https://www.capterra.com/p/148036/Calendly/reviews/) |

### Calendly'de Zaten Olanlar (İddiamın Sınırı & Dürüstlük)
Calendly'de bugün e-posta doğrulaması, reCAPTCHA v3, kişiyi elle engelleme, gelmeyeni (no-show) elle işaretleme ve yapay zekâ ile toplantı öncesi brifing üretme (Callie, 19.08.2026) bulunmaktadır ([Abuse prevention](https://calendly.com/help/abuse-prevention), [Mark no-shows](https://calendly.com/help/how-to-mark-no-shows-for-meetings), [AI basın bülteni](https://calendly.com/newsroom/press-release/calendly-new-ai-product-suite)).  
**Bu sebeple projemizde genel spam engelleme veya yapay zekâ brifi iddiasında bulunulmamaktadır.** Çözülen acı doğrudan takvim kilitlenmesi ve onay kuyruğudur.

### Slotla vs Calendly Karşılaştırma Matrisi

| Özellik | Calendly | Slotla |
| :--- | :---: | :---: |
| **Ev Sahibi Onayı (`pending` $\rightarrow$ Onayla / Reddet)** | **YOK** *(21.07.2026 itibarıyla)* | **VAR** |
| **Canlı Geri Sayım Sayacı (Onay Penceresi Süresi)** | **YOK** | **VAR** (Stimulus JS) |
| **Süresinde Onaylanmayanın Kendiliğinden Düşmesi & Slotun Açılması** | **YOK** *(04.03.2024)* | **VAR** (Solid Queue + Read-time check) |
| **İki Kez Gelmeyen (No-Show) Davetliye Otomatik Kural** | **YOK** *(Yalnızca elle engelleme var)* | **VAR** *(Randevu anında onaylı türde olsa bile zorunlu onaya düşer)* |
| **Veritabanı Seviyesinde Çift Rezervasyon Engelleme** | Var | **VAR** (PostgreSQL kısmi tekil indeks) |

### Kaynakların Sınırları
1. HPE ve US Foods'un Calendly müşterisi olduğunu gösteren kanıt Eylül 2023 tarihli basın bültenine dayanmaktadır; daha güncel bir şirket bazlı liste kamuya açıklanmamıştır.
2. Forum konularındaki görüntülenme sayıları 15.10.2026 tarihinde doğrudan Calendly Community üzerinden okunmuştur.
3. Reddit ve G2 üzerindeki bireysel forum yorumları yerine en güvenilir birincil kaynak olan Calendly Topluluk Yöneticilerinin kendi yanıtları ve Capterra incelemeleri kullanılmıştır.

---

## Yazılım Mimarisi & Kod Standartları

* **Çatı & Altyapı:** Ruby on Rails 8.1.4, PostgreSQL 16, Hotwire (Turbo Drive + Stimulus JS), Propshaft asset pipeline.
* **Arka Plan İşleri:** Tek process dağıtım için Puma içine gömülü çalışan `solid_queue`.
* **Kütüphane Sihirleri Yerine Saf Ruby Meta-Programlama (Ders Slaytı 21):**  
  `aasm` veya `state_machines` gibi dış gem'ler kullanılmamıştır. [app/models/booking.rb](file:///c:/Users/vgodak/Desktop/ruby/slot/app/models/booking.rb) içinde `TRANSITIONS` hash'i üzerinden `define_method` ile açık, hatasız ve anlaşılır durum metotları üretilmiştir (`confirm!`, `decline!`, `expire!`, `complete!`, `no_show!`, `cancel!`). İzin verilmeyen bir geçiş denendiğinde doğrudan `Booking::InvalidTransition` fırlatılır.
* **3 Zaman Kuralı (Tek Dosyada):**  
  [app/models/scheduling_rules.rb](file:///c:/Users/vgodak/Desktop/ruby/slot/app/models/scheduling_rules.rb) dosyası 3 kuralı tek bir saf Ruby sınıfında toplar:
  1. *En az 2 saat önceden rezervasyon kuralı* (`bookable?`).
  2. *Onay süresi hesaplama* (`approval_deadline_for`: toplantıdan 1 saat öncesi ile onay penceresinin minimumu).
  3. *No-show koruma kuralı* (`force_approval?` ve `can_mark_no_show?`: toplantı bitiminden 15 dk sonra işaretlenebilme, 2 kez gelmeyene zorunlu onay).
* **Test Güvencesi & Zaman Yolculuğu (Time Travel):**  
  Rails'in `travel_to` kütüphanesiyle yazılmış kapsamlı test paketi: **37 test, 122 assertion, 0 failure, 0 error**.

---

## Yapamadıklarım (Known Limitations)

1. **E-posta Bildirimi Gönderimi:** Render ücretsiz planında SMTP portları kapalı olduğu ve harici bir transactional e-posta servisi (SendGrid/Postmark vb.) kredi kartı gerektirdiği için e-posta gönderimi eklenmemiştir. Davetli randevu durumunu ve iptal butonunu doğrudan kendisine verilen `/b/:token` ekranından canlı olarak takip eder.
2. **Render Ücretsiz PostgreSQL Veritabanı Süresi:** Render'ın ücretsiz PostgreSQL veritabanı 30 gün sonra silinmektedir ([Render Free Tier Policy](https://render.com/docs/free)). Sunum ve değerlendirme için yeterlidir ancak kalıcı üretim için harici DB bağlanmalıdır.
3. **Uyku Modu (Cold Start):** Render ücretsiz web servisleri 15 dakika boyunca HTTP trafiği almadığında uyku moduna geçer. Sunumdan önce ilk istek atıldığında uygulamanın uyanması yaklaşık 50-60 saniye sürebilmektedir.

---

## Kurulum ve Çalıştırma

### Gereksinimler
* Ruby 3.3+
* PostgreSQL 14+

### Adımlar
```bash
# Bağımlılıkları yükleyin
bundle install

# Veritabanını hazırlayın ve şemayı yükleyin
bin/rails db:prepare

# Demo verilerini (Host, Randevu Türleri, Örnek Rezervasyonlar) yükleyin
bin/rails db:seed

# Testleri çalıştırın
bin/rails test

# Geliştirme sunucusunu başlatın
bin/rails server
```

### Canlı Demo Hesap Bilgileri
* **Host Paneli:** `http://127.0.0.1:3000` (veya Render canlı URL)
  * E-posta: `demo@slotwise.dev`
  * Şifre: `password123`
* **Davetli Rezervasyon Sayfası:** `http://127.0.0.1:3000/volkan/mentorluk`
* **Davetli Durum Takip Sayfası:** `http://127.0.0.1:3000/b/demo_pending_token`
