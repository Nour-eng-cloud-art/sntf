import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/data/models/routing.dart';
import 'package:sntf/data/models/transport.dart';

/// Widget that displays an itinerary on a map with route lines and station markers
class RouteMapView extends StatefulWidget {
  final Itinerary itinerary;
  final LatLng? currentLocation;
  final bool showControls;
  final bool interactiveMode;
  final double initialZoom;
  final VoidCallback? onClose;
  /// Extra padding at the bottom to account for overlaying UI elements (e.g., bottom sheets)
  final double bottomPadding;
  /// Extra padding at the top to account for overlaying UI elements (e.g., app bars)
  final double topPadding;

  const RouteMapView({
    super.key,
    required this.itinerary,
    this.currentLocation,
    this.showControls = true,
    this.interactiveMode = true,
    this.initialZoom = 13.0,
    this.onClose,
    this.bottomPadding = 50.0,
    this.topPadding = 50.0,
  });

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  late final MapController _mapController;
  String? _tileUrl;
  int? _selectedSegmentIndex;
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initTileUrl();
  }
  
  void _initTileUrl() {
    final maptilerKey = dotenv.env['MAP_TILER_API_KEY'];
    if (maptilerKey != null && maptilerKey.isNotEmpty) {
      _tileUrl = 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$maptilerKey';
    } else {
      // Fallback to OpenStreetMap
      _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLngBounds _getBounds() {
    final allStations = widget.itinerary.allStations;
    if (allStations.isEmpty) {
      return LatLngBounds(
        const LatLng(36.7, 3.0),
        const LatLng(36.8, 3.1),
      );
    }

    double minLat = allStations.first.latitude;
    double maxLat = allStations.first.latitude;
    double minLng = allStations.first.longitude;
    double maxLng = allStations.first.longitude;

    for (final station in allStations) {
      if (station.latitude < minLat) minLat = station.latitude;
      if (station.latitude > maxLat) maxLat = station.latitude;
      if (station.longitude < minLng) minLng = station.longitude;
      if (station.longitude > maxLng) maxLng = station.longitude;
    }

    // Add current location to bounds
    if (widget.currentLocation != null) {
      if (widget.currentLocation!.latitude < minLat) {
        minLat = widget.currentLocation!.latitude;
      }
      if (widget.currentLocation!.latitude > maxLat) {
        maxLat = widget.currentLocation!.latitude;
      }
      if (widget.currentLocation!.longitude < minLng) {
        minLng = widget.currentLocation!.longitude;
      }
      if (widget.currentLocation!.longitude > maxLng) {
        maxLng = widget.currentLocation!.longitude;
      }
    }

    // Add padding
    const padding = 0.01;
    return LatLngBounds(
      LatLng(minLat - padding, minLng - padding),
      LatLng(maxLat + padding, maxLng + padding),
    );
  }

  void _fitBounds() {
    final bounds = _getBounds();
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.only(
          top: widget.topPadding,
          left: 50,
          right: 50,
          bottom: widget.bottomPadding,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bounds = _getBounds();
    
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: EdgeInsets.only(
                top: widget.topPadding,
                left: 50,
                right: 50,
                bottom: widget.bottomPadding,
              ),
            ),
            interactionOptions: InteractionOptions(
              flags: widget.interactiveMode
                  ? InteractiveFlag.all
                  : InteractiveFlag.none,
            ),
          ),
          children: [
            // Tile layer
            TileLayer(
              urlTemplate: _tileUrl,
              userAgentPackageName: 'com.sntf.app',
            ),
            
            // Route polylines with tap detection
            PolylineLayer(
              polylines: _buildPolylines(),
            ),
            
            // Tappable polyline overlay (invisible, for tap detection)
            _TappablePolylineLayer(
              segments: widget.itinerary.segments,
              mapController: _mapController,
              onSegmentTap: _showSegmentStations,
            ),
            
            // Station markers
            MarkerLayer(
              markers: _buildMarkers(),
            ),
          ],
        ),
        
        // Controls overlay
        if (widget.showControls)
          Positioned(
            right: 16,
            bottom: widget.bottomPadding > 50 ? widget.bottomPadding - 30 : 16,
            child: Column(
              children: [
                // Fit bounds button
                FloatingActionButton.small(
                  heroTag: 'fit_bounds',
                  onPressed: _fitBounds,
                  backgroundColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  child: Icon(
                    LucideIcons.maximize2,
                    color: isDark
                        ? AppColors.darkOnSurface
                        : AppColors.lightOnSurface,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                // Current location button
                if (widget.currentLocation != null)
                  FloatingActionButton.small(
                    heroTag: 'current_location',
                    onPressed: () {
                      _mapController.move(widget.currentLocation!, 15);
                    },
                    backgroundColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    child: const Icon(
                      LucideIcons.locateFixed,
                      color: AppColors.info,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        
        // Close button
        if (widget.onClose != null)
          Positioned(
            left: 16,
            top: 16,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: widget.onClose,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    color: isDark
                        ? AppColors.darkOnSurface
                        : AppColors.lightOnSurface,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];
    
    for (final segment in widget.itinerary.segments) {
      final color = _parseColor(segment.color) ?? AppColors.primary;
      final points = segment.stations
          .map((s) => LatLng(s.latitude, s.longitude))
          .toList();
      
      // Main route line
      polylines.add(Polyline(
        points: points,
        strokeWidth: 5,
        color: color,
      ));
      
      // Outline for better visibility
      polylines.insert(
        0,
        Polyline(
          points: points,
          strokeWidth: 8,
          color: Colors.white,
        ),
      );
    }
    
    return polylines;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    final allStations = widget.itinerary.allStations;
    
    // Current location marker
    if (widget.currentLocation != null) {
      markers.add(Marker(
        point: widget.currentLocation!,
        width: 24,
        height: 24,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.info,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.info.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ));
    }
    
    // Station markers
    for (int i = 0; i < allStations.length; i++) {
      final station = allStations[i];
      final isOrigin = i == 0;
      final isDestination = i == allStations.length - 1;
      final isTransfer = _isTransferStation(station, i);
      
      // Determine marker style
      Color markerColor;
      double size;
      IconData? icon;
      
      if (isOrigin) {
        markerColor = AppColors.success;
        size = 32;
        icon = LucideIcons.circleDot;
      } else if (isDestination) {
        markerColor = AppColors.secondary;
        size = 32;
        icon = LucideIcons.mapPin;
      } else if (isTransfer) {
        markerColor = AppColors.warning;
        size = 28;
        icon = LucideIcons.arrowRightLeft;
      } else {
        // Regular intermediate stop
        markerColor = AppColors.grey500;
        size = 16;
        icon = null;
      }
      
      markers.add(Marker(
        point: LatLng(station.latitude, station.longitude),
        width: size,
        height: size,
        child: _StationMarker(
          station: station,
          color: markerColor,
          size: size,
          icon: icon,
          showLabel: isOrigin || isDestination || isTransfer,
        ),
      ));
    }
    
    return markers;
  }

  bool _isTransferStation(Station station, int index) {
    // Check if this station is where a line change occurs
    int stationCount = 0;
    for (final segment in widget.itinerary.segments) {
      for (int i = 0; i < segment.stations.length; i++) {
        if (stationCount == index) {
          // This is the station at the given index
          // It's a transfer if it's the last station of a segment (except the last segment)
          final isLastInSegment = i == segment.stations.length - 1;
          final isLastSegment = segment == widget.itinerary.segments.last;
          return isLastInSegment && !isLastSegment;
        }
        stationCount++;
      }
      stationCount--; // First station of next segment is same as last of previous
    }
    return false;
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return null;
    }
  }

  void _showSegmentStations(int segmentIndex) {
    final segment = widget.itinerary.segments[segmentIndex];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkOnSurface.withValues(alpha: 0.3)
                        : AppColors.lightOnSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _parseColor(segment.color) ?? AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                segment.ligne.nomCourt,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                segment.ligne.directionTerminus,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnSurfaceVariant
                                      : AppColors.lightOnSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${segment.stations.length} stations',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Stations list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: segment.stations.length,
                  itemBuilder: (context, index) {
                    final station = segment.stations[index];
                    final isFirst = index == 0;
                    final isLast = index == segment.stations.length - 1;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _parseColor(segment.color) ?? AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkSurface
                                        : AppColors.lightSurface,
                                    width: 2,
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 40,
                                  color: _parseColor(segment.color) ?? AppColors.primary,
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    station.nom,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (station.accessibilite)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            LucideIcons.wheelchair,
                                            size: 14,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Accessible',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationMarker extends StatelessWidget {
  final Station station;
  final Color color;
  final double size;
  final IconData? icon;
  final bool showLabel;

  const _StationMarker({
    required this.station,
    required this.color,
    required this.size,
    this.icon,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      // Large marker with icon
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.5,
        ),
      );
    }
    
    // Small dot for intermediate stops
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}

/// Custom layer for tappable polylines
class _TappablePolylineLayer extends StatelessWidget {
  final List<RouteSegment> segments;
  final MapController mapController;
  final Function(int segmentIndex) onSegmentTap;

  const _TappablePolylineLayer({
    required this.segments,
    required this.mapController,
    required this.onSegmentTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        _handleTap(context, details.localPosition);
      },
      child: Container(
        color: Colors.transparent,
        child: CustomPaint(
          painter: _TappablePolylinePainter(
            segments: segments,
            mapController: mapController,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, Offset tapPosition) {
    final mapState = FlutterMapState.maybeOf(context);
    if (mapState == null) return;

    // Convert tap position to lat/lng
    final tapPoint = mapState.camera.pointToLatLng(
      CustomPoint(tapPosition.dx, tapPosition.dy),
    );

    // Check distance from each segment
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final polylinePoints = segment.stations
          .map((s) => LatLng(s.latitude, s.longitude))
          .toList();

      // Check if tap is near any line segment
      if (_isPointNearPolyline(tapPoint, polylinePoints, mapState)) {
        onSegmentTap(i);
        return;
      }
    }
  }

  bool _isPointNearPolyline(
    LatLng point,
    List<LatLng> polylinePoints,
    FlutterMapState mapState,
  ) {
    const hitTolerance = 15.0; // pixels

    // Convert all points to pixel coordinates
    final pointPixel = mapState.camera.latLngToScreenPoint(point);

    for (int i = 0; i < polylinePoints.length - 1; i++) {
      final p1 = mapState.camera.latLngToScreenPoint(polylinePoints[i]);
      final p2 = mapState.camera.latLngToScreenPoint(polylinePoints[i + 1]);

      // Check distance from point to line segment
      final distance = _distanceFromPointToLineSegment(pointPixel, p1, p2);
      if (distance <= hitTolerance) {
        return true;
      }
    }

    return false;
  }

  double _distanceFromPointToLineSegment(
    Offset point,
    Offset lineStart,
    Offset lineEnd,
  ) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;
    final distSquared = dx * dx + dy * dy;

    if (distSquared == 0) {
      return _distance(point, lineStart);
    }

    var t = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) /
        distSquared;
    t = t.clamp(0, 1);

    final closestPoint = Offset(
      lineStart.dx + t * dx,
      lineStart.dy + t * dy,
    );

    return _distance(point, closestPoint);
  }

  double _distance(Offset p1, Offset p2) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    return sqrt(dx * dx + dy * dy);
  }
}

/// Custom painter for tap detection visualization
class _TappablePolylinePainter extends CustomPainter {
  final List<RouteSegment> segments;
  final MapController mapController;

  _TappablePolylinePainter({
    required this.segments,
    required this.mapController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // This painter is transparent; it's just for tap detection
  }

  @override
  bool shouldRepaint(_TappablePolylinePainter oldDelegate) => false;
}

/// A compact route preview for itinerary cards
class RoutePreview extends StatelessWidget {
  final Itinerary itinerary;
  final double height;

  const RoutePreview({
    super.key,
    required this.itinerary,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: RouteMapView(
          itinerary: itinerary,
          showControls: false,
          interactiveMode: false,
          initialZoom: 12,
        ),
      ),
    );
  }
}
