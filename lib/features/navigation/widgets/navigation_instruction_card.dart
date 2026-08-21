import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/route_step.dart';

class NavigationInstructionCard extends StatelessWidget {
  const NavigationInstructionCard(
      {super.key,
      required this.instruction,
      required this.landmark,
      required this.distance,
      required this.actionType});
  final String instruction, landmark;
  final int distance;
  final RouteActionType actionType;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _iconFor(actionType),
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                          position: Tween(
                                  begin: const Offset(0, .12), end: Offset.zero)
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
              ),
            ],
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

  IconData _iconFor(RouteActionType action) => switch (action) {
        RouteActionType.slightLeft => LucideIcons.moveUpLeft,
        RouteActionType.slightRight => LucideIcons.moveUpRight,
        RouteActionType.turnLeft ||
        RouteActionType.sharpLeft =>
          LucideIcons.cornerUpLeft,
        RouteActionType.turnRight ||
        RouteActionType.sharpRight =>
          LucideIcons.cornerUpRight,
        RouteActionType.uTurn => LucideIcons.undo2,
        RouteActionType.cross => LucideIcons.signpost,
        RouteActionType.arrive => LucideIcons.flag,
        _ => LucideIcons.arrowUp,
      };
}
