import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/navigation_map.dart';
import '../application/navigation_controller.dart';

class RoutePreviewScreen extends ConsumerWidget {
  const RoutePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigation = ref.watch(navigationProvider);
    final route = navigation.currentRoute;
    if (route == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Rute belum tersedia. Pilih tujuan terlebih dahulu.'),
        ),
      );
    }

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.mapPin,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.destination.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(route.destination.address),
                    ],
                  ),
                ),
              ],
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
              onPressed: () => context.go('/'),
              icon: const Icon(LucideIcons.mapPin, size: 18),
              label: const Text('Ubah tujuan'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () async {
                await ref.read(navigationProvider.notifier).start();
                if (context.mounted) context.go('/navigation');
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
