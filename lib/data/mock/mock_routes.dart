import '../models/destination.dart';
import '../models/navigation_route.dart';
import '../models/route_step.dart';

NavigationRoute buildMockRoute(Destination destination) => NavigationRoute(
      id: 'route-${destination.id}',
      destination: destination,
      estimatedTimeMinutes: 12,
      totalDistanceMeters: 850,
      steps: [
        const RouteStep(
            id: '1',
            instruction: 'Mulai berjalan ke arah gerbang utama.',
            landmarkName: 'Pos keamanan',
            distanceMeters: 120,
            actionType: RouteActionType.start,
            latitude: -6.8900,
            longitude: 107.6090),
        const RouteStep(
            id: '2',
            instruction: 'Berjalan lurus menuju gerbang utama.',
            landmarkName: 'Gerbang utama',
            distanceMeters: 180,
            actionType: RouteActionType.straight,
            latitude: -6.8905,
            longitude: 107.6095),
        const RouteStep(
            id: '3',
            instruction: 'Belok kanan setelah minimarket.',
            landmarkName: 'Minimarket kampus',
            distanceMeters: 90,
            actionType: RouteActionType.turnRight,
            latitude: -6.8910,
            longitude: 107.6100,
            shouldTriggerHaptic: true),
        const RouteStep(
            id: '4',
            instruction: 'Lanjutkan melewati gedung perpustakaan.',
            landmarkName: 'Perpustakaan Pusat',
            distanceMeters: 220,
            actionType: RouteActionType.straight,
            latitude: -6.8920,
            longitude: 107.6107),
        const RouteStep(
            id: '5',
            instruction: 'Seberang di dekat jalur pejalan kaki.',
            landmarkName: 'Jalur penyeberangan',
            distanceMeters: 80,
            actionType: RouteActionType.cross,
            latitude: -6.8925,
            longitude: 107.6110,
            shouldTriggerHaptic: true),
        RouteStep(
            id: '6',
            instruction: 'Tujuan Anda berada di sisi kiri.',
            landmarkName: destination.name,
            distanceMeters: 0,
            actionType: RouteActionType.arrive,
            latitude: destination.latitude,
            longitude: destination.longitude,
            shouldTriggerHaptic: true),
      ],
    );
