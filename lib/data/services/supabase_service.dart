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

  /// Get all stations (with or without coordinates)
  Future<List<Map<String, dynamic>>> getStationsWithCoordinates() async {
    final response = await client
        .from('stations')
        .select()
        .order('nom');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Find lignes that pass through both start and end stations
  /// Returns lignes with their stations in order
  Future<List<Map<String, dynamic>>> findConnectingLignes(
    String startStationId, 
    String endStationId,
  ) async {
    // Get all lignes that pass through the start station
    final startLignes = await client
        .from('arrets_lignes')
        .select('ligne_id')
        .eq('station_id', startStationId);
    
    final startLigneIds = (startLignes as List)
        .map((e) => e['ligne_id'] as String)
        .toSet();
    
    // Get all lignes that pass through the end station
    final endLignes = await client
        .from('arrets_lignes')
        .select('ligne_id')
        .eq('station_id', endStationId);
    
    final endLigneIds = (endLignes as List)
        .map((e) => e['ligne_id'] as String)
        .toSet();
    
    // Find common lignes
    final commonLigneIds = startLigneIds.intersection(endLigneIds);
    
    if (commonLigneIds.isEmpty) {
      return [];
    }
    
    // Get full ligne details with all stations
    final result = <Map<String, dynamic>>[];
    
    for (final ligneId in commonLigneIds) {
      // Get ligne info
      final ligneInfo = await client
          .from('lignes')
          .select()
          .eq('id', ligneId)
          .maybeSingle();
      
      if (ligneInfo == null) continue;
      
      // Get all stations for this ligne with coordinates
      final stationsOnLigne = await client
          .from('arrets_lignes')
          .select('*, stations(*)')
          .eq('ligne_id', ligneId)
          .order('ordre_passage');
      
      result.add({
        'ligne': ligneInfo,
        'stations': stationsOnLigne,
      });
    }
    
    return result;
  }

  /// Search stations by name (for autocomplete)
  Future<List<Map<String, dynamic>>> searchStationsByName(String query) async {
    if (query.isEmpty) return [];
    
    final response = await client
        .from('stations')
        .select()
        .ilike('nom', '%$query%')
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }
}
