# AGENT.md — Slotla Gelistirme Surec Gunlugu

> Bu dosya, Slotla projesinin AI kodlama ajanlari ile gelistirilme surecini belgelemektedir.
> Ders geregi hazirlanmistir.

---

## Kullanilan Ajanlar

| Ajan | Rol | Ortam |
|---|---|---|
| **Claude Code** (Claude Opus) | Takim lideri: mimari kararlar, kod yazimi, test yazimi, code review, CI kurulumu | Terminal (CLI) |
| **Antigravity IDE** (Gemini) | Yardimci gelistirici: gorev bazli kod uretimi | VS Code Extension |

---

## Surec Ozeti

### Gun 1 (15 Ekim 2026) — Iskelet ve Cekirdek

**Mimari Kararlar:**
- Rails 8.1 monolith secildi (React degil). Neden: Render'da Node.js derleme hatalari riski, hocanin CoC felsefesine uyum.
- Solid Queue, Puma'nin icinde calisacak (`plugin :solid_queue`). Neden: Render free tier'da ayri worker ucreti yok.
- 4 tablo modeli: User, EventType, AvailabilityRule, Booking. Davetli icin ayri tablo yok — `invitee_email` alani yeterli.
- Durum makinesi gem kullanmadan `TRANSITIONS` hash + `define_method` ile yapildi. Hocanin slayt 21'deki yaklasiminin aynisi.

**Uretilen Dosyalar:**
- `app/models/booking.rb` — TRANSITIONS hash, 7 durum, `InvalidTransition` exception, partial unique index icin scope'lar
- `app/models/scheduling_rules.rb` — 3 kural tek sinifta: 2-saat onceden rezervasyon, onay suresi hesaplama, no-show tespit
- `app/models/slot_finder.rb` — Musait saat hesaplama, `active_or_unexpired_pending` scope'u kullanarak Render uyurken bile dogru sonuc
- `app/models/bookings/create.rb` — Service object, `Data.define` ile Result tipi, callback'siz is mantigi
- `app/jobs/expire_pending_bookings_job.rb` — Her dakika calisir, suresi gecmis pending booking'leri expire eder

**Testler (travel_to ile):**
- `test/models/booking_test.rb` — 7 gecerli gecis, 4 yasak gecis, cift rezervasyon unique index testi
- `test/models/scheduling_rules_test.rb` — 3 zaman kurali, 100 puanlik no-show kurali, `Bookings::Create` entegrasyon testi
- `test/models/slot_finder_test.rb` — Slot hesaplama, dolu slot cikarma, expired pending slot geri acilmasi
- `test/models/bookings/create_test.rb` — Onay/aninda olusturma, 2-saat reddi, sure hesaplama, force_approval
- `test/jobs/expire_pending_bookings_job_test.rb` — Suresi dolan ve dolmayanlar, confirmed'a dokunmama

**CI:**
- `.github/workflows/ci.yml` — PostgreSQL 16 servisi, `bin/rails test`, `rubocop --parallel`, `brakeman`

### Gun 2 (16 Ekim 2026) — Ekranlar ve Deploy

**Davetli Ekranlari:**
- `public_bookings#new` — 14 gunluk takvim, slot grid, Stimulus `slot-select` controller ile form acilmasi
- `public_bookings#show` — Token bazli durum sayfasi, iptal butonu
- `public_bookings#create` — `Bookings::Create` servisi uzerinden rezervasyon

**Ev Sahibi Paneli:**
- Dashboard: 3 sekmeli (Onay Bekleyen + geri sayim sayaci, Yaklasan, Gecmis + no-show butonu)
- EventType CRUD
- AvailabilityRule toplu olusturma/guncelleme (transaction icinde)
- `repeat_no_show?` badge'i Onay Bekleyen ve Gecmis sekmelerinde gorunur

**Stimulus Controller'lar:**
- `countdown_controller.js` — Onay suresi icin gercek zamanli geri sayim
- `slot_select_controller.js` — Slot secimi ve form gosterimi
- `tabs_controller.js` — Dashboard sekme yonetimi
- `toggle_controller.js` — Mobil menu
- `flash_controller.js` — Bildirim otomatik kapatma

**Deploy:**
- `render.yaml` — Web service + PostgreSQL (her ikisi de free tier)
- `Dockerfile` — `libpq-dev` ile PostgreSQL destegi

### Gun 3 (17 Ekim 2026) — Dokumantasyon ve Demo Verisi

- `db/seeds.rb` — Demo host "volkan", 2 event type, Pzt-Cum musaitlik, 5 ornek booking (no-show demosu dahil)
- `README.md` — Fortune 500 kaynakli veriler, 100 puanlik aci kaniti, kullanim kilavuzu, CI rozeti, Known Limitations
- `AGENT.md` — Bu dosya

---

## Mimari Kararlar ve Gerekceleri

### Neden Service Object (Bookings::Create)?

Rails callback'leri (`before_save`, `after_create`) is mantigini modele gomdugununde test ve debug zorlasir. Hocanin "yasak sihirler" uyarisiyla uyumlu olarak is mantigi acik bir service object'e tasindi.

### Neden Gem Yok (aasm, state_machines)?

Hocanin slayt 21'deki yaklasimi: `define_method` ile durum gecisleri, gecis tablosu acikca gorunur. Gem kullansaydik "gizli sihir" uyarisi alinirdi.

### Neden Render Uyku Stratejisi?

Render free tier'da 15 dakika trafik gelmezse uygulama uyuyor. Solid Queue da duruyor. Iki katmanli cozum:
1. **Okuma-aninda dogru sonuc:** `active_or_unexpired_pending` scope'u suresi gecmis pending'leri zaten hesaba katmiyor.
2. **Arka plan kalicilastirma:** `ExpirePendingBookingsJob` her dakika calisir + dashboard acildiginda bir kez calisir.

### Neden `Data.define` Result Tipi?

Ruby 3.2+ ile gelen `Data.define`, immutable value object uretiyor. `Struct`'tan farkli olarak degistirilemez, bu da fonksiyonel programlama yaklasimina uygun.

---

## Ajanin Ogrenemeyecegi, Insanin Bildigi Seyler

1. **Calendly Community arastirmasi insan tarafindan yapildi.** Aci tespiti, thread'lerin okunmasi ve "gercekten yok mu?" dogrulamasi ogrencinin isidir.
2. **Sunum senaryosu insan tarafindan planlanandi.** 5 dakikaya ne sigdirilacagi, hangi sirada gosterilecegi, hocanin olasi sorularina hazirlik.
3. **"Yapamadiklarim" bolumu durust yazildi.** Ajan "her seyi yapabilirim" der, insan sinirlamalari bilir.

---

## Ajanla Calismanin Avantaj ve Dezavantajlari

### Avantajlar
- **Hiz:** 4 tablo, durum makinesi, 3 kural, testler ve CI dakikalar icinde uretildi.
- **Tutarlilik:** Ayni isimlendirme kurallari, ayni test stili, ayni dosya yapisi.
- **Refactoring cesaret:** "Bu kodu sil, yeniden yaz" demek kolay.

### Dezavantajlar
- **Baglam kaybi:** Uzun konusmalar sirasinda ajan onceki kararlari unutabiliyor, tekrar anlatmak gerekiyor.
- **Halusinasyon riski:** Ajan var olmayan ozellikleri "var" diye iddia edebiliyor. Calendly'nin Fortune 500 verisi ilk denemede yanlisti, duzeltildi.
- **Render deploy sorunlari:** Ajan yerel ortamda test eder ama Render'daki ortam farklarini (uyku, soguk acilis) bilemez.

---

## Sonuc

AI kodlama ajanlari, bir SaaS urunun cekirdek dilimini hizla kopyalamak icin son derece etkili. Ancak **"kullanici acisi" tespiti**, **sunum stratejisi** ve **durust sinir cizme** (Known Limitations) hala insanin isidir. Bu proje, ajan + insan isbirliginin en verimli noktasini bulmaya calisir.
