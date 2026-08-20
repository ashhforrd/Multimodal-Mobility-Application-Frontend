import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

class NavigationInstructionCard extends StatelessWidget {
  const NavigationInstructionCard(
      {super.key,
      required this.instruction,
      required this.landmark,
      required this.distance});
  final String instruction, landmark;
  final int distance;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppTheme.deepBlue, AppTheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x331769E0), blurRadius: 24, offset: Offset(0, 12))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(LucideIcons.navigation,
                color: Color(0xFFCFE3FF), size: 17),
            const SizedBox(width: 8),
            const Text('Instruksi saat ini',
                style: TextStyle(
                    color: Color(0xFFCFE3FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.22)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('$distance m',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                    position:
                        Tween(begin: const Offset(0, .12), end: Offset.zero)
                            .animate(animation),
                    child: child)),
            child: Text(instruction,
                key: ValueKey(instruction),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    height: 1.18,
                    letterSpacing: -.48)),
          ),
          const SizedBox(height: 18),
          Row(children: [
            const Icon(LucideIcons.landmark, color: Colors.white, size: 18),
            const SizedBox(width: 9),
            Expanded(
                child: Text(landmark,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500))),
          ]),
        ]),
      );
}
