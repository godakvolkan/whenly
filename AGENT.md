# AGENT.md

Bu dosya, Whenly projesinde çalışan yapay zekâ kodlama ajanları için ortak çalışma kurallarını ve geliştirme sürecinin kaydını içerir. Ajan, bu projede kod yazmadan önce bu dosyayı okur ve buradaki kurallara uyar.

---

## 1. Proje özeti

Whenly, ev sahibinin randevu taleplerini onaylayıp reddedebildiği bir randevu planlama uygulamasıdır. Ana iş akışı:

1. Ev sahibi haftalık müsaitliğini ve randevu türlerini tanımlar.
2. Davetli, herkese açık bağlantıdan uygun bir saat seçer.
3. Randevu talebi oluşur; randevu türü onay gerektiriyorsa `pending` durumuna geçer.
4. Ev sahibi talebi onaylar veya reddeder. Süresi içinde yanıtlanmayan talep `expired` olur.
5. Görüşme gerçekleşir (`completed`) veya davetli katılmaz (`no_show`).

Teknoloji: Ruby on Rails 8.1.4, PostgreSQL, Hotwire (Turbo, Stimulus), Solid Queue, Render.

---

## 2. Alan sözlüğü (Türkçe – kod)

Kullanıcıyla Türkçe, kodda İngilizce terimler kullanılır. Aşağıdaki eşleşmenin dışına çıkılmaz.

| Türkçe | Kod |
| :--- | :--- |
| Ev sahibi | `User` |
| Randevu türü | `EventType` |
| Müsaitlik kuralı | `AvailabilityRule` |
| Randevu, rezervasyon, talep | `Booking` |
| Davetli | `invitee_name`, `invitee_email` |
| Müsait saat | slot (`SlotFinder#available_slots`) |
| Onay bekliyor | `pending` |
| Onaylandı | `confirmed` |
| Reddedildi | `declined` |
| Süresi doldu | `expired` |
| İptal edildi | `canceled` |
| Tamamlandı | `completed` |
| Katılmadı | `no_show` |
| Onay son tarihi | `approval_deadline_at` |
| Onay penceresi (saat) | `EventType#approval_window_hours` |
| Asgari ön süre | `SchedulingRules::MINIMUM_NOTICE_HOURS` |
| Durum takip bağlantısı | `Booking#token`, `/b/:token` |
| Ana iş akışı (aort dilimi) | core flow |

---

## 3. Kod kuralları

### 3.1 Yasaklar

- `default_scope` kullanılmaz.
- `method_missing` ve global monkey patch kullanılmaz.
- İş kuralı içeren model geri çağrısı (callback) yazılmaz. İş kuralları servis nesnesinde (`app/models/bookings/create.rb`) veya `SchedulingRules` içinde yer alır. Modellerde yalnızca `token` ve `slug` üreten `before_validation` geri çağrıları vardır.
- Harici durum makinesi kütüphanesi (`aasm`, `state_machines`) eklenmez.

### 3.2 Zaman kuralları

- Tüm zaman kuralları `app/models/scheduling_rules.rb` içinde tutulur. Başka bir dosyada zaman hesabı yapılmaz.
- Süre kontrolü iki yerde yapılır: okuma anında (`Booking.active_or_unexpired_pending`) ve arka plan işinde (`ExpirePendingBookingsJob`). Uygulamanın doğruluğu arka plan işinin çalışmasına bağlı olmamalıdır.

### 3.3 Durum geçişleri

- Geçişler `Booking::TRANSITIONS` tablosunda tanımlıdır. Yeni bir geçiş yalnızca bu tabloya eklenir.
- İzin verilmeyen geçiş `Booking::InvalidTransition` hatası üretir.

### 3.4 Testler

- Her zaman kuralı `travel_to` ile test edilir.
- Her yasak geçiş için `assert_raises(Booking::InvalidTransition)` testi yazılır.
- Test verilerinde "bugünden X gün sonra" gibi göreli tarihler yerine sabit tarihler kullanılır. Aksi hâlde testler haftanın gününe göre farklı sonuç verebilir.
- Ajanın "testler geçti" ifadesi kanıt sayılmaz. Kanıt, GitHub Actions çıktısı veya yerelde çalıştırılan `bin/rails test` çıktısıdır. Çalıştırılmamış bir test sonucu README'ye yazılmaz.

### 3.5 Belgeler

- README'ye yalnızca kaynağı açıkça gösterilebilen bilgi yazılır. Her rakamın yanında bağlantı bulunur.
- Uygulamada çalışmayan bir özellik arayüzde veya README'de "var" olarak anlatılmaz; "Yapamadıklarım" bölümüne yazılır.
- Orijinal ürünün adı (Calendly) ve logosu uygulama arayüzünde kullanılmaz.

---

## 4. Rails konvansiyonlarından bilinçli sapmalar

| Sapma | Yer | Gerekçe |
| :--- | :--- | :--- |
| Durum alanı `enum` yerine `string` ve açık geçiş tablosu | `app/models/booking.rb` | Rails `enum`'u geçiş kuralı içermez; izin verilen geçişler tek tabloda görünür olsun diye. |
| Geçiş metotları `define_method` ile üretiliyor | `app/models/booking.rb` | Tekrarı azaltmak için. `confirm!`, `decline!`, `expire!`, `complete!`, `no_show!` dosyada ayrı `def` olarak görünmez; adları `TRANSITIONS` tablosundaki anahtarlardır. `cancel!` ayrı tanımlıdır. |
| Servis nesnesi ve düz Ruby sınıfları `app/models` altında | `app/models/bookings/create.rb`, `scheduling_rules.rb`, `slot_finder.rb` | Ayrı bir `app/services` klasörü açmadan Rails'in otomatik yüklemesinden yararlanmak için. |
| Herkese açık rezervasyon rotası `/:slug/:event_type` | `config/routes.rb` | Kısa paylaşım bağlantısı için. Bu rota iki parçalı tüm yolları yakalar; bu nedenle `config/routes.rb` dosyasının en sonunda tanımlanmalı ve `panel`, `session`, `passwords`, `b`, `up` kullanıcı `slug` değeri olarak kullanılmamalıdır. |
| Tek veritabanı | `config/database.yml` | Render ücretsiz planı tek PostgreSQL veritabanı sunar. |

---

## 5. Kullanılan ajanlar

| Ajan | Kullanım alanı |
| :--- | :--- |
| Claude Code (Claude Opus) | Mimari, model, servis, test ve CI kodunun üretimi |
| Antigravity (Gemini) | Görev listelerine (`tasks/`) göre kod üretimi |
| Claude (sohbet oturumu) | Ödev analizi, SaaS seçimi araştırması, kaynak doğrulama, kod inceleme |

Ajanlara verilen görev tanımları `tasks/` klasöründedir.

---

## 6. Geliştirme kaydı

### 14 Ekim 2026

- Ödev metni, ders slaytları ve ders kaydı incelendi.
- Faz 1 verileri (Fortune 500 genel tablosu) kaynaklarıyla toplandı.
- Aday SaaS ürünleri karşılaştırıldı: Zendesk, PagerDuty, Docebo, Envoy, Sentry, Procore, Samsara, SAP Concur, Ironclad, Jira Service Management. Calendly; Fortune 500 kanıtı, doğal zaman kuralı ve durum akışı, Calendly ekibinin kendi yanıtlarıyla belgelenen kullanıcı problemi nedeniyle seçildi.
- Satır sayısı tahmini için Cal.com kodu `cloc` ile sayıldı.
- Rails projesi ve veritabanı geçişleri oluşturuldu.

### 15 Ekim 2026

- Modeller, durum geçişleri, zaman kuralları, müsait saat hesaplama, rezervasyon servisi, arka plan işi, davetli ve ev sahibi ekranları ve testler yazıldı. İlk commit: `d8bece9`.
- Kod incelemesi yapıldı (bkz. bölüm 7).
- `Gemfile.lock` dosyasına `x86_64-linux` platformu eklendi.
- `render.yaml` derleme komutuna `assets:precompile` eklendi.
- Ürün adı Slotla'dan Whenly'ye değiştirildi; logo ve uygulama ikonu yenilendi. Ruby modül adı `Whenly` oldu. Yerel veritabanı adları (`slotwise_dev`, `slotwise_test`) mevcut kurulumu bozmamak için değiştirilmedi.

### 18 Ekim 2026

- ActionMailer e-posta bildirim sistemi entegre edildi (`BookingMailer` 5 şablonla eklendi: `pending_approval`, `new_booking_request`, `booking_confirmed`, `booking_declined`, `booking_expired`).
- Gerçek Gmail SMTP yapılandırıldı ve test maillerinin teslimatı doğrulandı.
- Silinmiş veya geçersiz randevu linkleri için `rescue_from ActiveRecord::RecordNotFound` ve `not_found.html.erb` eklendi.
- `SlotFinder` dolu saatleri gizlemek yerine takvimde üzeri çizili ve kırmızı `DOLU` rozetiyle gösterecek şekilde güncellendi.
- Panel sekmeleri (`tabs_controller.js`) eylem ve veri uyuşmazlığı giderilerek akıcı hale getirildi.
- Kronik no-show kuralının canlı sunumu için `db/seeds.rb` içine `bayulgen5546@gmail.com` adına 2 adet geçmiş randevu eklendi ve panelden "Gelmedi (No-Show)" işaretleme desteği sağlandı.
- SLA zaman aşımının canlı sunumu için Onay Bekleyenler kartına "Süreyi Doldur (Simüle Et)" butonu eklendi.
- Canlı dağıtım hedefi Railway olarak belirlendi; Dockerfile ve entrypoint derleme adımları hazırlandı.
- Tüm testler çalıştırıldı ve doğrulandı: 52 runs, 158 assertions, 0 failures, 0 errors.

### Sonraki adımlar

- GitHub'a gönderme ve CI sonucunun (yeşil rozet) doğrulanması
- Railway'e yayın ve canlı ortamda uçtan uca deneme
- README'deki CI rozeti ve canlı URL bağlantılarının güncellenmesi

---

## 7. Doğrulama kaydı

Ajanların ürettiği ve doğrulama sırasında hatalı bulunan bilgiler ile kod sorunları:

| # | Bulgu | Durum |
| :--- | :--- | :--- |
| 1 | Lyft, Dropbox, Atlassian, DocuSign, Twilio ve Box, Fortune 500 müşterisi olarak sunuldu. Hiçbiri 2026 Fortune 500 listesinde değil; Twilio ve Box için Calendly müşterisi olduklarına dair kanıt da bulunamadı. | Düzeltildi. Yalnızca HPE ve US Foods kullanılıyor. |
| 2 | Bir forum başlığının bağlantı numarası (5906) görüntülenme sayısı olarak yazıldı. Gerçek değer 162. | Düzeltildi |
| 3 | "Reddit ve G2'de 'Calendar hijacking by spam leads' şikâyetleri" alıntısı hiçbir kaynakta bulunamadı. | Kaldırıldı |
| 4 | Toplantı öncesi yapay zekâ özeti yenilik olarak önerildi. Calendly bu özelliği 19.08.2026'da duyurmuş. | Kaldırıldı |
| 5 | "Geleneksel geliştirme maliyeti 4,5 milyon $" ifadesinin kaynağı yok. | Kaldırıldı |
| 6 | README'de "37 test, 122 assertion, 0 failure" yazıyordu. O tarihte kodda 45 test tanımı vardı ve testler çalıştırılmamıştı. | Kaldırıldı. Yerine yerel çalıştırma çıktısı (51 test) eklendi; nihai kanıt CI çıktısıdır. |
| 7 | AGENT.md'de henüz yapılmamış işler (16–17 Ekim, yayın) tamamlanmış olarak yazılmıştı. | Düzeltildi |
| 8 | `Gemfile.lock` yalnızca Windows platformunu içeriyordu; Linux'ta (CI, Render) kurulum başarısız olurdu. | Düzeltildi |
| 9 | `render.yaml` CSS/JS derleme adımını içermiyordu. | Düzeltildi |
| 10 | `/:slug/:event_type` rotası panel rotalarından önce tanımlıydı. `GET/POST /panel/event_types` ve `GET/POST /panel/availability_rules` davetli sayfasına yönleniyor ve 404 veriyordu. | Düzeltildi (`config/routes.rb` içinde `namespace :panel` rotaları wildcard'ın üzerine taşındı). |
| 11 | Rezervasyon formunda "onay ve detay linki bu e-postaya gönderilecektir" yazıyordu; uygulama e-posta göndermiyor. | Düzeltildi (Metin "takip ve durum ekranınız anında açılacaktır" olarak düzeltildi). |
| 12 | Onay süresi geçmiş ama henüz `expired` olmamış bir talep, aynı saate yeni rezervasyon yapılmak istendiğinde veritabanı kısıtı nedeniyle hata (500) üretiyordu. | Düzeltildi (`Bookings::Create` içinde talep oluşturulmadan önce süresi geçenler otomatik expire ediliyor ve `RecordNotUnique` yakalanıyor). |
| 13 | Onay süresi geçmiş bir talep, randevu detay sayfasından onaylanabiliyordu. | Düzeltildi (`Booking#confirm!` metodunda onay süresi geçmişse `expire!` edilip `InvalidTransition` fırlatılıyor). |
| 14 | Davetli e-postası küçük harfe çevrilmiyordu; katılımsızlık kuralı büyük harfle yazılan e-postayla aşılabiliyordu. | Düzeltildi (`Booking#normalize_email` ve `SchedulingRules.repeat_no_show?` içinde `LOWER(invitee_email)` uygulandı). |
| 15 | Test verileri göreli tarihlerle üretiliyordu; testler Cuma ve Cumartesi günleri çakışma nedeniyle başarısız olabilirdi. | Düzeltildi (Fixtures sabit ileri tarihlere çekildi; testler `travel_to` ile donduruldu). |
| 16 | Solid Queue'nun yayın ortamı yapılandırması tamamlanmamıştı. `db/queue_schema.rb`, `config/queue.yml` ve `production.rb` ayarı eklendi. `production.rb` içindeki `writing: :queue` tanımı Render'ın tek veritabanı kısıtına uygun olarak kaldırılarak ana veritabanı bağlantısı sağlandı. | Düzeltildi |
| 17 | `config/cable.yml` yayın ortamında Redis kullanıyordu; projede Redis yok. | Düzeltildi (`adapter: solid_cable` olarak güncellendi). |
| 18 | `app/assets/stylesheets/app.css` yalnızca `@import "application.css"` içeriyordu; Propshaft yayın ortamında bu içe aktarmayı çözümlemeyebilirdi. | Düzeltildi (Layout şablonlarında doğrudan `stylesheet_link_tag "application"` bağlandı). |
