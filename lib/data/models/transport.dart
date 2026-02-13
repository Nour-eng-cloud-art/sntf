enum TransportType { bus, metro, rer, tramway, train }

class Station {
  final String id;
  final String nom;
  final double latitude;
  final double longitude;
  final bool accessibilite; // Accès handicapé

  Station({
    required this.id,
    required this.nom,
    required this.latitude,
    required this.longitude,
    this.accessibilite = false,
  });

  /// Parse PostGIS geography point from Supabase
  /// Format can be: "POINT(longitude latitude)" or {"type": "Point", "coordinates": [lng, lat]}
  static (double lat, double lng) _parseLocation(dynamic location) {
    if (location == null) {
      return (0.0, 0.0);
    }
    
    if (location is String) {
      // Parse "POINT(longitude latitude)" format
      final regex = RegExp(r'POINT\(([^\s]+)\s+([^\)]+)\)');
      final match = regex.firstMatch(location);
      if (match != null) {
        final lng = double.tryParse(match.group(1) ?? '0') ?? 0.0;
        final lat = double.tryParse(match.group(2) ?? '0') ?? 0.0;
        return (lat, lng);
      }
    } else if (location is Map) {
      // Parse GeoJSON format {"type": "Point", "coordinates": [lng, lat]}
      final coordinates = location['coordinates'] as List?;
      if (coordinates != null && coordinates.length >= 2) {
        final lng = (coordinates[0] as num).toDouble();
        final lat = (coordinates[1] as num).toDouble();
        return (lat, lng);
      }
    }
    
    return (0.0, 0.0);
  }

  factory Station.fromJson(Map<String, dynamic> json) {
    // Handle PostGIS location field
    double lat = 0.0;
    double lng = 0.0;
    
    if (json.containsKey('location')) {
      final (parsedLat, parsedLng) = _parseLocation(json['location']);
      lat = parsedLat;
      lng = parsedLng;
    } else if (json.containsKey('latitude') && json.containsKey('longitude')) {
      lat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
      lng = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    }
    
    return Station(
      id: json['id'],
      nom: json['nom'],
      latitude: lat,
      longitude: lng,
      accessibilite: json['accessibilite'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'location': 'POINT($longitude $latitude)',
      'accessibilite': accessibilite,
    };
  }
}

class Ligne {
  final String id;
  final String nomCourt; // Ex: "14", "B"
  final String directionTerminus; // Terminus
  final String? couleurHex; // Ex: "#62259D"
  final TransportType type;
  final DateTime? createdAt;

  Ligne({
    required this.id,
    required this.nomCourt,
    required this.directionTerminus,
    this.couleurHex,
    required this.type,
    this.createdAt,
  });

  factory Ligne.fromJson(Map<String, dynamic> json) {
    return Ligne(
      id: json['id'],
      nomCourt: json['nom_court'],
      directionTerminus: json['direction_terminus'],
      couleurHex: json['couleur_hex'],
      type: _parseTransportType(json['type']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }
  
  static TransportType _parseTransportType(dynamic type) {
    if (type == null) return TransportType.bus;
    final typeStr = type.toString().toLowerCase();
    return TransportType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => TransportType.bus,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'nom_court': nomCourt,
      'direction_terminus': directionTerminus,
      'couleur_hex': couleurHex,
      'type': type.name,
    };
  }
}

/// Junction table for ligne-station relationship
class ArretLigne {
  final String ligneId;
  final String stationId;
  final int? ordrePassage;
  final Station? station; // Populated when joined
  final Ligne? ligne; // Populated when joined

  ArretLigne({
    required this.ligneId,
    required this.stationId,
    this.ordrePassage,
    this.station,
    this.ligne,
  });

  factory ArretLigne.fromJson(Map<String, dynamic> json) {
    return ArretLigne(
      ligneId: json['ligne_id'],
      stationId: json['station_id'],
      ordrePassage: json['ordre_passage'],
      station: json['stations'] != null 
          ? Station.fromJson(json['stations']) 
          : null,
      ligne: json['lignes'] != null 
          ? Ligne.fromJson(json['lignes']) 
          : null,
    );
  }
}

class Horaire {
  final String id;
  final String? stationId;
  final String? ligneId;
  final DateTime heurePassage;
  final bool estEnRetard;
  final Station? station; // Populated when joined
  final Ligne? ligne; // Populated when joined

  Horaire({
    required this.id,
    this.stationId,
    this.ligneId,
    required this.heurePassage,
    this.estEnRetard = false,
    this.station,
    this.ligne,
  });

  factory Horaire.fromJson(Map<String, dynamic> json) {
    return Horaire(
      id: json['id'],
      stationId: json['station_id'],
      ligneId: json['ligne_id'],
      heurePassage: DateTime.parse(json['heure_passage']),
      estEnRetard: json['est_en_retard'] ?? false,
      station: json['stations'] != null 
          ? Station.fromJson(json['stations']) 
          : null,
      ligne: json['lignes'] != null 
          ? Ligne.fromJson(json['lignes']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'station_id': stationId,
      'ligne_id': ligneId,
      'heure_passage': heurePassage.toIso8601String(),
      'est_en_retard': estEnRetard,
    };
  }
  
  /// Get time until this passage
  Duration get timeUntil => heurePassage.difference(DateTime.now());
  
  /// Check if this horaire is upcoming (within next hour)
  bool get isUpcoming {
    final now = DateTime.now();
    return heurePassage.isAfter(now) && 
           heurePassage.isBefore(now.add(const Duration(hours: 1)));
  }
}

class Vehicule {
  final String id;
  final String? ligneId;
  final String? immatriculation;
  final DateTime? dateMiseService;
  final bool estEnService;
  final Ligne? ligne; // Populated when joined

  Vehicule({
    required this.id,
    this.ligneId,
    this.immatriculation,
    this.dateMiseService,
    this.estEnService = true,
    this.ligne,
  });

  factory Vehicule.fromJson(Map<String, dynamic> json) {
    return Vehicule(
      id: json['id'],
      ligneId: json['ligne_id'],
      immatriculation: json['immatriculation'],
      dateMiseService: json['date_mise_service'] != null 
          ? DateTime.parse(json['date_mise_service']) 
          : null,
      estEnService: json['est_en_service'] ?? true,
      ligne: json['lignes'] != null 
          ? Ligne.fromJson(json['lignes']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'ligne_id': ligneId,
      'immatriculation': immatriculation,
      'date_mise_service': dateMiseService?.toIso8601String().split('T')[0],
      'est_en_service': estEnService,
    };
  }
}