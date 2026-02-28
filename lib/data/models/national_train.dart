/// Models for national train system

/// National station model
class StationNationale {
  final String id;
  final String nom;
  final String code;
  final double latitude;
  final double longitude;
  final String ville;
  final DateTime? createdAt;

  StationNationale({
    required this.id,
    required this.nom,
    required this.code,
    required this.latitude,
    required this.longitude,
    required this.ville,
    this.createdAt,
  });

  factory StationNationale.fromJson(Map<String, dynamic> json) {
    return StationNationale(
      id: json['id'] as String,
      nom: json['nom'] as String,
      code: json['code'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      ville: json['ville'] as String,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'code': code,
      'latitude': latitude,
      'longitude': longitude,
      'ville': ville,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

/// National route model
class TrajetNational {
  final String id;
  final String stationDepartId;
  final String stationArriveeId;
  final int distanceKm;
  final int dureeMinutes;
  final DateTime? createdAt;
  
  // Join fields
  final StationNationale? stationDepart;
  final StationNationale? stationArrivee;

  TrajetNational({
    required this.id,
    required this.stationDepartId,
    required this.stationArriveeId,
    required this.distanceKm,
    required this.dureeMinutes,
    this.createdAt,
    this.stationDepart,
    this.stationArrivee,
  });

  factory TrajetNational.fromJson(Map<String, dynamic> json) {
    return TrajetNational(
      id: json['id'] as String,
      stationDepartId: json['station_depart_id'] as String,
      stationArriveeId: json['station_arrivee_id'] as String,
      distanceKm: json['distance_km'] as int,
      dureeMinutes: json['duree_minutes'] as int,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      stationDepart: json['station_depart'] != null 
          ? StationNationale.fromJson(json['station_depart'] as Map<String, dynamic>)
          : null,
      stationArrivee: json['station_arrivee'] != null 
          ? StationNationale.fromJson(json['station_arrivee'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Train schedule model
class HoraireNational {
  final String id;
  final String trajetId;
  final String numeroTrain;
  final String heureDepart;
  final String heureArrivee;
  final String typeTrain;
  final double prixBase;
  final int placesDisponibles;
  final List<int> joursCirculation;
  final bool actif;
  final DateTime? createdAt;
  
  // Join fields
  final TrajetNational? trajet;

  HoraireNational({
    required this.id,
    required this.trajetId,
    required this.numeroTrain,
    required this.heureDepart,
    required this.heureArrivee,
    required this.typeTrain,
    required this.prixBase,
    required this.placesDisponibles,
    required this.joursCirculation,
    required this.actif,
    this.createdAt,
    this.trajet,
  });

  factory HoraireNational.fromJson(Map<String, dynamic> json) {
    return HoraireNational(
      id: json['id'] as String,
      trajetId: json['trajet_id'] as String,
      numeroTrain: json['numero_train'] as String,
      heureDepart: json['heure_depart'] as String,
      heureArrivee: json['heure_arrivee'] as String,
      typeTrain: json['type_train'] as String,
      prixBase: (json['prix_base'] as num).toDouble(),
      placesDisponibles: json['places_disponibles'] as int? ?? 100,
      joursCirculation: json['jours_circulation'] != null 
          ? List<int>.from(json['jours_circulation'] as List)
          : [1, 2, 3, 4, 5, 6, 7],
      actif: json['actif'] as bool? ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      trajet: json['trajets_nationaux'] != null 
          ? TrajetNational.fromJson(json['trajets_nationaux'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Get duration in format "Xh Ymin"
  String get dureeFormatted {
    if (trajet != null) {
      final hours = trajet!.dureeMinutes ~/ 60;
      final minutes = trajet!.dureeMinutes % 60;
      if (hours > 0 && minutes > 0) {
        return '${hours}h ${minutes}min';
      } else if (hours > 0) {
        return '${hours}h';
      } else {
        return '${minutes}min';
      }
    }
    return '';
  }
}

/// Reservation model
class ReservationNationale {
  final String id;
  final String userId;
  final String horaireId;
  final DateTime dateVoyage;
  final int nombrePassagers;
  final double prixTotal;
  final String statut;
  final String numeroReservation;
  final int? voiture;
  final int? place;
  final DateTime? dateReservation;
  
  // Join fields
  final HoraireNational? horaire;

  ReservationNationale({
    required this.id,
    required this.userId,
    required this.horaireId,
    required this.dateVoyage,
    required this.nombrePassagers,
    required this.prixTotal,
    required this.statut,
    required this.numeroReservation,
    this.voiture,
    this.place,
    this.dateReservation,
    this.horaire,
  });

  factory ReservationNationale.fromJson(Map<String, dynamic> json) {
    return ReservationNationale(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      horaireId: json['horaire_id'] as String,
      dateVoyage: DateTime.parse(json['date_voyage'] as String),
      nombrePassagers: json['nombre_passagers'] as int? ?? 1,
      prixTotal: (json['prix_total'] as num).toDouble(),
      statut: json['statut'] as String? ?? 'confirme',
      numeroReservation: json['numero_reservation'] as String,
      voiture: json['voiture'] as int?,
      place: json['place'] as int?,
      dateReservation: json['date_reservation'] != null 
          ? DateTime.parse(json['date_reservation'] as String) 
          : null,
      horaire: json['horaires_nationaux'] != null 
          ? HoraireNational.fromJson(json['horaires_nationaux'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'horaire_id': horaireId,
      'date_voyage': dateVoyage.toIso8601String().split('T')[0],
      'nombre_passagers': nombrePassagers,
      'prix_total': prixTotal,
      'statut': statut,
      'numero_reservation': numeroReservation,
      'voiture': voiture,
      'place': place,
    };
  }

  /// Check if reservation is upcoming
  bool get isUpcoming {
    return dateVoyage.isAfter(DateTime.now()) && statut == 'confirme';
  }

  /// Check if reservation is past
  bool get isPast {
    return dateVoyage.isBefore(DateTime.now()) || statut == 'utilise';
  }

  /// Check if reservation is cancelled
  bool get isCancelled {
    return statut == 'annule';
  }

  /// Get formatted date
  String get dateFormatted {
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    final dayName = days[dateVoyage.weekday - 1];
    final monthName = months[dateVoyage.month - 1];
    return '$dayName. ${dateVoyage.day} $monthName ${dateVoyage.year}';
  }

  /// Get formatted voyage date (alias for dateFormatted)
  String get dateVoyageFormatted => dateFormatted;

  /// Get departure city from joined horaire
  String get villeDepart {
    return horaire?.trajet?.stationDepart?.ville ?? 'N/A';
  }

  /// Get arrival city from joined horaire
  String get villeArrivee {
    return horaire?.trajet?.stationArrivee?.ville ?? 'N/A';
  }

  /// Get formatted departure time
  String get heureDepartFormatted {
    if (horaire != null) {
      final parts = horaire!.heureDepart.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
    }
    return 'N/A';
  }

  /// Get formatted duration
  String get dureeFormatted {
    if (horaire?.trajet != null) {
      final minutes = horaire!.trajet!.dureeMinutes;
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (hours > 0 && mins > 0) {
        return '${hours}h ${mins}min';
      } else if (hours > 0) {
        return '${hours}h';
      } else {
        return '${mins}min';
      }
    }
    return 'N/A';
  }
}

/// Train search result combining schedule and route info
class TrainSearchResult {
  final String horaireId;
  final String numeroTrain;
  final String gareDepart;
  final String codeDepart;
  final String villeDepart;
  final String gareArrivee;
  final String codeArrivee;
  final String villeArrivee;
  final String heureDepart;
  final String heureArrivee;
  final int dureeMinutes;
  final int distanceKm;
  final String typeTrain;
  final double prixBase;
  final int placesDisponibles;

  TrainSearchResult({
    required this.horaireId,
    required this.numeroTrain,
    required this.gareDepart,
    required this.codeDepart,
    required this.villeDepart,
    required this.gareArrivee,
    required this.codeArrivee,
    required this.villeArrivee,
    required this.heureDepart,
    required this.heureArrivee,
    required this.dureeMinutes,
    required this.distanceKm,
    required this.typeTrain,
    required this.prixBase,
    required this.placesDisponibles,
  });

  factory TrainSearchResult.fromJson(Map<String, dynamic> json) {
    return TrainSearchResult(
      horaireId: json['horaire_id'] as String,
      numeroTrain: json['numero_train'] as String,
      gareDepart: json['gare_depart'] as String,
      codeDepart: json['code_depart'] as String,
      villeDepart: json['ville_depart'] as String,
      gareArrivee: json['gare_arrivee'] as String,
      codeArrivee: json['code_arrivee'] as String,
      villeArrivee: json['ville_arrivee'] as String,
      heureDepart: json['heure_depart'] as String,
      heureArrivee: json['heure_arrivee'] as String,
      dureeMinutes: json['duree_minutes'] as int,
      distanceKm: json['distance_km'] as int,
      typeTrain: json['type_train'] as String,
      prixBase: (json['prix_base'] as num).toDouble(),
      placesDisponibles: json['places_disponibles'] as int? ?? 100,
    );
  }

  /// Get duration formatted
  String get dureeFormatted {
    final hours = dureeMinutes ~/ 60;
    final minutes = dureeMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  /// Format time from HH:MM:SS to HH:MM
  String get heureDepartFormatted {
    final parts = heureDepart.split(':');
    return '${parts[0]}:${parts[1]}';
  }

  String get heureArriveeFormatted {
    final parts = heureArrivee.split(':');
    return '${parts[0]}:${parts[1]}';
  }
}
