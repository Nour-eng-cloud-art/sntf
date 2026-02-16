import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/data/models/routing.dart';
import 'package:sntf/providers/routing_provider.dart';
import 'package:sntf/ui/widgets/itinerary_card.dart';
import 'package:sntf/ui/widgets/route_map_view.dart';

/// Full-screen map view showing the selected route
class RouteMapScreen extends StatelessWidget {
  final Itinerary itinerary;

  const RouteMapScreen({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<RoutingProvider>(
        builder: (context, routing, child) {
          // Get current location if available
          LatLng? currentLocation;
          if (routing.currentPosition != null) {
            currentLocation = LatLng(
              routing.currentPosition!.latitude,
              routing.currentPosition!.longitude,
            );
          }

          return Stack(
            children: [
              // Full screen map
              RouteMapView(
                itinerary: itinerary,
                currentLocation: currentLocation,
                showControls: true,
                interactiveMode: true,
                onClose: () => Navigator.of(context).pop(),
              ),

              // Bottom details sheet
              DraggableScrollableSheet(
                initialChildSize: 0.35,
                minChildSize: 0.15,
                maxChildSize: 0.75,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          // Handle
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 12),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.grey700
                                    : AppColors.grey300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // Itinerary summary header
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        LucideIcons.route,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Votre itinéraire',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? AppColors.grey400
                                                  : AppColors.grey600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${itinerary.origin.nom} → ${itinerary.destination.nom}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Itinerary details
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ItineraryCard(
                              itinerary: itinerary,
                              showDetails: true,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Station list as timeline
                          _buildStationTimeline(context, isDark),

                          // Start navigation button
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Navigation démarrée ! Suivez les indications.',
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                icon: const Icon(LucideIcons.navigation),
                                label: const Text(
                                  'Démarrer le trajet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Safe area padding
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStationTimeline(BuildContext context, bool isDark) {
    final allStations = itinerary.allStations;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stations (${allStations.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.grey300 : AppColors.grey700,
            ),
          ),
          const SizedBox(height: 12),
          
          ...List.generate(allStations.length, (index) {
            final station = allStations[index];
            final isFirst = index == 0;
            final isLast = index == allStations.length - 1;
            
            // Determine the color based on which segment the station belongs to
            Color lineColor = AppColors.primary;
            for (final segment in itinerary.segments) {
              if (segment.stations.any((s) => s.id == station.id)) {
                lineColor = _parseColor(segment.color);
                break;
              }
            }
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline indicator
                Column(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isFirst || isLast
                            ? (isFirst ? AppColors.success : AppColors.secondary)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isFirst || isLast ? Colors.white : lineColor,
                          width: 3,
                        ),
                        boxShadow: isFirst || isLast
                            ? [
                                BoxShadow(
                                  color: (isFirst
                                          ? AppColors.success
                                          : AppColors.secondary)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 32,
                        color: lineColor,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                
                // Station info
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.nom,
                          style: TextStyle(
                            fontSize: isFirst || isLast ? 15 : 14,
                            fontWeight: isFirst || isLast
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isDark
                                ? (isFirst || isLast
                                    ? AppColors.darkOnSurface
                                    : AppColors.grey400)
                                : (isFirst || isLast
                                    ? AppColors.lightOnSurface
                                    : AppColors.grey600),
                          ),
                        ),
                        if (station.accessibilite)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.accessibility,
                                  size: 12,
                                  color: AppColors.info,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Accessible PMR',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.info,
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
          }),
        ],
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }
}
