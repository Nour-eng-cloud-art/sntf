import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Place prediction from MapTiler Search Autocomplete
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final LatLng? position;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.position,
  });

  factory PlacePrediction.fromMapTilerJson(Map<String, dynamic> json) {
    final properties = json['properties'] ?? {};
    final geometry = json['geometry'] ?? {};
    final coordinates = geometry['coordinates'] as List?;
    
    final placeName = properties['name'] ?? 
                      json['place_name'] ?? 
                      'Unknown';
    
    final context = properties['context'] ?? json['context'] ?? {};
    final city = context['place']?['name'] ?? 
                 properties['city'] ?? 
                 properties['locality'] ?? '';
    final country = context['country']?['name'] ?? 
                    properties['country'] ?? '';
    final secondaryText = [city, country]
        .where((s) => s.isNotEmpty)
        .join(', ');
    
    LatLng? latLng;
    if (coordinates != null && coordinates.length >= 2) {
      latLng = LatLng(
        (coordinates[1] as num).toDouble(),
        (coordinates[0] as num).toDouble(),
      );
    }

    return PlacePrediction(
      placeId: json['id']?.toString() ?? properties['id']?.toString() ?? '',
      description: placeName + (secondaryText.isNotEmpty ? ', $secondaryText' : ''),
      mainText: placeName,
      secondaryText: secondaryText,
      position: latLng,
    );
  }
}

/// Place details from MapTiler
class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final LatLng location;
  final String? vicinity;
  final Map<String, String> addressComponents;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.location,
    this.vicinity,
    this.addressComponents = const {},
  });

  factory PlaceDetails.fromMapTilerJson(Map<String, dynamic> json) {
    final properties = json['properties'] ?? {};
    final geometry = json['geometry'] ?? {};
    final coordinates = geometry['coordinates'] as List?;
    final context = properties['context'] ?? json['context'] ?? {};
    
    final components = <String, String>{
      'street': properties['street'] ?? '',
      'city': context['place']?['name'] ?? properties['city'] ?? properties['locality'] ?? '',
      'state': context['region']?['name'] ?? properties['state'] ?? '',
      'country': context['country']?['name'] ?? properties['country'] ?? '',
      'postalCode': properties['postcode'] ?? '',
    };

    final name = properties['name'] ?? 
                 json['place_name'] ?? 
                 'Unknown';

    double lat = 0;
    double lon = 0;
    if (coordinates != null && coordinates.length >= 2) {
      lon = (coordinates[0] as num).toDouble();
      lat = (coordinates[1] as num).toDouble();
    }

    return PlaceDetails(
      placeId: json['id']?.toString() ?? properties['id']?.toString() ?? '',
      name: name,
      formattedAddress: json['place_name'] ?? properties['full_address'] ?? name,
      location: LatLng(lat, lon),
      vicinity: components['city'],
      addressComponents: components,
    );
  }
}

/// MapTiler Search API Service
class MapTilerService {
  final String apiKey;
  static const String _baseUrl = 'https://api.maptiler.com/geocoding';
  
  MapTilerService({required this.apiKey});

  /// Search for place predictions (geocoding / autocomplete)
  Future<List<PlacePrediction>> getPlacePredictions(
    String query, {
    LatLng? location,
    int? radius,
    String language = 'fr',
    String? countrySet,
    int limit = 10,
  }) async {
    if (query.isEmpty) return [];

    final params = {
      'key': apiKey,
      'language': language,
      'limit': limit.toString(),
      'autocomplete': 'true',
      if (location != null) 'proximity': '${location.longitude},${location.latitude}',
      if (countrySet != null) 'country': countrySet,
    };

    final encodedQuery = Uri.encodeComponent(query);
    final uri = Uri.parse('$_baseUrl/$encodedQuery.json')
        .replace(queryParameters: params);
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final features = json['features'] as List? ?? [];
        return features.map((r) => PlacePrediction.fromMapTilerJson(r)).toList();
      }
    } catch (e) {
      // Handle error silently, return empty list
    }
    return [];
  }

  /// Reverse geocode - get address from coordinates
  Future<PlaceDetails?> reverseGeocode(LatLng position, {String language = 'fr'}) async {
    final params = {
      'key': apiKey,
      'language': language,
    };

    final uri = Uri.parse(
      '$_baseUrl/${position.longitude},${position.latitude}.json'
    ).replace(queryParameters: params);
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final features = json['features'] as List? ?? [];
        if (features.isNotEmpty) {
          final result = features.first;
          final properties = result['properties'] ?? {};
          final context = properties['context'] ?? result['context'] ?? {};
          
          return PlaceDetails(
            placeId: result['id']?.toString() ?? '',
            name: properties['name'] ?? 
                  result['place_name'] ?? 
                  'Unknown',
            formattedAddress: result['place_name'] ?? '',
            location: position,
            vicinity: context['place']?['name'] ?? properties['locality'],
            addressComponents: {
              'street': properties['street'] ?? '',
              'city': context['place']?['name'] ?? properties['city'] ?? properties['locality'] ?? '',
              'state': context['region']?['name'] ?? properties['state'] ?? '',
              'country': context['country']?['name'] ?? properties['country'] ?? '',
              'postalCode': properties['postcode'] ?? '',
              'name': properties['name'] ?? '',
              'display_name': result['place_name'] ?? '',
            },
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }
    return null;
  }

  /// Search nearby places (POI search)
  Future<List<PlaceDetails>> searchNearby(
    LatLng location, {
    int radius = 1500,
    String? categorySet,
    String language = 'fr',
    int limit = 20,
  }) async {
    // MapTiler uses proximity-based search
    final params = {
      'key': apiKey,
      'language': language,
      'limit': limit.toString(),
      'proximity': '${location.longitude},${location.latitude}',
      if (categorySet != null) 'types': categorySet,
    };

    // Search for POIs in the area
    final uri = Uri.parse('$_baseUrl/.json')
        .replace(queryParameters: params);
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final features = json['features'] as List? ?? [];
        return features.map((r) => PlaceDetails.fromMapTilerJson(r)).toList();
      }
    } catch (e) {
      // Handle error silently
    }
    return [];
  }

  /// Get MapTiler streets map tile URL
  static String getTileUrl(String apiKey) {
    return 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$apiKey';
  }

  /// Get MapTiler satellite tile URL
  static String getSatelliteTileUrl(String apiKey) {
    return 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=$apiKey';
  }

  /// Get MapTiler hybrid tile URL (satellite with labels)
  static String getHybridTileUrl(String apiKey) {
    return 'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=$apiKey';
  }
}

// Backward compatibility alias
typedef TomTomService = MapTilerService;