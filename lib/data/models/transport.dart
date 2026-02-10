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

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'],
      nom: json['nom'],
      // Gestion sécurisée des nombres (parfois int, parfois double)
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accessibilite: json['accessibilite'] ?? false,
    );
  }
}

class Ligne {
  final String id;
  final String nomCourt; // Ex: "14", "B"
  final String direction; // Terminus
  final String couleurHex; // Ex: "#62259D"
  final TransportType type;

  Ligne({
    required this.id,
    required this.nomCourt,
    required this.direction,
    required this.couleurHex,
    required this.type,
  });

  factory Ligne.fromJson(Map<String, dynamic> json) {
    return Ligne(
      id: json['id'],
      nomCourt: json['nom_court'],
      direction: json['direction'],
      couleurHex: json['couleur'],
      type: TransportType.values.firstWhere((e) => e.name == json['type']),
    );
  }
}

class Horaire {
  final String id;
  final String stationId;
  final String ligneId;
  final DateTime heurePassage;
  final bool estEnRetard;

  Horaire({
    required this.id,
    required this.stationId,
    required this.ligneId,
    required this.heurePassage,
    this.estEnRetard = false,
  });

  factory Horaire.fromJson(Map<String, dynamic> json) {
    return Horaire(
      id: json['id'],
      stationId: json['station_id'],
      ligneId: json['ligne_id'],
      heurePassage: DateTime.parse(json['heure_passage']), // Supabase renvoie un String ISO
      estEnRetard: json['est_en_retard'] ?? false,
    );
  }
}