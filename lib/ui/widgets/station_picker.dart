import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/data/models/transport.dart';

/// A widget for selecting a station from a list
class StationPicker extends StatefulWidget {
  final List<Station> stations;
  final List<Station>? nearbyStations;
  final Station? selectedStation;
  final String hintText;
  final bool showCurrentLocation;
  final ValueChanged<Station>? onStationSelected;
  final VoidCallback? onCurrentLocationSelected;

  const StationPicker({
    super.key,
    required this.stations,
    this.nearbyStations,
    this.selectedStation,
    this.hintText = 'Rechercher une station...',
    this.showCurrentLocation = false,
    this.onStationSelected,
    this.onCurrentLocationSelected,
  });

  @override
  State<StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends State<StationPicker> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Station> _filteredStations = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _filteredStations = widget.stations;
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() => _showResults = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _showResults = true;
      if (query.isEmpty) {
        _filteredStations = widget.nearbyStations ?? widget.stations.take(10).toList();
      } else {
        final lowercaseQuery = query.toLowerCase();
        _filteredStations = widget.stations
            .where((s) => s.nom.toLowerCase().contains(lowercaseQuery))
            .take(15)
            .toList();
      }
    });
  }

  void _selectStation(Station station) {
    _searchController.text = station.nom;
    setState(() => _showResults = false);
    _focusNode.unfocus();
    widget.onStationSelected?.call(station);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search TextField
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(
              LucideIcons.search,
              color: isDark ? AppColors.grey400 : AppColors.grey600,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.lightSurfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: _onSearchChanged,
          onTap: () {
            setState(() => _showResults = true);
            _onSearchChanged(_searchController.text);
          },
        ),
        
        // Results list
        if (_showResults)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  // Current location option
                  if (widget.showCurrentLocation)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.locateFixed,
                          color: AppColors.info,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Ma position actuelle',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () {
                        _searchController.text = 'Ma position';
                        setState(() => _showResults = false);
                        widget.onCurrentLocationSelected?.call();
                      },
                    ),
                  
                  // Nearby stations header
                  if (widget.nearbyStations != null && 
                      widget.nearbyStations!.isNotEmpty &&
                      _searchController.text.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Stations à proximité',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.grey400
                              : AppColors.grey600,
                        ),
                      ),
                    ),
                  
                  // Station list
                  ..._filteredStations.map((station) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        station.accessibilite
                            ? LucideIcons.accessibility
                            : LucideIcons.trainFront,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      station.nom,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: station.accessibilite
                        ? const Text(
                            'Accessible PMR',
                            style: TextStyle(fontSize: 12),
                          )
                        : null,
                    trailing: widget.selectedStation?.id == station.id
                        ? const Icon(
                            LucideIcons.check,
                            color: AppColors.success,
                          )
                        : null,
                    onTap: () => _selectStation(station),
                  )),
                  
                  // Empty state
                  if (_filteredStations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.searchX,
                            size: 48,
                            color: isDark
                                ? AppColors.grey600
                                : AppColors.grey400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune station trouvée',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.grey400
                                  : AppColors.grey600,
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
    );
  }
}

/// A compact station selector field
class StationField extends StatelessWidget {
  final String label;
  final Station? station;
  final String placeholder;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const StationField({
    super.key,
    required this.label,
    this.station,
    this.placeholder = 'Sélectionner',
    this.icon = LucideIcons.mapPin,
    this.iconColor,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.grey400 : AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isLoading)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      station?.nom ?? placeholder,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: station != null
                            ? (isDark
                                ? AppColors.darkOnSurface
                                : AppColors.lightOnSurface)
                            : (isDark
                                ? AppColors.grey500
                                : AppColors.grey500),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: isDark ? AppColors.grey500 : AppColors.grey500,
            ),
          ],
        ),
      ),
    );
  }
}
