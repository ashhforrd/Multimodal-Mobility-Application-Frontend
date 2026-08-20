import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../application/navigation_controller.dart';

class ManualFeedbackActions extends ConsumerWidget {
  const ManualFeedbackActions({
    required this.onRecoveryRequested,
    super.key,
  });

  final Future<void> Function() onRecoveryRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    void close() => Navigator.pop(context);
    return SafeArea(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Text('Bantuan',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Tutup bantuan',
                      onPressed: close,
                      icon: const Icon(LucideIcons.x),
                    )
                  ]),
                  const SizedBox(height: 4),
                  _Action('Ulangi instruksi', () {
                    ref
                        .read(navigationProvider.notifier)
                        .speakActiveInstruction();
                    close();
                  }),
                  const Divider(height: 1),
                  _Action('Dengarkan instruksi berikutnya', () {
                    final next = nav.nextStep?.instruction ??
                        'Anda sudah di langkah terakhir.';
                    ref.read(ttsProvider).speak(next);
                    close();
                  }),
                  const Divider(height: 1),
                  _Action('Saya bingung', () {
                    final text =
                        'Cari ${nav.activeStep?.landmarkName}. ${nav.activeInstruction}';
                    ref.read(navigationProvider.notifier).useInstruction(text);
                    ref.read(ttsProvider).speak(text);
                    close();
                  }),
                  const Divider(height: 1),
                  _Action('Pulihkan rute', () async {
                    close();
                    await onRecoveryRequested();
                  })
                ])));
  }
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        minTileHeight: 52,
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        title: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
}
