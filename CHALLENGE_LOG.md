# CHALLENGE_LOG — Hafta 2

**Proje:** Whenly (Calendly Enterprise Clone)
**Ogrenci:** Volkan Godak — 231118058
**Canli URL:** https://whenly-cpyy.onrender.com
**Repo:** https://github.com/godakvolkan/whenly
**Coding Agent:** Claude Code (Anthropic CLI)

---

## Bu Hafta Eklenen Ozellikler

### 1. REST API (Bearer Token Auth)
- **Ne:** `/api/v1/bookings` ve `/api/v1/event_types` endpoint'leri
- **Neden:** Dis sistemlerle entegrasyon icin standart bir API katmani gerekiyordu
- **Karar:** Gem kullanmadan pure Rails controller ile yaptim — proje olcegi icin yeterli, Doorkeeper/JWT gibi gem'ler gereksiz karmasiklik eklerdi
- **Dosyalar:** `app/controllers/api/v1/base_controller.rb`, `bookings_controller.rb`, `event_types_controller.rb`
- **Kanit:** `curl -H "Authorization: Bearer TOKEN" https://whenly-cpyy.onrender.com/api/v1/bookings` (401 donerse token gecersiz, dogru token ile JSON doner)

### 2. Istatistik Dashboard (Chart.js)
- **Ne:** 5 farkli grafik: haftalik randevu, durum dagilimi, gunluk trend, en yogun gun, en yogun saat
- **Neden:** Ev sahiplerinin randevu performansini gorsel olarak takip etmesi
- **Karar:** Chart.js 4.4.4 sectim — lightweight, CDN'den yuklenebilir, importmap ile uyumlu. D3.js cok agir olurdu bu is icin
- **Dosyalar:** `app/javascript/controllers/charts_controller.js`, `app/controllers/panel/dashboard_controller.rb`
- **Kanit:** Panel > Randevular sekmesinde "Istatistikler" tab'ina tiklandiginda grafikler gorulur

### 3. Gercek Zamanli WebSocket (ActionCable)
- **Ne:** Yeni randevu geldiginde dashboard otomatik guncellenme
- **Neden:** Sayfayi yenilemeden canli bildirim almak — enterprise sistemlerde standart beklenti
- **Karar:** ActionCable + Turbo Streams — Rails'in yerlesik cozumu, ekstra gem gerektirmiyor
- **Dosyalar:** `app/channels/bookings_channel.rb`, `app/javascript/channels/index.js`, `app/models/booking.rb` (broadcast_update)
- **Kanit:** Iki farkli tarayici sekmesinde paneli ac, birinden randevu olustur, digerinde otomatik guncellenir

### 4. .ics Takvim Dosyasi Indirme
- **Ne:** Onaylanan randevular icin .ics dosyasi olusturma ve indirme
- **Neden:** Kullanicilar randevuyu Google Calendar / Outlook'a tek tikla ekleyebilmeli
- **Karar:** Gem yerine kendi `IcsGenerator` servisimi yazdim — ics formati basit, gem bagimliligina gerek yok
- **Dosyalar:** `app/services/ics_generator.rb`, `config/routes.rb` (booking_ics_path)
- **Kanit:** Onaylanmis randevu sayfasinda "Takvime Ekle (.ics indir)" butonu

### 5. Cok Dilli Telegram Bot (TR/EN)
- **Ne:** Telegram bot'un Turkce ve Ingilizce destegi, `/lang` komutu ile gecis
- **Neden:** Uluslararasi kullanim senaryosu — enterprise urunlerde cok dil standart
- **Karar:** Basit LANGS hash ile i18n yaptim — Rails I18n yerine, cunku bot servisi bagimsiz calisacak sekilde tasarlandi
- **Dosyalar:** `app/services/telegram_bot_service.rb` (LANGS constant, `t()` helper)
- **Kanit:** Telegram'da `/lang` yazinca TR/EN secenegi gelir, dil secince tum mesajlar o dilde olur

### 6. Ev Sahibi Rol Filtresi
- **Ne:** Bot'ta sadece `role: "host"` olan kullanicilar ev sahibi olarak listelenir
- **Neden:** Client rolundeki kullanicilar ev sahibi listesinde gorunmemeliydi
- **Karar:** `User.all` yerine `User.where(role: "host")` — veritabaninda role kolonu zaten vardi
- **Kanit:** Birden fazla host kayitliysa bot secim listesi gosterir

---

## Agent-First Fark Katmani

### Claude Code Nasil Kullanildi?
- **CLAUDE.md:** `.claude/CLAUDE.md` dosyasinda proje kurallari, deploy sureci ve mimari bilgiler tanimli
- **Workflow:** Turkce dogal dil ile talimat verildi, Claude Code kodu yazdi, test etti, commit + push yapti, Render deploy'u tetikledi
- **Gercek zamanli debug:** Telegram bot calismiyordu → Claude Code webhook log'larini analiz etti → `DoubleRenderError` + eksik `require` + eksik `dotenv-rails` gem'i buldu → hepsini tek seferde duzeltip deploy etti
- **Karar destegi:** Chart.js vs D3.js, gem vs custom servis, ActionCable vs polling gibi kararlarda Claude Code alternatiflerle birlikte onerisini sundu

### LLM Zekasi Nerede Gorulur?
1. **Telegram Bot NLP:** Kullanici "yarin bos saatiniz var mi?" yazdığinda bot bunu anliyor ve randevu akisini baslatıyor (`handle_natural_language` metodu)
2. **Akilli Hata Tespiti:** 500 hatasi alan webhook'ta response time analizi yaparak sorunun token eksikliginden mi yoksa kod hatasindan mi kaynaklandigini ayirt etti
3. **Cok adimli otonom calışma:** Tek bir Turkce talimatla 6 ozellik ekledi, test etti, commit yapti ve deploy tetikledi

---

## Kisisel Hedef
Telegram bot'un webhook modunda Render uzerinde calismasini saglamak ve gercek kullanicilarla test etmek.
**Durum:** Calisiyor ✅ — Webhook URL aktif, env var set edildi, bot mesajlara cevap veriyor.

---

## Commit Gecmisi (Bu Hafta)
```
ea51535 fix: filter hosts by role in Telegram bot service
c7cfc31 fix: add dotenv-rails and require telegram/bot in webhook controller
65ad211 fix: resolve DoubleRenderError in Telegram webhook controller
c369bea fix: safe Chart.js reuse/destruction and webhook exception safety
ba0d92f fix: restore Whenly logo visibility, add tab favicons, public profile route
6529529 fix: allow unauthenticated access for Telegram webhook
eced5ad feat: add reschedule, dashboard stats, profile editing, booking notes
1d6e3f9 fix: hide API token by default and remove token from curl example
d0d34ad fix: add missing ApplicationCable::Channel and remove duplicate notification
7568858 feat: add REST API, statistics dashboard, WebSocket live updates, .ics calendar, multi-language support
```
