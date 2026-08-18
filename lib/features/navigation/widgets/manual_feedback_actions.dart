import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/navigation_controller.dart';

class ManualFeedbackActions extends ConsumerWidget {
  const ManualFeedbackActions({super.key});
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
                    IconButton(onPressed: close, icon: const Icon(Icons.close))
                  ]),
                  _Action(Icons.replay, 'Ulangi instruksi', () {
                    ref.read(navigationProvider.notifier).speakActive();
                    close();
                  }),
                  _Action(Icons.skip_next, 'Instruksi berikutnya', () {
                    final next = nav.nextStep?.instruction ??
                        'Anda sudah di langkah terakhir.';
                    ref.read(ttsProvider).speak(next);
                    close();
                  }),
                  _Action(Icons.help_outline, 'Saya bingung', () {
                    final text =
                        'Cari ${nav.activeStep?.landmarkName}. ${nav.activeInstruction}';
                    ref.read(navigationProvider.notifier).useInstruction(text);
                    ref.read(ttsProvider).speak(text);
                    close();
                  }),
                  _Action(Icons.route, 'Bantu kembali ke rute', () {
                    close();
                    ref.read(navigationProvider.notifier).offRoute();
                    context.push('/recovery');
                  })
                ])));
  }
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
      onTap: onTap,
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right));
}
