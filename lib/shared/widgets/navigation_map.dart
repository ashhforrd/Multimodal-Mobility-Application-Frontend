import 'dart:math' as math;

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
    this.followUser = false,
    this.onPointSelected,
  });

  final NavigationRoute? route;
  final GeoPoint? currentPosition;
  final Destination? destination;
  final List<GeoPoint> recoveryPoints;
  final double height;
  final bool selectable;
  final bool followUser;
  final ValueChanged<GeoPoint>? onPointSelected;

  bool get isRecovery => recoveryPoints.isNotEmpty;

  @override
  State<NavigationMap> createState() => _NavigationMapState();
}

class _NavigationMapState extends State<NavigationMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final MapController _mapController;
  late bool _isFollowingUser;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _isFollowingUser = widget.followUser;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant NavigationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.followUser || !_isFollowingUser) return;
    final position = widget.currentPosition;
    final previous = oldWidget.currentPosition;
    if (position == null ||
        (position == previous &&
            position.courseDegrees == previous?.courseDegrees)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _followPosition(position, previous: previous),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    _mapController.dispose();
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
            mapController: _mapController,
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
              onMapReady: () {
                _mapReady = true;
                if (widget.followUser && _isFollowingUser) {
                  final position = widget.currentPosition;
                  if (position != null) _followPosition(position);
                }
              },
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
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.rotate,
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
          if (widget.followUser)
            Positioned(
              top: 12,
              right: 12,
              child: IconButton.filledTonal(
                key: const Key('follow-walking-direction'),
                tooltip: _isFollowingUser
                    ? 'Hentikan mengikuti arah'
                    : 'Ikuti arah berjalan',
                onPressed: _toggleFollowing,
                icon: Icon(
                  _isFollowingUser
                      ? LucideIcons.navigation
                      : LucideIcons.locateFixed,
                  size: 19,
                ),
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
          rotate: true,
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
          rotate: true,
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
          rotate: true,
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

  void _toggleFollowing() {
    setState(() => _isFollowingUser = !_isFollowingUser);
    if (_isFollowingUser && widget.currentPosition != null) {
      _followPosition(widget.currentPosition!);
    }
  }

  void _followPosition(GeoPoint position, {GeoPoint? previous}) {
    if (!_mapReady || !_isFollowingUser) return;
    final course = position.courseDegrees ??
        (previous == null ? null : _bearingBetween(previous, position));
    final rotation =
        course == null ? _mapController.camera.rotation : (360 - course) % 360;
    _mapController.moveAndRotate(
      _latLng(position),
      math.max(_mapController.camera.zoom, 17),
      rotation,
      id: 'follow-walking-direction',
    );
  }

  double? _bearingBetween(GeoPoint start, GeoPoint end) {
    if (start.latitude == end.latitude && start.longitude == end.longitude) {
      return null;
    }
    final startLatitude = start.latitude * math.pi / 180;
    final endLatitude = end.latitude * math.pi / 180;
    final deltaLongitude = (end.longitude - start.longitude) * math.pi / 180;
    final y = math.sin(deltaLongitude) * math.cos(endLatitude);
    final x = math.cos(startLatitude) * math.sin(endLatitude) -
        math.sin(startLatitude) *
            math.cos(endLatitude) *
            math.cos(deltaLongitude);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }
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
                  letterSpacing: -.24,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      );
}
