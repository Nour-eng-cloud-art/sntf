import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Location service for handling all location-related operations
class LocationService {
  // Private constructor for singleton
  LocationService._();
  
  // Singleton instance
  static final LocationService _instance = LocationService._();
  
  // Factory constructor
  factory LocationService() => _instance;
  
  // Cache current position
  Position? _currentPosition;
  DateTime? _lastUpdate;
  
  /// Get current position (cached if recent)
  Position? get currentPosition => _currentPosition;
  
  /// Get current position as LatLng
  LatLng? get currentLatLng => _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : null;
  
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }
  
  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }
  
  /// Check and request permission if needed
  Future<bool> ensurePermission() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    
    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }
  
  /// Get current position
  Future<Position?> getCurrentPosition({
    bool forceRefresh = false,
    Duration cacheValidDuration = const Duration(minutes: 1),
  }) async {
    // Return cached position if recent and not forced
    if (!forceRefresh && 
        _currentPosition != null && 
        _lastUpdate != null &&
        DateTime.now().difference(_lastUpdate!) < cacheValidDuration) {
      return _currentPosition;
    }
    
    // Check permission
    final hasPermission = await ensurePermission();
    if (!hasPermission) {
      return null;
    }
    
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _lastUpdate = DateTime.now();
      return _currentPosition;
    } catch (e) {
      return null;
    }
  }
  
  /// Get position stream for continuous tracking
  Stream<Position> getPositionStream({
    int distanceFilter = 10,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }
  
  /// Calculate distance between two points in meters
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }
  
  /// Calculate distance from current position to a point
  double? distanceFromCurrentPosition(LatLng point) {
    if (_currentPosition == null) return null;
    return calculateDistance(currentLatLng!, point);
  }
  
  /// Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
  
  /// Calculate estimated walking time (average 5 km/h)
  Duration calculateWalkingTime(double meters) {
    // 5 km/h = 83.33 m/min
    final minutes = (meters / 83.33).round();
    return Duration(minutes: minutes);
  }
  
  /// Calculate estimated driving time (average 30 km/h in city)
  Duration calculateDrivingTime(double meters) {
    // 30 km/h = 500 m/min
    final minutes = (meters / 500).round();
    return Duration(minutes: minutes);
  }
  
  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
  
  /// Open app settings (for permission settings)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
