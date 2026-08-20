import 'dart:async';

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
  late final VoiceController _voiceController;

  @override
  void initState() {
    super.initState();
    _voiceController = ref.read(voiceProvider.notifier);
    Future.microtask(() async {
      await _voiceController.clear();
      if (!mounted) return;
      await _voiceController.startContinuousConversation();
    });
  }

  @override
  void dispose() {
    unawaited(
      _voiceController.stopContinuousConversation(updateState: false),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(voiceProvider);
    final displayedQuestion =
        voice.transcript.isNotEmpty ? voice.transcript : voice.lastQuestion;

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
                  voice.isSpeaking
                      ? LucideIcons.volume2
                      : voice.isListening
                          ? LucideIcons.audioLines
                          : LucideIcons.mic,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    voice.isSpeaking
                        ? 'Jawaban sedang dibacakan. Mikrofon akan aktif kembali setelah audio selesai.'
                        : voice.isListening
                            ? 'Sedang mendengarkan. Pertanyaan dikirim otomatis setelah Anda selesai bicara.'
                            : voice.isProcessing
                                ? 'Pertanyaan sedang diproses…'
                                : voice.isConversationActive
                                    ? 'Menyiapkan mikrofon…'
                                    : 'Sesi bantuan suara tidak aktif.',
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            if (displayedQuestion.isNotEmpty)
              _ConversationBubble(
                label: 'Pertanyaan Anda',
                text: displayedQuestion,
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
            if (voice.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  voice.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
