import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/data/services/places_service.dart';
import 'package:sntf/ui/screen/map/full_screen_map_picker.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _showStationsList = false;
  String? _selectedStation;
  bool _isMapReady = false;
  String? _selectedLocationName;
  LatLng? _selectedLocation;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.env['TOMTOM_API_KEY'];
  }

  /// Animate map to a location
  void _animateMapTo(LatLng destLocation, double destZoom) {
    if (!_isMapReady) return;
    _mapController.move(destLocation, destZoom);
  }

  /// Open location picker
  void _openLocationPicker() async {
    final result = await FullScreenMapPicker.show(
      context,
      initialPosition: _selectedLocation ?? const LatLng(35.6969, -0.6331),
      title: 'Rechercher un lieu',
      selectButtonText: 'Sélectionner ce lieu',
      primaryColor: AppColors.primary,
    );
    
    if (result != null) {
      setState(() {
        _selectedLocation = result.latLng;
        _selectedLocationName = result.addressData['display_name'] ?? result.address;
      });
      _animateMapTo(result.latLng, 15.0);
    }
  }

  final List<_Station> _stations = [
    _Station(
      name: 'Gare d\'Alger',
      city: 'Alger',
      position: const LatLng(36.7753, 3.0601),
      lines: ['Ligne Alger-Oran', 'Ligne Alger-Constantine'],
    ),
    _Station(
      name: 'Gare d\'Oran',
      city: 'Oran',
      position: const LatLng(35.6987, -0.6349),
      lines: ['Ligne Alger-Oran', 'Ligne Oran-Tlemcen'],
    ),
    _Station(
      name: 'Gare de Constantine',
      city: 'Constantine',
      position: const LatLng(36.3650, 6.6147),
      lines: ['Ligne Alger-Constantine', 'Ligne Constantine-Annaba'],
    ),
    _Station(
      name: 'Gare d\'Annaba',
      city: 'Annaba',
      position: const LatLng(36.9000, 7.7667),
      lines: ['Ligne Constantine-Annaba'],
    ),
    _Station(
      name: 'Gare de Sétif',
      city: 'Sétif',
      position: const LatLng(36.1898, 5.4108),
      lines: ['Ligne Alger-Constantine'],
    ),
    _Station(
      name: 'Gare de Blida',
      city: 'Blida',
      position: const LatLng(36.4703, 2.8277),
      lines: ['Ligne Alger-Oran'],
    ),
    _Station(
      name: 'Gare de Béjaïa',
      city: 'Béjaïa',
      position: const LatLng(36.7509, 5.0567),
      lines: ['Ligne Béni Mansour-Béjaïa'],
    ),
    _Station(
      name: 'Gare de Tlemcen',
      city: 'Tlemcen',
      position: const LatLng(34.8828, -1.3167),
      lines: ['Ligne Oran-Tlemcen'],
    ),
  ];

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    
    // Station markers
    for (final station in _stations) {
      final isSelected = _selectedStation == station.name;
      markers.add(
        Marker(
          point: station.position,
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedStation = station.name);
              if (_isMapReady) {
                _animateMapTo(station.position, 12);
              }
            },
            child: Icon(
              LucideIcons.trainFront,
              color: isSelected ? AppColors.primary : AppColors.primaryDark,
              size: isSelected ? 32 : 28,
            ),
          ),
        ),
      );
    }
    
    // Selected location marker
    if (_selectedLocation != null) {
      markers.add(
        Marker(
          point: _selectedLocation!,
          width: 50,
          height: 50,
          child: Icon(
            LucideIcons.mapPin,
            color: AppColors.error,
            size: 32,
          ),
        ),
      );
    }
    
    return markers;
  }

  List<Polyline> _buildPolylines() {
    return [
      // Alger - Oran line
      Polyline(
        points: const [
          LatLng(36.7753, 3.0601), // Alger
          LatLng(36.4703, 2.8277), // Blida
          LatLng(35.6987, -0.6349), // Oran
        ],
        color: AppColors.trainTGV,
        strokeWidth: 3,
      ),
      // Alger - Constantine line
      Polyline(
        points: const [
          LatLng(36.7753, 3.0601), // Alger
          LatLng(36.1898, 5.4108), // Sétif
          LatLng(36.3650, 6.6147), // Constantine
        ],
        color: AppColors.trainTER,
        strokeWidth: 3,
      ),
      // Constantine - Annaba line
      Polyline(
        points: const [
          LatLng(36.3650, 6.6147), // Constantine
          LatLng(36.9000, 7.7667), // Annaba
        ],
        color: AppColors.trainIntercite,
        strokeWidth: 3,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // TomTom Map
        if (_apiKey != null && _apiKey!.isNotEmpty)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(35.6969, -0.6331), 
              initialZoom: 6.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onMapReady: () {
                setState(() => _isMapReady = true);
              },
              onTap: (tapPosition, point) {
                setState(() {
                  _showStationsList = false;
                  _selectedStation = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: TomTomService.getTileUrl(_apiKey!),
                userAgentPackageName: 'com.sntf.app',
              ),
              PolylineLayer(polylines: _buildPolylines()),
              MarkerLayer(markers: _buildMarkers().toList()),
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
                    'Clé API TomTom non configurée',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Top Bar - Search
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _openLocationPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.search,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedLocationName ?? 'Rechercher un lieu...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _selectedLocationName != null
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedLocationName != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedLocationName = null;
                                  _selectedLocation = null;
                                });
                              },
                              child: Icon(
                                LucideIcons.x,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _showStationsList = !_showStationsList),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _showStationsList
                          ? AppColors.primary
                          : (isDark ? AppColors.darkSurface : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      LucideIcons.list,
                      color: _showStationsList ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Zoom Controls
        Positioned(
          right: 16,
          bottom: 200,
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
                    // Center on Oran
                    _animateMapTo(const LatLng(35.6969, -0.6331), 10);
                  }
                },
                isDark: isDark,
              ),
            ],
          ),
        ),

        // Legend
        Positioned(
          left: 16,
          bottom: 120,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lignes',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _LegendItem(color: AppColors.trainTGV, label: 'Alger-Oran'),
                _LegendItem(color: AppColors.trainTER, label: 'Alger-Constantine'),
                _LegendItem(color: AppColors.trainIntercite, label: 'Constantine-Annaba'),
              ],
            ),
          ),
        ),

        // Station Info Card
        if (_selectedStation != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _StationInfoCard(
              station: _stations.firstWhere((s) => s.name == _selectedStation),
              onClose: () => setState(() => _selectedStation = null),
              isDark: isDark,
            ),
          ),

        // Selected Location Info Card
        if (_selectedLocation != null && _selectedStation == null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _LocationInfoCard(
              locationName: _selectedLocationName ?? 'Lieu sélectionné',
              location: _selectedLocation!,
              onClose: () => setState(() {
                _selectedLocation = null;
                _selectedLocationName = null;
              }),
              isDark: isDark,
            ),
          ),

        // Stations List
        if (_showStationsList)
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            bottom: 100,
            child: _StationsList(
              stations: _stations,
              onStationTap: (station) {
                setState(() {
                  _selectedStation = station.name;
                  _showStationsList = false;
                });
                if (_isMapReady) {
                  _animateMapTo(station.position, 12);
                }
              },
              isDark: isDark,
            ),
          ),
      ],
    );
  }
}

class _Station {
  final String name;
  final String city;
  final LatLng position;
  final List<String> lines;

  _Station({
    required this.name,
    required this.city,
    required this.position,
    required this.lines,
  });
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
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _LocationInfoCard extends StatelessWidget {
  final String locationName;
  final LatLng location;
  final VoidCallback onClose;
  final bool isDark;

  const _LocationInfoCard({
    required this.locationName,
    required this.location,
    required this.onClose,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.mapPin,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lieu sélectionné',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locationName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Icon(
                  LucideIcons.x,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.navigation,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Open in external maps app
                  },
                  icon: const Icon(LucideIcons.externalLink, size: 18),
                  label: const Text('Ouvrir dans Maps'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Find nearest station
                  },
                  icon: const Icon(LucideIcons.trainFront, size: 18),
                  label: const Text('Gare proche'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StationInfoCard extends StatelessWidget {
  final _Station station;
  final VoidCallback onClose;
  final bool isDark;

  const _StationInfoCard({
    required this.station,
    required this.onClose,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.trainFront,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      station.city,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Icon(
                  LucideIcons.x,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Lignes desservies',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: station.lines.map((line) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  line,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.navigation, size: 18),
                  label: const Text('Itinéraire'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.ticket, size: 18),
                  label: const Text('Horaires'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StationsList extends StatelessWidget {
  final List<_Station> stations;
  final Function(_Station) onStationTap;
  final bool isDark;

  const _StationsList({
    required this.stations,
    required this.onStationTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Toutes les gares',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];
                return ListTile(
                  onTap: () => onStationTap(station),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.trainFront,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    station.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    station.city,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
