import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sntf/data/models/routing.dart';
import 'package:sntf/data/models/transport.dart';
import 'package:sntf/data/services/routing_service.dart';
import 'package:sntf/data/services/supabase_service.dart';

/// State for route planning
enum RoutingState {
  initial,
  loading,
  ready,
  searching,
  resultsReady,
  routeSelected,
  error,
}

/// Provider for managing route planning and navigation
class RoutingProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final RoutingService _routingService = RoutingService();
  
  // State
  RoutingState _state = RoutingState.initial;
  String? _errorMessage;
  
  // Origin and destination
  RoutePoint? _origin;
  RoutePoint? _destination;
  
  // Search results
  RouteSearchResult? _searchResult;
  Itinerary? _selectedItinerary;
  
  // Available stations for selection
  List<Station> _stations = [];
  List<Station> _nearbyStations = [];
  
  // Current position (for "my location" feature)
  Position? _currentPosition;
  
  // Getters
  RoutingState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == RoutingState.loading || _state == RoutingState.searching;
  bool get hasError => _state == RoutingState.error;
  bool get isReady => _routingService.isInitialized;
  
  RoutePoint? get origin => _origin;
  RoutePoint? get destination => _destination;
  bool get canSearch => _origin != null && _destination != null;
  
  RouteSearchResult? get searchResult => _searchResult;
  List<Itinerary> get itineraries => _searchResult?.itineraries ?? [];
  bool get hasResults => _searchResult?.hasResults ?? false;
  
  Itinerary? get selectedItinerary => _selectedItinerary;
  bool get hasSelectedRoute => _selectedItinerary != null;
  
  List<Station> get stations => _stations;
  List<Station> get nearbyStations => _nearbyStations;
  
  Position? get currentPosition => _currentPosition;
  
  RoutingProvider() {
    _initialize();
  }
  
  /// Initialize the routing provider
  Future<void> _initialize() async {
    _state = RoutingState.loading;
    notifyListeners();
    
    try {
      await _loadStationsAndBuildGraph();
      await _getCurrentLocation();
      _state = RoutingState.ready;
    } catch (e) {
      debugPrint('Error initializing routing: $e');
      _errorMessage = 'Erreur lors de l\'initialisation du routage';
      _state = RoutingState.error;
    }
    
    notifyListeners();
  }
  
  /// Load stations and build routing graph
  Future<void> _loadStationsAndBuildGraph() async {
    // Load all data needed for routing
    final stationsData = await _supabase.getStations();
    final lignesData = await _supabase.getLignes();
    final arretsData = await _supabase.getAllArretsLignes();
    
    _stations = stationsData.map((json) => Station.fromJson(json)).toList();
    final lignes = lignesData.map((json) => Ligne.fromJson(json)).toList();
    final arrets = arretsData.map((json) => ArretLigne.fromJson(json)).toList();
    
    // Build the routing graph
    _routingService.buildGraph(_stations, lignes, arrets);
  }
  
  /// Get current location
  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      
      if (permission != LocationPermission.deniedForever) {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        
        // Update nearby stations
        if (_currentPosition != null) {
          _nearbyStations = _routingService.findNearestStations(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            radiusKm: 2.0,
            limit: 10,
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }
  
  /// Set origin point
  void setOrigin(RoutePoint? origin) {
    _origin = origin;
    _clearResults();
    notifyListeners();
  }
  
  /// Set origin from station
  void setOriginStation(Station station) {
    _origin = RoutePoint.fromStation(station);
    _clearResults();
    notifyListeners();
  }
  
  /// Set origin to current location
  void setOriginToCurrentLocation() {
    if (_currentPosition != null) {
      _origin = RoutePoint.fromCurrentLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      _clearResults();
      notifyListeners();
    }
  }
  
  /// Set destination point
  void setDestination(RoutePoint? destination) {
    _destination = destination;
    _clearResults();
    notifyListeners();
  }
  
  /// Set destination from station
  void setDestinationStation(Station station) {
    _destination = RoutePoint.fromStation(station);
    _clearResults();
    notifyListeners();
  }
  
  /// Swap origin and destination
  void swapOriginDestination() {
    final temp = _origin;
    _origin = _destination;
    _destination = temp;
    _clearResults();
    notifyListeners();
  }
  
  /// Clear search results
  void _clearResults() {
    _searchResult = null;
    _selectedItinerary = null;
    if (_state == RoutingState.resultsReady || _state == RoutingState.routeSelected) {
      _state = RoutingState.ready;
    }
  }
  
  /// Search for routes
  Future<void> searchRoutes() async {
    if (!canSearch) {
      _errorMessage = 'Veuillez sélectionner un départ et une arrivée';
      notifyListeners();
      return;
    }
    
    _state = RoutingState.searching;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _searchResult = _routingService.findRoutes(
        _origin!,
        _destination!,
        maxResults: 4,
        maxTransfers: 2,
      );
      
      if (_searchResult!.hasError) {
        _errorMessage = _searchResult!.errorMessage;
        _state = RoutingState.error;
      } else if (!_searchResult!.hasResults) {
        _errorMessage = 'Aucun itinéraire trouvé';
        _state = RoutingState.ready;
      } else {
        _state = RoutingState.resultsReady;
      }
    } catch (e) {
      debugPrint('Error searching routes: $e');
      _errorMessage = 'Erreur lors de la recherche d\'itinéraires';
      _state = RoutingState.error;
    }
    
    notifyListeners();
  }
  
  /// Select an itinerary
  void selectItinerary(Itinerary itinerary) {
    _selectedItinerary = itinerary;
    _state = RoutingState.routeSelected;
    notifyListeners();
  }
  
  /// Clear selected itinerary
  void clearSelectedItinerary() {
    _selectedItinerary = null;
    _state = _searchResult?.hasResults == true 
        ? RoutingState.resultsReady 
        : RoutingState.ready;
    notifyListeners();
  }
  
  /// Clear all selections
  void clearAll() {
    _origin = null;
    _destination = null;
    _searchResult = null;
    _selectedItinerary = null;
    _errorMessage = null;
    _state = RoutingState.ready;
    notifyListeners();
  }
  
  /// Search stations by name
  List<Station> searchStations(String query) {
    if (query.isEmpty) return _stations;
    final lowercaseQuery = query.toLowerCase();
    return _stations
        .where((s) => s.nom.toLowerCase().contains(lowercaseQuery))
        .toList();
  }
  
  /// Get lignes for a station
  List<Ligne> getLignesForStation(String stationId) {
    return _routingService.getLignesForStation(stationId);
  }
  
  /// Refresh location and nearby stations
  Future<void> refreshLocation() async {
    await _getCurrentLocation();
    notifyListeners();
  }
  
  /// Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == RoutingState.error) {
      _state = RoutingState.ready;
    }
    notifyListeners();
  }
  
  /// Refresh everything
  Future<void> refresh() async {
    await _initialize();
  }
  
  @override
  void dispose() {
    _routingService.clear();
    super.dispose();
  }
}
