import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/navigation_map.dart';
import '../../navigation/application/navigation_controller.dart';
import '../../navigation/application/navigation_state.dart';
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
    ref.listen<RouteStatus>(
      navigationProvider.select((state) => state.routeStatus),
      (previous, next) {
        if (previous == RouteStatus.recovering && next == RouteStatus.active) {
          Navigator.of(context).maybePop();
        }
      },
    );
    final recovery = ref.watch(recoveryProvider);
    final navigation = ref.watch(navigationProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pemulihan rute')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(children: [
                Icon(
                  LucideIcons.triangleAlert,
                  size: 32,
                  color: Color(0xFFB45309),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anda keluar dari rute',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 19,
                          letterSpacing: -.38,
                          color: AppTheme.ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text('Tetap tenang dan ikuti arahan pemulihan.'),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            NavigationMap(
              key: const Key('recovery-navigation-map'),
              route: navigation.currentRoute,
              currentPosition: navigation.currentPosition,
              destination: navigation.selectedDestination,
              recoveryPoints: recovery.recoveryPoints,
              height: 280,
              followUser: true,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(
                        LucideIcons.route,
                        color: AppTheme.primary,
                        size: 19,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Ikuti arahan pemulihan',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        recovery.recoveryInstruction,
                        key: ValueKey(recovery.recoveryInstruction),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 21,
                          letterSpacing: -.42,
                          height: 1.25,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    if (recovery.recalculationCount > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Rute telah dihitung ulang ${recovery.recalculationCount} kali.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (recovery.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                recovery.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => ref.read(recoveryProvider.notifier).speak(),
              icon: const Icon(LucideIcons.volume2),
              label: const Text('Dengarkan arahan'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('recalculate-recovery-route'),
              onPressed: recovery.isRecalculating
                  ? null
                  : () => ref.read(recoveryProvider.notifier).recalculate(),
              icon: const Icon(LucideIcons.refreshCw),
              label: Text(
                recovery.isRecalculating
                    ? 'Menghitung ulang…'
                    : 'Perbarui rute navigasi',
              ),
            ),
            if (kShowDemoControls) ...[
              const SizedBox(height: 18),
              Center(
                child: ActionChip(
                  avatar: const Icon(LucideIcons.badgeCheck, size: 18),
                  label: const Text('Simulasikan kembali ke rute'),
                  onPressed: () => ref.read(recoveryProvider.notifier).finish(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
