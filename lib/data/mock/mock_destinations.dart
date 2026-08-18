import '../models/destination.dart';

const mockDestinations = <Destination>[
  Destination(
      id: 'library',
      name: 'Perpustakaan Pusat',
      address: 'Jalan Akademik 1',
      latitude: -6.8920,
      longitude: 107.6107,
      description: 'Perpustakaan utama kampus'),
  Destination(
      id: 'gate',
      name: 'Gerbang Utama',
      address: 'Jalan Kampus Raya',
      latitude: -6.8911,
      longitude: 107.6095,
      description: 'Pintu masuk utama kampus'),
  Destination(
      id: 'station',
      name: 'Stasiun Terdekat',
      address: 'Jalan Stasiun 8',
      latitude: -6.8890,
      longitude: 107.6070,
      description: 'Akses transportasi publik'),
  Destination(
      id: 'lecture',
      name: 'Gedung Kuliah Umum',
      address: 'Kompleks Akademik',
      latitude: -6.8931,
      longitude: 107.6120,
      description: 'Gedung perkuliahan bersama'),
  Destination(
      id: 'canteen',
      name: 'Kantin Utama',
      address: 'Jalan Mahasiswa',
      latitude: -6.8940,
      longitude: 107.6110,
      description: 'Area makan kampus'),
];
