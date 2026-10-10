# SENS X IOS - VIP PERFORMANCE & TOUCH UTILITY
**Developed by RANZY NXRPLOIT DEV**

SENS X IOS adalah aplikasi iOS utility modern dengan desain **Dark & Glow Obsidian Aesthetic**, lengkap dengan 5-second animated particle splash screen, Supabase License Key authentication, dan fitur tuning touch & performance lengkap.

---

## 🌟 Fitur Utama (Full Redesign)

1. **Top Bar Header**:
   - Title: `RANZY NXRPLOIT DEV` & `SENS X IOS`
   - Active status indicator & quick lock button.

2. **5-Second Particle Splash Screen**:
   - Full animation particle system dengan progress bar real-time (0 - 100%).
   - Transisi otomatis ke menu Access Login.

3. **Supabase Access Login**:
   - Input Username & License Key.
   - Verifikasi lisensi dilakukan oleh Supabase; koneksi/error tidak pernah dianggap sebagai lisensi valid.
   - Mendukung lisensi durasi 1–30 hari (aktif sejak verifikasi pertama) dan `lifetime`.

4. **Aim & Recoil Toggles (On / Off)**:
   - `AIMDRAG`
   - `FIX RECOIL`
   - `STABILIZER AIM`
   - `HIGH SENS Y AND X`

5. **System Boost Engine**:
   - `MAX TOUCH BOOST`
   - `BOOST FPS`
   - `BOOST TOUCH FEEL`

6. **3-Second Animated Junk Cleaner**:
   - Tombol **Cleaner All Junks File** dengan modal animasi radial progress ring selama 3 detik.
   - Mengosongkan cache sandbox iOS dan memberikan summary hasil pembersihan.

7. **Drag System (Gliding 1 - 7)**:
   - Slider gliding level 1 sampai 7 dengan indikator visual glow.

8. **3 Performance Modes**:
   - `Balance`
   - `Performa`
   - `Competitive`

9. **Kursor Touch (Batasan 1 - 120)**:
   - Direct text input & tombol stepper `+` / `-` dengan validasi ketat rentang `1 - 120`.

---

## 🚀 Cara Build IPA di Windows (via GitHub Actions)

1. Commit & Push seluruh folder project ini ke repository GitHub kamu (`main` / `master`).
2. Buka tab **Actions** di repository GitHub kamu.
3. GitHub Actions akan otomatis menjalankan workflow `Build unsigned SENS X IOS IPA`.
4. Setelah build selesai (~2-3 menit), download file `SENSXIOS-unsigned-IPA.zip`.
5. Extract ZIP tersebut untuk mendapatkan file `SENSXIOS-unsigned.ipa`.

---

## 📱 Cara Install di iOS

Kamu bisa menginstal file `.ipa` yang sudah di-download menggunakan metode pilihanmu:
- **Sideloadly**
- **Esign**
- **KSign**
- **TrollStore** / **AltStore**

## 🔐 Supabase License Setup

Untuk setup baru, jalankan migration [20261010000000_license_expiry.sql](supabase/migrations/20261010000000_license_expiry.sql) lalu [20261011000000_license_duration_days.sql](supabase/migrations/20261011000000_license_duration_days.sql) di Supabase SQL Editor, secara berurutan. Jika migration lisensi sebelumnya sudah dijalankan, jalankan migration kedua saja. Migration kedua memperluas paket durasi ke 1–30 hari serta mempertahankan lisensi lifetime dan key 1 hari yang sudah ada.

Buat setiap key melalui dashboard/admin tepercaya (jangan pernah menaruh service-role key di aplikasi):

- **Durasi 1–30 hari:** simpan `license_key`, set `status` ke `active`, `license_type` ke `duration`, dan `duration_days` ke angka 1 sampai 30. Set `activated_at` dan `expires_at` ke `NULL`; verifikasi pertama memulai masa aktif di server.
- **Lifetime:** simpan `license_key`, set `status` ke `active`, `license_type` ke `lifetime`, dan `duration_days`, `activated_at`, serta `expires_at` ke `NULL`.

Contoh penerbitan key dari Supabase SQL Editor (ganti placeholder dengan key acak unik yang dibuat secara aman):

```sql
INSERT INTO public.licenses (license_key, status, license_type, duration_days, activated_at, expires_at)
VALUES ('PUT_RANDOM_UNIQUE_KEY_HERE', 'active', 'duration', 1, NULL, NULL);

INSERT INTO public.licenses (license_key, status, license_type, duration_days, activated_at, expires_at)
VALUES ('PUT_ANOTHER_RANDOM_UNIQUE_KEY_HERE', 'active', 'duration', 30, NULL, NULL);

INSERT INTO public.licenses (license_key, status, license_type, duration_days, activated_at, expires_at)
VALUES ('PUT_LIFETIME_KEY_HERE', 'active', 'lifetime', NULL, NULL, NULL);
```

Kolom tabel yang sudah ada harus mencakup `license_key` dan `status`. Key lama diberi tipe `lifetime` oleh migration agar key aktif yang sudah terbit tidak langsung kadaluarsa. Verifikasi membutuhkan koneksi internet ke Supabase; aplikasi menolak akses jika server tidak dapat dihubungi. Jangan gunakan kredensial service-role di klien iOS.
