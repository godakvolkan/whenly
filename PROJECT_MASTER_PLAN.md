# PROJECT MASTER PLAN: SlotWise

> **Ders:** Ruby on Rails / Yazilim Muhendisligi
> **Ogretim Uyesi:** Prof. Dr. Nurettin Senyer
> **Teslim & Sunum Tarihi:** 19 Ekim 2026 Pazartesi, Ders Saati (Sinifta 5 Dakika Canli Sunum)
> **Odev Turu:** Bireysel Sinav Notu (Grup calismasi yoktur)
> **Hedef Not:** 100+ Tam Puan
> **Proje Adi:** **SlotWise**
> **Teknoloji Yigini:** Ruby on Rails 8.1, Hotwire (Turbo + Stimulus), PostgreSQL, Solid Queue, Render.com, GitHub Actions CI

---

## 1. Odevin Ozeti, Amaci ve Kesin Kurallari

### A. Neden Bu Odev?
* Fortune 500 sirketleri yuzlerce SaaS urunune her yil milyonlarca dolar abonelik ucreti oduyor.
* Gunumuzun yapay zeka kodlama ajanlari (Coding Agents) ile bu SaaS urunlerinin cekirdegini (aort dilimini) kopyalamak cok ucuzladi ve hizlandi.
* **100 Puanlik Soru:** Sadece kopyalamak marifet degil; o urunun kullanicisina **"tam ayagina gelen kullanilabilir pasi"** kim atacak? Yani kullanicinin gercekte cektigi bir aciyi kim cozecek?

### B. Kesin Puanlama Baremi (Sadece 3 Not Vardir: 0, 85, 100+)
*Gidis yoluna, harcanan emege kesinlikle puan verilmez.*

| Not | Kosullar |
| :--- | :--- |
| **0 Puan** *(Biri bile olursa dogrudan 0)* | 1. Canli URL yoksa veya "Hocam kendi bilgisayarimdan gostereyim" denirse. 2. Aort dilimi canlida uctan uca calismiyorsa. 3. Sunumda "var" denip calismayan/patlayan bir ozellik cikarsa. 4. Ajanin uydurdugu, gercekte calistirilmamis sahte bir test raporu varsa. 5. Orijinal marka adi ("Calendly") veya logosu uygulamada gorunuyorsa. |
| **85 Puan** *(Hepsi eksiksiz olmali)* | 1. Fortune 500 kaniti + Faz 1 ve Faz 2 verileri kaynakli olarak README'de yer alacak. 2. Aort dilimi canlida uctan uca calisacak. 3. Testler GitHub Actions'ta kosacak ve yesil olacak (CI rozeti README'de). 4. Zaman kurali ve durum gecisi icin Rails'in `travel_to` zaman yolculugu kutuphanesiyle yazilmis testler bulunacak. 5. `AGENT.md` dosyasi (Ajanla birlikte uretilmis surec gunlugu). 6. README'de durustce yazilmis "Yapamadiklarim" (Known Limitations) bolumu. |
| **100 ve Uzeri Puan** | 85 puanin tamami + Secilen SaaS'in gercek kullanici yorumlarindan (G2, Capterra, Calendly Community) tespit edilen **gercek bir acinin klonda cozulmus olmasi**. Sunumda tek cumleyle savunulabilmeli. |

---

## 2. Faz 1: Fortune 500 & SaaS Genel Tablosu (README Icin Kaynakli)

1. **Degerleme Araligi (Market Cap / Valuation):**
   * *Aralik:* En kucuk Fortune 500 sirketi **~$7 - $10 Milyar Dolar** seviyesindeyken, en buyuk sirketler (Apple, Microsoft, Nvidia) **~$3 - $3.5 Trilyon Dolar** degerindedir.
   * *Kaynak:* [Fortune 500 Official Directory (2025/2026)](https://fortune.com/ranking/fortune500/) & [CompaniesMarketCap](https://companiesmarketcap.com/).
2. **Calisan Sayisi Araligi:**
   * *Aralik:* En az ~1.200 calisandan baslayip, Walmart gibi zirvedeki sirketlerde **~2.1 Milyon calisan** seviyesine ulasir. Fortune 500 medyan calisan sayisi **~28.000** kisidir.
   * *Kaynak:* [Fortune 500 Employment Metrics & Statista](https://www.statista.com/statistics/264423/number-of-employees-at-fortune-500-companies/).
3. **Kullanilan SaaS Urunu Sayisi:**
   * *Aralik:* Bir Fortune 500 firmasi bunyesinde ortalama **130 ile 290 adet aktif SaaS aboneligi** barindirir.
   * *Kaynak:* [Zylo SaaS Management Index Report](https://zylo.com/reports/saas-management-index/) & [BetterCloud State of SaaSOps](https://www.bettercloud.com/).
4. **SaaS Aboneliklerine Yillik Odenen Para:**
   * *Aralik:* Buyuk olcekli bir kurumsal firma SaaS lisanslarina yilda ortalama **$40 Milyon ile $120+ Milyon Dolar** arasinda butce harcamaktadir.
   * *Kaynak:* [Gartner IT Spending Forecast & Zylo Annual SaaS Spend Benchmark](https://www.gartner.com/en/newsroom).

---

## 3. SaaS Secimi & Fortune 500 Kaniti

* **Ilham Kaynagi Olan SaaS:** **Calendly Enterprise**
* **Bizim Urun Adimiz:** **SlotWise** *(Ozgun logo, ozgun renk paleti; Calendly adi UI'da asla gecmez, sadece README'de "ilham kaynagi" olarak anilir).*
* **Fortune 500 Kaniti:**
  * Calendly Eylul 2023 basin bultenine gore: Fortune 500 sirketlerinin **4/5'i** Calendly kullaniyor.
  * *Resmi Musteriler:* **Hewlett Packard Enterprise (HPE)** (Fortune 500 #123), **US Foods** (Fortune 500 #120).
  * *Kaynak:* [Calendly Basin Bulteni, Eylul 2023](https://calendly.com/newsroom/press-release/calendly-achieves-61-yoy-increase-in-enterprise-growth)
* **Urun Olcegi (LOC):** Calendly; takvim motorlari, Round-robin dagitimi, Routing forms, SAML SSO, admin denetim izleri ile toplamda **~300.000 satir kod** buyuklugunde devasa bir SaaS'tir (Cal.com acik kaynak klonunun `cloc` olcumu: ~324.000 LOC).

---

## 4. Faz 2: Kod Olcegi ve Maliyet Tahmini

* **Yaklasik Satir Sayisi Tahmini:**
  * Cekirdek rezervasyon motoru: ~25.000 LOC
  * Takvim ve e-posta entegrasyon protokolleri (CalDAV, Graph API, Google API): ~70.000 LOC
  * Kurumsal yonetim, SSO, RBAC ve denetim loglari: ~85.000 LOC
  * Is akislari (Workflows), form yonlendirme motoru ve webhook'lar: ~60.000 LOC
  * On yuz ve mobil bilesenler: ~60.000 LOC
  * *Toplam:* **~300.000 Satir Kod (LOC)**.
* **Geleneksel Yazilim Gelistirme Maliyeti:**
  * 15-20 kisilik kidemli muhendis ekibi, 18-24 ay gelistirme, toplam maliyet **~$4.500.000+**.
* **AI Coding Ajanlari ile Cekirdek (Aort Dilimi) Uretim Maliyeti:**
  * *Gelistirme Suresi:* 2-3 is gunu (1 muhendis + 1 AI ajan).
  * *Gerceklesen Harcama:* ~$2.50 token maliyeti + Render free hosting ($0).

---

## 5. Genel Yapi: Tek Bir Rails Monoliti

* **Backend:** Ruby on Rails 8.1 + PostgreSQL
* **Frontend:** Hotwire (Turbo). Ayri bir React projesi yok, JS derleme adimi da yok.
* **Arka plan isleri:** Solid Queue, Puma'nin icinde calisiyor (`plugin :solid_queue`). Boylece ayri ve ucretli bir worker gerekmiyor.
* **Ev sahibi girisi:** Rails 8'in kendi `bin/rails g authentication` ureticisi.
* **Saat dilimi:** Uygulama `Europe/Istanbul`, veritabani UTC.

### Neden React Degil?
Render deployment'inda Node.js derleme (webpack/vite) hatalari yasanmaz. Rails'in tek bir process ile 2 dakikada hatasiz yayina girmesini saglar. Hoca Rails felsefesini (Convention over Configuration) aramaktadir.

---

## 6. Veri Modeli: 4 Tablo

| Model | Alanlar | Neden |
| :--- | :--- | :--- |
| **User** (ev sahibi) | ad, e-posta, sifre, slug | Herkese acik link: `/volkan/mentorluk` |
| **EventType** | ad, sure (dk), requires_approval, approval_window_hours | "30 dk mentorluk" gibi randevu turleri |
| **AvailabilityRule** | haftanin gunu, baslangic ve bitis saati | Haftalik calisma saatleri |
| **Booking** | baslangic, bitis, davetli adi/e-postasi, status, approval_deadline_at, token | Aort diliminin kalbi |

Davetliler icin ayri bir tablo yok. "Bu kisi kac kez gelmedi?" sorusu `Booking.where(invitee_email:).no_show.count` ile cevaplaniyor.

Ayni saate iki rezervasyon dusmesini veritabani engelliyor: `[user_id, starts_at]` uzerinde kismi tekil index (yalnizca aktif rezervasyonlar icin).

---

## 7. Durum Makinesi: Gem Yok, Acik Kod

```
pending ---confirm---> confirmed ---complete---> completed
  |                      |---no_show---> no_show
  |---decline---> declined
  |                      |---cancel----> canceled
  |---expire----> expired
  |---cancel----> canceled
```

Gecisler Booking icinde tek bir `TRANSITIONS` tablosunda duruyor. Her gecis acik bir metot (`confirm!`, `expire!` vb.), izin verilmeyen gecis `InvalidTransition` hatasi firlatiyor.

Hocanin slayt 21'deki yaklasiminin aynisi. `aasm` gibi bir gem kullanmiyoruz, cunku hoca "gizli sihir" konusunda uyariyor.

---

## 8. 3 Zaman Kurali: Hepsi Tek Dosyada

Kurallar `app/models/scheduling_rules.rb` adli duz bir Ruby sinifinda toplaniyor:

1. **En az 2 saat onceden rezervasyon.** Daha yakin bir saat alinamiyor.
2. **Onay suresi.** Ev sahibi, rezervasyondan sonraki X saat icinde ya da toplantidan 1 saat oncesine kadar (hangisi once gelirse) onaylamazsa randevu `expired` olur ve o saat yeniden acilir.
3. **Gelmeme kurali.** "Gelmedi" isareti toplanti bittikten 15 dakika sonra aciliyor. 2 kez gelmeyen davetlinin sonraki rezervasyonu, o randevu turu onay istemese bile otomatik olarak `pending` geliyor. **Bu, 100 puanlik "pas".**

**Kod yeri sorusuna hazirlik:** Hoca "onay suresi hafta sonunu saymasin" derse gosterilecek yer tek bir metot: `SchedulingRules.approval_deadline_for`.

---

## 9. 100 Puanlik "Kullanilabilir Pas" (Gercek Kullanici Acisi)

### A. Calendly Community'den Tespit Edilen Gercek Aci

Calendly'nin topluluk yoneticisi **Allie M**, 21 Temmuz 2026'da su cevabi verdi:

> *"Right now, there isn't a native 'pending approval' feature in Calendly."*
> *Kaynak:* [Approve bookings - Calendly Community](https://community.calendly.com/how-do-i-40/approve-bookings-5906)

**Ek kanitlar:**

| Tarih | Sorun | Calendly'nin cevabi | Kaynak |
|---|---|---|---|
| 06.03.2024 | Gelmeyen kisiyi engelleme (11 yanit, 7.907 goruntulenme) | "there is no way to directly block a specific person" | [Block a person](https://community.calendly.com/how-do-i-40/block-a-person-from-scheduling-1009) |
| 10.06.2024 | Davetli basina aylik rezervasyon siniri | "or limit the number of times a specific invitee can book with you." (yok) | [Limit per invitee](https://community.calendly.com/how-do-i-40/limit-number-of-booking-per-invitee-a-month-1658) |
| 28.07.2025 | Ayni e-postayla gunde birden fazla rezervasyon | "there isn't any setting inside of Calendly that prevents multiple bookings from the same person." | [Duplicate bookings](https://community.calendly.com/how-do-i-40/how-can-i-prevent-duplicate-bookings-e-g-same-email-booking-multiple-times-in-one-day-in-calendly-4351) |
| 21.08.2025 | Bir haftada 7 sahte rezervasyon | "there's no way to prevent fake appointments from being set." | [Fake appointments](https://community.calendly.com/how-do-i-40/fake-appointments-4539) |

### B. Sunumda Soylenecek O Tek Cumle

> **"Calendly'de her rezervasyon onay beklemeden takvime dusuyor. Calendly'nin topluluk yoneticisi 21 Temmuz 2026'da bu ozelligin olmadigini yazdi. SlotWise'da randevu onay bekliyor olarak gelir: ev sahibi onaylar ya da reddeder, suresinde onaylanmayan randevu kendiliğinden duser ve slot geri acilir. Tekrar tekrar gelmeyen davetlilere otomatik kurallar uygulanir."**

### C. Calendly'de BUGUN Zaten Olanlar (Hocaya Karsi Savunma)

| Ozellik | Durum | Kaynak |
|---|---|---|
| reCAPTCHA v3 | **Var** (Subat 2025) | [spam thread](https://community.calendly.com/how-do-i-40/drastic-increase-in-spam-bookings-clogging-up-calendar-3493) |
| E-posta dogrulamasi | **Var** (Ekim 2025) | [Abuse prevention](https://calendly.com/help/abuse-prevention) |
| Kisiyi elle engelleme | **Var** (2026) | [How to block](https://calendly.com/help/how-to-block-someone-from-booking-with-you) |
| Gelmeyeni (no-show) isaretleme | **Var**, elle | [Mark no-shows](https://calendly.com/help/how-to-mark-no-shows-for-meetings) |
| AI toplanti ozeti ("Ask Callie") | **Var** (Agustos 2026) | [Calendly AI bulteni](https://calendly.com/newsroom/press-release/calendly-new-ai-product-suite) |
| **Ev sahibi onayi (pending approval)** | **YOK** (21.07.2026) | [Approve bookings](https://community.calendly.com/how-do-i-40/approve-bookings-5906) |
| **Onaylanmayani otomatik iptal / slotu geri acma** | **YOK** | [Reconfirm thread](https://community.calendly.com/how-do-i-40/reconfirm-does-not-cancel-appointments-998) |
| **Davetli basina limit / ayni gun cift rezervasyonu engelleme** | **YOK** | [Duplicate bookings](https://community.calendly.com/how-do-i-40/how-can-i-prevent-duplicate-bookings-e-g-same-email-booking-multiple-times-in-one-day-in-calendly-4351) |
| **Tekrar eden gelmemeye otomatik kural** | **YOK** | [How to block](https://calendly.com/help/how-to-block-someone-from-booking-with-you) |

---

## 10. Render Ucretsiz Plan: Uygulama Uyurken de Dogru Calismasi

Render'in ucretsiz planinda uygulama 15 dakika trafik gelmezse uyuyor. Uyurken arka planda zamanlanmis isler calismiyor. Buna karsi iki katman var:

1. **Okuma aninda dogru sonuc.** Bos saat hesaplanirken, suresi gecmis pending randevular zaten dolu sayilmiyor (`approval_deadline_at > now` kosulu). Is hic calismasa bile o saat musait gorunur.
2. **Arka planda kalicilastirma.** Solid Queue her dakika suresi dolanlari gercekten `expired` yapar. Ev sahibi paneli acildiginda da ayni kontrol bir kez calisir.

---

## 11. Ekranlar

| Ekran | Kim | Ne yapar |
| :--- | :--- | :--- |
| `/:kullanici/:tur` | Davetli | Gun ve saat secer, ad/e-posta girer |
| `/b/:token` | Davetli | Randevu durumunu gorur (onay bekliyor / onaylandi), iptal eder |
| `/panel` | Ev sahibi | Sekmeler: Onay bekleyen (geri sayimla), Yaklasan, Gecmis. Onayla / reddet / gelmedi butonlari |
| `/panel/turler`, `/panel/musaitlik` | Ev sahibi | Randevu turleri ve haftalik saatler |

**E-posta yok.** Render'in ucretsiz planinda e-posta gonderimi icin ek bir servis gerekir. Davetli durumunu `/b/:token` sayfasindan goruyor. Bu README'nin "Yapamadiklarim" bolumune yazilacak.

---

## 12. Dosya Yapisi (Onemli Olanlar)

```
app/models/booking.rb                  # durumlar + gecisler
app/models/scheduling_rules.rb         # 3 zaman kurali, tek yerde
app/models/slot_finder.rb              # bos saat hesaplama
app/models/bookings/create.rb          # rezervasyon olusturma (callback yerine)
app/jobs/expire_pending_bookings_job.rb
config/recurring.yml                   # her dakika calisan is
test/models/booking_test.rb            # gecisler + yasak gecisler
test/models/scheduling_rules_test.rb   # travel_to ile 3 kural
.github/workflows/ci.yml              # test + rubocop + brakeman
```

Is mantigi callback'lerde degil, `Bookings::Create` icinde. Bu da hocanin AGENT.md slaytindaki "yasak sihirler" kuralina uyuyor.

---

## 13. Sunum Senaryosu (5 Dakika - Canli URL Uzerinden)

| Sure | Bolum | Ne Soylenecek & Ne Gosterilecek? |
| :---: | :--- | :--- |
| **0:00 - 0:30** (30 sn) | **Giris & Orijinal SaaS** | "Projemiz SlotWise. Ilham kaynagimiz Fortune 500'un 4/5'inin para odedigi Calendly Enterprise. Musterinin para odedigi aort dilimi olan 'Musaitlik Tanimi, Rezervasyon ve Durum Yonetimi'ni aldik." |
| **0:30 - 2:30** (2 dk) | **Canli Aort Dilimi Demosu** | Canli Render URL'i acilir. Davetli gozuyle `/:kullanici/:tur` linkine gidilir. Saat secilir, form doldurulup randevu alinir. Host paneline gelinir; durum `pending` -> `confirmed` yapilir. |
| **2:30 - 3:30** (1 dk) | **Zaman Kurali & Durum Kodu** | GitHub acilir: `booking.rb` dosyasindaki durum makinesi, `scheduling_rules.rb` ve `travel_to` ile yazilan auto-expire testi gosterilir. |
| **3:30 - 4:30** (1 dk) | **100 Puanlik Kullanici Acisi** | Calendly Community thread'i gosterilir: "there isn't a native pending approval feature." Canlida no-show kurali gosterilir: 2. kez gelmeyen davetlinin sonraki rezervasyonu otomatik `pending` olarak gelir. |
| **4:30 - 5:00** (30 sn) | **Kod Yeri Sorusu** | Hoca: "Onay suresi hafta sonunu saymasin, nereye yazarsin?" Cevap: "Hocam `app/models/scheduling_rules.rb` icindeki `SchedulingRules.approval_deadline_for` metoduna `ActiveSupport`'un `on_weekend?` kontrolunu ekleriz." |

---

## 14. Zaman Plani (Sunum 19 Ekim Pazartesi)

| Gun | Is |
| :--- | :--- |
| Per 15 | Iskelet, modeller, durum makinesi, 3 kural ve testleri, CI'in yesil yanmasi |
| Cum 16 | Davetli ve ev sahibi ekranlari, deploy |
| Cmt 17 | Gelmeme kurali (pas), README, AGENT.md, demo verisi |
| Paz 18 | Tampon gun, canlida bastan sona prova |

---

## 15. Risk ve Uyarilar

* **Soguk acilis yaklasik 1 dakika suruyor.** Sunumdan 5 dakika once linki acip uygulamayi uyandirmak gerekecek.
* **Render'in ucretsiz Postgres veritabani 30 gun sonra siliniyor.** Sunum icin sorun degil, ama "Yapamadiklarim" bolumune yazilmali.
* **E-posta bildirimi yok.** Davetli durumunu `/b/:token` sayfasindan takip ediyor.

---

## 16. Teslim Edilecekler

* **GitHub Repo Icerigi:**
  * `README.md` (Faz 1, Faz 2, Calendly Community kaynakli aci kaniti, Kullanim Kilavuzu, CI Rozeti, **Yapamadiklarim**)
  * `AGENT.md` (Ajanla birlikte uretilmis surec gunlugu)
  * `.github/workflows/ci.yml` (Yesil rozet saglayan test otomasyonu)
* **Canli URL:** Render.com uzerinde deploy edilmis uygulama.
