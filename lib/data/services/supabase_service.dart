import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton service to access Supabase client throughout the app
class SupabaseService {
  // Private constructor
  SupabaseService._();
  
  // Singleton instance
  static final SupabaseService _instance = SupabaseService._();
  
  // Factory constructor to return the singleton instance
  factory SupabaseService() => _instance;
  
  /// Get the Supabase client
  SupabaseClient get client => Supabase.instance.client;
  
  /// Get the current authenticated user
  User? get currentUser => client.auth.currentUser;
  
  /// Get the current session
  Session? get currentSession => client.auth.currentSession;
  
  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
  
  /// Get the auth state changes stream
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  // ==================== AUTH OPERATIONS ====================
  
  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }
  
  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  /// Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }
  
  /// Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
  
  // ==================== PROFILES ====================
  
  /// Get user profile by ID
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }
  
  /// Create or update user profile
  Future<Map<String, dynamic>> upsertProfile(Map<String, dynamic> profile) async {
    final response = await client
        .from('profiles')
        .upsert(profile)
        .select()
        .single();
    return response;
  }
  
  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(String userId, Map<String, dynamic> updates) async {
    final response = await client
        .from('profiles')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();
    return response;
  }
  
  // ==================== CHAUFFEURS ====================
  
  /// Get chauffeur by ID
  Future<Map<String, dynamic>?> getChauffeur(String id) async {
    final response = await client
        .from('chauffeurs')
        .select('*, profiles(*)')
        .eq('id', id)
        .maybeSingle();
    return response;
  }
  
  /// Get all chauffeurs
  Future<List<Map<String, dynamic>>> getAllChauffeurs() async {
    final response = await client
        .from('chauffeurs')
        .select('*, profiles(*)');
    return List<Map<String, dynamic>>.from(response);
  }
  
  // ==================== CONTROLEURS ====================
  
  /// Get controleur by ID
  Future<Map<String, dynamic>?> getControleur(String id) async {
    final response = await client
        .from('controleurs')
        .select('*, profiles(*)')
        .eq('id', id)
        .maybeSingle();
    return response;
  }
  
  /// Get all controleurs
  Future<List<Map<String, dynamic>>> getAllControleurs() async {
    final response = await client
        .from('controleurs')
        .select('*, profiles(*)');
    return List<Map<String, dynamic>>.from(response);
  }
  
  // ==================== STATIONS ====================
  
  /// Get all stations
  Future<List<Map<String, dynamic>>> getStations() async {
    final response = await client.from('stations').select();
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Get station by ID
  Future<Map<String, dynamic>?> getStation(String id) async {
    final response = await client
        .from('stations')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }
  
  /// Get stations for a specific line
  Future<List<Map<String, dynamic>>> getStationsForLigne(String ligneId) async {
    final response = await client
        .from('arrets_lignes')
        .select('*, stations(*)')
        .eq('ligne_id', ligneId)
        .order('ordre_passage');
    return List<Map<String, dynamic>>.from(response);
  }
  
  // ==================== LIGNES ====================
  
  /// Get all lignes
  Future<List<Map<String, dynamic>>> getLignes() async {
    final response = await client.from('lignes').select();
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Get ligne by ID
  Future<Map<String, dynamic>?> getLigne(String id) async {
    final response = await client
        .from('lignes')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response;
  }
  
  /// Get lignes by type (bus, tramway, train)
  Future<List<Map<String, dynamic>>> getLignesByType(String type) async {
    final response = await client
        .from('lignes')
        .select()
        .eq('type', type);
    return List<Map<String, dynamic>>.from(response);
  }
  
  // ==================== ARRETS_LIGNES ====================
  
  /// Get line stops (junction table)
  Future<List<Map<String, dynamic>>> getArretsLigne(String ligneId) async {
    final response = await client
        .from('arrets_lignes')
        .select('*, stations(*)')
        .eq('ligne_id', ligneId)
        .order('ordre_passage');
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Get lines passing through a station
  Future<List<Map<String, dynamic>>> getLignesForStation(String stationId) async {
    final response = await client
        .from('arrets_lignes')
        .select('*, lignes(*)')
        .eq('station_id', stationId);
    return List<Map<String, dynamic>>.from(response);
  }
  
  // ==================== HORAIRES (SCHEDULES) ====================
  
  /// Get all horaires for a station
  Future<List<Map<String, dynamic>>> getHorairesForStation(String stationId) async {
    final response = await client
        .from('horaires')
        .select('*, lignes(*)')
        .eq('station_id', stationId)
        .order('heure_passage');
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Get all horaires for a ligne
  Future<List<Map<String, dynamic>>> getHorairesForLigne(String ligneId) async {
    final response = await client
        .from('horaires')
        .select('*, stations(*)')
        .eq('ligne_id', ligneId)
        .order('heure_passage');
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Get upcoming horaires for a station (next departures)
  Future<List<Map<String, dynamic>>> getUpcomingHoraires(String stationId, {int limit = 10}) async {
    final now = DateTime.now().toIso8601String();
    final response = await client
        .from('horaires')
        .select('*, lignes(*)')
        .eq('station_id', stationId)
        .gte('heure_passage', now)
        .order('heure_passage')
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Get horaires for a specific ligne at a specific station
  Future<List<Map<String, dynamic>>> getHorairesForLigneAtStation(String ligneId, String stationId) async {
    final response = await client
        .from('horaires')
        .select()
        .eq('ligne_id', ligneId)
        .eq('station_id', stationId)
        .order('heure_passage');
    return List<Map<String, dynamic>>.from(response);
  }
  
  // ==================== VEHICULES ====================
  
  /// Get all vehicules
  Future<List<Map<String, dynamic>>> getVehicules() async {
    final response = await client
        .from('vehicules')
        .select('*, lignes(*)');
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Get vehicules for a ligne
  Future<List<Map<String, dynamic>>> getVehiculesForLigne(String ligneId) async {
    final response = await client
        .from('vehicules')
        .select('*, lignes(*)')
        .eq('ligne_id', ligneId);
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Get vehicules currently in service
  Future<List<Map<String, dynamic>>> getVehiculesEnService() async {
    final response = await client
        .from('vehicules')
        .select('*, lignes(*)')
        .eq('est_en_service', true);
    return List<Map<String, dynamic>>.from(response);
  }
  
  // ==================== TICKETS ====================
  
  /// Get tickets for a user
  Future<List<Map<String, dynamic>>> getTicketsForUser(String userId) async {
    final response = await client
        .from('tickets')
        .select()
        .eq('user_id', userId)
        .order('date_achat', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Create a new ticket
  Future<Map<String, dynamic>> createTicket(Map<String, dynamic> ticket) async {
    final response = await client
        .from('tickets')
        .insert(ticket)
        .select()
        .single();
    return response;
  }
  
  /// Validate a ticket
  Future<Map<String, dynamic>> validateTicket(String ticketId) async {
    final response = await client
        .from('tickets')
        .update({'date_validation': DateTime.now().toIso8601String()})
        .eq('id', ticketId)
        .select()
        .single();
    return response;
  }
  
  /// Get valid tickets for user (not yet validated or still valid)
  Future<List<Map<String, dynamic>>> getValidTicketsForUser(String userId) async {
    final response = await client
        .from('tickets')
        .select()
        .eq('user_id', userId)
        .or('date_validation.is.null,date_validation.gte.${DateTime.now().subtract(const Duration(minutes: 90)).toIso8601String()}');
    return List<Map<String, dynamic>>.from(response);
  }
  
  // ==================== ABONNEMENTS ====================
  
  /// Get abonnements for a user
  Future<List<Map<String, dynamic>>> getAbonnementsForUser(String userId) async {
    final response = await client
        .from('abonnements')
        .select()
        .eq('user_id', userId)
        .order('date_fin', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Get active abonnement for a user
  Future<Map<String, dynamic>?> getActiveAbonnement(String userId) async {
    final now = DateTime.now().toIso8601String().split('T')[0];
    final response = await client
        .from('abonnements')
        .select()
        .eq('user_id', userId)
        .lte('date_debut', now)
        .gte('date_fin', now)
        .maybeSingle();
    return response;
  }
  
  /// Create a new abonnement
  Future<Map<String, dynamic>> createAbonnement(Map<String, dynamic> abonnement) async {
    final response = await client
        .from('abonnements')
        .insert(abonnement)
        .select()
        .single();
    return response;
  }
  
  // ==================== AMENDES ====================
  
  /// Get amendes for a user
  Future<List<Map<String, dynamic>>> getAmendesForUser(String userId) async {
    final response = await client
        .from('amendes')
        .select('*, controleurs(*, profiles(*))')
        .eq('user_id', userId)
        .order('date_emission', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Get unpaid amendes for a user
  Future<List<Map<String, dynamic>>> getUnpaidAmendes(String userId) async {
    final response = await client
        .from('amendes')
        .select('*, controleurs(*, profiles(*))')
        .eq('user_id', userId)
        .eq('est_payee', false);
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Create an amende (for controleurs)
  Future<Map<String, dynamic>> createAmende(Map<String, dynamic> amende) async {
    final response = await client
        .from('amendes')
        .insert(amende)
        .select()
        .single();
    return response;
  }
  
  /// Pay an amende
  Future<Map<String, dynamic>> payAmende(String amendeId) async {
    final response = await client
        .from('amendes')
        .update({'est_payee': true})
        .eq('id', amendeId)
        .select()
        .single();
    return response;
  }
  
  // ==================== PANNES ====================
  
  /// Get all pannes
  Future<List<Map<String, dynamic>>> getPannes() async {
    final response = await client
        .from('pannes')
        .select('*, vehicules(*, lignes(*))')
        .order('date_signalement', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Get active pannes (not resolved)
  Future<List<Map<String, dynamic>>> getActivePannes() async {
    final response = await client
        .from('pannes')
        .select('*, vehicules(*, lignes(*))')
        .eq('est_resolu', false)
        .order('date_signalement', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Get pannes for a vehicule
  Future<List<Map<String, dynamic>>> getPannesForVehicule(String vehiculeId) async {
    final response = await client
        .from('pannes')
        .select()
        .eq('vehicule_id', vehiculeId)
        .order('date_signalement', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// Report a new panne
  Future<Map<String, dynamic>> reportPanne(Map<String, dynamic> panne) async {
    final response = await client
        .from('pannes')
        .insert(panne)
        .select()
        .single();
    return response;
  }
  
  /// Resolve a panne
  Future<Map<String, dynamic>> resolvePanne(String panneId) async {
    final response = await client
        .from('pannes')
        .update({'est_resolu': true})
        .eq('id', panneId)
        .select()
        .single();
    return response;
  }
  
  // ==================== REAL-TIME SUBSCRIPTIONS ====================
  
  /// Subscribe to real-time changes on a table
  RealtimeChannel subscribeToTable(
    String table, {
    required void Function(PostgresChangePayload payload) onInsert,
    void Function(PostgresChangePayload payload)? onUpdate,
    void Function(PostgresChangePayload payload)? onDelete,
  }) {
    final channel = client.channel('public:$table');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: table,
      callback: onInsert,
    );
    
    if (onUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        callback: onUpdate,
      );
    }
    
    if (onDelete != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: table,
        callback: onDelete,
      );
    }
    
    channel.subscribe();
    return channel;
  }
  
  /// Unsubscribe from a channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }

  // ==================== ROUTING ====================

  /// Get all ligne-station connections (for building routing graph)
  Future<List<Map<String, dynamic>>> getAllArretsLignes() async {
    final response = await client
        .from('arrets_lignes')
        .select('*, stations(*), lignes(*)')
        .order('ligne_id')
        .order('ordre_passage');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get all ligne-station connections for specific lignes
  Future<List<Map<String, dynamic>>> getArretsLignesForLignes(List<String> ligneIds) async {
    final response = await client
        .from('arrets_lignes')
        .select('*, stations(*), lignes(*)')
        .inFilter('ligne_id', ligneIds)
        .order('ligne_id')
        .order('ordre_passage');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get lignes that pass through both stations
  Future<List<Map<String, dynamic>>> getLignesConnectingStations(
    String stationId1,
    String stationId2,
  ) async {
    // Get lignes for first station
    final lignes1 = await client
        .from('arrets_lignes')
        .select('ligne_id')
        .eq('station_id', stationId1);
    
    if (lignes1.isEmpty) return [];
    
    final ligneIds = (lignes1 as List).map((e) => e['ligne_id'] as String).toList();
    
    // Get lignes that also pass through second station
    final response = await client
        .from('arrets_lignes')
        .select('*, lignes(*)')
        .eq('station_id', stationId2)
        .inFilter('ligne_id', ligneIds);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get stations near a coordinate (within radius in meters)
  /// Note: This requires PostGIS function. Falls back to fetching all if not available.
  Future<List<Map<String, dynamic>>> getStationsNearLocation(
    double latitude,
    double longitude, {
    double radiusMeters = 1000,
  }) async {
    try {
      // Try using PostGIS function if available
      final response = await client.rpc(
        'stations_within_radius',
        params: {
          'lat': latitude,
          'lng': longitude,
          'radius_meters': radiusMeters,
        },
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback: fetch all stations (filtering will be done client-side)
      return getStations();
    }
  }

  /// Get upcoming horaires for multiple stations at once
  Future<List<Map<String, dynamic>>> getUpcomingHorairesForStations(
    List<String> stationIds, {
    int limitPerStation = 5,
  }) async {
    final now = DateTime.now().toIso8601String();
    final response = await client
        .from('horaires')
        .select('*, lignes(*), stations(*)')
        .inFilter('station_id', stationIds)
        .gte('heure_passage', now)
        .order('heure_passage')
        .limit(limitPerStation * stationIds.length);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPriceServices() async {
    // 1. Await the response from the database
    final List<dynamic> response = await SupabaseService().client
        .from('prices_service')
        .select(); // No need for '*' as it's the default in newer versions

    // 2. Cast the response to the specific List of Maps required
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPenalities(String userId) async {
    final response = await SupabaseService().client
        .from('amendes')
        .select('*, controleurs(*, profiles(*))')
        .eq('user_id', userId)
        .order('date_emission', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllLignes() async {
    final response = await SupabaseService().client
        .from('lignes')
        .select()
        .order('nom_court');
    return List<Map<String, dynamic>>.from(response);
  }

  // ==================== ROUTE PLANNING ====================

  /// Get all stations with parsed coordinates
  Future<List<Map<String, dynamic>>> getStationsWithCoordinates() async {
    final response = await client
        .from('stations')
        .select()
        .order('nom');
    
    // Parse coordinates for each station
    final stations = List<Map<String, dynamic>>.from(response);
    for (final station in stations) {
      final coords = _parseWkbLocation(station['location']);
      if (coords != null) {
        station['latitude'] = coords.$1;
        station['longitude'] = coords.$2;
      }
    }
    
    return stations;
  }

  /// Find lignes that pass through both start and end stations (direct route)
  Future<List<Map<String, dynamic>>> findConnectingLignes(
    String startStationId, 
    String endStationId,
  ) async {
    debugPrint('findConnectingLignes: $startStationId -> $endStationId');
    
    // Find lignes that contain the start station
    final startArrets = await client
        .from('arrets_lignes')
        .select('ligne_id')
        .eq('station_id', startStationId);
    
    final startLigneIds = (startArrets as List)
        .map((e) => e['ligne_id'] as String)
        .toSet();
    
    // Find lignes that contain the end station
    final endArrets = await client
        .from('arrets_lignes')
        .select('ligne_id')
        .eq('station_id', endStationId);
    
    final endLigneIds = (endArrets as List)
        .map((e) => e['ligne_id'] as String)
        .toSet();
    
    debugPrint('Start in ${startLigneIds.length} lignes, End in ${endLigneIds.length} lignes');
    
    // Find common lignes
    final commonLigneIds = startLigneIds.intersection(endLigneIds);
    debugPrint('Common lignes: ${commonLigneIds.length}');
    
    if (commonLigneIds.isEmpty) return [];
    
    final result = <Map<String, dynamic>>[];
    
    for (final ligneId in commonLigneIds) {
      final ligneInfo = await client
          .from('lignes')
          .select()
          .eq('id', ligneId)
          .maybeSingle();
      
      if (ligneInfo == null) continue;
      
      // Get all stations for this ligne with coordinates
      final stationsOnLigne = await client
          .from('arrets_lignes')
          .select('ordre_passage, station_id, stations(id, nom, location, accessibilite)')
          .eq('ligne_id', ligneId)
          .order('ordre_passage');
      
      // Parse coordinates for each station
      for (final stop in stationsOnLigne) {
        final station = stop['stations'] as Map<String, dynamic>?;
        if (station != null) {
          final coords = _parseWkbLocation(station['location']);
          if (coords != null) {
            station['latitude'] = coords.$1;
            station['longitude'] = coords.$2;
          }
        }
      }
      
      result.add({
        'ligne': ligneInfo,
        'stations': stationsOnLigne,
      });
    }
    
    return result;
  }

  /// Search stations by name
  Future<List<Map<String, dynamic>>> searchStationsByName(String query) async {
    if (query.isEmpty) return [];
    
    final response = await client
        .from('stations')
        .select()
        .ilike('nom', '%$query%')
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Find routes with transfers (multi-hop routing)
  /// Uses BFS to find shortest path with minimum transfers
  Future<Map<String, dynamic>> findRoutesWithTransfers(
    String startStationId,
    String endStationId,
  ) async {
    debugPrint('=== ROUTE SEARCH ===');
    debugPrint('From: $startStationId To: $endStationId');
    
    // First try direct routes
    final directRoutes = await findConnectingLignes(startStationId, endStationId);
    
    if (directRoutes.isNotEmpty) {
      debugPrint('Found ${directRoutes.length} direct route(s)');
      
      // Build all route options for user to choose from
      final allRouteOptions = <Map<String, dynamic>>[];
      
      for (final route in directRoutes) {
        final allStations = route['stations'] as List;
        final filteredStations = _filterStationsBetween(
          allStations, 
          startStationId, 
          endStationId,
        );
        
        allRouteOptions.add({
          'type': 'direct',
          'segments': [
            {
              'ligne': route['ligne'],
              'stations': filteredStations,
              'fromStation': startStationId,
              'toStation': endStationId,
            }
          ],
          'totalTransfers': 0,
          'ligne': route['ligne'],
        });
      }
      
      // Return first route as selected, but include all options
      return {
        'type': 'direct',
        'segments': allRouteOptions.first['segments'],
        'totalTransfers': 0,
        'allRouteOptions': allRouteOptions,
        'selectedRouteIndex': 0,
      };
    }

    // No direct route - find route with transfers using BFS
    debugPrint('No direct route, searching with transfers...');
    
    final graph = await _buildTransitGraph();
    debugPrint('Graph built with ${graph.length} stations');
    
    // Check if stations are in graph
    final startInGraph = graph.containsKey(startStationId);
    final endInGraph = graph.containsKey(endStationId);
    debugPrint('Start in graph: $startInGraph, End in graph: $endInGraph');
    
    if (!startInGraph || !endInGraph) {
      debugPrint('One or both stations not in transit network');
      return {
        'type': 'none',
        'segments': [],
        'totalTransfers': 0,
        'allRoutes': [],
        'error': 'Stations not connected to transit network',
      };
    }
    
    // BFS to find multiple paths
    final paths = _bfsMultiplePaths(graph, startStationId, endStationId, maxPaths: 5);
    
    if (paths.isEmpty) {
      debugPrint('No path found');
      return {
        'type': 'none',
        'segments': [],
        'totalTransfers': 0,
        'allRouteOptions': [],
      };
    }

    debugPrint('Found ${paths.length} path(s)');
    
    // Convert all paths to route options
    final allRouteOptions = <Map<String, dynamic>>[];
    for (final path in paths) {
      final segments = await _pathToSegments(path);
      allRouteOptions.add({
        'type': 'transfer',
        'segments': segments,
        'totalTransfers': segments.length - 1,
        'path': path,
      });
    }
    
    debugPrint('Created ${allRouteOptions.length} route option(s)');
    
    return {
      'type': 'transfer',
      'segments': allRouteOptions.first['segments'],
      'totalTransfers': allRouteOptions.first['totalTransfers'],
      'allRouteOptions': allRouteOptions,
      'selectedRouteIndex': 0,
    };
  }
  
  /// Filter stations list to only include those between start and end
  List<Map<String, dynamic>> _filterStationsBetween(
    List<dynamic> allStations, 
    String startId, 
    String endId,
  ) {
    int startIdx = -1;
    int endIdx = -1;
    
    for (int i = 0; i < allStations.length; i++) {
      final stationId = allStations[i]['station_id'] as String?;
      if (stationId == startId) startIdx = i;
      if (stationId == endId) endIdx = i;
    }
    
    if (startIdx == -1 || endIdx == -1) {
      return List<Map<String, dynamic>>.from(allStations);
    }
    
    // Ensure correct order (handle reverse direction)
    if (startIdx > endIdx) {
      final temp = startIdx;
      startIdx = endIdx;
      endIdx = temp;
    }
    
    return List<Map<String, dynamic>>.from(
      allStations.sublist(startIdx, endIdx + 1)
    );
  }

  /// Build transit graph from database
  /// Graph structure: stationId -> {neighborStationId -> [connection info]}
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> _buildTransitGraph() async {
    // Get all ligne-station connections with ligne info
    final allArrets = await client
        .from('arrets_lignes')
        .select('ligne_id, station_id, ordre_passage, stations(id, nom, location), lignes(id, nom_court, direction_terminus, couleur_hex, type)')
        .order('ligne_id')
        .order('ordre_passage');
    
    debugPrint('Loaded ${allArrets.length} arrets');
    
    // Group by ligne
    final ligneStations = <String, List<Map<String, dynamic>>>{};
    for (final arret in allArrets) {
      final ligneId = arret['ligne_id'] as String;
      ligneStations.putIfAbsent(ligneId, () => []);
      ligneStations[ligneId]!.add(Map<String, dynamic>.from(arret));
    }
    
    debugPrint('Found ${ligneStations.length} lignes');
    
    // Build adjacency graph
    final graph = <String, Map<String, List<Map<String, dynamic>>>>{};
    int edgesCreated = 0;
    
    for (final entry in ligneStations.entries) {
      final stops = entry.value;
      // Sort by ordre_passage
      stops.sort((a, b) => 
        (a['ordre_passage'] as int? ?? 0).compareTo(b['ordre_passage'] as int? ?? 0)
      );
      
      // Connect consecutive stations
      for (int i = 0; i < stops.length - 1; i++) {
        final currentStationId = stops[i]['station_id'] as String;
        final nextStationId = stops[i + 1]['station_id'] as String;
        final ligne = stops[i]['lignes'] as Map<String, dynamic>?;
        final currentStationInfo = stops[i]['stations'] as Map<String, dynamic>?;
        final nextStationInfo = stops[i + 1]['stations'] as Map<String, dynamic>?;
        
        if (ligne == null) continue;
        
        // Parse coordinates for stations
        if (currentStationInfo != null) {
          final coords = _parseWkbLocation(currentStationInfo['location']);
          if (coords != null) {
            currentStationInfo['latitude'] = coords.$1;
            currentStationInfo['longitude'] = coords.$2;
          }
        }
        if (nextStationInfo != null) {
          final coords = _parseWkbLocation(nextStationInfo['location']);
          if (coords != null) {
            nextStationInfo['latitude'] = coords.$1;
            nextStationInfo['longitude'] = coords.$2;
          }
        }
        
        final connectionInfo = {
          'ligne': ligne,
          'station_info': currentStationInfo,
          'next_station_info': nextStationInfo,
        };
        
        // Add bidirectional edge
        graph.putIfAbsent(currentStationId, () => {});
        graph[currentStationId]!.putIfAbsent(nextStationId, () => []);
        graph[currentStationId]![nextStationId]!.add(connectionInfo);
        
        graph.putIfAbsent(nextStationId, () => {});
        graph[nextStationId]!.putIfAbsent(currentStationId, () => []);
        graph[nextStationId]![currentStationId]!.add({
          'ligne': ligne,
          'station_info': nextStationInfo,
          'next_station_info': currentStationInfo,
        });
        
        edgesCreated++;
      }
    }
    
    debugPrint('Created $edgesCreated edges, graph has ${graph.length} stations');
    
    // Add ALL stations to the graph with walking connections
    // This ensures any station (even those not on transit lines) can be reached
    final allStations = await client.from('stations').select('id, nom, location');
    debugPrint('Total stations in database: ${allStations.length}');
    
    final stationCoords = <String, (double lat, double lng, Map<String, dynamic> info)>{};
    
    // Parse coordinates for ALL stations
    for (final station in allStations) {
      final stationId = station['id'] as String;
      final coords = _parseWkbLocation(station['location']);
      if (coords != null) {
        stationCoords[stationId] = (coords.$1, coords.$2, Map<String, dynamic>.from(station));
        // Ensure station exists in graph (even if not on any transit line)
        graph.putIfAbsent(stationId, () => {});
      }
    }
    
    debugPrint('Stations with valid coordinates: ${stationCoords.length}');
    
    // Add walking edges between nearby stations (within 2km for better connectivity)
    int walkingEdges = 0;
    final walkingLigne = {
      'id': 'walking',
      'nom': 'À pied',
      'nom_court': '🚶',
      'couleur_hex': '#888888',
      'type': 'walking',
    };
    
    final stationIds = stationCoords.keys.toList();
    for (int i = 0; i < stationIds.length; i++) {
      final id1 = stationIds[i];
      final (lat1, lng1, info1) = stationCoords[id1]!;
      
      // Find nearest stations for this station
      final distances = <(String, double, Map<String, dynamic>)>[];
      
      for (int j = 0; j < stationIds.length; j++) {
        if (i == j) continue;
        final id2 = stationIds[j];
        final (lat2, lng2, info2) = stationCoords[id2]!;
        final distance = _calculateDistance(lat1, lng1, lat2, lng2);
        distances.add((id2, distance, info2));
      }
      
      // Sort by distance
      distances.sort((a, b) => a.$2.compareTo(b.$2));
      
      // Connect to nearest 5 stations within 3km (ensures connectivity even for isolated stations)
      int connectionsAdded = 0;
      for (final (id2, distance, info2) in distances) {
        if (distance > 3000) break; // Max 3km
        if (connectionsAdded >= 5) break; // Max 5 connections per station
        
        // Add walking connection if not already connected by transit
        final existingConnections = graph[id1]?[id2];
        final hasTransitConnection = existingConnections?.any((c) => c['walking'] != true) ?? false;
        
        if (!hasTransitConnection) {
          final (lat2, lng2, _) = stationCoords[id2]!;
          
          graph.putIfAbsent(id1, () => {});
          graph[id1]!.putIfAbsent(id2, () => []);
          
          // Check if walking connection already exists
          final hasWalkingConnection = existingConnections?.any((c) => c['walking'] == true) ?? false;
          if (!hasWalkingConnection) {
            graph[id1]![id2]!.add({
              'ligne': walkingLigne,
              'station_info': {...info1, 'latitude': lat1, 'longitude': lng1},
              'next_station_info': {...info2, 'latitude': lat2, 'longitude': lng2},
              'walking': true,
              'distance': distance.round(),
            });
            
            // Add reverse direction
            graph.putIfAbsent(id2, () => {});
            graph[id2]!.putIfAbsent(id1, () => []);
            graph[id2]![id1]!.add({
              'ligne': walkingLigne,
              'station_info': {...info2, 'latitude': lat2, 'longitude': lng2},
              'next_station_info': {...info1, 'latitude': lat1, 'longitude': lng1},
              'walking': true,
              'distance': distance.round(),
            });
            walkingEdges++;
          }
          connectionsAdded++;
        }
      }
    }
    
    debugPrint('Walking connections added: $walkingEdges');
    debugPrint('Final graph has ${graph.length} stations');
    
    return graph;
  }
  
  /// Parse PostGIS WKB hex format to (latitude, longitude)
  (double, double)? _parseWkbLocation(dynamic location) {
    if (location == null) return null;
    
    if (location is! String) return null;
    
    // Check for WKB hex format (starts with 01 for little endian)
    if (location.length >= 50 && RegExp(r'^[0-9A-Fa-f]+$').hasMatch(location)) {
      try {
        // WKB format: byte_order(1) + type(4) + srid(4) + x(8) + y(8) = 25 bytes = 50 hex
        // 01 01000020 E6100000 XXXXXXXX YYYYYYYY
        
        final byteOrder = int.parse(location.substring(0, 2), radix: 16);
        final isLittleEndian = byteOrder == 1;
        
        // Position 18 = after byte order (2) + type (8) + srid (8)
        const coordsStart = 18;
        final xHex = location.substring(coordsStart, coordsStart + 16);
        final yHex = location.substring(coordsStart + 16, coordsStart + 32);
        
        final lng = _parseHexToDouble(xHex, isLittleEndian);
        final lat = _parseHexToDouble(yHex, isLittleEndian);
        
        if (lng != null && lat != null && lat.abs() <= 90 && lng.abs() <= 180) {
          return (lat, lng);
        }
      } catch (e) {
        debugPrint('WKB parse error: $e');
      }
    }
    
    // Try WKT format: POINT(lng lat)
    final regex = RegExp(r'POINT\(([^\s]+)\s+([^\)]+)\)');
    final match = regex.firstMatch(location);
    if (match != null) {
      final lng = double.tryParse(match.group(1) ?? '');
      final lat = double.tryParse(match.group(2) ?? '');
      if (lat != null && lng != null) {
        return (lat, lng);
      }
    }
    
    return null;
  }
  
  /// Parse IEEE 754 double from hex string
  double? _parseHexToDouble(String hex, bool isLittleEndian) {
    if (hex.length != 16) return null;
    
    try {
      // Convert hex to bytes
      final bytes = Uint8List(8);
      for (int i = 0; i < 8; i++) {
        bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
      }
      
      // Create ByteData and read as float64
      final byteData = ByteData.view(bytes.buffer);
      return byteData.getFloat64(0, isLittleEndian ? Endian.little : Endian.big);
    } catch (e) {
      return null;
    }
  }
  
  /// Calculate distance between two coordinates in meters (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Earth radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return R * c;
  }
  
  double _toRadians(double degree) => degree * 3.141592653589793 / 180;
  
  /// Parse PostGIS WKB hex format for Point geometry
  /// Format: BBTTTTTTTTSSSSSSSSXXXXXXXXXXXXXXXX (B=byte order, T=type, S=srid, X=coords)
  (double, double)? _parseWkbHex(String hex) {
    // Minimum length for Point with SRID: 1+4+4+8+8 = 25 bytes = 50 hex chars
    if (hex.length < 50) return null;
    
    // Parse byte order (01 = little endian, 00 = big endian)
    final byteOrder = int.parse(hex.substring(0, 2), radix: 16);
    final isLittleEndian = byteOrder == 1;
    
    // Skip type (4 bytes) and SRID (4 bytes) = 8 bytes = 16 hex chars
    // Position: 2 (byte order) + 8 (type) + 8 (srid) = 18
    final coordsStart = 18;
    
    // Extract coordinates (two 8-byte doubles)
    final xHex = hex.substring(coordsStart, coordsStart + 16);
    final yHex = hex.substring(coordsStart + 16, coordsStart + 32);
    
    // Parse as IEEE 754 double
    final lng = _parseHexDouble(xHex, isLittleEndian);
    final lat = _parseHexDouble(yHex, isLittleEndian);
    
    if (lng != null && lat != null && lat.abs() <= 90 && lng.abs() <= 180) {
      return (lat, lng);
    }
    
    return null;
  }
  
  /// Parse hex string to IEEE 754 double
  double? _parseHexDouble(String hex, bool isLittleEndian) {
    if (hex.length != 16) return null;
    
    try {
      // Convert hex to bytes
      final bytes = List<int>.generate(8, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16));
      
      // Reverse for little endian
      if (isLittleEndian) {
        bytes.reversed;
        // Build 64-bit integer in little endian order
        int bits = 0;
        for (int i = 7; i >= 0; i--) {
          bits = (bits << 8) | bytes[i];
        }
        // Convert to double using IEEE 754
        final data = ByteData(8);
        data.setInt64(0, bits);
        return data.getFloat64(0);
      } else {
        int bits = 0;
        for (final byte in bytes) {
          bits = (bits << 8) | byte;
        }
        final data = ByteData(8);
        data.setInt64(0, bits);
        return data.getFloat64(0);
      }
    } catch (e) {
      return null;
    }
  }

  /// BFS to find shortest path (minimum transfers)
  List<Map<String, dynamic>>? _bfsShortestPath(
    Map<String, Map<String, List<Map<String, dynamic>>>> graph,
    String startId,
    String endId,
  ) {
    if (!graph.containsKey(startId)) {
      debugPrint('BFS: Start station not in graph');
      return null;
    }
    
    if (!graph.containsKey(endId)) {
      debugPrint('BFS: End station not in graph');
      return null;
    }
    
    debugPrint('BFS: Start has ${graph[startId]?.length ?? 0} neighbors');
    debugPrint('BFS: End has ${graph[endId]?.length ?? 0} neighbors');
    
    // Queue: (currentStation, currentLigne, path)
    final queue = <Map<String, dynamic>>[];
    final visited = <String, Set<String>>{}; // station -> set of lignes used to reach it
    
    // Start from all lines at the start station
    for (final neighbor in graph[startId]?.entries ?? <MapEntry<String, List<Map<String, dynamic>>>>[]) {
      for (final connection in neighbor.value) {
        final ligneId = connection['ligne']['id'] as String;
        queue.add({
          'station': neighbor.key,
          'ligne': connection['ligne'],
          'stationInfo': connection['next_station_info'],
          'path': [
            {
              'from': startId,
              'to': neighbor.key,
              'ligne': connection['ligne'],
              'fromInfo': connection['station_info'],
              'toInfo': connection['next_station_info'],
            }
          ],
        });
        visited.putIfAbsent(neighbor.key, () => {});
        visited[neighbor.key]!.add(ligneId);
      }
    }
    
    debugPrint('BFS: Initial queue size: ${queue.length}');
    int iterations = 0;
    const maxIterations = 100000;
    const maxPathLength = 20; // Allow longer paths for complex routes
    
    while (queue.isNotEmpty && iterations < maxIterations) {
      iterations++;
      final current = queue.removeAt(0);
      final currentStation = current['station'] as String;
      final currentLigne = current['ligne'] as Map<String, dynamic>;
      final path = current['path'] as List<Map<String, dynamic>>;
      
      // Found destination
      if (currentStation == endId) {
        debugPrint('BFS: Found path with ${path.length} steps after $iterations iterations');
        return path;
      }
      
      // Limit path length to avoid very long routes
      if (path.length > maxPathLength) continue;
      
      // Explore neighbors
      for (final neighbor in graph[currentStation]?.entries ?? <MapEntry<String, List<Map<String, dynamic>>>>[]) {
        for (final connection in neighbor.value) {
          final ligneId = connection['ligne']['id'] as String;
          final neighborStation = neighbor.key;
          
          // Skip if already visited with this ligne
          if (visited[neighborStation]?.contains(ligneId) == true) continue;
          
          visited.putIfAbsent(neighborStation, () => {});
          visited[neighborStation]!.add(ligneId);
          
          final newPath = List<Map<String, dynamic>>.from(path);
          
          // Check if this is a transfer (different ligne)
          if (ligneId != currentLigne['id']) {
            // Add transfer marker
            newPath.add({
              'transfer': true,
              'at': currentStation,
              'atInfo': current['stationInfo'],
              'fromLigne': currentLigne,
              'toLigne': connection['ligne'],
            });
          }
          
          newPath.add({
            'from': currentStation,
            'to': neighborStation,
            'ligne': connection['ligne'],
            'fromInfo': connection['station_info'],
            'toInfo': connection['next_station_info'],
          });
          
          queue.add({
            'station': neighborStation,
            'ligne': connection['ligne'],
            'stationInfo': connection['next_station_info'],
            'path': newPath,
          });
        }
      }
    }
    
    debugPrint('BFS: No path found after $iterations iterations. Visited ${visited.length} stations.');
    return null;
  }

  /// BFS to find multiple alternative paths
  List<List<Map<String, dynamic>>> _bfsMultiplePaths(
    Map<String, Map<String, List<Map<String, dynamic>>>> graph,
    String startId,
    String endId, {
    int maxPaths = 5,
  }) {
    if (!graph.containsKey(startId) || !graph.containsKey(endId)) {
      return [];
    }
    
    final foundPaths = <List<Map<String, dynamic>>>[];
    final usedLigneSequences = <String>{}; // Track unique ligne combinations
    
    // Queue: (currentStation, currentLigne, path)
    final queue = <Map<String, dynamic>>[];
    
    // Start from all lines at the start station
    for (final neighbor in graph[startId]?.entries ?? <MapEntry<String, List<Map<String, dynamic>>>>[]) {
      for (final connection in neighbor.value) {
        final ligneId = connection['ligne']['id'] as String;
        queue.add({
          'station': neighbor.key,
          'ligne': connection['ligne'],
          'stationInfo': connection['next_station_info'],
          'path': [
            {
              'from': startId,
              'to': neighbor.key,
              'ligne': connection['ligne'],
              'fromInfo': connection['station_info'],
              'toInfo': connection['next_station_info'],
            }
          ],
          'visited': {startId, neighbor.key},
          'ligneSequence': <String>[ligneId],
        });
      }
    }
    
    int iterations = 0;
    const maxIterations = 50000;
    const maxPathLength = 15;
    
    while (queue.isNotEmpty && iterations < maxIterations && foundPaths.length < maxPaths) {
      iterations++;
      final current = queue.removeAt(0);
      final currentStation = current['station'] as String;
      final currentLigne = current['ligne'] as Map<String, dynamic>;
      final path = current['path'] as List<Map<String, dynamic>>;
      final visited = current['visited'] as Set<String>;
      final ligneSequence = List<String>.from(current['ligneSequence'] as List);
      
      // Found destination
      if (currentStation == endId) {
        // Check if this is a unique path (different ligne sequence)
        final sequenceKey = ligneSequence.join('-');
        if (!usedLigneSequences.contains(sequenceKey)) {
          usedLigneSequences.add(sequenceKey);
          foundPaths.add(List<Map<String, dynamic>>.from(path));
          debugPrint('BFS: Found path ${foundPaths.length} using lignes: $sequenceKey');
        }
        continue; // Continue searching for more paths
      }
      
      // Limit path length
      if (path.length > maxPathLength) continue;
      
      // Explore neighbors
      for (final neighbor in graph[currentStation]?.entries ?? <MapEntry<String, List<Map<String, dynamic>>>>[]) {
        final neighborStation = neighbor.key;
        
        // Skip already visited stations in this path
        if (visited.contains(neighborStation)) continue;
        
        for (final connection in neighbor.value) {
          final ligneId = connection['ligne']['id'] as String;
          
          final newPath = List<Map<String, dynamic>>.from(path);
          final newLigneSequence = List<String>.from(ligneSequence);
          
          // Check if this is a transfer (different ligne)
          if (ligneId != currentLigne['id']) {
            newPath.add({
              'transfer': true,
              'at': currentStation,
              'atInfo': current['stationInfo'],
              'fromLigne': currentLigne,
              'toLigne': connection['ligne'],
            });
            newLigneSequence.add(ligneId);
          }
          
          newPath.add({
            'from': currentStation,
            'to': neighborStation,
            'ligne': connection['ligne'],
            'fromInfo': connection['station_info'],
            'toInfo': connection['next_station_info'],
          });
          
          queue.add({
            'station': neighborStation,
            'ligne': connection['ligne'],
            'stationInfo': connection['next_station_info'],
            'path': newPath,
            'visited': {...visited, neighborStation},
            'ligneSequence': newLigneSequence,
          });
        }
      }
    }
    
    debugPrint('BFS: Found ${foundPaths.length} unique paths after $iterations iterations');
    return foundPaths;
  }

  /// Convert BFS path to route segments
  Future<List<Map<String, dynamic>>> _pathToSegments(List<Map<String, dynamic>> path) async {
    final segments = <Map<String, dynamic>>[];
    Map<String, dynamic>? currentSegment;
    
    for (final step in path) {
      if (step['transfer'] == true) {
        // Save current segment and start new one
        if (currentSegment != null) {
          segments.add(currentSegment);
        }
        currentSegment = null;
        continue;
      }
      
      final ligne = step['ligne'] as Map<String, dynamic>;
      
      if (currentSegment == null || currentSegment['ligne']['id'] != ligne['id']) {
        // Save previous segment
        if (currentSegment != null) {
          segments.add(currentSegment);
        }
        // Start new segment
        currentSegment = {
          'ligne': ligne,
          'stations': [
            {'station_id': step['from'], 'stations': step['fromInfo']},
            {'station_id': step['to'], 'stations': step['toInfo']},
          ],
          'fromStation': step['from'],
          'toStation': step['to'],
        };
      } else {
        // Continue current segment
        currentSegment['stations'].add({
          'station_id': step['to'],
          'stations': step['toInfo'],
        });
        currentSegment['toStation'] = step['to'];
      }
    }
    
    // Add last segment
    if (currentSegment != null) {
      segments.add(currentSegment);
    }
    
    return segments;
  }
}
