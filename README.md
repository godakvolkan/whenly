# SlotWise

[![CI](https://github.com/godakvolkan/slot/actions/workflows/ci.yml/badge.svg)](https://github.com/godakvolkan/slot/actions/workflows/ci.yml)

**Calendly Enterprise'in cekirdek aort dilimini Ruby on Rails 8.1 ile yeniden ureten randevu planlama uygulamasi.**

> Ilham kaynagi: Calendly Enterprise — Fortune 500 sirketlerinin 4/5'inin kullandigi randevu planlama SaaS'i.

**Canli URL:** [https://slotwise.onrender.com](https://slotwise.onrender.com)

---

## Fortune 500 & SaaS Genel Tablosu

| Olcut | Deger | Kaynak |
|---|---|---|
| Fortune 500 degerleme araligi | $7-10 Milyar — $3.5 Trilyon | [Fortune 500 Directory](https://fortune.com/ranking/fortune500/), [CompaniesMarketCap](https://companiesmarketcap.com/) |
| Fortune 500 medyan calisan sayisi | ~28.000 | [Statista](https://www.statista.com/statistics/264423/number-of-employees-at-fortune-500-companies/) |
| Firma basina aktif SaaS aboneligi | 130 – 290 adet | [Zylo SaaS Management Index](https://zylo.com/reports/saas-management-index/) |
| Yillik SaaS harcamasi | $40M – $120M+ | [Gartner IT Spending Forecast](https://www.gartner.com/en/newsroom) |

### Secilen SaaS: Calendly Enterprise

* **Fortune 500 Kaniti:** Calendly Eylul 2023 basin bultenine gore Fortune 500 sirketlerinin **4/5'i** Calendly kullaniyor. Resmi musteriler: **Hewlett Packard Enterprise (HPE)** (Fortune 500 #123), **US Foods** (Fortune 500 #120). ([Kaynak](https://calendly.com/newsroom/press-release/calendly-achieves-61-yoy-increase-in-enterprise-growth))
* **Urun Olcegi:** ~300.000 LOC (Cal.com acik kaynak klonu `cloc` olcumu: ~324.000 LOC)
* **Geleneksel Gelistirme Maliyeti:** 15-20 muhendis, 18-24 ay, ~$4.500.000+
* **AI Ajanla Gelistirme:** 2-3 is gunu, 1 muhendis + 1 AI ajan, ~$2.50 token + Render free hosting

---

## Aort Dilimi: Ne Kopyalandi?

Calendly'nin musterisinin para odedigi cekirdek: **Musaitlik Tanimi + Rezervasyon + Durum Yonetimi**

| Ozellik | Aciklama |
|---|---|
| Musaitlik takvimi | Ev sahibi haftalik calisma saatlerini tanimlar |
| Zaman dilimi secimi | Gun secer, musait saatleri gorur, form doldurur |
| Durum makinesi | `pending → confirmed → completed` + dallanmalar |
| Onay suresi (auto-expire) | Suresinde onaylanmayan randevu otomatik duser, slot geri acilir |
| Ev sahibi paneli | 3 sekmeli yonetim: Onay Bekleyen, Yaklasan, Gecmis |

---

## 100 Puanlik Kullanici Acisi

### Sorun: Calendly'de Ev Sahibi Onayi Yok

Calendly'nin topluluk yoneticisi **Allie M**, 21 Temmuz 2026'da:

> *"Right now, there isn't a native 'pending approval' feature in Calendly."*
> [Kaynak: Calendly Community](https://community.calendly.com/how-do-i-40/approve-bookings-5906)

**Ek Kanitlar:**

| Sorun | Calendly'nin Durumu | Kaynak |
|---|---|---|
| Gelmeyen kisiyi engelleme | "there is no way to directly block" (2024) | [Community thread](https://community.calendly.com/how-do-i-40/block-a-person-from-scheduling-1009) |
| Ayni gun cift rezervasyon | "no setting prevents multiple bookings from same person" (2025) | [Community thread](https://community.calendly.com/how-do-i-40/how-can-i-prevent-duplicate-bookings-e-g-same-email-booking-multiple-times-in-one-day-in-calendly-4351) |
| Sahte randevular | "no way to prevent fake appointments" (2025) | [Community thread](https://community.calendly.com/how-do-i-40/fake-appointments-4539) |

### SlotWise'in Cozumu: 3 Katmanli Koruma

1. **Onay Kuyrugu** — Her randevu `pending` olarak gelir, ev sahibi onayla/reddet yapar.
2. **Otomatik Sure Asimi** — Suresinde onaylanmayan randevu `expired` olur, slot otomatik geri acilir. Render uyuyor olsa bile okuma aninda dogru calisir.
3. **Tekrar Eden Gelmeme (No-Show) Kurali** — 2+ kez gelmeyen davetlinin sonraki randevusu, olay turu aninda onay verse bile, otomatik `pending` olarak gelir ve ev sahibi uyarilir.

**Sunumda tek cumle:** "Calendly'de her rezervasyon onay beklemeden takvime dusuyor. SlotWise'da ev sahibi onaylar veya reddeder; suresi gecinirse slot otomatik acilir; tekrar gelmeyen davetliye kural uygulanir."

---

## Teknoloji Yigini

| Katman | Teknoloji |
|---|---|
| Backend | Ruby 3.3, Rails 8.1, PostgreSQL |
| Frontend | Hotwire (Turbo + Stimulus), Propshaft |
| Arka plan | Solid Queue (Puma icinde, `plugin :solid_queue`) |
| Kimlik dogrulama | Rails 8 `bin/rails g authentication` |
| CI/CD | GitHub Actions (test + rubocop + brakeman) |
| Deploy | Render.com (free tier) |
| Saat dilimi | Uygulama: `Europe/Istanbul`, DB: UTC |

---

## Veri Modeli (4 Tablo)

```
User (ev sahibi)
├── EventType (randevu turleri: 30dk mentorluk, 15dk tanitim...)
├── AvailabilityRule (haftalik calisma saatleri)
└── Booking (randevular + durum makinesi)
```

Davetliler icin ayri tablo yok — `invitee_email` alani ile takip edilir.
Ayni saate cift rezervasyon `[user_id, starts_at]` uzerinde kismi tekil index ile engellenir.

---

## Durum Makinesi (Gem Yok, Acik Kod)

```
pending ──confirm──▶ confirmed ──complete──▶ completed
  │                     │──no_show──▶ no_show
  │──decline──▶ declined
  │                     │──cancel───▶ canceled
  │──expire───▶ expired
  │──cancel───▶ canceled
```

`TRANSITIONS` hash'i + `define_method` ile uretilen metotlar (`confirm!`, `decline!`, `expire!` vb.). Izin verilmeyen gecis `InvalidTransition` hatasi firlatiyor. `cancel!` ozel: hem `pending` hem `confirmed` durumundan calisiyor.

---

## 3 Zaman Kurali (`app/models/scheduling_rules.rb`)

| # | Kural | Uygulama |
|---|---|---|
| 1 | En az 2 saat onceden rezervasyon | `SchedulingRules.bookable?(starts_at)` |
| 2 | Onay suresi = min(olusturma + X saat, toplanti - 1 saat) | `SchedulingRules.approval_deadline_for(booking)` |
| 3 | 2+ no-show → sonraki randevu otomatik pending | `SchedulingRules.force_approval?(user, email, event_type)` |

Tum kurallar `travel_to` ile test edildi — `test/models/scheduling_rules_test.rb`.

---

## Kurulum

```bash
git clone https://github.com/godakvolkan/slot.git
cd slot
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

Demo verisi:
- **Host giris:** demo@slotwise.dev / password123
- **Davetli linki:** http://localhost:3000/volkan/mentorluk

---

## Testler

```bash
bin/rails test
```

Test dosyalari:

| Dosya | Ne Test Ediyor |
|---|---|
| `test/models/booking_test.rb` | 7 gecerli + 4 yasak durum gecisi, cift rezervasyon |
| `test/models/scheduling_rules_test.rb` | 3 zaman kurali (`travel_to` ile), 100 puanlik no-show kurali |
| `test/models/slot_finder_test.rb` | Slot hesaplama, dolu slot cikarma, expired pending slot geri acilmasi |
| `test/models/bookings/create_test.rb` | Servis nesnesi: onay/aninda, 2-saat kurali, force_approval |
| `test/jobs/expire_pending_bookings_job_test.rb` | Suresi dolan randevulari expire etme |
| `test/controllers/public_bookings_controller_test.rb` | Davetli akisi: form, rezervasyon, durum, iptal |

---

## Proje Dosya Yapisi

```
app/models/booking.rb                   # Durum makinesi (TRANSITIONS + define_method)
app/models/scheduling_rules.rb          # 3 zaman kurali
app/models/slot_finder.rb               # Musait saat hesaplama
app/models/bookings/create.rb           # Rezervasyon olusturma servisi
app/jobs/expire_pending_bookings_job.rb  # Her dakika suresi dolanlari expire eder
config/recurring.yml                    # Solid Queue recurring job tanimi
app/views/public_bookings/              # Davetli ekranlari
app/views/panel/                        # Ev sahibi paneli
app/javascript/controllers/             # Stimulus: countdown, slot-select, tabs
.github/workflows/ci.yml               # CI: test + rubocop + brakeman
```

---

## Yapamadiklarim (Known Limitations)

1. **E-posta bildirimi yok.** Render free tier'da e-posta servisi kurulamadi. Davetli randevu durumunu `/b/:token` sayfasindan takip ediyor.
2. **Render soguk acilis ~1 dakika.** Free tier'da 15 dakika trafik gelmezse uygulama uyuyor. Ilk istekte ~60 saniye bekleme yasaniyor.
3. **Render PostgreSQL 30 gun sonra siliniyor.** Free tier sinirlamasi; sunum icin sorun degil.
4. **Takvim entegrasyonu yok.** Google Calendar / Outlook senkronizasyonu yok — sadece dahili slot yonetimi.
5. **Round-robin dagitimi yok.** Calendly'nin ekip bazli dagitim ozelligi kapsam disi.
6. **Coklu saat dilimi destegi yok.** Tum saatler `Europe/Istanbul` uzerinden gosteriliyor.

---

## Lisans

Bu proje Samsun Universitesi Yazilim Muhendisligi dersi icin gelistirilmistir.

**Ogrenci:** Volkan Godak (231118058)
**Ders:** Ruby on Rails / Yazilim Muhendisligi
**Ogretim Uyesi:** Prof. Dr. Nurettin Senyer
