import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sntf/data/models/national_train.dart';

/// Service for national train operations
class NationalTrainService {
  final SupabaseClient _client;

  NationalTrainService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Get all national stations
  Future<List<StationNationale>> getStations() async {
    try {
      final response = await _client
          .from('stations_nationales')
          .select()
          .order('nom');
      
      return (response as List)
          .map((json) => StationNationale.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des gares: $e');
    }
  }

  /// Get station by city name
  Future<StationNationale?> getStationByVille(String ville) async {
    try {
      final response = await _client
          .from('stations_nationales')
          .select()
          .ilike('ville', ville)
          .maybeSingle();
      
      if (response != null) {
        return StationNationale.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Search trains between two cities on a specific date
  Future<List<TrainSearchResult>> searchTrains({
    required String villeDepart,
    required String villeArrivee,
    required DateTime date,
  }) async {
    try {
      // Get day of week (1 = Monday, 7 = Sunday)
      final dayOfWeek = date.weekday;
      
      // First try to use the view
      final response = await _client
          .from('recherche_trains')
          .select()
          .ilike('ville_depart', villeDepart)
          .ilike('ville_arrivee', villeArrivee)
          .eq('actif', true)
          .contains('jours_circulation', [dayOfWeek])
          .order('heure_depart');
      
      return (response as List)
          .map((json) => TrainSearchResult.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback: manual join if view doesn't exist
      return await _searchTrainsFallback(
        villeDepart: villeDepart,
        villeArrivee: villeArrivee,
        date: date,
      );
    }
  }

  /// Fallback search method using manual joins
  Future<List<TrainSearchResult>> _searchTrainsFallback({
    required String villeDepart,
    required String villeArrivee,
    required DateTime date,
  }) async {
    try {
      // Get stations
      final stationDepart = await getStationByVille(villeDepart);
      final stationArrivee = await getStationByVille(villeArrivee);
      
      if (stationDepart == null || stationArrivee == null) {
        return [];
      }

      // Get route
      final trajetResponse = await _client
          .from('trajets_nationaux')
          .select()
          .eq('station_depart_id', stationDepart.id)
          .eq('station_arrivee_id', stationArrivee.id)
          .maybeSingle();
      
      if (trajetResponse == null) {
        return [];
      }

      final trajet = TrajetNational.fromJson(trajetResponse);
      final dayOfWeek = date.weekday;

      // Get schedules
      final horairesResponse = await _client
          .from('horaires_nationaux')
          .select()
          .eq('trajet_id', trajet.id)
          .eq('actif', true)
          .contains('jours_circulation', [dayOfWeek])
          .order('heure_depart');
      
      return (horairesResponse as List).map((json) {
        return TrainSearchResult(
          horaireId: json['id'],
          numeroTrain: json['numero_train'],
          gareDepart: stationDepart.nom,
          codeDepart: stationDepart.code,
          villeDepart: stationDepart.ville,
          gareArrivee: stationArrivee.nom,
          codeArrivee: stationArrivee.code,
          villeArrivee: stationArrivee.ville,
          heureDepart: json['heure_depart'],
          heureArrivee: json['heure_arrivee'],
          dureeMinutes: trajet.dureeMinutes,
          distanceKm: trajet.distanceKm,
          typeTrain: json['type_train'],
          prixBase: (json['prix_base'] as num).toDouble(),
          placesDisponibles: json['places_disponibles'] ?? 100,
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche des trains: $e');
    }
  }

  /// Create a reservation
  Future<ReservationNationale> createReservation({
    required String horaireId,
    required DateTime dateVoyage,
    required int nombrePassagers,
    required double prixTotal,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Generate reservation number
      final numeroReservation = _generateReservationNumber();
      
      // Random car and seat
      final random = Random();
      final voiture = random.nextInt(5) + 1;
      final place = random.nextInt(50) + 1;

      final response = await _client
          .from('reservations_nationales')
          .insert({
            'user_id': userId,
            'horaire_id': horaireId,
            'date_voyage': dateVoyage.toIso8601String().split('T')[0],
            'nombre_passagers': nombrePassagers,
            'prix_total': prixTotal,
            'statut': 'confirme',
            'numero_reservation': numeroReservation,
            'voiture': voiture,
            'place': place,
          })
          .select('''
            *,
            horaires_nationaux (
              *,
              trajets_nationaux (
                *,
                station_depart:stations_nationales!trajets_nationaux_station_depart_fkey (*),
                station_arrivee:stations_nationales!trajets_nationaux_station_arrivee_fkey (*)
              )
            )
          ''')
          .single();
      
      return ReservationNationale.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la réservation: $e');
    }
  }

  /// Get user's reservations
  Future<List<ReservationNationale>> getUserReservations() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      final response = await _client
          .from('reservations_nationales')
          .select('''
            *,
            horaires_nationaux (
              *,
              trajets_nationaux (
                *,
                station_depart:stations_nationales!trajets_nationaux_station_depart_fkey (*),
                station_arrivee:stations_nationales!trajets_nationaux_station_arrivee_fkey (*)
              )
            )
          ''')
          .eq('user_id', userId)
          .order('date_voyage', ascending: false);
      
      return (response as List)
          .map((json) => ReservationNationale.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des réservations: $e');
    }
  }

  /// Get upcoming reservations
  Future<List<ReservationNationale>> getUpcomingReservations() async {
    try {
      final reservations = await getUserReservations();
      final now = DateTime.now();
      return reservations
          .where((r) => r.dateVoyage.isAfter(now) && r.statut == 'confirme')
          .toList()
        ..sort((a, b) => a.dateVoyage.compareTo(b.dateVoyage));
    } catch (e) {
      return [];
    }
  }

  /// Get past reservations
  Future<List<ReservationNationale>> getPastReservations() async {
    try {
      final reservations = await getUserReservations();
      final now = DateTime.now();
      return reservations
          .where((r) => r.dateVoyage.isBefore(now) || r.statut == 'utilise')
          .toList()
        ..sort((a, b) => b.dateVoyage.compareTo(a.dateVoyage));
    } catch (e) {
      return [];
    }
  }

  /// Get cancelled reservations
  Future<List<ReservationNationale>> getCancelledReservations() async {
    try {
      final reservations = await getUserReservations();
      return reservations
          .where((r) => r.statut == 'annule')
          .toList()
        ..sort((a, b) => b.dateVoyage.compareTo(a.dateVoyage));
    } catch (e) {
      return [];
    }
  }

  /// Cancel a reservation
  Future<void> cancelReservation(String reservationId) async {
    try {
      await _client
          .from('reservations_nationales')
          .update({'statut': 'annule'})
          .eq('id', reservationId);
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation: $e');
    }
  }

  /// Generate unique reservation number
  String _generateReservationNumber() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final randomPart = random.nextInt(9999).toString().padLeft(4, '0');
    return 'SNTF-$timestamp$randomPart';
  }

  /// Update available seats after booking
  Future<void> _updateAvailableSeats(String horaireId, int seatsBooked) async {
    try {
      // Get current available seats
      final response = await _client
          .from('horaires_nationaux')
          .select('places_disponibles')
          .eq('id', horaireId)
          .single();
      
      final currentSeats = response['places_disponibles'] as int;
      final newSeats = currentSeats - seatsBooked;
      
      if (newSeats >= 0) {
        await _client
            .from('horaires_nationaux')
            .update({'places_disponibles': newSeats})
            .eq('id', horaireId);
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }
}
