import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/destination.dart';
import '../../data/models/geo_point.dart';
import '../../data/models/navigation_route.dart';

class NavigationMap extends StatefulWidget {
  const NavigationMap({
    super.key,
    this.route,
    this.currentPosition,
    this.destination,
    this.recoveryPoints = const [],
    this.height = 230,
    this.selectable = false,
    this.onPointSelected,
  });

  final NavigationRoute? route;
  final GeoPoint? currentPosition;
  final Destination? destination;
  final List<GeoPoint> recoveryPoints;
  final double height;
  final bool selectable;
  final ValueChanged<GeoPoint>? onPointSelected;

  bool get isRecovery => recoveryPoints.isNotEmpty;

  @override
  State<NavigationMap> createState() => _NavigationMapState();
}

class _NavigationMapState extends State<NavigationMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routePoints = widget.route == null
        ? <LatLng>[]
        : widget.route!.geometry.isNotEmpty
            ? widget.route!.geometry.map(_latLng).toList()
            : [
                _latLng(widget.route!.origin),
                ...widget.route!.steps.map(
                  (step) => LatLng(step.latitude, step.longitude),
                ),
              ];
    final recoveryPoints = widget.recoveryPoints.map(_latLng).toList();
    final center = _centerFor(routePoints, recoveryPoints);
    final visiblePoints = [...routePoints, ...recoveryPoints];

    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A163B68),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          FlutterMap(
            key: ValueKey(
              '${widget.route?.id}-${widget.recoveryPoints.length}-'
              '${widget.recoveryPoints.isEmpty ? '' : widget.recoveryPoints.last.latitude}',
            ),
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16.2,
              initialCameraFit: visiblePoints.length > 1
                  ? CameraFit.coordinates(
                      coordinates: visiblePoints,
                      padding: const EdgeInsets.all(42),
                      maxZoom: 17,
                    )
                  : null,
              onTap: widget.selectable
                  ? (_, point) => widget.onPointSelected?.call(
                        GeoPoint(
                          latitude: point.latitude,
                          longitude: point.longitude,
                        ),
                      )
                  : null,
              interactionOptions: const InteractionOptions(
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
              if (routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: widget.isRecovery
                          ? const Color(0xFF94A3B8).withValues(alpha: .65)
                          : Colors.white,
                      strokeWidth: widget.isRecovery ? 5 : 10,
                    ),
                    if (!widget.isRecovery)
                      Polyline(
                        points: routePoints,
                        color: AppTheme.primary,
                        strokeWidth: 6,
                      ),
                  ],
                ),
              if (recoveryPoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: recoveryPoints,
                      color: Colors.white,
                      strokeWidth: 10,
                    ),
                    Polyline(
                      points: recoveryPoints,
                      color: const Color(0xFFF59E0B),
                      strokeWidth: 6,
                    ),
                  ],
                ),
              MarkerLayer(markers: _markers()),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _MapBadge(
              label: widget.selectable
                  ? 'Ketuk untuk memilih tujuan'
                  : widget.isRecovery
                      ? 'Rute pemulihan'
                      : 'Peta interaktif',
              icon: widget.selectable
                  ? LucideIcons.mapPinPlus
                  : widget.isRecovery
                      ? LucideIcons.route
                      : LucideIcons.map,
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _markers() {
    final markers = <Marker>[];
    final position = widget.currentPosition ?? widget.route?.origin;
    if (position != null) {
      markers.add(
        Marker(
          point: _latLng(position),
          width: 48,
          height: 48,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) => Transform.scale(
              scale: .9 + (_pulse.value * .1),
              child: child,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: .18),
              ),
              padding: const EdgeInsets.all(9),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                ),
                child: const Icon(
                  LucideIcons.navigation,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      );
    }
    final destination = widget.destination ?? widget.route?.destination;
    if (destination != null) {
      markers.add(
        Marker(
          point: LatLng(destination.latitude, destination.longitude),
          width: 42,
          height: 42,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.deepBlue,
            ),
            child: const Icon(
              LucideIcons.mapPin,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }
    if (widget.recoveryPoints.isNotEmpty) {
      markers.add(
        Marker(
          point: _latLng(widget.recoveryPoints.last),
          width: 42,
          height: 42,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF59E0B),
            ),
            child: const Icon(
              LucideIcons.flag,
              color: Colors.white,
              size: 19,
            ),
          ),
        ),
      );
    }
    return markers;
  }

  LatLng _centerFor(List<LatLng> route, List<LatLng> recovery) {
    final points = [...route, ...recovery];
    if (points.isEmpty && widget.currentPosition != null) {
      return _latLng(widget.currentPosition!);
    }
    if (points.isEmpty) return const LatLng(-6.8915, 107.6105);
    final latitude =
        points.fold<double>(0, (sum, point) => sum + point.latitude) /
            points.length;
    final longitude =
        points.fold<double>(0, (sum, point) => sum + point.longitude) /
            points.length;
    return LatLng(latitude, longitude);
  }

  LatLng _latLng(GeoPoint point) => LatLng(point.latitude, point.longitude);
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x1A163B68), blurRadius: 12),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppTheme.primary),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      );
}
