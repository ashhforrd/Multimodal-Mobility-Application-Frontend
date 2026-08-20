import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../application/navigation_controller.dart';

class ActionPointAlert extends ConsumerWidget {
  const ActionPointAlert({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    return AlertDialog(
        icon: const Icon(LucideIcons.vibrate, size: 38),
        title: const Text('Mendekati titik aksi'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(nav.activeInstruction,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                letterSpacing: -.38,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
              '${nav.distanceToNextActionPoint} m • ${nav.activeStep?.landmarkName}'),
          const SizedBox(height: 8),
          const Chip(
              avatar: Icon(LucideIcons.vibrate, size: 16),
              label: Text('Getaran menandai tindakan penting'))
        ]),
        actions: [
          FilledButton.tonal(
              onPressed: () => ref
                  .read(navigationProvider.notifier)
                  .speakActiveInstruction(),
              child: const Text('Ulangi instruksi')),
          FilledButton(
              onPressed: () {
                ref.read(navigationProvider.notifier).dismissAlert();
                Navigator.pop(context);
              },
              child: const Text('Saya paham'))
        ]);
  }
}
