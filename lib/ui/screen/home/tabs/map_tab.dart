import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  bool _showStationsList = false;
  String? _selectedStation;

  // Major railway stations in Algeria
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(36.7538, 3.0588), // Alger
            initialZoom: 6.0,
            minZoom: 5.0,
            maxZoom: 18.0,
            onTap: (_, __) {
              setState(() {
                _showStationsList = false;
                _selectedStation = null;
              });
            },
          ),
          children: [
            // Tile Layer
            TileLayer(
              urlTemplate: isDark
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.sntf.app',
            ),

            // Railway lines (simplified representation)
            PolylineLayer(
              polylines: [
                // Alger - Oran line
                Polyline(
                  points: [
                    const LatLng(36.7753, 3.0601), // Alger
                    const LatLng(36.4703, 2.8277), // Blida
                    const LatLng(35.6987, -0.6349), // Oran
                  ],
                  color: AppColors.trainTGV,
                  strokeWidth: 3,
                ),
                // Alger - Constantine line
                Polyline(
                  points: [
                    const LatLng(36.7753, 3.0601), // Alger
                    const LatLng(36.1898, 5.4108), // Sétif
                    const LatLng(36.3650, 6.6147), // Constantine
                  ],
                  color: AppColors.trainTER,
                  strokeWidth: 3,
                ),
                // Constantine - Annaba line
                Polyline(
                  points: [
                    const LatLng(36.3650, 6.6147), // Constantine
                    const LatLng(36.9000, 7.7667), // Annaba
                  ],
                  color: AppColors.trainIntercite,
                  strokeWidth: 3,
                ),
              ],
            ),

            // Station markers
            MarkerLayer(
              markers: _stations.map((station) {
                final isSelected = _selectedStation == station.name;
                return Marker(
                  point: station.position,
                  width: isSelected ? 60 : 40,
                  height: isSelected ? 60 : 40,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedStation = station.name);
                      _mapController.move(station.position, 12);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.trainFront,
                        color: isSelected ? Colors.white : AppColors.primary,
                        size: isSelected ? 28 : 20,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Top Bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        Text(
                          'Rechercher une gare...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _showStationsList = !_showStationsList),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _showStationsList ? AppColors.primary : (isDark ? AppColors.darkSurface : Colors.white),
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
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                },
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _MapButton(
                icon: LucideIcons.minus,
                onTap: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                },
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _MapButton(
                icon: LucideIcons.locate,
                onTap: () {
                  // Center on Algiers
                  _mapController.move(const LatLng(36.7538, 3.0588), 10);
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
                _mapController.move(station.position, 12);
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
