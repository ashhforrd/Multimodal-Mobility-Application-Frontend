import 'package:flutter/material.dart';
import '../application/navigation_state.dart';

class RouteStatusChip extends StatelessWidget {
  const RouteStatusChip({super.key, required this.status});
  final RouteStatus status;
  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      RouteStatus.active => 'Di dalam rute',
      RouteStatus.approachingActionPoint => 'Mendekati titik aksi',
      RouteStatus.offRoute => 'Keluar dari rute',
      RouteStatus.completed => 'Tiba di tujuan',
      _ => 'Siap bernavigasi'
    };
    return Chip(
        avatar: Icon(
            status == RouteStatus.offRoute
                ? Icons.warning_amber
                : Icons.navigation,
            size: 18),
        label: Text(label));
  }
}
