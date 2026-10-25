# Whenly - Claude Code Agent Kuralları

## Proje
Whenly: Calendly benzeri randevu yonetim sistemi (Rails 8.1, PostgreSQL, Hotwire, ActionCable).

## Deploy
- **Platform:** Render.com (https://whenly-cpyy.onrender.com)
- GitHub main branch'e push yapildiginda Render otomatik deploy eder.
- Environment variable'lar (TELEGRAM_BOT_TOKEN, DATABASE_URL, RAILS_MASTER_KEY) Render dashboard'dan set edilir.
- `.env` dosyasi sadece local development icindir, production'a gitmez.

## Kurallar
- "Calendly" kelimesi UI'da ASLA gorunmemeli, sadece README'de "ilham kaynagi" olarak gecer.
- `config/master.key` ve `.env` dosyalari ASLA git'e commit edilmemeli.
- SMTP credentials hardcoded olarak `config/environments/development.rb` icindedir.
- Test raporlari gercek olmali, sahte test raporu olusturulmamali.
- Commit mesajlari Turkce veya Ingilizce, aciklayici ve kisa olmali.

## Mimari
- Monolith Rails uygulamasi, API + Web + Telegram Bot ayni projede.
- REST API: `/api/v1/` namespace, Bearer token auth.
- WebSocket: ActionCable ile BookingsChannel, gercek zamanli dashboard.
- Telegram Bot: Webhook modu (Render), polling modu (localhost).
- ICS dosya olusturma: `IcsGenerator` servisi.
- Istatistik: Chart.js 4.4.4 ile 5 grafik (weekly, status, daily, busiest_day, busiest_hour).
