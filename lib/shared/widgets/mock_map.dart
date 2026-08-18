import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

class MockMap extends StatefulWidget {
  const MockMap({super.key, this.recovery = false, this.height = 230});
  final bool recovery;
  final double height;

  @override
  State<MockMap> createState() => _MockMapState();
}

class _MockMapState extends State<MockMap> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  static const _route = <LatLng>[
    LatLng(-6.8900, 107.6090),
    LatLng(-6.8905, 107.6095),
    LatLng(-6.8910, 107.6100),
    LatLng(-6.8920, 107.6107),
    LatLng(-6.8925, 107.6110),
    LatLng(-6.8931, 107.6120),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeColor =
        widget.recovery ? const Color(0xFFF59E0B) : AppTheme.primary;
    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A163B68), blurRadius: 24, offset: Offset(0, 10))
        ],
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(-6.8915, 107.6105),
              initialZoom: 16.2,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'id.ac.tugasakhir.langkah_sahabat',
              ),
              PolylineLayer(polylines: [
                Polyline(points: _route, color: Colors.white, strokeWidth: 10),
                Polyline(points: _route, color: routeColor, strokeWidth: 6),
              ]),
              MarkerLayer(markers: [
                Marker(
                  point: _route.first,
                  width: 48,
                  height: 48,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) => Transform.scale(
                        scale: .9 + (_pulse.value * .1), child: child),
                    child: Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withValues(alpha: .18)),
                      padding: const EdgeInsets.all(9),
                      child: Container(
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: AppTheme.primary),
                        child: const Icon(LucideIcons.navigation,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ),
                Marker(
                  point: _route.last,
                  width: 42,
                  height: 42,
                  child: Container(
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppTheme.deepBlue),
                    child: const Icon(LucideIcons.mapPin,
                        color: Colors.white, size: 20),
                  ),
                ),
              ]),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors')
                ],
              ),
            ],
          ),
          Positioned(
              top: 14, left: 14, child: _MapBadge(recovery: widget.recovery)),
        ],
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.recovery});
  final bool recovery;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x1A163B68), blurRadius: 12)
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(recovery ? LucideIcons.route : LucideIcons.map,
                size: 15, color: AppTheme.primary),
            const SizedBox(width: 7),
            Text(
              recovery ? 'Rute pemulihan' : 'Peta interaktif',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.ink),
            ),
          ]),
        ),
      );
}
