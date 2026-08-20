# Keterlacakan Persyaratan Implementasi

Dokumen ini menghubungkan kebutuhan pada laporan Tugas Akhir dengan modul, service, komponen antarmuka, dan pengujian. OpenStreetMap menggantikan pilihan teknologi peta sebelumnya sesuai arahan terbaru.

## Persyaratan fungsional

| ID | Perilaku yang diwajibkan | Modul dan komponen | Service/state | Verifikasi otomatis |
|---|---|---|---|---|
| FR01 | Mencari atau memilih tujuan, melihat pratinjau, lalu memulai navigasi | M01: `SearchDestinationScreen`, `RoutePreviewScreen`, `NavigationMap` | `NavigationController`, `LocationService`, `RouteService` (OSRM), `MapService` (Nominatim) | `widget_test.dart`, `navigation_controller_test.dart`, `route_service_test.dart` |
| FR02 | Menampilkan dan membacakan instruksi berbasis landmark | M02: `ActiveNavigationScreen`, `NavigationInstructionCard` | `NavigationController`, `TextToSpeechService` | `navigation_controller_test.dart` |
| FR03 | Menerima bantuan suara maupun aksi manual, menampilkan transkrip dan jawaban | M03: `VoiceInteractionPanel`, `ManualFeedbackActions` | `VoiceController`, `VoiceService`, `GeminiService`, `TextToSpeechService` | `voice_controller_test.dart` |
| FR04 | Memberi peringatan sebelum titik aksi melalui visual, haptik, dan audio | M04: `ActionPointAlert` | `NavigationController`, `MapService`, `HapticService`, `TextToSpeechService` | `navigation_controller_test.dart`, `map_service_test.dart` |
| FR05 | Mendeteksi keluar rute, menampilkan jalur pemulihan, memutar audio awal, dan menghitung ulang | M05: `RouteRecoveryView`, `NavigationMap` | `RecoveryController`, `RouteService`, `MapService`, `TextToSpeechService` | `recovery_controller_test.dart`, `route_service_test.dart` |

## State antarmuka

| Rancangan | Route atau overlay | Pemicu | Jalan keluar |
|---|---|---|---|
| S01 Pencarian tujuan | `/` | Aplikasi dibuka | Tujuan dipilih dan tombol pratinjau ditekan |
| S02 Pratinjau rute | `/preview` | Rute tujuan tersedia | Ubah tujuan atau mulai navigasi |
| S03 Navigasi aktif | `/navigation` | Tombol mulai navigasi | Pemulihan rute bila keluar jalur |
| S04 Interaksi suara | Bottom sheet | Tombol **Tanyakan arah** | Tutup atau gunakan arahan |
| S05 Peringatan titik aksi | Dialog | Ambang jarak titik aksi tercapai | Tombol **Saya paham** |
| S06 Pemulihan rute | `/recovery` | Status `offRoute` | Posisi kembali ke rute |
| S07 Bantuan manual | Bottom sheet | Tombol **Buka bantuan** | Aksi dipilih atau panel ditutup |

## Keputusan antarmuka

- Satoshi digunakan secara lokal untuk menghindari ketergantungan font daring.
- Biru adalah warna primer; aksi sekunder memakai `FilledButton.tonal`, bukan tombol outline.
- Instruksi aktif, jarak, dan landmark diprioritaskan secara visual.
- Panel bantuan mempertahankan konteks navigasi sebagai bottom sheet.
- Animasi dibatasi pada perubahan state yang membantu pemahaman: pemilihan tujuan, pergantian instruksi, status mikrofon, marker posisi, dan perubahan arahan pemulihan.
- Semua aksi berbasis ikon memiliki label teks atau tooltip agar maknanya tidak bergantung pada ikon saja.

## Integrasi data nyata

`RouteService` (S02) mengambil geometri, jarak, durasi, dan manuver pejalan kaki dari OSRM. `MapService` (S03) menangani pencarian tujuan Nominatim, perhitungan jarak, ambang titik aksi, dan deviasi terhadap segmen rute. `LocationService` (S01) menyediakan posisi GPS dan pembaruan posisi foreground. `NavigationMap` merender tile serta data rute OpenStreetMap. Data simulasi tidak digunakan pada alur default; kontrol demonstrasi hanya aktif melalui `--dart-define=SHOW_DEMO_CONTROLS=true`.
