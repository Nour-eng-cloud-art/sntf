import 'package:sntf/data/models/transport.dart';

/// Represents a single segment of a route (e.g., take Line 1 from Station A to Station B)
class RouteSegment {
  final Ligne ligne;
  final List<Station> stations; // Ordered list of stations in this segment
  final Station departureStation;
  final Station arrivalStation;
  final Duration estimatedDuration;
  final int stopCount;

  RouteSegment({
    required this.ligne,
    required this.stations,
    required this.departureStation,
    required this.arrivalStation,
    required this.estimatedDuration,
    required this.stopCount,
  });

  /// Get the color of this segment's ligne
  String get color => ligne.couleurHex ?? '#4285F4';

  /// Human-readable description
  String get description {
    return 'Prendre ${ligne.type.name} ${ligne.nomCourt} direction ${ligne.directionTerminus}';
  }
}

/// Represents a complete itinerary from origin to destination
class Itinerary {
  final String id;
  final Station origin;
  final Station destination;
  final List<RouteSegment> segments;
  final Duration totalDuration;
  final int totalStops;
  final int transfers; // Number of line changes
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final double? walkingDistanceStart; // meters to walk to first station
  final double? walkingDistanceEnd; // meters to walk from last station

  Itinerary({
    required this.id,
    required this.origin,
    required this.destination,
    required this.segments,
    required this.totalDuration,
    required this.totalStops,
    required this.transfers,
    this.departureTime,
    this.arrivalTime,
    this.walkingDistanceStart,
    this.walkingDistanceEnd,
  });

  /// Get all stations in order for the entire itinerary
  List<Station> get allStations {
    final List<Station> result = [];
    for (final segment in segments) {
      if (result.isEmpty) {
        result.addAll(segment.stations);
      } else {
        // Skip the first station of subsequent segments (it's the same as the last of previous)
        result.addAll(segment.stations.skip(1));
      }
    }
    return result;
  }

  /// Get all unique lignes used in this itinerary
  List<Ligne> get lignesUsed => segments.map((s) => s.ligne).toList();

  /// Human-readable summary
  String get summary {
    if (segments.length == 1) {
      return 'Direct - ${segments.first.ligne.nomCourt}';
    }
    return '${transfers} correspondance${transfers > 1 ? 's' : ''} - ${lignesUsed.map((l) => l.nomCourt).join(' → ')}';
  }

  /// Format duration as string
  String get formattedDuration {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes} min';
  }
}

/// Represents a user's location point (can be a station or custom location)
class RoutePoint {
  final String? stationId;
  final Station? station;
  final double latitude;
  final double longitude;
  final String name;
  final bool isCurrentLocation;

  RoutePoint({
    this.stationId,
    this.station,
    required this.latitude,
    required this.longitude,
    required this.name,
    this.isCurrentLocation = false,
  });

  factory RoutePoint.fromStation(Station station) {
    return RoutePoint(
      stationId: station.id,
      station: station,
      latitude: station.latitude,
      longitude: station.longitude,
      name: station.nom,
    );
  }

  factory RoutePoint.fromCurrentLocation(double lat, double lng) {
    return RoutePoint(
      latitude: lat,
      longitude: lng,
      name: 'Ma position',
      isCurrentLocation: true,
    );
  }

  factory RoutePoint.fromCoordinates(double lat, double lng, String name) {
    return RoutePoint(
      latitude: lat,
      longitude: lng,
      name: name,
    );
  }
}

/// Graph node for pathfinding
class StationNode {
  final Station station;
  final List<StationEdge> edges;

  StationNode({
    required this.station,
    this.edges = const [],
  });
}

/// Graph edge connecting two stations on a ligne
class StationEdge {
  final Station fromStation;
  final Station toStation;
  final Ligne ligne;
  final int ordrePassage; // Position in ligne's stops

  StationEdge({
    required this.fromStation,
    required this.toStation,
    required this.ligne,
    required this.ordrePassage,
  });

  /// Estimated travel time between adjacent stations (2 minutes default)
  Duration get estimatedDuration => const Duration(minutes: 2);
}

/// Result of a route search
class RouteSearchResult {
  final List<Itinerary> itineraries;
  final RoutePoint origin;
  final RoutePoint destination;
  final bool hasDirectRoute;
  final String? errorMessage;

  RouteSearchResult({
    required this.itineraries,
    required this.origin,
    required this.destination,
    this.hasDirectRoute = false,
    this.errorMessage,
  });

  bool get hasResults => itineraries.isNotEmpty;
  bool get hasError => errorMessage != null;
}
