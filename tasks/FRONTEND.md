# FRONTEND - Gorev Listesi

> Turbo/Stimulus ile gorunumler, CSS, mobil uyumluluk

---

## GUN 1 (Persembe 15 Ekim)

### FE-01: Layout & Tasarim Temelleri
- [ ] `app/views/layouts/application.html.erb` duzenle:
  - Google Font: Plus Jakarta Sans
  - Viewport meta tag
  - Turbo Drive varsayilan olarak aktif
- [ ] `app/assets/stylesheets/application.css` icinde design token'lari tanimla:
  ```css
  :root {
    --color-primary: #4F46E5;
    --color-primary-hover: #4338CA;
    --color-success: #059669;
    --color-warning: #D97706;
    --color-danger: #DC2626;
    --color-bg: #F9FAFB;
    --color-surface: #FFFFFF;
    --color-text: #111827;
    --color-text-secondary: #6B7280;
    --color-border: #E5E7EB;
    --radius: 12px;
    --shadow: 0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06);
    --shadow-lg: 0 10px 15px rgba(0,0,0,0.1), 0 4px 6px rgba(0,0,0,0.05);
    --font: 'Plus Jakarta Sans', system-ui, sans-serif;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: var(--font);
    background: var(--color-bg);
    color: var(--color-text);
    line-height: 1.6;
  }
  ```
- [ ] Temel utility class'lar: `.container`, `.card`, `.btn`, `.btn-primary`, `.btn-danger`, `.btn-outline`, `.badge`
- [ ] Mobil oncelikli: max-width 680px icin responsive kurallar

---

## GUN 2 (Cuma 16 Ekim)

### FE-02: Davetli Ekrani — Slot Secimi (`/:slug/:event_type`)
- [ ] `app/views/public_bookings/new.html.erb`:
  - Ust kisim: ev sahibi adi + event type adi + sure
  - Takvim: gun secici (bugun + 14 gun ilerisi). Turbo Frame ile gun degistiginde slotlar yenilenir
  - Slot listesi: her slot bir buton, secilince form acilir
  - Form alanlari: ad, e-posta
  - Gonder butonu
- [ ] Takvim gun secici icin Stimulus controller:
  ```javascript
  // app/javascript/controllers/date_picker_controller.js
  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = ["dateInput"]

    select(event) {
      const date = event.currentTarget.dataset.date
      this.dateInputTarget.value = date
      // Turbo Frame src guncelle
      const frame = document.getElementById("slots-frame")
      const url = new URL(window.location)
      url.searchParams.set("date", date)
      frame.src = url.toString()
    }
  }
  ```
- [ ] Slot secimi icin Stimulus controller:
  ```javascript
  // app/javascript/controllers/slot_select_controller.js
  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = ["form", "startsAt", "selectedSlot"]

    select(event) {
      const btn = event.currentTarget
      // Onceki secimi kaldir
      this.element.querySelectorAll(".slot-btn").forEach(b => b.classList.remove("selected"))
      btn.classList.add("selected")

      this.startsAtTarget.value = btn.dataset.startsAt
      this.formTarget.classList.remove("hidden")
    }
  }
  ```
- [ ] Slot butonlari CSS:
  ```css
  .slot-btn {
    padding: 10px 20px;
    border: 2px solid var(--color-primary);
    border-radius: var(--radius);
    background: transparent;
    color: var(--color-primary);
    cursor: pointer;
    font-weight: 600;
    transition: all 0.15s;
  }
  .slot-btn:hover, .slot-btn.selected {
    background: var(--color-primary);
    color: white;
  }
  ```

### FE-03: Davetli Ekrani — Booking Durumu (`/b/:token`)
- [ ] `app/views/public_bookings/show.html.erb`:
  - Durum badge'i: pending (sari), confirmed (yesil), declined (kirmizi), canceled (gri), expired (gri)
  - Tarih/saat bilgisi
  - Ev sahibi adi
  - Iptal butonu (sadece pending veya confirmed ise):
    ```erb
    <% if @booking.status.in?(%w[pending confirmed]) %>
      <%= button_to "Randevuyu Iptal Et", cancel_booking_path(@booking.token),
          method: :patch, class: "btn btn-danger",
          data: { turbo_confirm: "Iptal etmek istediginize emin misiniz?" } %>
    <% end %>
    ```
- [ ] Turbo Stream ile canli guncelleme (opsiyonel, zaman kalirsa)

### FE-04: Panel Layout
- [ ] `app/views/layouts/panel.html.erb` (veya partial):
  - Sol sidebar: SlotWise logosu, navigasyon linkleri (Panel, Randevu Turleri, Musaitlik, Cikis)
  - Ust bar: hosgeldin mesaji + ev sahibi adi
  - Mobilde sidebar hamburger menu ile acilir
- [ ] Sidebar CSS:
  ```css
  .sidebar {
    width: 240px;
    background: var(--color-surface);
    border-right: 1px solid var(--color-border);
    height: 100vh;
    position: fixed;
    padding: 24px 16px;
  }
  .main-content {
    margin-left: 240px;
    padding: 32px;
  }
  @media (max-width: 768px) {
    .sidebar { display: none; }
    .sidebar.open { display: block; z-index: 100; }
    .main-content { margin-left: 0; }
  }
  ```

### FE-05: Panel Dashboard (`/panel`)
- [ ] `app/views/panel/dashboard/index.html.erb`:
  - **3 sekme**: Onay Bekleyen | Yaklasan | Gecmis (Turbo Frames ile)
  - Her booking karti:
    ```
    +------------------------------------------+
    | Davetli Adi        30 dk Mentorluk       |
    | davetli@email.com  15 Ekim 2026, 10:00   |
    |                                          |
    | [Onayla]  [Reddet]       Kalan: 5s 23dk  |
    +------------------------------------------+
    ```
  - Onay bekleyenlerde geri sayim (approval_deadline_at'a kadar)
  - Gecmis sekmesinde: `no_show` butonu (sadece SchedulingRules.can_mark_no_show? ise)
- [ ] Geri sayim icin Stimulus controller:
  ```javascript
  // app/javascript/controllers/countdown_controller.js
  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static values = { deadline: String }

    connect() {
      this.tick()
      this.timer = setInterval(() => this.tick(), 1000)
    }

    disconnect() {
      clearInterval(this.timer)
    }

    tick() {
      const now = new Date()
      const deadline = new Date(this.deadlineValue)
      const diff = deadline - now

      if (diff <= 0) {
        this.element.textContent = "Suresi doldu"
        this.element.classList.add("text-danger")
        clearInterval(this.timer)
        // Sayfayi yenile (Turbo ile)
        location.reload()
        return
      }

      const hours = Math.floor(diff / 3600000)
      const minutes = Math.floor((diff % 3600000) / 60000)
      const seconds = Math.floor((diff % 60000) / 1000)
      this.element.textContent = `${hours}s ${minutes}dk ${seconds}sn`
    }
  }
  ```

### FE-06: Panel — Randevu Turleri (`/panel/turler`)
- [ ] `app/views/panel/event_types/index.html.erb`:
  - Liste: her tur bir kart (ad, sure, onay gerekli mi?, duzenle/sil butonlari)
  - Yeni tur butonu
- [ ] `app/views/panel/event_types/_form.html.erb`:
  - Ad, sure (select: 15/30/45/60), onay gerekli mi? (checkbox), onay suresi (saat)
  - Onay gerekli degilse onay suresi alani gizlenir (Stimulus toggle)

### FE-07: Panel — Musaitlik (`/panel/musaitlik`)
- [ ] `app/views/panel/availability_rules/index.html.erb`:
  - 7 gun listesi (Pazartesi - Pazar)
  - Her gun icin: aktif/pasif toggle, baslangic saati, bitis saati
  - Kaydet butonu (toplu guncelleme)
- [ ] Saat secici: select dropdown (00:00 - 23:30, 30 dk aralikla)

---

## GUN 3 (Cumartesi 17 Ekim)

### FE-08: No-Show Badge & Uyari
- [ ] Davetli daha once 2+ kez gelmemisse booking kartinda uyari goster:
  ```erb
  <% if SchedulingRules.repeat_no_show?(@booking.user, @booking.invitee_email) %>
    <span class="badge badge-warning">Tekrar eden no-show</span>
  <% end %>
  ```
- [ ] Pending booking kartinda "Bu davetli daha once gelmemis, onay zorunlu" notu

### FE-09: Flash Mesajlari & Hata Gosterimleri
- [ ] `app/views/layouts/application.html.erb` icinde flash partial:
  ```erb
  <% flash.each do |type, message| %>
    <div class="flash flash-<%= type %>" data-controller="flash" data-flash-delay-value="5000">
      <%= message %>
      <button data-action="flash#dismiss">&times;</button>
    </div>
  <% end %>
  ```
- [ ] Flash Stimulus controller (5 sn sonra otomatik kapanir)
- [ ] Form validasyon hatalari icin inline error gosterimi

### FE-10: Son Parlatis
- [ ] Tum sayfalarda mobil test (375px, 768px, 1024px)
- [ ] Empty state mesajlari ("Henuz randevu yok", "Musaitlik tanimlanmamis")
- [ ] Loading state (Turbo navigate sirasinda progress bar)
- [ ] Favicon ve page title'lar
