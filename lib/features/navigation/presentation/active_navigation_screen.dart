import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mock_map.dart';
import '../../voice/presentation/voice_interaction_panel.dart';
import '../application/navigation_controller.dart';
import '../widgets/action_point_alert.dart';
import '../widgets/manual_feedback_actions.dart';
import '../widgets/navigation_instruction_card.dart';
import '../widgets/route_status_chip.dart';

class ActiveNavigationScreen extends ConsumerWidget {
  const ActiveNavigationScreen({super.key});
  Future<void> _sheet(BuildContext c, Widget child) => showModalBottomSheet(
      context: c,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => child);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    if (nav.currentRoute == null) {
      return const Scaffold(
          body: Center(child: Text('Pilih rute terlebih dahulu.')));
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Navigasi aktif'), actions: [
          Padding(
              padding: const EdgeInsets.only(right: 12),
              child: RouteStatusChip(status: nav.routeStatus))
        ]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const MockMap(height: 230),
          const SizedBox(height: 14),
          AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: NavigationInstructionCard(
                  key: ValueKey(nav.activeInstruction),
                  instruction: nav.activeInstruction,
                  landmark: nav.activeStep!.landmarkName,
                  distance: nav.distanceToNextActionPoint)),
          const SizedBox(height: 10),
          Card(
              child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FF),
                          borderRadius: BorderRadius.circular(14)),
                      child: const Icon(LucideIcons.signpost,
                          color: AppTheme.primary, size: 21)),
                  title: const Text('Instruksi berikutnya'),
                  subtitle: Text(nav.nextStep?.instruction ??
                      'Anda telah mencapai tujuan.'))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: FilledButton.icon(
                    onPressed: () =>
                        _sheet(context, const VoiceInteractionPanel()),
                    icon: const Icon(LucideIcons.mic, size: 19),
                    label: const Text('Tanyakan arah'))),
            const SizedBox(width: 10),
            Expanded(
                child: FilledButton.tonalIcon(
                    onPressed: () =>
                        _sheet(context, const ManualFeedbackActions()),
                    icon: const Icon(LucideIcons.lifeBuoy, size: 19),
                    label: const Text('Buka bantuan')))
          ]),
          if (kShowDemoControls) ...[
            const SizedBox(height: 22),
            const Text('Kontrol demonstrasi',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ActionChip(
                  avatar: const Icon(LucideIcons.stepForward, size: 18),
                  label: const Text('Lanjutkan satu langkah'),
                  onPressed: () =>
                      ref.read(navigationProvider.notifier).nextStep()),
              ActionChip(
                  avatar: const Icon(LucideIcons.vibrate, size: 18),
                  label: const Text('Picu peringatan'),
                  onPressed: () async {
                    await ref
                        .read(navigationProvider.notifier)
                        .showActionAlert();
                    if (context.mounted) {
                      showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const ActionPointAlert());
                    }
                  }),
              ActionChip(
                  avatar: const Icon(LucideIcons.mapPinOff, size: 18),
                  label: const Text('Simulasikan keluar dari rute'),
                  onPressed: () async {
                    await ref.read(navigationProvider.notifier).offRoute();
                    if (context.mounted) context.push('/recovery');
                  }),
              ActionChip(
                  avatar: const Icon(LucideIcons.rotateCcw, size: 18),
                  label: const Text('Atur ulang rute'),
                  onPressed: () =>
                      ref.read(navigationProvider.notifier).reset())
            ])
          ]
        ]));
  }
}
