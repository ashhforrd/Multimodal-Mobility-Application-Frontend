import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../shared/widgets/mock_map.dart';
import '../application/recovery_controller.dart';

class RouteRecoveryView extends ConsumerStatefulWidget {
  const RouteRecoveryView({super.key});
  @override
  ConsumerState<RouteRecoveryView> createState() => _RouteRecoveryViewState();
}

class _RouteRecoveryViewState extends ConsumerState<RouteRecoveryView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(recoveryProvider.notifier).enter());
  }

  @override
  Widget build(BuildContext context) {
    final recovery = ref.watch(recoveryProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Pemulihan rute')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(18)),
              child: const Row(children: [
                Icon(LucideIcons.triangleAlert, size: 34),
                SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Anda keluar dari rute',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 19)),
                      Text('Tetap tenang. Ikuti arahan pemulihan.')
                    ]))
              ])),
          const SizedBox(height: 16),
          const MockMap(recovery: true),
          const SizedBox(height: 16),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ikuti arahan pemulihan',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(recovery.recoveryInstruction,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 21)),
                        const SizedBox(height: 8),
                        Text(
                            'Rute dihitung ulang ${recovery.recalculationCount} kali')
                      ]))),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
              onPressed: () => ref.read(recoveryProvider.notifier).speak(),
              icon: const Icon(LucideIcons.volume2),
              label: const Text('Dengarkan arahan')),
          FilledButton.tonalIcon(
              onPressed: () =>
                  ref.read(recoveryProvider.notifier).recalculate(),
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Hitung ulang rute')),
          const SizedBox(height: 6),
          FilledButton.icon(
              onPressed: () {
                ref.read(recoveryProvider.notifier).finish();
                context.go('/navigation');
              },
              icon: const Icon(LucideIcons.navigation),
              label: const Text('Kembali ke navigasi'))
        ]));
  }
}
