# AVPlayer — Android Only / GitHub Actions

AVPlayer adalah MVP media player Android dengan fondasi subtitle AI Bahasa Indonesia.

## Penting untuk pengguna HP saja

Anda **tidak membutuhkan PC** untuk membuat APK. GitHub Actions akan memasang Flutter di server GitHub, membuat Android project dari template Flutter stable, lalu menghasilkan APK release.

### Upload ke GitHub

Upload **ISI folder ini**, bukan file ZIP-nya, ke repository `AVPlayer`.

Setelah upload, pastikan file ini terlihat di GitHub:

`.github/workflows/build-apk.yml`

### Build APK

1. Buka repository GitHub.
2. Masuk ke **Actions**.
3. Pilih **Build AVPlayer APK**.
4. Tekan **Run workflow**.
5. Tunggu sampai job selesai dengan tanda hijau.
6. Buka hasil workflow.
7. Pada **Artifacts**, download `AVPlayer-release-apk`.
8. Extract ZIP artifact dan install `app-release.apk` di Android.

Workflow juga otomatis berjalan saat ada push ke branch `main`.

## Fitur MVP

- Pemutar video lokal melalui Flutter `video_player`
- File picker untuk media dan SRT/VTT
- Subtitle SRT/VTT sederhana
- Tombol AI Indonesia
- Pengaturan URL backend
- Logo AVPlayer
- Backend Node.js sebagai fondasi AI

## AI subtitle

APK tidak menyimpan API key. Backend menerima media pada endpoint:

`POST /subtitle`

Tambahkan provider speech-to-text dan terjemahan Indonesia di `backend/server.mjs`.

Untuk HP fisik, bila backend dijalankan pada komputer/server di jaringan yang sama, gunakan URL seperti:

`http://192.168.1.10:3000`

Untuk Android Emulator, gunakan:

`http://10.0.2.2:3000`

## Catatan format media

Kemampuan format video/audio mengikuti codec dan dukungan platform Android. `video_player` bukan jaminan bahwa semua file MKV/AVI akan dapat diputar. Untuk dukungan format yang jauh lebih luas, tahap berikutnya sebaiknya menggunakan engine FFmpeg/Media3.

## Struktur

- `.github/workflows/build-apk.yml` — CI build APK
- `lib/main.dart` — aplikasi Flutter
- `assets/avplayer_logo.png` — logo
- `backend/` — fondasi backend AI
- `android/` — penanda struktur Android; CI menghasilkan template Android yang sesuai Flutter stable
