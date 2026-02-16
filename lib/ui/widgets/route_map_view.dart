import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

  const RouteMapView({
    super.key,
    required this.itinerary,
    this.currentLocation,
    this.showControls = true,
    this.interactiveMode = true,
    this.initialZoom = 13.0,
    this.onClose,
  });

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  late final MapController _mapController;
  String? _tileUrl;
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initTileUrl();
  }
  
  void _initTileUrl() {
    final tomtomKey = dotenv.env['TOMTOM_API_KEY'];
    if (tomtomKey != null && tomtomKey.isNotEmpty) {
      _tileUrl = 'https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key=$tomtomKey';
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
        padding: const EdgeInsets.all(50),
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
              padding: const EdgeInsets.all(50),
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
            
            // Route polylines
            PolylineLayer(
              polylines: _buildPolylines(),
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
            bottom: 16,
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
