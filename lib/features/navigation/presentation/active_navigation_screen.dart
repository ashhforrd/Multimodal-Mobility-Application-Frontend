import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_entrance.dart';
import '../../../shared/widgets/auto_closing_dialog.dart';
import '../../../shared/widgets/navigation_map.dart';
import '../../voice/presentation/voice_interaction_panel.dart';
import '../application/navigation_controller.dart';
import '../application/navigation_state.dart';
import '../widgets/action_point_alert.dart';
import '../widgets/manual_feedback_actions.dart';
import '../widgets/navigation_instruction_card.dart';
import '../widgets/route_status_chip.dart';

class ActiveNavigationScreen extends ConsumerStatefulWidget {
  const ActiveNavigationScreen({super.key});

  @override
  ConsumerState<ActiveNavigationScreen> createState() =>
      _ActiveNavigationScreenState();
}

class _ActiveNavigationScreenState
    extends ConsumerState<ActiveNavigationScreen> {
  bool _dialogVisible = false;
  bool _arrivalDialogVisible = false;
  bool _openingRecovery = false;

  Future<void> _openSheet(Widget child) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => child,
      );

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      navigationProvider.select((state) => state.isActionAlertVisible),
      (_, visible) {
        if (visible && !_dialogVisible) _showActionAlert();
      },
    );
    ref.listen<RouteStatus>(
      navigationProvider.select((state) => state.routeStatus),
      (_, status) {
        if (status == RouteStatus.offRoute && !_openingRecovery) {
          _openRecovery();
        } else if (status == RouteStatus.completed && !_arrivalDialogVisible) {
          _showArrivalAlert();
        }
      },
    );

    final navigation = ref.watch(navigationProvider);
    final route = navigation.currentRoute;
    if (route == null) {
      return const Scaffold(
        body: Center(child: Text('Pilih rute terlebih dahulu.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigasi aktif'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: RouteStatusChip(status: navigation.routeStatus),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            AppEntrance(
              child: NavigationMap(
                key: const Key('active-navigation-map'),
                route: route,
                currentPosition: navigation.currentPosition,
                destination: route.destination,
                height: 250,
                followUser: true,
              ),
            ),
            const SizedBox(height: 14),
            AppEntrance(
              delay: const Duration(milliseconds: 50),
              child: _JourneySummary(
                remainingDistanceMeters: navigation.remainingDistanceMeters,
                estimatedMinutes: navigation.estimatedRemainingMinutes,
              ),
            ),
            const SizedBox(height: 12),
            AppEntrance(
              delay: const Duration(milliseconds: 100),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(.03, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: NavigationInstructionCard(
                  key: ValueKey(navigation.activeInstruction),
                  instruction: navigation.activeInstruction,
                  landmark: navigation.activeStep!.landmarkName,
                  distance: navigation.distanceToNextActionPoint,
                  actionType: navigation.activeStep!.actionType,
                ),
              ),
            ),
            const SizedBox(height: 10),
            AppEntrance(
              delay: const Duration(milliseconds: 150),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      LucideIcons.signpost,
                      color: AppTheme.primary,
                      size: 21,
                    ),
                  ),
                  title: const Text('Instruksi berikutnya'),
                  subtitle: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      navigation.nextStep?.instruction ??
                          'Anda telah mencapai tujuan.',
                      key: ValueKey(navigation.nextStep?.id),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppEntrance(
              delay: const Duration(milliseconds: 200),
              child: Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openSheet(const VoiceInteractionPanel()),
                    icon: const Icon(LucideIcons.mic, size: 19),
                    label: const Text('Tanyakan arah'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _openManualFeedback,
                    icon: const Icon(LucideIcons.lifeBuoy, size: 19),
                    label: const Text('Buka bantuan'),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            AppEntrance(
              delay: const Duration(milliseconds: 250),
              child: FilledButton.tonalIcon(
                key: const Key('finish-journey-action'),
                onPressed: _confirmFinishJourney,
                icon: const Icon(LucideIcons.flag, size: 19),
                label: const Text('Selesai perjalanan'),
              ),
            ),
            if (kShowDemoControls) ...[
              const SizedBox(height: 22),
              const Text(
                'Kontrol demonstrasi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ActionChip(
                  avatar: const Icon(LucideIcons.stepForward, size: 18),
                  label: const Text('Lanjutkan satu langkah'),
                  onPressed: () =>
                      ref.read(navigationProvider.notifier).nextStep(),
                ),
                ActionChip(
                  avatar: const Icon(LucideIcons.vibrate, size: 18),
                  label: const Text('Picu peringatan'),
                  onPressed: () =>
                      ref.read(navigationProvider.notifier).showActionAlert(),
                ),
                ActionChip(
                  avatar: const Icon(LucideIcons.mapPinOff, size: 18),
                  label: const Text('Simulasikan keluar dari rute'),
                  onPressed: () =>
                      ref.read(navigationProvider.notifier).markOffRoute(),
                ),
                ActionChip(
                  avatar: const Icon(LucideIcons.rotateCcw, size: 18),
                  label: const Text('Atur ulang rute'),
                  onPressed: () =>
                      ref.read(navigationProvider.notifier).reset(),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showActionAlert() async {
    _dialogVisible = true;
    try {
      await showAutoClosingDialog<void>(
        context: context,
        duration: kNavigationDialogAutoCloseDuration,
        onAutoClose: () => ref.read(navigationProvider.notifier).dismissAlert(),
        builder: (_) => const ActionPointAlert(),
      );
    } finally {
      _dialogVisible = false;
    }
  }

  Future<void> _openRecovery() async {
    _openingRecovery = true;
    try {
      await context.push('/recovery');
    } finally {
      _openingRecovery = false;
    }
  }

  Future<void> _showArrivalAlert() async {
    _arrivalDialogVisible = true;
    try {
      await showAutoClosingDialog<void>(
        context: context,
        duration: kNavigationDialogAutoCloseDuration,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              LucideIcons.badgeCheck,
              color: AppTheme.primary,
              size: 34,
            ),
            title: const Text('Tujuan tercapai'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Anda sudah berada dalam jarak 5 meter dari tujuan.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Dialog ditutup otomatis dalam 5 detik.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Selesai'),
              ),
            ],
          );
        },
      );
    } finally {
      _arrivalDialogVisible = false;
    }
    if (mounted &&
        ref.read(navigationProvider).routeStatus == RouteStatus.completed) {
      await _finishJourney();
    }
  }

  Future<void> _openManualFeedback() => _openSheet(
        ManualFeedbackActions(onRecoveryRequested: _requestRecovery),
      );

  Future<void> _requestRecovery() async {
    await ref.read(navigationProvider.notifier).markOffRoute();
    if (!mounted || _openingRecovery) return;
    await _openRecovery();
  }

  Future<void> _confirmFinishJourney() => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            LucideIcons.flag,
            color: AppTheme.primary,
            size: 28,
          ),
          title: const Text('Selesaikan perjalanan?'),
          content: const Text(
            'Konfirmasi jika Anda sudah tiba atau ingin menghentikan navigasi.',
          ),
          actions: [
            FilledButton.tonal(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _finishJourney();
              },
              child: const Text('Ya, selesai'),
            ),
          ],
        ),
      );

  Future<void> _finishJourney() async {
    final completion = ref.read(navigationProvider.notifier).finishJourney();
    if (mounted) context.go('/');
    await completion;
  }
}

class _JourneySummary extends StatelessWidget {
  const _JourneySummary({
    required this.remainingDistanceMeters,
    required this.estimatedMinutes,
  });

  final int remainingDistanceMeters;
  final int estimatedMinutes;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: _SummaryItem(
            icon: LucideIcons.route,
            label: 'Jarak tersisa',
            value: '$remainingDistanceMeters m',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryItem(
            icon: LucideIcons.clock3,
            label: 'Estimasi tiba',
            value: '$estimatedMinutes menit',
          ),
        ),
      ]);
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Icon(icon, color: AppTheme.primary, size: 19),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: -.22,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      );
}
