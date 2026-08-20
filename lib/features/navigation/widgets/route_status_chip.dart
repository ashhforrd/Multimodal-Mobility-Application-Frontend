import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../application/navigation_state.dart';

class RouteStatusChip extends StatelessWidget {
  const RouteStatusChip({super.key, required this.status});
  final RouteStatus status;
  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      RouteStatus.idle => 'Belum ada rute',
      RouteStatus.preview => 'Pratinjau rute',
      RouteStatus.active => 'Di dalam rute',
      RouteStatus.approachingActionPoint => 'Mendekati titik aksi',
      RouteStatus.offRoute => 'Keluar dari rute',
      RouteStatus.recovering => 'Memulihkan rute',
      RouteStatus.completed => 'Tiba di tujuan',
    };
    final isWarning = status == RouteStatus.offRoute;
    return Chip(
      backgroundColor:
          isWarning ? const Color(0xFFFFF3E2) : const Color(0xFFEAF2FF),
      side: BorderSide.none,
      avatar: Icon(
        isWarning ? LucideIcons.triangleAlert : LucideIcons.navigation,
        color: isWarning ? const Color(0xFFB45309) : AppTheme.primary,
        size: 17,
      ),
      label: Text(label),
    );
  }
}
