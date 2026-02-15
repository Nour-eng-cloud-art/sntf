import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Place prediction from TomTom Search Autocomplete
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

  factory PlacePrediction.fromTomTomJson(Map<String, dynamic> json) {
    final address = json['address'] ?? {};
    final position = json['position'] ?? {};
    
    final mainText = address['freeformAddress'] ?? 
                     address['streetName'] ?? 
                     json['poi']?['name'] ?? 
                     'Unknown';
    
    final municipality = address['municipality'] ?? '';
    final country = address['country'] ?? '';
    final secondaryText = [municipality, country]
        .where((s) => s.isNotEmpty)
        .join(', ');
    
    LatLng? latLng;
    if (position['lat'] != null && position['lon'] != null) {
      latLng = LatLng(
        (position['lat'] as num).toDouble(),
        (position['lon'] as num).toDouble(),
      );
    }

    return PlacePrediction(
      placeId: json['id']?.toString() ?? '',
      description: mainText + (secondaryText.isNotEmpty ? ', $secondaryText' : ''),
      mainText: json['poi']?['name'] ?? address['streetName'] ?? mainText,
      secondaryText: secondaryText,
      position: latLng,
    );
  }
}

/// Place details from TomTom
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

  factory PlaceDetails.fromTomTomJson(Map<String, dynamic> json) {
    final address = json['address'] ?? {};
    final position = json['position'] ?? {};
    
    final components = <String, String>{
      'street': address['streetName'] ?? '',
      'city': address['municipality'] ?? address['localName'] ?? '',
      'state': address['countrySubdivision'] ?? '',
      'country': address['country'] ?? '',
      'postalCode': address['postalCode'] ?? '',
    };

    final name = json['poi']?['name'] ?? 
                 address['streetName'] ?? 
                 address['freeformAddress'] ?? 
                 'Unknown';

    return PlaceDetails(
      placeId: json['id']?.toString() ?? '',
      name: name,
      formattedAddress: address['freeformAddress'] ?? '',
      location: LatLng(
        (position['lat'] as num?)?.toDouble() ?? 0,
        (position['lon'] as num?)?.toDouble() ?? 0,
      ),
      vicinity: address['municipality'],
      addressComponents: components,
    );
  }
}

/// TomTom Search API Service
class TomTomService {
  final String apiKey;
  static const String _baseUrl = 'https://api.tomtom.com/search/2';
  
  TomTomService({required this.apiKey});

  /// Search for place predictions (fuzzy search / autocomplete)
  Future<List<PlacePrediction>> getPlacePredictions(
    String query, {
    LatLng? location,
    int? radius,
    String language = 'fr-FR',
    String? countrySet,
    int limit = 10,
  }) async {
    if (query.isEmpty) return [];

    final params = {
      'key': apiKey,
      'language': language,
      'limit': limit.toString(),
      'typeahead': 'true',
      if (location != null) 'lat': location.latitude.toString(),
      if (location != null) 'lon': location.longitude.toString(),
      if (radius != null) 'radius': radius.toString(),
      if (countrySet != null) 'countrySet': countrySet,
    };

    final encodedQuery = Uri.encodeComponent(query);
    final uri = Uri.parse('$_baseUrl/search/$encodedQuery.json')
        .replace(queryParameters: params);
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final results = json['results'] as List? ?? [];
        return results.map((r) => PlacePrediction.fromTomTomJson(r)).toList();
      }
    } catch (e) {
      // Handle error silently, return empty list
    }
    return [];
  }

  /// Reverse geocode - get address from coordinates
  Future<PlaceDetails?> reverseGeocode(LatLng position, {String language = 'fr-FR'}) async {
    final params = {
      'key': apiKey,
      'language': language,
    };

    final uri = Uri.parse(
      '$_baseUrl/reverseGeocode/${position.latitude},${position.longitude}.json'
    ).replace(queryParameters: params);
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final addresses = json['addresses'] as List? ?? [];
        if (addresses.isNotEmpty) {
          final result = addresses.first;
          final address = result['address'] ?? {};
          
          return PlaceDetails(
            placeId: result['id']?.toString() ?? '',
            name: address['streetName'] ?? 
                  address['municipality'] ?? 
                  address['freeformAddress'] ?? 'Unknown',
            formattedAddress: address['freeformAddress'] ?? '',
            location: position,
            vicinity: address['municipality'],
            addressComponents: {
              'street': address['streetName'] ?? '',
              'city': address['municipality'] ?? address['localName'] ?? '',
              'state': address['countrySubdivision'] ?? '',
              'country': address['country'] ?? '',
              'postalCode': address['postalCode'] ?? '',
              'name': address['streetName'] ?? address['municipality'] ?? '',
              'display_name': address['freeformAddress'] ?? '',
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
    String language = 'fr-FR',
    int limit = 20,
  }) async {
    final params = {
      'key': apiKey,
      'lat': location.latitude.toString(),
      'lon': location.longitude.toString(),
      'radius': radius.toString(),
      'language': language,
      'limit': limit.toString(),
      if (categorySet != null) 'categorySet': categorySet,
    };

    final uri = Uri.parse('$_baseUrl/nearbySearch/.json')
        .replace(queryParameters: params);
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final results = json['results'] as List? ?? [];
        return results.map((r) => PlaceDetails.fromTomTomJson(r)).toList();
      }
    } catch (e) {
      // Handle error silently
    }
    return [];
  }

  /// Get TomTom map tile URL
  static String getTileUrl(String apiKey) {
    return 'https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key=$apiKey';
  }

  /// Get TomTom satellite tile URL
  static String getSatelliteTileUrl(String apiKey) {
    return 'https://api.tomtom.com/map/1/tile/sat/main/{z}/{x}/{y}.jpg?key=$apiKey';
  }

  /// Get TomTom hybrid tile URL (satellite with labels)
  static String getHybridTileUrl(String apiKey) {
    return 'https://api.tomtom.com/map/1/tile/hybrid/main/{z}/{x}/{y}.png?key=$apiKey';
  }
}

