# Langkah Sahabat

Langkah Sahabat adalah prototipe frontend Flutter untuk Tugas Akhir mengenai navigasi berjalan kaki multimodal. Aplikasi bertindak sebagai pendamping yang menggabungkan modalitas visual, modalitas audio, dan modalitas haptik. Seluruh alur utama dapat didemonstrasikan tanpa backend, Google Maps API key, Gemini API key, atau perjalanan fisik.

## Fitur

- Pencarian dan pemilihan lima tujuan mock
- Pratinjau rute dengan estimasi, arah awal, dan landmark
- Enam langkah instruksi berjalan kaki berbasis landmark
- Peta OpenStreetMap interaktif dengan polyline rute dan atribusi sumber
- Kontrol demo untuk langkah berikutnya, titik aksi, keluar rute, dan reset
- Peringatan titik aksi dengan audio serta haptic feedback
- Bantuan suara melalui speech-to-text dan fallback input teks
- Respons asisten mock; Gemini bersifat opsional dan otomatis memiliki fallback
- Text-to-speech bahasa Indonesia
- Bantuan manual dan pemulihan rute dengan perhitungan ulang mock
- State management Riverpod dan routing dengan go_router
- Sistem desain biru, font Satoshi lokal, ikon Lucide, dan microanimation

## Prasyarat

- Flutter stable 3.22 atau lebih baru (Dart 3.4+)
- Android Studio/Xcode beserta emulator atau perangkat fisik

## Menjalankan aplikasi

Repositori ini berisi source aplikasi. Bila folder platform belum ada, buat secara aman dari root repositori:

```sh
flutter create . --platforms=android,ios
cp .env.example .env
flutter pub get
flutter run
```

`flutter create .` mempertahankan isi `lib/`, lalu menghasilkan runner Android/iOS yang sesuai dengan versi Flutter lokal. Untuk verifikasi:

```sh
flutter format lib test
flutter analyze
flutter test
```

Untuk fitur perangkat nyata, tambahkan deskripsi izin berikut setelah runner dibuat: `NSLocationWhenInUseUsageDescription` dan `NSSpeechRecognitionUsageDescription`/`NSMicrophoneUsageDescription` pada `ios/Runner/Info.plist`, serta `ACCESS_FINE_LOCATION`, `RECORD_AUDIO`, dan `INTERNET` pada `android/app/src/main/AndroidManifest.xml`.

## Konfigurasi

`.env.example`:

```env
GEMINI_API_KEY=
USE_MOCK_ASSISTANT=true
USE_MOCK_LOCATION=true
```

Mode mock direkomendasikan untuk presentasi. Jika ingin mencoba Gemini, isi API key dan ubah `USE_MOCK_ASSISTANT=false`. Kegagalan jaringan/API otomatis kembali ke respons mock. Jangan commit `.env` yang berisi rahasia.

Izin lokasi dan mikrofon perlu ditambahkan ke manifest platform yang dihasilkan bila integrasi perangkat nyata digunakan. Alur demo utama tidak bergantung pada lokasi nyata. Speech-to-text yang tidak tersedia otomatis dapat digantikan oleh input teks.

## Alur demo Tugas Akhir

1. Pilih tujuan di layar “Mau ke mana?”.
2. Buka pratinjau dan tekan “Mulai navigasi”.
3. Gunakan “Simulate Next Step” untuk memperbarui instruksi.
4. Gunakan “Simulate Action Point” untuk menunjukkan modalitas haptik dan audio.
5. Buka “Tanya arah”; gunakan mikrofon atau masukkan teks.
6. Buka “Bantuan” untuk menunjukkan seluruh aksi manual.
7. Gunakan “Simulate Off Route”, hitung ulang rute, lalu kembali ke navigasi.

## Struktur

```text
lib/
  core/                 konfigurasi, konstanta, dan tema
  data/                 model, data mock, dan service perangkat/API
  features/
    navigation/         state, layar, dan widget navigasi
    voice/              state dan panel interaksi suara
    recovery/           state dan layar pemulihan rute
  shared/widgets/       visual peta simulasi reusable
```

## User experience goals

Instruksi aktif dibuat dominan, landmark selalu mempertahankan konteks, label memakai bahasa sederhana, dan fungsi penting selalu memiliki alternatif manual. Panel bantuan tidak menghilangkan konteks navigasi di belakangnya.

## Keterbatasan

- Jalur, posisi, jarak, dan pergerakan adalah simulasi untuk demonstrasi.
- Tile OpenStreetMap membutuhkan koneksi internet; data rute dan instruksi masih berupa simulasi.
- Kualitas speech recognition dan text-to-speech bergantung pada dukungan perangkat.
- Gemini adalah peningkatan opsional, bukan syarat fungsi aplikasi.
