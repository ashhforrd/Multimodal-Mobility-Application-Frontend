import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/destination.dart';
import '../../../data/models/geo_point.dart';
import '../../../shared/widgets/navigation_map.dart';
import '../application/navigation_controller.dart';

final _originPlaceProvider =
    FutureProvider.autoDispose.family<Destination, GeoPoint>(
  (ref, point) => ref.watch(mapServiceProvider).reverseGeocode(point),
);

class RoutePreviewScreen extends ConsumerWidget {
  const RoutePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigation = ref.watch(navigationProvider);
    final route = navigation.currentRoute;
    if (route == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pratinjau rute')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Rute belum tersedia. Pilih tujuan terlebih dahulu.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(LucideIcons.house, size: 18),
                  label: const Text('Kembali ke beranda'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final originPlace = ref.watch(_originPlaceProvider(route.origin));
    final originCoordinates = '${route.origin.latitude.toStringAsFixed(5)}, '
        '${route.origin.longitude.toStringAsFixed(5)}';
    final originName = originPlace.when(
      data: (place) => place.name,
      loading: () => 'Lokasi saat ini',
      error: (_, __) => 'Lokasi saat ini',
    );
    final originAddress = originPlace.when(
      data: (place) => place.address,
      loading: () => 'Mengenali lokasi…',
      error: (_, __) => originCoordinates,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Pratinjau rute')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            NavigationMap(
              route: route,
              currentPosition: navigation.currentPosition,
              destination: route.destination,
              height: 260,
            ),
            const SizedBox(height: 20),
            _RouteEndpoints(
              originName: originName,
              originAddress: originAddress,
              destination: route.destination,
            ),
            const SizedBox(height: 18),
            Row(children: [
              _Metric(
                icon: LucideIcons.clock3,
                value: '${route.estimatedTimeMinutes} menit',
                label: 'Waktu',
              ),
              const SizedBox(width: 10),
              _Metric(
                icon: LucideIcons.ruler,
                value: '${route.totalDistanceMeters} m',
                label: 'Jarak',
              ),
              const SizedBox(width: 10),
              _Metric(
                icon: LucideIcons.signpost,
                value:
                    '${route.steps.where((step) => step.shouldTriggerHaptic).length}',
                label: 'Titik aksi',
              ),
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.deepBlue, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2B1769E0),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Arah awal',
                    style: TextStyle(
                      color: Color(0xFFCFE3FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    route.steps.first.instruction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      letterSpacing: -.46,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    const Icon(
                      LucideIcons.landmark,
                      color: Colors.white,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Landmark awal: ${route.steps.first.landmarkName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.shieldAlert,
                      color: AppTheme.primary,
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rute ini memakai data pejalan kaki OpenStreetMap. '
                        'Tetap perhatikan trotoar, penyeberangan, dan kondisi sekitar.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () {
                ref
                    .read(navigationProvider.notifier)
                    .clearDestinationSelection();
                if (context.canPop()) {
                  context.pop(true);
                } else {
                  context.go('/');
                }
              },
              icon: const Icon(LucideIcons.mapPin, size: 18),
              label: const Text('Ubah tujuan'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () {
                final controller = ref.read(navigationProvider.notifier);
                context.go('/navigation');
                unawaited(controller.start());
              },
              icon: const Icon(LucideIcons.navigation, size: 18),
              label: const Text('Mulai navigasi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteEndpoints extends StatelessWidget {
  const _RouteEndpoints({
    required this.originName,
    required this.originAddress,
    required this.destination,
  });

  final String originName;
  final String originAddress;
  final Destination destination;

  @override
  Widget build(BuildContext context) => Card(
        key: const Key('route-endpoints'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan perjalanan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _Endpoint(
                icon: LucideIcons.locateFixed,
                label: 'Titik awal',
                name: originName,
                address: originAddress,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: SizedBox(
                  height: 22,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 2,
                    color: Color(0xFFB8CDED),
                  ),
                ),
              ),
              _Endpoint(
                icon: LucideIcons.mapPin,
                label: 'Tujuan',
                name: destination.name,
                address: destination.address,
              ),
            ],
          ),
        ),
      );
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.icon,
    required this.label,
    required this.name,
    required this.address,
  });

  final IconData icon;
  final String label;
  final String name;
  final String address;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(address),
              ],
            ),
          ),
        ],
      );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(children: [
              Icon(icon, color: AppTheme.primary, size: 20),
              const SizedBox(height: 7),
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: -.24,
                ),
              ),
            ]),
          ),
        ),
      );
}
