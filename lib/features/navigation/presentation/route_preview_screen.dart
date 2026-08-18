import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../shared/widgets/mock_map.dart';
import '../application/navigation_controller.dart';

class RoutePreviewScreen extends ConsumerWidget {
  const RoutePreviewScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    final route = nav.currentRoute;
    if (route == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(
              child:
                  Text('Rute belum tersedia. Pilih tujuan terlebih dahulu.')));
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Pratinjau rute')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const MockMap(),
          const SizedBox(height: 18),
          Text(route.destination.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(route.destination.address),
          const SizedBox(height: 16),
          Row(children: [
            _Metric(
                icon: LucideIcons.clock3,
                value: '${route.estimatedTimeMinutes} menit',
                label: 'Waktu'),
            const SizedBox(width: 10),
            _Metric(
                icon: LucideIcons.ruler,
                value: '${route.totalDistanceMeters} m',
                label: 'Jarak'),
            const SizedBox(width: 10),
            _Metric(
                icon: LucideIcons.signpost,
                value: '${route.steps.length}',
                label: 'Titik aksi')
          ]),
          const SizedBox(height: 18),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Arah awal',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(route.steps.first.instruction,
                            style: const TextStyle(fontSize: 18)),
                        const Divider(height: 28),
                        const Text('Landmark awal',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(route.steps.first.landmarkName)
                      ]))),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
              onPressed: () => context.pop(),
              icon: const Icon(LucideIcons.mapPin, size: 18),
              label: const Text('Ubah tujuan')),
          const SizedBox(height: 8),
          FilledButton.icon(
              onPressed: () {
                ref.read(navigationProvider.notifier).start();
                context.go('/navigation');
              },
              icon: const Icon(LucideIcons.navigation),
              label: const Text('Mulai navigasi'))
        ]));
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
      child: Card(
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(children: [
                Icon(icon),
                const SizedBox(height: 5),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(fontSize: 12))
              ]))));
}
