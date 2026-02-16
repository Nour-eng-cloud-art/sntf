import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/providers/routing_provider.dart';
import 'package:sntf/ui/screen/routing/route_map_screen.dart';
import 'package:sntf/ui/widgets/itinerary_card.dart';
import 'package:sntf/ui/widgets/station_picker.dart';

/// Screen for planning a route between two points
class RoutePlanningScreen extends StatefulWidget {
  const RoutePlanningScreen({super.key});

  @override
  State<RoutePlanningScreen> createState() => _RoutePlanningScreenState();
}

class _RoutePlanningScreenState extends State<RoutePlanningScreen> {
  bool _showOriginPicker = false;
  bool _showDestinationPicker = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark 
          ? AppColors.darkBackground 
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Planifier un trajet'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<RoutingProvider>(
        builder: (context, routing, child) {
          if (routing.state == RoutingState.loading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des données...'),
                ],
              ),
            );
          }

          if (routing.state == RoutingState.error && !routing.isReady) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.alignVerticalDistributeStart,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      routing.errorMessage ?? 'Une erreur est survenue',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => routing.refresh(),
                      icon: const Icon(LucideIcons.refreshCw),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Origin/Destination selection card
              _buildRouteInputCard(context, routing, isDark),

              // Results or empty state
              Expanded(
                child: _buildContent(context, routing, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRouteInputCard(
    BuildContext context,
    RoutingProvider routing,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Origin field
          if (_showOriginPicker)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Départ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            setState(() => _showOriginPicker = false),
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StationPicker(
                    stations: routing.stations,
                    nearbyStations: routing.nearbyStations,
                    selectedStation: routing.origin?.station,
                    hintText: 'Rechercher une gare de départ...',
                    showCurrentLocation: routing.currentPosition != null,
                    onStationSelected: (station) {
                      routing.setOriginStation(station);
                      setState(() => _showOriginPicker = false);
                    },
                    onCurrentLocationSelected: () {
                      routing.setOriginToCurrentLocation();
                      setState(() => _showOriginPicker = false);
                    },
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: StationField(
                label: 'Départ',
                station: routing.origin?.station,
                placeholder: routing.origin?.name ?? 'Choisir un point de départ',
                icon: LucideIcons.circleDot,
                iconColor: AppColors.success,
                onTap: () => setState(() {
                  _showOriginPicker = true;
                  _showDestinationPicker = false;
                }),
              ),
            ),

          // Swap button
          if (!_showOriginPicker && !_showDestinationPicker)
            Row(
              children: [
                const Expanded(child: Divider(indent: 16)),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowUpDown, size: 20),
                    onPressed: routing.origin != null || routing.destination != null
                        ? () => routing.swapOriginDestination()
                        : null,
                    tooltip: 'Inverser',
                  ),
                ),
                const Expanded(child: Divider(endIndent: 16)),
              ],
            ),

          // Destination field
          if (_showDestinationPicker)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Arrivée',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            setState(() => _showDestinationPicker = false),
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StationPicker(
                    stations: routing.stations,
                    nearbyStations: routing.nearbyStations,
                    selectedStation: routing.destination?.station,
                    hintText: 'Rechercher une gare d\'arrivée...',
                    showCurrentLocation: false, // Destination shouldn't be current location
                    onStationSelected: (station) {
                      routing.setDestinationStation(station);
                      setState(() => _showDestinationPicker = false);
                    },
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: StationField(
                label: 'Arrivée',
                station: routing.destination?.station,
                placeholder: routing.destination?.name ?? 'Choisir une destination',
                icon: LucideIcons.mapPin,
                iconColor: AppColors.secondary,
                onTap: () => setState(() {
                  _showDestinationPicker = true;
                  _showOriginPicker = false;
                }),
              ),
            ),

          // Search button
          if (!_showOriginPicker && !_showDestinationPicker)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: routing.canSearch && !routing.isLoading
                      ? () => routing.searchRoutes()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: routing.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(LucideIcons.search),
                  label: Text(
                    routing.isLoading ? 'Recherche...' : 'Rechercher',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, RoutingProvider routing, bool isDark) {
    // Error state
    if (routing.errorMessage != null && routing.state != RoutingState.loading) {
      return _buildErrorState(routing, isDark);
    }

    // Results
    if (routing.hasResults) {
      return _buildResults(context, routing, isDark);
    }

    // Empty/initial state
    return _buildEmptyState(isDark);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.route,
              size: 80,
              color: isDark ? AppColors.grey600 : AppColors.grey400,
            ),
            const SizedBox(height: 24),
            Text(
              'Planifiez votre trajet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.grey300 : AppColors.grey700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sélectionnez un point de départ et une destination pour voir les itinéraires disponibles',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.grey500 : AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(RoutingProvider routing, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.routeOff,
              size: 64,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              routing.errorMessage ?? 'Aucun itinéraire trouvé',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.grey300 : AppColors.grey700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos points de départ ou d\'arrivée',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.grey500 : AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, RoutingProvider routing, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${routing.itineraries.length} itinéraire${routing.itineraries.length > 1 ? 's' : ''} trouvé${routing.itineraries.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                ),
              ),
              const Spacer(),
              if (routing.searchResult?.hasDirectRoute == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.check,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Direct disponible',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Itinerary list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: routing.itineraries.length,
            itemBuilder: (context, index) {
              final itinerary = routing.itineraries[index];
              final isSelected =
                  routing.selectedItinerary?.id == itinerary.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ItineraryCard(
                  itinerary: itinerary,
                  isSelected: isSelected,
                  showDetails: isSelected,
                  onTap: () {
                    if (isSelected) {
                      // Navigate to full map view
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => RouteMapScreen(
                            itinerary: itinerary,
                          ),
                        ),
                      );
                    } else {
                      routing.selectItinerary(itinerary);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
