import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sntf/data/models/routing.dart';
import 'package:sntf/data/models/transport.dart';

/// Service for calculating routes between stations
class RoutingService {
  // Graph data structure
  final Map<String, StationNode> _graph = {};
  final Map<String, Station> _stationsById = {};
  final Map<String, Ligne> _lignesById = {};
  final Map<String, List<ArretLigne>> _arretsParLigne = {};
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the routing graph from arrets_lignes data
  void buildGraph(
    List<Station> stations,
    List<Ligne> lignes,
    List<ArretLigne> arretsLignes,
  ) {
    _graph.clear();
    _stationsById.clear();
    _lignesById.clear();
    _arretsParLigne.clear();

    // Index stations and lignes
    for (final station in stations) {
      _stationsById[station.id] = station;
      _graph[station.id] = StationNode(station: station, edges: []);
    }

    for (final ligne in lignes) {
      _lignesById[ligne.id] = ligne;
    }

    // Group arrets by ligne
    for (final arret in arretsLignes) {
      _arretsParLigne.putIfAbsent(arret.ligneId, () => []).add(arret);
    }

    // Sort each ligne's arrets by ordre_passage
    for (final ligneId in _arretsParLigne.keys) {
      _arretsParLigne[ligneId]!.sort(
        (a, b) => (a.ordrePassage ?? 0).compareTo(b.ordrePassage ?? 0),
      );
    }

    // Build edges between consecutive stations on each ligne
    int edgesAdded = 0;
    int edgesSkipped = 0;
    for (final entry in _arretsParLigne.entries) {
      final ligneId = entry.key;
      final arrets = entry.value;
      final ligne = _lignesById[ligneId];
      
      if (ligne == null) continue;

      for (int i = 0; i < arrets.length - 1; i++) {
        final currentArret = arrets[i];
        final nextArret = arrets[i + 1];
        
        // IMPORTANT: Use stations from _stationsById to ensure consistency with graph nodes
        final fromStation = _stationsById[currentArret.stationId] ?? currentArret.station;
        final toStation = _stationsById[nextArret.stationId] ?? nextArret.station;
        
        if (fromStation == null || toStation == null) {
          edgesSkipped++;
          continue;
        }
        
        // Ensure stations exist in graph before adding edges
        if (!_graph.containsKey(fromStation.id) || !_graph.containsKey(toStation.id)) {
          edgesSkipped++;
          continue;
        }

        // Add bidirectional edges
        _addEdge(fromStation, toStation, ligne, currentArret.ordrePassage ?? i);
        _addEdge(toStation, fromStation, ligne, nextArret.ordrePassage ?? i + 1);
        edgesAdded += 2;
      }
    }

    _isInitialized = true;
    debugPrint('Routing graph built: ${_graph.length} nodes, ${_countEdges()} edges');
    debugPrint('Edges added: $edgesAdded, skipped: $edgesSkipped');
  }

  void _addEdge(Station from, Station to, Ligne ligne, int ordre) {
    final node = _graph[from.id];
    if (node == null) {
      debugPrint('Warning: Cannot add edge - station ${from.id} (${from.nom}) not in graph');
      return;
    }

    final edge = StationEdge(
      fromStation: from,
      toStation: to,
      ligne: ligne,
      ordrePassage: ordre,
    );

    // Check if edge already exists (avoid duplicates)
    final existingEdge = node.edges.any(
      (e) => e.toStation.id == to.id && e.ligne.id == ligne.id,
    );

    if (!existingEdge) {
      node.edges.add(edge);
    }
  }

  int _countEdges() {
    int count = 0;
    for (final node in _graph.values) {
      count += node.edges.length;
    }
    return count;
  }

  /// Check if two stations are in the same connected component
  /// Returns set of all reachable station IDs from origin
  Set<String> _getReachableStations(String originId) {
    final reachable = <String>{originId};
    final queue = Queue<String>();
    queue.add(originId);
    
    while (queue.isNotEmpty) {
      final currentId = queue.removeFirst();
      final node = _graph[currentId];
      if (node == null) continue;
      
      for (final edge in node.edges) {
        if (!reachable.contains(edge.toStation.id)) {
          reachable.add(edge.toStation.id);
          queue.add(edge.toStation.id);
        }
      }
    }
    
    return reachable;
  }

  /// Debug function to check graph connectivity
  void debugConnectivity(String originId, String destId) {
    final originNode = _graph[originId];
    final destNode = _graph[destId];
    
    debugPrint('=== Connectivity Debug ===');
    debugPrint('Origin in graph: ${originNode != null}, edges: ${originNode?.edges.length ?? 0}');
    debugPrint('Dest in graph: ${destNode != null}, edges: ${destNode?.edges.length ?? 0}');
    
    if (originNode != null) {
      debugPrint('Origin neighbors: ${originNode.edges.map((e) => e.toStation.nom).take(5).join(", ")}');
    }
    
    if (destNode != null) {
      debugPrint('Dest neighbors: ${destNode.edges.map((e) => e.toStation.nom).take(5).join(", ")}');
    }
    
    final reachableFromOrigin = _getReachableStations(originId);
    debugPrint('Stations reachable from origin: ${reachableFromOrigin.length}');
    debugPrint('Destination reachable: ${reachableFromOrigin.contains(destId)}');
    
    if (!reachableFromOrigin.contains(destId) && destNode != null) {
      final reachableFromDest = _getReachableStations(destId);
      debugPrint('Stations reachable from dest: ${reachableFromDest.length}');
    }
  }

  /// Find routes between two stations
  /// Returns multiple route options sorted by efficiency
  /// Supports multi-line combinations with transfers
  RouteSearchResult findRoutes(
    RoutePoint origin,
    RoutePoint destination, {
    int maxResults = 5,
    int maxTransfers = 3,
  }) {
    if (!_isInitialized) {
      debugPrint('RoutingService: Not initialized');
      return RouteSearchResult(
        itineraries: [],
        origin: origin,
        destination: destination,
        errorMessage: 'Service de routage non initialisé',
      );
    }

    final originStation = origin.station ?? _findNearestStation(origin.latitude, origin.longitude);
    final destStation = destination.station ?? _findNearestStation(destination.latitude, destination.longitude);

    debugPrint('RoutingService: Searching route from "${originStation?.nom}" to "${destStation?.nom}"');
    
    if (originStation == null || destStation == null) {
      debugPrint('RoutingService: Station(s) not found - origin: ${originStation?.nom}, dest: ${destStation?.nom}');
      return RouteSearchResult(
        itineraries: [],
        origin: origin,
        destination: destination,
        errorMessage: 'Stations non trouvées',
      );
    }
    
    // Check if both stations exist in the graph
    final hasOriginInGraph = _graph.containsKey(originStation.id);
    final hasDestInGraph = _graph.containsKey(destStation.id);
    debugPrint('RoutingService: Origin in graph: $hasOriginInGraph, Dest in graph: $hasDestInGraph');
    
    if (!hasOriginInGraph || !hasDestInGraph) {
      debugPrint('RoutingService: Station(s) not in routing graph');
      return RouteSearchResult(
        itineraries: [],
        origin: origin,
        destination: destination,
        errorMessage: 'Station(s) non connectée(s) au réseau',
      );
    }
    
    // Check connectivity before attempting BFS
    debugConnectivity(originStation.id, destStation.id);

    // Find all possible routes using BFS with transfer tracking
    final routes = _findAllRoutes(
      originStation,
      destStation,
      maxTransfers: maxTransfers,
      maxResults: maxResults * 2, // Get more to filter later
    );
    
    debugPrint('RoutingService: Found ${routes.length} possible routes');

    if (routes.isEmpty) {
      // Additional debug info when no routes found
      final reachable = _getReachableStations(originStation.id);
      if (!reachable.contains(destStation.id)) {
        return RouteSearchResult(
          itineraries: [],
          origin: origin,
          destination: destination,
          errorMessage: 'Les stations ne sont pas connectées sur le réseau',
        );
      }
      return RouteSearchResult(
        itineraries: [],
        origin: origin,
        destination: destination,
        errorMessage: 'Aucun itinéraire trouvé',
      );
    }

    // Convert routes to itineraries
    final itineraries = routes.map((route) => _buildItinerary(
      origin,
      destination,
      originStation,
      destStation,
      route,
    )).toList();

    // Sort by total duration, then by number of transfers
    itineraries.sort((a, b) {
      final durationCompare = a.totalDuration.compareTo(b.totalDuration);
      if (durationCompare != 0) return durationCompare;
      return a.transfers.compareTo(b.transfers);
    });

    // Check if there's a direct route
    final hasDirectRoute = itineraries.any((it) => it.transfers == 0);

    return RouteSearchResult(
      itineraries: itineraries.take(maxResults).toList(),
      origin: origin,
      destination: destination,
      hasDirectRoute: hasDirectRoute,
    );
  }

  /// Find the nearest station to a coordinate
  Station? _findNearestStation(double lat, double lng) {
    Station? nearest;
    double minDistance = double.infinity;

    for (final station in _stationsById.values) {
      final distance = _calculateDistance(
        lat, lng,
        station.latitude, station.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = station;
      }
    }

    return nearest;
  }

  /// Find nearest stations within a radius
  List<Station> findNearestStations(double lat, double lng, {double radiusKm = 1.0, int limit = 5}) {
    final stationsWithDistance = <MapEntry<Station, double>>[];

    for (final station in _stationsById.values) {
      final distance = _calculateDistance(lat, lng, station.latitude, station.longitude);
      if (distance <= radiusKm) {
        stationsWithDistance.add(MapEntry(station, distance));
      }
    }

    stationsWithDistance.sort((a, b) => a.value.compareTo(b.value));
    return stationsWithDistance.take(limit).map((e) => e.key).toList();
  }

  /// BFS-based pathfinding that tracks line changes
  /// Supports multi-line routes with transfers at shared stations
  List<List<StationEdge>> _findAllRoutes(
    Station origin,
    Station destination, {
    int maxTransfers = 3,
    int maxResults = 6,
    int maxIterations = 50000,
  }) {
    final results = <List<StationEdge>>[];
    
    // Queue: (current station, path so far, current ligne, transfer count)
    final queue = Queue<_PathState>();
    
    // Track visited states as (station_id, ligne_id) -> min transfers
    // This allows visiting the same station on different lines (for transfers)
    final visited = <String, int>{};

    // Initialize with all edges from origin station
    final originNode = _graph[origin.id];
    if (originNode == null) {
      debugPrint('BFS: Origin station not found in graph: ${origin.id}');
      return [];
    }
    
    debugPrint('BFS: Searching from "${origin.nom}" to "${destination.nom}"');
    debugPrint('BFS: Origin has ${originNode.edges.length} edges');

    for (final edge in originNode.edges) {
      queue.add(_PathState(
        currentStation: edge.toStation,
        path: [edge],
        currentLigne: edge.ligne,
        transfers: 0,
      ));
    }
    
    int iterations = 0;
    final Set<String> stationsExplored = {};

    while (queue.isNotEmpty && results.length < maxResults && iterations < maxIterations) {
      iterations++;
      final state = queue.removeFirst();
      stationsExplored.add(state.currentStation.id);
      
      // Check if we reached destination
      if (state.currentStation.id == destination.id) {
        debugPrint('BFS: Found route with ${state.path.length} edges and ${state.transfers} transfers');
        results.add(state.path);
        continue;
      }

      // Use composite key: station_id + ligne_id
      // This allows arriving at the same station via different lines
      final visitKey = '${state.currentStation.id}_${state.currentLigne.id}';
      
      // Skip if we've visited this (station, line) combination with fewer or equal transfers
      if (visited.containsKey(visitKey) && visited[visitKey]! <= state.transfers) {
        continue;
      }
      visited[visitKey] = state.transfers;

      // Explore neighbors
      final currentNode = _graph[state.currentStation.id];
      if (currentNode == null) continue;

      for (final edge in currentNode.edges) {
        // Skip if going back to a station already in path (prevent cycles)
        if (state.path.any((e) => e.fromStation.id == edge.toStation.id)) {
          continue;
        }
        
        // Also skip if destination station is origin (no going back to start)
        if (edge.toStation.id == origin.id) {
          continue;
        }

        final isTransfer = edge.ligne.id != state.currentLigne.id;
        final newTransfers = state.transfers + (isTransfer ? 1 : 0);

        // Skip if exceeds max transfers
        if (newTransfers > maxTransfers) continue;

        queue.add(_PathState(
          currentStation: edge.toStation,
          path: [...state.path, edge],
          currentLigne: edge.ligne,
          transfers: newTransfers,
        ));
      }
    }
    
    debugPrint('BFS: Completed after $iterations iterations');
    debugPrint('BFS: Explored ${stationsExplored.length} unique stations');
    debugPrint('BFS: Found ${results.length} routes');
    
    if (results.isEmpty && iterations >= maxIterations) {
      debugPrint('BFS: Hit max iterations limit!');
    }

    return results;
  }

  /// Build an Itinerary from a list of edges
  Itinerary _buildItinerary(
    RoutePoint origin,
    RoutePoint destination,
    Station originStation,
    Station destStation,
    List<StationEdge> edges,
  ) {
    final segments = <RouteSegment>[];
    
    if (edges.isEmpty) {
      return Itinerary(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        origin: originStation,
        destination: destStation,
        segments: [],
        totalDuration: Duration.zero,
        totalStops: 0,
        transfers: 0,
      );
    }

    // Group edges by ligne to create segments
    List<StationEdge> currentSegmentEdges = [];
    Ligne? currentLigne;

    for (final edge in edges) {
      if (currentLigne == null || edge.ligne.id == currentLigne.id) {
        currentSegmentEdges.add(edge);
        currentLigne = edge.ligne;
      } else {
        // New ligne - save current segment and start new one
        if (currentSegmentEdges.isNotEmpty) {
          segments.add(_createSegment(currentSegmentEdges, currentLigne));
        }
        currentSegmentEdges = [edge];
        currentLigne = edge.ligne;
      }
    }

    // Add last segment
    if (currentSegmentEdges.isNotEmpty && currentLigne != null) {
      segments.add(_createSegment(currentSegmentEdges, currentLigne));
    }

    // Calculate totals
    final totalDuration = segments.fold<Duration>(
      Duration.zero,
      (sum, segment) => sum + segment.estimatedDuration,
    );
    
    final totalStops = segments.fold<int>(
      0,
      (sum, segment) => sum + segment.stopCount,
    );

    final transfers = segments.length - 1;

    // Calculate walking distances if origin/destination are not stations
    double? walkingDistanceStart;
    double? walkingDistanceEnd;

    if (origin.station == null) {
      walkingDistanceStart = _calculateDistance(
        origin.latitude, origin.longitude,
        originStation.latitude, originStation.longitude,
      ) * 1000; // Convert to meters
    }

    if (destination.station == null) {
      walkingDistanceEnd = _calculateDistance(
        destination.latitude, destination.longitude,
        destStation.latitude, destStation.longitude,
      ) * 1000; // Convert to meters
    }

    return Itinerary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      origin: originStation,
      destination: destStation,
      segments: segments,
      totalDuration: totalDuration,
      totalStops: totalStops,
      transfers: transfers,
      walkingDistanceStart: walkingDistanceStart,
      walkingDistanceEnd: walkingDistanceEnd,
    );
  }

  RouteSegment _createSegment(List<StationEdge> edges, Ligne ligne) {
    // Collect all stations in order
    final stations = <Station>[edges.first.fromStation];
    for (final edge in edges) {
      stations.add(edge.toStation);
    }

    // Estimate duration: 2 minutes per stop
    final duration = Duration(minutes: 2 * edges.length);

    return RouteSegment(
      ligne: ligne,
      stations: stations,
      departureStation: stations.first,
      arrivalStation: stations.last,
      estimatedDuration: duration,
      stopCount: edges.length,
    );
  }

  /// Calculate distance between two points (Haversine formula) in km
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  /// Get all lignes passing through a station
  List<Ligne> getLignesForStation(String stationId) {
    final node = _graph[stationId];
    if (node == null) return [];

    final ligneIds = <String>{};
    for (final edge in node.edges) {
      ligneIds.add(edge.ligne.id);
    }

    return ligneIds.map((id) => _lignesById[id]).whereType<Ligne>().toList();
  }

  /// Get ordered stations for a ligne
  List<Station> getStationsForLigne(String ligneId) {
    final arrets = _arretsParLigne[ligneId];
    if (arrets == null) return [];

    return arrets
        .map((a) => a.station ?? _stationsById[a.stationId])
        .whereType<Station>()
        .toList();
  }

  /// Clear graph data
  void clear() {
    _graph.clear();
    _stationsById.clear();
    _lignesById.clear();
    _arretsParLigne.clear();
    _isInitialized = false;
  }
}

/// Internal class for BFS state tracking
class _PathState {
  final Station currentStation;
  final List<StationEdge> path;
  final Ligne currentLigne;
  final int transfers;

  _PathState({
    required this.currentStation,
    required this.path,
    required this.currentLigne,
    required this.transfers,
  });
}
