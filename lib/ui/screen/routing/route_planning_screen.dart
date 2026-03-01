import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

class _RoutePlanningScreenState extends State<RoutePlanningScreen> with TickerProviderStateMixin {
  bool _showOriginPicker = false;
  bool _showDestinationPicker = false;
  bool _isSearchContainerMinimized = false;
  bool _isItineraryContainerMinimized = false;
  
  late AnimationController _searchAnimationController;
  late AnimationController _itineraryAnimationController;
  late Animation<double> _searchAnimation;
  late Animation<double> _itineraryAnimation;
  
  MapController? _mapController;
  String? _tileUrl;
  
  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _itineraryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
    _itineraryAnimation = CurvedAnimation(
      parent: _itineraryAnimationController,
      curve: Curves.easeInOut,
    );
    _searchAnimationController.value = 1.0; // Start expanded
    _itineraryAnimationController.value = 1.0; // Start expanded
    _initTileUrl();
  }
  
  void _initTileUrl() {
    final maptilerKey = dotenv.env['MAP_TILER_API_KEY'];
    if (maptilerKey != null && maptilerKey.isNotEmpty) {
      _tileUrl = 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$maptilerKey';
    } else {
      _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }
  
  @override
  void dispose() {
    _searchAnimationController.dispose();
    _itineraryAnimationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
  
  void _toggleSearchContainer() {
    setState(() {
      _isSearchContainerMinimized = !_isSearchContainerMinimized;
      if (_isSearchContainerMinimized) {
        _searchAnimationController.reverse();
      } else {
        _searchAnimationController.forward();
      }
    });
  }
  
  void _toggleItineraryContainer() {
    setState(() {
      _isItineraryContainerMinimized = !_isItineraryContainerMinimized;
      if (_isItineraryContainerMinimized) {
        _itineraryAnimationController.reverse();
      } else {
        _itineraryAnimationController.forward();
      }
    });
  }
  
  void _fitBoundsToRoute(RoutingProvider routing) {
    if (_mapController == null || routing.selectedItinerary == null) return;
    
    final allStations = routing.selectedItinerary!.allStations;
    if (allStations.isEmpty) return;
    
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
    
    // Add padding
    final latPadding = (maxLat - minLat) * 0.15;
    final lngPadding = (maxLng - minLng) * 0.15;
    
    final bounds = LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
    
    _mapController!.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark 
          ? AppColors.darkBackground 
          : AppColors.lightBackground,
      body: Consumer<RoutingProvider>(
        builder: (context, routing, child) {
          if (routing.state == RoutingState.loading && !routing.isReady) {
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

          // Show map view when there are results
          final showMap = routing.hasResults && routing.selectedItinerary != null;
          
          return Stack(
            children: [
              // Map background when itinerary is selected
              if (showMap)
                _buildMapBackground(routing, isDark),
              
              // Content overlay
              SafeArea(
                child: Column(
                  children: [
                    // App bar
                    _buildAppBar(context, isDark),
                    
                    // Collapsible search container
                    _buildCollapsibleSearchCard(context, routing, isDark),
                    
                    // Results or empty state
                    if (!showMap)
                      Expanded(
                        child: _buildContent(context, routing, isDark),
                      ),
                    
                    // Collapsible itinerary container (only when map is shown)
                    if (showMap)
                      Expanded(
                        child: Column(
                          children: [
                            const Spacer(),
                            _buildCollapsibleItineraryCard(context, routing, isDark),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Planifier un trajet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }
  
  Widget _buildMapBackground(RoutingProvider routing, bool isDark) {
    _mapController ??= MapController();
    final itinerary = routing.selectedItinerary!;
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          itinerary.origin.latitude,
          itinerary.origin.longitude,
        ),
        initialZoom: 10.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onMapReady: () => _fitBoundsToRoute(routing),
      ),
      children: [
        // Map tiles
        TileLayer(
          urlTemplate: _tileUrl ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.sntf.app',
        ),
        
        // Route polyline
        PolylineLayer(
          polylines: _buildRoutePolylines(itinerary),
        ),
        
        // Station markers
        MarkerLayer(
          markers: _buildStationMarkers(itinerary, isDark),
        ),
      ],
    );
  }
  
  List<Polyline> _buildRoutePolylines(dynamic itinerary) {
    final List<Polyline> polylines = [];
    
    for (final segment in itinerary.segments) {
      final points = <LatLng>[];
      for (final station in segment.stations) {
        points.add(LatLng(station.latitude, station.longitude));
      }
      
      polylines.add(Polyline(
        points: points,
        strokeWidth: 5.0,
        color: AppColors.primary,
      ));
    }
    
    return polylines;
  }
  
  List<Marker> _buildStationMarkers(dynamic itinerary, bool isDark) {
    final List<Marker> markers = [];
    final allStations = itinerary.allStations;
    
    for (int i = 0; i < allStations.length; i++) {
      final station = allStations[i];
      final isOrigin = i == 0;
      final isDestination = i == allStations.length - 1;
      
      markers.add(Marker(
        point: LatLng(station.latitude, station.longitude),
        width: isOrigin || isDestination ? 40 : 24,
        height: isOrigin || isDestination ? 40 : 24,
        child: Container(
          decoration: BoxDecoration(
            color: isOrigin 
                ? AppColors.success 
                : isDestination 
                    ? AppColors.secondary 
                    : (isDark ? AppColors.darkSurface : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(
              color: isOrigin || isDestination 
                  ? Colors.white 
                  : AppColors.primary,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
              ),
            ],
          ),
          child: isOrigin || isDestination
              ? Icon(
                  isOrigin ? LucideIcons.circleDot : LucideIcons.mapPin,
                  color: Colors.white,
                  size: 20,
                )
              : null,
        ),
      ));
    }
    
    return markers;
  }
  
  Widget _buildCollapsibleSearchCard(
    BuildContext context,
    RoutingProvider routing,
    bool isDark,
  ) {
    final showMap = routing.hasResults && routing.selectedItinerary != null;
    
    return AnimatedBuilder(
      animation: _searchAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minimize/Expand header (only show when results exist)
              if (showMap)
                InkWell(
                  onTap: _toggleSearchContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.search,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isSearchContainerMinimized 
                                ? '${routing.origin?.name ?? ""} → ${routing.destination?.name ?? ""}'
                                : 'Recherche d\'itinéraire',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AnimatedRotation(
                          turns: _isSearchContainerMinimized ? 0 : 0.5,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            LucideIcons.chevronDown,
                            size: 20,
                            color: isDark ? AppColors.grey400 : AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Expandable content
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: SizedBox(
                    height: _isSearchContainerMinimized ? 0 : null,
                    child: _isSearchContainerMinimized ? null : _buildSearchContent(context, routing, isDark),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSearchContent(
    BuildContext context,
    RoutingProvider routing,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
                      onPressed: () => setState(() => _showOriginPicker = false),
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
                      onPressed: () => setState(() => _showDestinationPicker = false),
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
                  showCurrentLocation: false,
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }
  
  Widget _buildCollapsibleItineraryCard(
    BuildContext context,
    RoutingProvider routing,
    bool isDark,
  ) {
    return AnimatedBuilder(
      animation: _itineraryAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * (_isItineraryContainerMinimized ? 0.1 : 0.45),
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle and minimize button
              InkWell(
                onTap: _toggleItineraryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey700 : AppColors.grey300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.route,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${routing.itineraries.length} itinéraire${routing.itineraries.length > 1 ? 's' : ''} trouvé${routing.itineraries.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _isItineraryContainerMinimized ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              LucideIcons.chevronUp,
                              size: 20,
                              color: isDark ? AppColors.grey400 : AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Expandable itinerary list
              if (!_isItineraryContainerMinimized)
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    itemCount: routing.itineraries.length,
                    itemBuilder: (context, index) {
                      final itinerary = routing.itineraries[index];
                      final isSelected = routing.selectedItinerary?.id == itinerary.id;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ItineraryCard(
                          itinerary: itinerary,
                          isSelected: isSelected,
                          showDetails: false,
                          onTap: () {
                            routing.selectItinerary(itinerary);
                            // Fit map to show the route
                            Future.delayed(const Duration(milliseconds: 100), () {
                              _fitBoundsToRoute(routing);
                            });
                            // Optionally minimize to see more map
                            if (!_isSearchContainerMinimized) {
                              _toggleSearchContainer();
                            }
                          },
                          onDoubleTap: () {
                            // Navigate to full map view on double tap
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => RouteMapScreen(
                                  itinerary: itinerary,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              
              // View full map button
              if (!_isItineraryContainerMinimized && routing.selectedItinerary != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RouteMapScreen(
                              itinerary: routing.selectedItinerary!,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: AppColors.primary),
                      ),
                      icon: const Icon(LucideIcons.maximize2, size: 18),
                      label: const Text('Voir carte complète'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, RoutingProvider routing, bool isDark) {
    // Error state
    if (routing.errorMessage != null && routing.state != RoutingState.loading) {
      return _buildErrorState(routing, isDark);
    }

    // Results - show list only when no itinerary is selected yet
    if (routing.hasResults && routing.selectedItinerary == null) {
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
              final isSelected = routing.selectedItinerary?.id == itinerary.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ItineraryCard(
                  itinerary: itinerary,
                  isSelected: isSelected,
                  showDetails: false,
                  onTap: () {
                    routing.selectItinerary(itinerary);
                    // When selected, the map will appear and we use collapsible cards
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
