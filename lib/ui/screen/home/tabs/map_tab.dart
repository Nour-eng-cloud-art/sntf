import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/data/services/places_service.dart';
import 'package:sntf/data/services/supabase_service.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final SupabaseService _supabaseService = SupabaseService();
  
  bool _isMapReady = false;
  String? _apiKey;
  
  // Route planning state
  Map<String, dynamic>? _startStation;
  Map<String, dynamic>? _endStation;
  List<Map<String, dynamic>> _availableStations = [];
  List<Map<String, dynamic>> _foundRoutes = [];
  bool _isSearching = false;
  bool _showStationPicker = false;
  bool _isSelectingStart = true;
  String _stationSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.env['MAP_TILER_API_KEY'];
    _loadStations();
  }

  Future<void> _loadStations() async {
    try {
      final stations = await _supabaseService.getStationsWithCoordinates();
      setState(() {
        _availableStations = stations;
      });
    } catch (e) {
      debugPrint('Error loading stations: $e');
    }
  }

  /// Animate map to a location
  void _animateMapTo(LatLng destLocation, double destZoom) {
    if (!_isMapReady) return;
    _mapController.move(destLocation, destZoom);
  }

  /// Search for connecting routes
  Future<void> _searchRoutes() async {
    if (_startStation == null || _endStation == null) return;
    
    setState(() {
      _isSearching = true;
      _foundRoutes = [];
    });
    
    try {
      final routes = await _supabaseService.findConnectingLignes(
        _startStation!['id'].toString(),
        _endStation!['id'].toString(),
      );
      
      setState(() {
        _foundRoutes = routes;
        _isSearching = false;
      });
      
      // Fit map to show the route
      if (routes.isNotEmpty) {
        _fitMapToRoute();
      }
    } catch (e) {
      debugPrint('Error searching routes: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// Fit map to show all points of the route
  void _fitMapToRoute() {
    if (!_isMapReady) return;
    
    final points = <LatLng>[];
    
    if (_startStation != null) {
      final lat = _startStation!['latitude'];
      final lng = _startStation!['longitude'];
      if (lat != null && lng != null) {
        points.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }
    
    if (_endStation != null) {
      final lat = _endStation!['latitude'];
      final lng = _endStation!['longitude'];
      if (lat != null && lng != null) {
        points.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }
    
    if (points.length >= 2) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(80),
        ),
      );
    }
  }

  /// Open station picker
  void _openStationPicker(bool isStart) {
    setState(() {
      _showStationPicker = true;
      _isSelectingStart = isStart;
      _stationSearchQuery = '';
    });
  }

  /// Select a station
  void _selectStation(Map<String, dynamic> station) {
    setState(() {
      if (_isSelectingStart) {
        _startStation = station;
      } else {
        _endStation = station;
      }
      _showStationPicker = false;
      _foundRoutes = [];
    });
    
    // Auto-search when both stations are selected
    if (_startStation != null && _endStation != null) {
      _searchRoutes();
    }
  }

  /// Clear route
  void _clearRoute() {
    setState(() {
      _startStation = null;
      _endStation = null;
      _foundRoutes = [];
    });
  }

  /// Swap start and end stations
  void _swapStations() {
    setState(() {
      final temp = _startStation;
      _startStation = _endStation;
      _endStation = temp;
      _foundRoutes = [];
    });
    
    if (_startStation != null && _endStation != null) {
      _searchRoutes();
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    
    // Start station marker
    if (_startStation != null) {
      final lat = _startStation!['latitude'];
      final lng = _startStation!['longitude'];
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            point: LatLng(lat.toDouble(), lng.toDouble()),
            width: 50,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.mapPin,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      }
    }
    
    // End station marker
    if (_endStation != null) {
      final lat = _endStation!['latitude'];
      final lng = _endStation!['longitude'];
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            point: LatLng(lat.toDouble(), lng.toDouble()),
            width: 50,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.flag,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      }
    }
    
    // Station markers along routes
    for (final route in _foundRoutes) {
      final stations = route['stations'] as List?;
      if (stations == null) continue;
      
      for (final stop in stations) {
        final station = stop['stations'] as Map<String, dynamic>?;
        if (station == null) continue;
        
        final lat = station['latitude'];
        final lng = station['longitude'];
        if (lat == null || lng == null) continue;
        
        // Skip if it's start or end station
        if (_startStation != null && station['id'] == _startStation!['id']) continue;
        if (_endStation != null && station['id'] == _endStation!['id']) continue;
        
        markers.add(
          Marker(
            point: LatLng(lat.toDouble(), lng.toDouble()),
            width: 30,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Icon(
                LucideIcons.circle,
                color: AppColors.primary,
                size: 12,
              ),
            ),
          ),
        );
      }
    }
    
    return markers;
  }

  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];
    
    final colors = [
      AppColors.primary,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    
    int colorIndex = 0;
    
    for (final route in _foundRoutes) {
      final stations = route['stations'] as List?;
      if (stations == null || stations.isEmpty) continue;
      
      final points = <LatLng>[];
      
      for (final stop in stations) {
        final station = stop['stations'] as Map<String, dynamic>?;
        if (station == null) continue;
        
        final lat = station['latitude'];
        final lng = station['longitude'];
        if (lat != null && lng != null) {
          points.add(LatLng(lat.toDouble(), lng.toDouble()));
        }
      }
      
      if (points.length >= 2) {
        polylines.add(
          Polyline(
            points: points,
            color: colors[colorIndex % colors.length],
            strokeWidth: 4,
          ),
        );
        colorIndex++;
      }
    }
    
    return polylines;
  }

  List<Map<String, dynamic>> get _filteredStations {
    if (_stationSearchQuery.isEmpty) {
      return _availableStations;
    }
    return _availableStations.where((station) {
      final name = station['nom']?.toString().toLowerCase() ?? '';
      return name.contains(_stationSearchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // MapTiler Map
        if (_apiKey != null && _apiKey!.isNotEmpty)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(35.6969, -0.6331), // Oran city center
              initialZoom: 13.0, // Zoom in on Oran
              minZoom: 5.0,
              maxZoom: 18.0,
              onMapReady: () {
                setState(() => _isMapReady = true);
              },
              onTap: (tapPosition, point) {
                setState(() {
                  _showStationPicker = false;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapTilerService.getTileUrl(_apiKey!),
                userAgentPackageName: 'com.sntf.app',
              ),
              PolylineLayer(polylines: _buildPolylines()),
              MarkerLayer(markers: _buildMarkers()),
            ],
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.mapPin, size: 48, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  Text(
                    'Carte non disponible',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Clé API MapTiler non configurée',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Route Planning Card
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Start Point
                  _buildStationInput(
                    label: 'Départ',
                    station: _startStation,
                    icon: LucideIcons.circleDot,
                    color: Colors.green,
                    onTap: () => _openStationPicker(true),
                    onClear: () => setState(() {
                      _startStation = null;
                      _foundRoutes = [];
                    }),
                    theme: theme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  // Swap button
                  Row(
                    children: [
                      const SizedBox(width: 20),
                      Container(
                        height: 24,
                        width: 2,
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const Spacer(),
                      if (_startStation != null && _endStation != null)
                        GestureDetector(
                          onTap: _swapStations,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              LucideIcons.arrowUpDown,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // End Point
                  _buildStationInput(
                    label: 'Arrivée',
                    station: _endStation,
                    icon: LucideIcons.mapPin,
                    color: Colors.red,
                    onTap: () => _openStationPicker(false),
                    onClear: () => setState(() {
                      _endStation = null;
                      _foundRoutes = [];
                    }),
                    theme: theme,
                    isDark: isDark,
                  ),
                  // Found routes indicator
                  if (_isSearching)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recherche des lignes...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_foundRoutes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.check,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_foundRoutes.length} ligne${_foundRoutes.length > 1 ? 's' : ''} trouvée${_foundRoutes.length > 1 ? 's' : ''}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_startStation != null && _endStation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.messageCircleWarning,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Aucune ligne directe trouvée',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Zoom Controls
        Positioned(
          right: 16,
          bottom: _foundRoutes.isNotEmpty ? 280 : 120,
          child: Column(
            children: [
              _MapButton(
                icon: LucideIcons.plus,
                onTap: () {
                  if (_isMapReady) {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  }
                },
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _MapButton(
                icon: LucideIcons.minus,
                onTap: () {
                  if (_isMapReady) {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  }
                },
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _MapButton(
                icon: LucideIcons.locate,
                onTap: () {
                  if (_isMapReady) {
                    _animateMapTo(const LatLng(35.6969, -0.6331), 13);
                  }
                },
                isDark: isDark,
              ),
              if (_startStation != null || _endStation != null) ...[
                const SizedBox(height: 8),
                _MapButton(
                  icon: LucideIcons.trash2,
                  onTap: _clearRoute,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),

        // Found Routes List
        if (_foundRoutes.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.route,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lignes disponibles',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _foundRoutes.length,
                      itemBuilder: (context, index) {
                        final route = _foundRoutes[index];
                        final ligne = route['ligne'] as Map<String, dynamic>;
                        final stations = route['stations'] as List;
                        final ligneColor = _parseColor(ligne['couleur']);
                        
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: ligneColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ligne['nom_court'] ?? ligne['nom'] ?? 'Ligne',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            ligne['nom'] ?? 'Ligne ${index + 1}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${stations.length} arrêts',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.grey500,
                            ),
                          ),
                          trailing: Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: AppColors.grey400,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Station Picker Modal
        if (_showStationPicker)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _showStationPicker = false),
              child: Container(
                color: Colors.black54,
                child: GestureDetector(
                  onTap: () {}, // Prevent tap through
                  child: SafeArea(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  _isSelectingStart ? LucideIcons.circleDot : LucideIcons.mapPin,
                                  color: _isSelectingStart ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isSelectingStart ? 'Choisir le départ' : 'Choisir l\'arrivée',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setState(() => _showStationPicker = false),
                                  child: const Icon(LucideIcons.x),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              onChanged: (value) => setState(() => _stationSearchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Rechercher une station...',
                                prefixIcon: const Icon(LucideIcons.search, size: 20),
                                filled: true,
                                fillColor: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _filteredStations.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.searchX,
                                          size: 48,
                                          color: AppColors.grey400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Aucune station trouvée',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: AppColors.grey500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    itemCount: _filteredStations.length,
                                    itemBuilder: (context, index) {
                                      final station = _filteredStations[index];
                                      final isSelected = (_isSelectingStart && _startStation?['id'] == station['id']) ||
                                          (!_isSelectingStart && _endStation?['id'] == station['id']);
                                      
                                      return ListTile(
                                        onTap: () => _selectStation(station),
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary.withOpacity(0.1)
                                                : AppColors.grey100,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            LucideIcons.mapPin,
                                            color: isSelected ? AppColors.primary : AppColors.grey500,
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          station['nom'] ?? 'Station',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? AppColors.primary : null,
                                          ),
                                        ),
                                        trailing: isSelected
                                            ? Icon(LucideIcons.check, color: AppColors.primary)
                                            : null,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStationInput({
    required String label,
    required Map<String, dynamic>? station,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onClear,
    required ThemeData theme,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: station != null
              ? Border.all(color: color.withOpacity(0.5), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.grey500,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    station?['nom'] ?? 'Sélectionner une station',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: station != null ? null : AppColors.grey400,
                      fontWeight: station != null ? FontWeight.w600 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (station != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(LucideIcons.x, size: 18, color: AppColors.grey400),
              ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return AppColors.primary;
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      }
      return AppColors.primary;
    } catch (e) {
      return AppColors.primary;
    }
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _MapButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
