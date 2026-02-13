import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sntf/data/models/transport.dart';

/// Map state
enum MapState {
  initial,
  loading,
  ready,
  error,
}

/// MapProvider manages location and map-related functionality
class MapProvider extends ChangeNotifier {
  // State
  MapState _state = MapState.initial;
  String? _errorMessage;
  
  // Location
  Position? _currentPosition;
  LatLng? _selectedLocation;
  bool _isTracking = false;
  
  // Map config
  double _zoom = 13.0;
  LatLng _center = const LatLng(36.7538, 3.0588); // Default: Algiers
  
  // Selected items
  Station? _selectedStation;
  Ligne? _selectedLigne;
  
  // Getters
  MapState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == MapState.loading;
  bool get hasError => _state == MapState.error;
  
  Position? get currentPosition => _currentPosition;
  LatLng? get currentLatLng => _currentPosition != null 
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : null;
  LatLng? get selectedLocation => _selectedLocation;
  bool get isTracking => _isTracking;
  
  double get zoom => _zoom;
  LatLng get center => _center;
  
  Station? get selectedStation => _selectedStation;
  Ligne? get selectedLigne => _selectedLigne;
  
  MapProvider() {
    _initialize();
  }
  
  /// Initialize location services
  Future<void> _initialize() async {
    _state = MapState.loading;
    notifyListeners();
    
    final hasPermission = await _checkAndRequestPermission();
    if (hasPermission) {
      await getCurrentLocation();
    }
    
    _state = MapState.ready;
    notifyListeners();
  }
  
  /// Check and request location permission
  Future<bool> _checkAndRequestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Les services de localisation sont désactivés';
        return false;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Permission de localisation refusée';
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Permission de localisation refusée définitivement';
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      _errorMessage = 'Erreur lors de la vérification des permissions';
      return false;
    }
  }
  
  /// Get current location
  Future<void> getCurrentLocation() async {
    try {
      _state = MapState.loading;
      _errorMessage = null;
      notifyListeners();
      
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      if (_currentPosition != null) {
        _center = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      }
      
      _state = MapState.ready;
    } catch (e) {
      debugPrint('Error getting location: $e');
      _errorMessage = 'Impossible d\'obtenir la position actuelle';
      _state = MapState.error;
    }
    notifyListeners();
  }
  
  /// Start tracking location
  void startTracking() {
    if (_isTracking) return;
    
    _isTracking = true;
    notifyListeners();
    
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(
      (Position position) {
        _currentPosition = position;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Location tracking error: $error');
        _isTracking = false;
        notifyListeners();
      },
    );
  }
  
  /// Stop tracking location
  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }
  
  /// Set map center
  void setCenter(LatLng center) {
    _center = center;
    notifyListeners();
  }
  
  /// Set map zoom
  void setZoom(double zoom) {
    _zoom = zoom.clamp(5.0, 18.0);
    notifyListeners();
  }
  
  /// Center map on current location
  void centerOnCurrentLocation() {
    if (_currentPosition != null) {
      _center = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      _zoom = 15.0;
      notifyListeners();
    }
  }
  
  /// Center map on a station
  void centerOnStation(Station station) {
    _center = LatLng(station.latitude, station.longitude);
    _selectedStation = station;
    _zoom = 16.0;
    notifyListeners();
  }
  
  /// Select a location on the map
  void selectLocation(LatLng location) {
    _selectedLocation = location;
    notifyListeners();
  }
  
  /// Clear selected location
  void clearSelectedLocation() {
    _selectedLocation = null;
    notifyListeners();
  }
  
  /// Select a station
  void selectStation(Station station) {
    _selectedStation = station;
    centerOnStation(station);
  }
  
  /// Clear selected station
  void clearSelectedStation() {
    _selectedStation = null;
    notifyListeners();
  }
  
  /// Select a ligne
  void selectLigne(Ligne ligne) {
    _selectedLigne = ligne;
    notifyListeners();
  }
  
  /// Clear selected ligne
  void clearSelectedLigne() {
    _selectedLigne = null;
    notifyListeners();
  }
  
  /// Calculate distance between current position and a station
  double? distanceToStation(Station station) {
    if (_currentPosition == null) return null;
    
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      station.latitude,
      station.longitude,
    );
  }
  
  /// Get formatted distance string
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
  
  /// Calculate estimated walking time to a station (5 km/h average)
  Duration? walkingTimeToStation(Station station) {
    final distance = distanceToStation(station);
    if (distance == null) return null;
    
    // 5 km/h = 83.33 m/min
    final minutes = (distance / 83.33).round();
    return Duration(minutes: minutes);
  }
  
  /// Find nearest stations from current position
  List<MapEntry<Station, double>> findNearestStations(
    List<Station> stations, {
    int limit = 5,
  }) {
    if (_currentPosition == null) return [];
    
    final stationsWithDistance = stations.map((station) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        station.latitude,
        station.longitude,
      );
      return MapEntry(station, distance);
    }).toList();
    
    stationsWithDistance.sort((a, b) => a.value.compareTo(b.value));
    return stationsWithDistance.take(limit).toList();
  }
  
  /// Create bounds for a list of stations
  (LatLng, LatLng)? getBoundsForStations(List<Station> stations) {
    if (stations.isEmpty) return null;
    
    double minLat = stations.first.latitude;
    double maxLat = stations.first.latitude;
    double minLng = stations.first.longitude;
    double maxLng = stations.first.longitude;
    
    for (final station in stations) {
      if (station.latitude < minLat) minLat = station.latitude;
      if (station.latitude > maxLat) maxLat = station.latitude;
      if (station.longitude < minLng) minLng = station.longitude;
      if (station.longitude > maxLng) maxLng = station.longitude;
    }
    
    // Add padding
    const padding = 0.01;
    return (
      LatLng(minLat - padding, minLng - padding),
      LatLng(maxLat + padding, maxLng + padding),
    );
  }
  
  /// Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == MapState.error) {
      _state = MapState.ready;
    }
    notifyListeners();
  }
  
  /// Refresh location
  Future<void> refresh() async {
    await getCurrentLocation();
  }
}
