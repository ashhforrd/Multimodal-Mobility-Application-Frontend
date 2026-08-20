import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../navigation/application/navigation_controller.dart';
import '../application/voice_controller.dart';

class VoiceInteractionPanel extends ConsumerStatefulWidget {
  const VoiceInteractionPanel({super.key});

  @override
  ConsumerState<VoiceInteractionPanel> createState() =>
      _VoiceInteractionPanelState();
}

class _VoiceInteractionPanelState extends ConsumerState<VoiceInteractionPanel> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(voiceProvider.notifier).clear();
      await ref.read(voiceProvider.notifier).toggleListening();
    });
  }

  @override
  void dispose() {
    final voice = ref.read(voiceProvider);
    if (voice.isListening) {
      ref.read(voiceProvider.notifier).toggleListening();
    }
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(voiceProvider);
    if (_textController.text != voice.transcript && voice.isListening) {
      _textController
        ..text = voice.transcript
        ..selection = TextSelection.collapsed(offset: voice.transcript.length);
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text(
                'Bantuan suara',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Tutup bantuan suara',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x),
              ),
            ]),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: voice.isListening
                    ? const Color(0xFFEAF2FF)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Icon(
                  voice.isListening ? LucideIcons.audioLines : LucideIcons.mic,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    voice.isListening
                        ? 'Aplikasi sedang mendengarkan…'
                        : 'Mikrofon dijeda. Anda tetap dapat mengetik.',
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            if (voice.transcript.isNotEmpty)
              _ConversationBubble(
                label: 'Pertanyaan Anda',
                text: voice.transcript,
                alignment: Alignment.centerRight,
                color: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            if (voice.appResponse.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ConversationBubble(
                label: 'Jawaban aplikasi',
                text: voice.appResponse,
                alignment: Alignment.centerLeft,
                color: const Color(0xFFEAF2FF),
                foregroundColor: AppTheme.ink,
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              onChanged: ref.read(voiceProvider.notifier).setTranscript,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Pertanyaan Anda',
                hintText: 'Contoh: Saya harus belok di mana?',
              ),
            ),
            if (voice.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  voice.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () =>
                  ref.read(voiceProvider.notifier).toggleListening(),
              icon: Icon(
                voice.isListening ? LucideIcons.square : LucideIcons.mic,
                size: 18,
              ),
              label: Text(
                voice.isListening
                    ? 'Berhenti mendengarkan'
                    : 'Mulai mendengarkan',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: voice.isProcessing
                  ? null
                  : () => ref.read(voiceProvider.notifier).submit(),
              icon: const Icon(LucideIcons.send, size: 18),
              label: Text(
                voice.isProcessing ? 'Memproses…' : 'Kirim pertanyaan',
              ),
            ),
            if (voice.appResponse.isNotEmpty) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: _applyResponse,
                icon: Icon(
                  voice.shouldOpenRecovery
                      ? LucideIcons.route
                      : LucideIcons.check,
                  size: 18,
                ),
                label: Text(
                  voice.shouldOpenRecovery
                      ? 'Buka pemulihan rute'
                      : 'Gunakan arahan',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _applyResponse() {
    final voice = ref.read(voiceProvider);
    ref.read(voiceProvider.notifier).applyResponse();
    Navigator.pop(context);
    if (voice.shouldOpenRecovery) {
      ref.read(navigationProvider.notifier).markOffRoute();
    }
  }
}

class _ConversationBubble extends StatelessWidget {
  const _ConversationBubble({
    required this.label,
    required this.text,
    required this.alignment,
    required this.color,
    required this.foregroundColor,
  });

  final String label;
  final String text;
  final Alignment alignment;
  final Color color;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) => Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: foregroundColor.withValues(alpha: .75),
                      fontSize: 11,
                      letterSpacing: -.22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(text, style: TextStyle(color: foregroundColor)),
                ],
              ),
            ),
          ),
        ),
      );
}
