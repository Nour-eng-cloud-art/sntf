import 'package:flutter/foundation.dart';
import 'package:sntf/data/models/transport.dart';
import 'package:sntf/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Transport data loading state
enum TransportLoadingState {
  initial,
  loading,
  loaded,
  error,
}

/// TransportProvider manages all transport-related data:
/// - Lignes (bus, tramway, train routes)
/// - Stations
/// - Horaires (schedules)
/// - Vehicules
class TransportProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  
  // State
  TransportLoadingState _state = TransportLoadingState.initial;
  String? _errorMessage;
  
  // Data
  List<Ligne> _lignes = [];
  List<Station> _stations = [];
  List<Horaire> _horaires = [];
  List<Vehicule> _vehicules = [];
  List<ArretLigne> _arretsLignes = [];
  
  // Selected items
  Ligne? _selectedLigne;
  Station? _selectedStation;
  
  // Real-time subscriptions
  RealtimeChannel? _horairesChannel;
  
  // Getters
  TransportLoadingState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == TransportLoadingState.loading;
  bool get hasError => _state == TransportLoadingState.error;
  
  List<Ligne> get lignes => _lignes;
  List<Station> get stations => _stations;
  List<Horaire> get horaires => _horaires;
  List<Vehicule> get vehicules => _vehicules;
  
  Ligne? get selectedLigne => _selectedLigne;
  Station? get selectedStation => _selectedStation;
  
  // Filtered getters
  List<Ligne> get busLignes => 
      _lignes.where((l) => l.type == TransportType.bus).toList();
  List<Ligne> get tramwayLignes => 
      _lignes.where((l) => l.type == TransportType.tramway).toList();
  List<Ligne> get trainLignes => 
      _lignes.where((l) => l.type == TransportType.train).toList();
  List<Ligne> get metroLignes => 
      _lignes.where((l) => l.type == TransportType.metro).toList();
  
  List<Vehicule> get vehiculesEnService => 
      _vehicules.where((v) => v.estEnService).toList();
  
  List<Horaire> get upcomingHoraires {
    final now = DateTime.now();
    return _horaires
        .where((h) => h.heurePassage.isAfter(now))
        .toList()
      ..sort((a, b) => a.heurePassage.compareTo(b.heurePassage));
  }
  
  TransportProvider() {
    loadAllData();
  }
  
  /// Load all transport data
  Future<void> loadAllData() async {
    try {
      _state = TransportLoadingState.loading;
      _errorMessage = null;
      notifyListeners();
      
      await Future.wait([
        _loadLignes(),
        _loadStations(),
        _loadVehicules(),
      ]);
      
      _state = TransportLoadingState.loaded;
    } catch (e) {
      debugPrint('Error loading transport data: $e');
      _errorMessage = 'Erreur lors du chargement des données';
      _state = TransportLoadingState.error;
    }
    notifyListeners();
  }
  
  /// Load all lignes
  Future<void> _loadLignes() async {
    final data = await _supabase.getLignes();
    _lignes = data.map((json) => Ligne.fromJson(json)).toList();
  }
  
  /// Load all stations
  Future<void> _loadStations() async {
    final data = await _supabase.getStations();
    _stations = data.map((json) => Station.fromJson(json)).toList();
  }
  
  /// Load all vehicules
  Future<void> _loadVehicules() async {
    final data = await _supabase.getVehicules();
    _vehicules = data.map((json) => Vehicule.fromJson(json)).toList();
  }
  
  /// Get lignes by type
  Future<List<Ligne>> getLignesByType(TransportType type) async {
    try {
      final data = await _supabase.getLignesByType(type.name);
      return data.map((json) => Ligne.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading lignes by type: $e');
      return [];
    }
  }
  
  /// Select a ligne and load its stations and schedules
  Future<void> selectLigne(Ligne ligne) async {
    _selectedLigne = ligne;
    notifyListeners();
    
    await Future.wait([
      loadStationsForLigne(ligne.id),
      loadHorairesForLigne(ligne.id),
    ]);
  }
  
  /// Clear selected ligne
  void clearSelectedLigne() {
    _selectedLigne = null;
    _arretsLignes = [];
    notifyListeners();
  }
  
  /// Select a station and load its schedules
  Future<void> selectStation(Station station) async {
    _selectedStation = station;
    notifyListeners();
    
    await loadHorairesForStation(station.id);
  }
  
  /// Clear selected station
  void clearSelectedStation() {
    _selectedStation = null;
    _horaires = [];
    notifyListeners();
  }
  
  /// Load stations for a specific ligne (in order)
  Future<List<Station>> loadStationsForLigne(String ligneId) async {
    try {
      final data = await _supabase.getStationsForLigne(ligneId);
      _arretsLignes = data.map((json) => ArretLigne.fromJson(json)).toList();
      notifyListeners();
      return _arretsLignes
          .where((al) => al.station != null)
          .map((al) => al.station!)
          .toList();
    } catch (e) {
      debugPrint('Error loading stations for ligne: $e');
      return [];
    }
  }
  
  /// Get stations for the selected ligne
  List<Station> getStationsForSelectedLigne() {
    return _arretsLignes
        .where((al) => al.station != null)
        .map((al) => al.station!)
        .toList();
  }
  
  /// Load lignes passing through a station
  Future<List<Ligne>> loadLignesForStation(String stationId) async {
    try {
      final data = await _supabase.getLignesForStation(stationId);
      final arretsLignes = data.map((json) => ArretLigne.fromJson(json)).toList();
      return arretsLignes
          .where((al) => al.ligne != null)
          .map((al) => al.ligne!)
          .toList();
    } catch (e) {
      debugPrint('Error loading lignes for station: $e');
      return [];
    }
  }
  
  /// Load horaires for a station
  Future<void> loadHorairesForStation(String stationId) async {
    try {
      final data = await _supabase.getHorairesForStation(stationId);
      _horaires = data.map((json) => Horaire.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading horaires for station: $e');
    }
  }
  
  /// Load horaires for a ligne
  Future<void> loadHorairesForLigne(String ligneId) async {
    try {
      final data = await _supabase.getHorairesForLigne(ligneId);
      _horaires = data.map((json) => Horaire.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading horaires for ligne: $e');
    }
  }
  
  /// Get upcoming departures for a station
  Future<List<Horaire>> getUpcomingDepartures(String stationId, {int limit = 10}) async {
    try {
      final data = await _supabase.getUpcomingHoraires(stationId, limit: limit);
      return data.map((json) => Horaire.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading upcoming departures: $e');
      return [];
    }
  }
  
  /// Get horaires for a specific ligne at a specific station
  Future<List<Horaire>> getHorairesForLigneAtStation(String ligneId, String stationId) async {
    try {
      final data = await _supabase.getHorairesForLigneAtStation(ligneId, stationId);
      return data.map((json) => Horaire.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading horaires: $e');
      return [];
    }
  }
  
  /// Get vehicules for a ligne
  Future<List<Vehicule>> getVehiculesForLigne(String ligneId) async {
    try {
      final data = await _supabase.getVehiculesForLigne(ligneId);
      return data.map((json) => Vehicule.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading vehicules: $e');
      return [];
    }
  }
  
  /// Search stations by name
  List<Station> searchStations(String query) {
    if (query.isEmpty) return _stations;
    final lowercaseQuery = query.toLowerCase();
    return _stations
        .where((s) => s.nom.toLowerCase().contains(lowercaseQuery))
        .toList();
  }
  
  /// Search lignes by name
  List<Ligne> searchLignes(String query) {
    if (query.isEmpty) return _lignes;
    final lowercaseQuery = query.toLowerCase();
    return _lignes
        .where((l) => 
            l.nomCourt.toLowerCase().contains(lowercaseQuery) ||
            l.directionTerminus.toLowerCase().contains(lowercaseQuery))
        .toList();
  }
  
  /// Find nearest stations to a location
  List<Station> findNearestStations(double latitude, double longitude, {int limit = 5}) {
    final stationsWithDistance = _stations.map((station) {
      final distance = _calculateDistance(
        latitude, longitude,
        station.latitude, station.longitude,
      );
      return MapEntry(station, distance);
    }).toList();
    
    stationsWithDistance.sort((a, b) => a.value.compareTo(b.value));
    
    return stationsWithDistance
        .take(limit)
        .map((e) => e.key)
        .toList();
  }
  
  /// Calculate distance between two points (Haversine formula approximation)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = 
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
        _sin(dLon / 2) * _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }
  
  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;
  double _sin(double x) => _sinTable(x);
  double _cos(double x) => _sinTable(x + 1.5707963267948966);
  double _sqrt(double x) => x <= 0 ? 0 : _sqrtNewton(x);
  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 1.5707963267948966;
    if (x == 0 && y < 0) return -1.5707963267948966;
    return 0;
  }
  
  double _sqrtNewton(double x) {
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  
  double _sinTable(double x) {
    // Normalize to [-pi, pi]
    while (x > 3.141592653589793) x -= 6.283185307179586;
    while (x < -3.141592653589793) x += 6.283185307179586;
    // Taylor series approximation
    final x2 = x * x;
    return x * (1 - x2/6 * (1 - x2/20 * (1 - x2/42)));
  }
  
  double _atan(double x) {
    // Simple approximation for small x
    if (x.abs() <= 1) {
      final x2 = x * x;
      return x * (1 - x2/3 + x2*x2/5 - x2*x2*x2/7);
    }
    // For |x| > 1, use atan(x) = pi/2 - atan(1/x)
    return (x > 0 ? 1 : -1) * 1.5707963267948966 - _atan(1/x);
  }
  
  /// Subscribe to real-time horaire updates for a station
  void subscribeToHoraires(String stationId) {
    _horairesChannel?.unsubscribe();
    
    _horairesChannel = _supabase.subscribeToTable(
      'horaires',
      onInsert: (payload) {
        final newHoraire = Horaire.fromJson(payload.newRecord);
        if (newHoraire.stationId == stationId) {
          _horaires.add(newHoraire);
          _horaires.sort((a, b) => a.heurePassage.compareTo(b.heurePassage));
          notifyListeners();
        }
      },
      onUpdate: (payload) {
        final updatedHoraire = Horaire.fromJson(payload.newRecord);
        final index = _horaires.indexWhere((h) => h.id == updatedHoraire.id);
        if (index != -1) {
          _horaires[index] = updatedHoraire;
          notifyListeners();
        }
      },
      onDelete: (payload) {
        final deletedId = payload.oldRecord['id'];
        _horaires.removeWhere((h) => h.id == deletedId);
        notifyListeners();
      },
    );
  }
  
  /// Unsubscribe from real-time updates
  void unsubscribeFromHoraires() {
    if (_horairesChannel != null) {
      _supabase.unsubscribe(_horairesChannel!);
      _horairesChannel = null;
    }
  }
  
  /// Refresh all data
  Future<void> refresh() async {
    await loadAllData();
  }
  
  /// Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == TransportLoadingState.error) {
      _state = _lignes.isNotEmpty 
          ? TransportLoadingState.loaded 
          : TransportLoadingState.initial;
    }
    notifyListeners();
  }
  
  @override
  void dispose() {
    unsubscribeFromHoraires();
    super.dispose();
  }
}
