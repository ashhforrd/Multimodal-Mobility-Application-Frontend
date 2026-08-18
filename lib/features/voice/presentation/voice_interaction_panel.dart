import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/voice_controller.dart';
import '../../navigation/application/navigation_controller.dart';

class VoiceInteractionPanel extends ConsumerStatefulWidget {
  const VoiceInteractionPanel({super.key});
  @override
  ConsumerState<VoiceInteractionPanel> createState() =>
      _VoiceInteractionPanelState();
}

class _VoiceInteractionPanelState extends ConsumerState<VoiceInteractionPanel> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(voiceProvider);
    if (controller.text != voice.transcript && voice.isListening) {
      controller.text = voice.transcript;
      controller.selection =
          TextSelection.collapsed(offset: controller.text.length);
    }
    return SafeArea(
        child: SingleChildScrollView(
            padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 20 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Text('Bantuan suara',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close))
                  ]),
                  Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        Icon(voice.isListening
                            ? Icons.graphic_eq
                            : Icons.mic_none),
                        const SizedBox(width: 10),
                        Text(voice.isListening
                            ? 'Aplikasi sedang mendengarkan'
                            : 'Tekan mikrofon atau ketik pertanyaan')
                      ])),
                  const SizedBox(height: 14),
                  TextField(
                      controller: controller,
                      onChanged: ref.read(voiceProvider.notifier).setTranscript,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                          labelText: 'Pertanyaan Anda',
                          hintText: 'Contoh: Saya harus belok di mana?')),
                  if (voice.errorMessage != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(voice.errorMessage!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error))),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                      onPressed: () =>
                          ref.read(voiceProvider.notifier).toggleListening(),
                      icon: Icon(voice.isListening ? Icons.stop : Icons.mic),
                      label: Text(voice.isListening
                          ? 'Berhenti mendengarkan'
                          : 'Mulai mendengarkan')),
                  FilledButton(
                      onPressed: voice.isProcessing
                          ? null
                          : () => ref.read(voiceProvider.notifier).submit(),
                      child: Text(voice.isProcessing
                          ? 'Memproses…'
                          : 'Kirim pertanyaan')),
                  if (voice.appResponse.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Jawaban aplikasi',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(voice.appResponse)
                                ]))),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                        onPressed: () {
                          ref
                              .read(navigationProvider.notifier)
                              .useInstruction(voice.appResponse);
                          Navigator.pop(context);
                        },
                        child: const Text('Gunakan arahan'))
                  ]
                ])));
  }
}
