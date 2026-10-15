# Kullanıcı Problemi: Kaynak Dosyası

Bu dosya, Whenly'nin çözdüğü kullanıcı probleminin kaynaklarını içerir. Alıntılar kaynaklardan birebir aktarılmıştır. Görüntülenme sayıları 15.10.2026 tarihinde okunmuştur.

---

## 1. Problem

Calendly'de bir davetli rezervasyon yaptığında randevu, ev sahibinin onayı alınmadan doğrudan takvime işlenir. Ev sahibinin talebi onaylama veya reddetme imkânı yoktur. Onay e-postası davetliye gönderildiği için davetli, ev sahibi karar vermeden etkinliği kendi takvimine ekleyebilir.

## 2. Çözüm

Whenly'de randevu talebi `pending` (onay bekliyor) durumunda oluşur:

1. Ev sahibi talebi onaylar (`confirmed`) veya reddeder (`declined`).
2. Onay son tarihine kadar yanıtlanmayan talep `expired` durumuna geçer ve ilgili saat yeniden müsait olur.
3. İki kez katılmayan (`no_show`) bir davetlinin yeni talebi, randevu türü anında onaylı olsa bile onaya düşer.

---

## 3. Birincil kaynaklar: Calendly ekibinin yanıtları

| Tarih | Yanıtlayan | Alıntı | Görüntülenme | Bağlantı |
| :--- | :--- | :--- | ---: | :--- |
| 29.10.2023 | Kelsi (CalPal Emeritus) | *"Unfortunately, Calendly does not currently support manual confirmations."* | 5.474 | [Approving before accepting](https://community.calendly.com/how-do-i-40/approving-before-accepting-277) |
| 21.11.2023 | Kelsi (CalPal Emeritus) | Aynı ifade | 3.904 | [Approve bookings](https://community.calendly.com/how-do-i-40/approve-bookings-415) |
| 19.02.2024 | Kelsi (CalPal Emeritus) | Aynı ifade | 1.028 | [Manual confirmations](https://community.calendly.com/how-do-i-40/does-calendly-support-manual-confirmations-reconfirmations-of-bookings-908) |
| 01.12.2025 | David (Community Manager) | *"Right now there is not a way to manually confirm events that are scheduled through Calendly."* | 145 | [Manual approval for internal use](https://community.calendly.com/api-webhook-help-61/manual-approval-feature-for-internal-company-use-5071) |
| 21.07.2026 | Allie M (Community Manager) | *"Right now, there isn't a native "pending approval" feature in Calendly."* | 162 | [Approve bookings](https://community.calendly.com/how-do-i-40/approve-bookings-5906) |

**Calendly'nin gerekçesi** (29.10.2023, 21.11.2023 ve 19.02.2024 yanıtları): *"We've found that manual confirmation increases the steps you have to take to book meetings."*

**Kullanıcı talepleri** (21.07.2026 tarihli başlık):

| Tarih | Kullanıcı | Alıntı |
| :--- | :--- | :--- |
| 21.07.2026 | RB093 | Rezervasyonların takvime işlenmeden önce onay gerektirmesi seçeneğini talep ediyor. |
| 26.07.2026 | JeffreyLebowski | *"That's EXACTLY what I need - the ability to accept or decline a booking"* |
| 30.07.2026 | Lee73645 | *"I would desperately like to have this ability as well."* |

---

## 4. Destekleyici kaynaklar

| Tarih | Konu | Calendly'nin yanıtı | Bağlantı |
| :--- | :--- | :--- | :--- |
| 04.03.2024 | Yeniden onay akışı, onaylanmayan randevuyu iptal etmiyor | *"there is no functionality that allows for an event to be automatically cancelled"* | [Reconfirm does not cancel](https://community.calendly.com/how-do-i-40/reconfirm-does-not-cancel-appointments-998) |
| 06.03.2024 | Sürekli rezervasyon yapıp katılmayan kişiyi engelleme (11 yanıt, 7.907 görüntülenme) | *"At this time, there is no way to directly block a specific person from booking with you via your public booking page."* Bu yanıttan sonra Calendly elle engelleme özelliği eklemiştir (bkz. bölüm 5). | [Block a person](https://community.calendly.com/how-do-i-40/block-a-person-from-scheduling-1009) |
| 10.06.2024 | Davetli başına rezervasyon sınırı | *"At this time there is not a way to block invitees from booking or limit the number of times a specific invitee can book with you."* | [Limit per invitee](https://community.calendly.com/how-do-i-40/limit-number-of-booking-per-invitee-a-month-1658) |
| 28.07.2025 | Aynı e-postayla günde birden fazla rezervasyon | *"there isn't any setting inside of Calendly that prevents multiple bookings from the same person"* | [Duplicate bookings](https://community.calendly.com/how-do-i-40/how-can-i-prevent-duplicate-bookings-e-g-same-email-booking-multiple-times-in-one-day-in-calendly-4351) |
| 25.11.2025 | Özel ders veren eğitmen: *"If students forgot to come to sessions, I had no proof that they had scheduled."* | — | [Capterra](https://www.capterra.com/p/148036/Calendly/reviews/) |

---

## 5. Calendly'de mevcut olan özellikler

| Özellik | Durum | Kaynak |
| :--- | :--- | :--- |
| reCAPTCHA v3 (yalnızca şüpheli rezervasyonda doğrulama ister) | Mevcut (Şubat 2025'te personel tarafından belirtildi) | [Forum başlığı](https://community.calendly.com/how-do-i-40/drastic-increase-in-spam-bookings-clogging-up-calendar-3493) |
| E-posta doğrulaması zorunluluğu | Mevcut (Ekim 2025'te duyuruldu) | [Abuse prevention](https://calendly.com/help/abuse-prevention) |
| Kişiyi elle engelleme | Mevcut (eklenme tarihi belirtilmemiş) | [How to block someone](https://calendly.com/help/how-to-block-someone-from-booking-with-you.html) |
| E-posta alan adı engelleme | Mevcut (routing forms, ücretli planlar) | [Abuse prevention](https://calendly.com/help/abuse-prevention) |
| Katılmayanı elle işaretleme | Mevcut | [Mark no-shows](https://calendly.com/help/how-to-mark-no-shows-for-meetings) |
| Yapay zekâ ile toplantı hazırlığı (Callie) | Duyuruldu (19.08.2026) | [Calendly AI duyurusu](https://calendly.com/newsroom/press-release/calendly-new-ai-product-suite) |
| Ev sahibi onayı | Mevcut değil (21.07.2026) | [Approve bookings](https://community.calendly.com/how-do-i-40/approve-bookings-5906) |
| Onaylanmayan randevunun otomatik iptali | Mevcut değil (04.03.2024); sonradan eklendiğine dair kaynak bulunamadı | [Reconfirm does not cancel](https://community.calendly.com/how-do-i-40/reconfirm-does-not-cancel-appointments-998) |
| Tekrar eden katılımsızlığa otomatik kural | Yardım sayfalarında yer almıyor | [How to block someone](https://calendly.com/help/how-to-block-someone-from-booking-with-you.html) |

Bu nedenle Whenly spam engelleme ve yapay zekâ özetleme alanında bir iddiada bulunmaz.

---

## 6. Kaynakların sınırları

- HPE ve US Foods'un Calendly müşterisi olduğunu gösteren kaynak Eylül 2023 tarihlidir.
- Reddit ve G2'deki ilgili yorumlara doğrudan erişilememiştir. Birincil kaynak olarak Calendly ekibinin forum yanıtları ve Capterra yorumları kullanılmıştır.
- Calendly'nin bu özellikleri 21.07.2026 sonrasında ekleyip eklemediği sunumdan önce yeniden kontrol edilmelidir.
