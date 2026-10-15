# ANTIGRAVITY ACIL GOREV LISTESI

Oncelik sirasi ile asagidaki isleri yap. Projede tasks/BACKEND.md, tasks/FRONTEND.md, tasks/TEST.md dosyalarini oku, orada her sey detayli yazili. Asagida ozet ve oncelik sirasi var.

---

## ONCELIK 1: Eksik Model Dosyalari (BUNLAR OLMADAN HICBIR SEY CALISMAZ)

Bu dosyalar daha once duzenlenmis ama diske KAYDEDILMEMIS. tasks/BACKEND.md dosyasindaki BE-04, BE-05, BE-06, BE-07 gorevlerini oku ve bu 4 dosyayi olustur:

1. `app/models/booking.rb` — Durum makinesi (TRANSITIONS hash'i ile), scope'lar, token uretimi. BE-04'teki kodu aynen uygula. cancel! metodu hem pending hem confirmed'dan gecilebilmeli.

2. `app/models/scheduling_rules.rb` — 3 zaman kurali tek dosyada. BE-05'teki kodu aynen uygula. bookable?, approval_deadline_for, repeat_no_show?, can_mark_no_show?, force_approval? metotlari olmali.

3. `app/models/slot_finder.rb` — Bos saat hesaplama. BE-06'daki kodu uygula. Suresi dolmus pending booking'ler slotu BLOKLAMAMALI (active_or_unexpired_pending scope'u kullanilmali).

4. `app/models/bookings/create.rb` — Service object. BE-07'deki kodu uygula. Callback yerine service object kullaniyoruz (hocanin "yasak sihirler" kurali).

---

## ONCELIK 2: Eksik Job Dosyasi

5. `app/jobs/expire_pending_bookings_job.rb` — Booking.pending_expired.find_each ile suresi dolanlari expire et. recurring.yml zaten var, sadece job dosyasi eksik.

---

## ONCELIK 3: Eksik Controller Dosyalari

6. `app/controllers/public_bookings_controller.rb` — Davetli ekrani. new, create, show, cancel action'lari. allow_unauthenticated_access olmali. BE-10'daki kodu uygula.

7. `app/controllers/panel/dashboard_controller.rb` — Host paneli. index action'inda expire_overdue_bookings cagirilmali (Render uyku stratejisi). BE-12'deki kodu uygula.

8. `app/controllers/panel/bookings_controller.rb` — confirm, decline, cancel, complete, no_show action'lari. InvalidTransition hatasini yakala.

9. `app/controllers/panel/event_types_controller.rb` — Standart CRUD.

10. `app/controllers/panel/availability_rules_controller.rb` — index ve create action'lari.

---

## ONCELIK 4: View Dosyalari

Asagidaki view'lari olustur. tasks/FRONTEND.md dosyasini oku, FE-02 ile FE-07 arasindaki gorevlerde detaylar var.

11. `app/views/public_bookings/new.html.erb` — Slot secim ekrani. Gun secici + slot butonlari + form (ad, e-posta).
12. `app/views/public_bookings/show.html.erb` — Booking durumu sayfasi. Durum badge'i, tarih/saat, iptal butonu.
13. `app/views/panel/dashboard/index.html.erb` — 3 sekmeli panel: Onay Bekleyen (geri sayimla), Yaklasan, Gecmis.
14. `app/views/panel/event_types/index.html.erb` — Tur listesi.
15. `app/views/panel/event_types/_form.html.erb` — Tur formu.
16. `app/views/panel/event_types/new.html.erb` ve `edit.html.erb`
17. `app/views/panel/availability_rules/index.html.erb` — 7 gun listesi, saat secimi.
18. `app/views/layouts/panel.html.erb` veya partial — Sidebar + main content layout.

---

## ONCELIK 5: Stimulus Controller'lari

19. `app/javascript/controllers/countdown_controller.js` — Onay suresi geri sayim.
20. `app/javascript/controllers/slot_select_controller.js` — Slot secimi.

---

## ONCELIK 6: Gemfile ve Dockerfile Duzeltmesi

21. Gemfile'dan `gem "sqlite3"` satirini SIL. Biz sadece PostgreSQL kullaniyoruz.
22. Dockerfile'da `sqlite3` yerine `libpq-dev` yaz (apt-get install satirinda).

---

## ONCELIK 7: CSS

23. `app/assets/stylesheets/application.css` dosyasini tasks/FRONTEND.md FE-01'deki design token'larla guncelle. Plus Jakarta Sans font, Indigo/Menekse renk paleti, mobil uyumlu.

---

## YAPMA LISTESI (bunlari YAPMA)
- Test dosyalari YAZMA, onlari ben yazacagim
- CI pipeline OLUSTURMA
- README YAZMA
- AGENT.md YAZMA
- Git commit YAPMA
- Deploy YAPMA
