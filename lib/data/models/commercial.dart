/// Ticket types enum matching database
enum TicketType { unitaire, carnet, navigoJour, allerRetour }

class Ticket {
  final String id;
  final String userId;
  final String type; // "unitaire", "carnet", "navigo_jour", "aller_retour"
  final double prix;
  final DateTime dateAchat;
  final DateTime? dateValidation; // Null si pas encore utilisé

  Ticket({
    required this.id,
    required this.userId,
    required this.type,
    required this.prix,
    required this.dateAchat,
    this.dateValidation,
  });

  bool get estValide {
    if (dateValidation == null) return true; // Pas encore composté
    // Exemple : Valide 1h30 après validation
    final finValidite = dateValidation!.add(const Duration(minutes: 90));
    return DateTime.now().isBefore(finValidite);
  }
  
  bool get estUtilise => dateValidation != null;
  
  /// Time remaining before expiration (after validation)
  Duration? get tempsRestant {
    if (dateValidation == null) return null;
    final finValidite = dateValidation!.add(const Duration(minutes: 90));
    final remaining = finValidite.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      prix: (json['prix'] as num).toDouble(),
      dateAchat: DateTime.parse(json['date_achat']),
      dateValidation: json['date_validation'] != null 
          ? DateTime.parse(json['date_validation']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'prix': prix,
      'date_achat': dateAchat.toIso8601String(),
      'date_validation': dateValidation?.toIso8601String(),
    };
  }
  
  /// Create a new ticket for purchase
  static Map<String, dynamic> forPurchase({
    required String userId,
    required String type,
    required double prix,
  }) {
    return {
      'user_id': userId,
      'type': type,
      'prix': prix,
    };
  }
}

class Abonnement {
  final String id;
  final String userId;
  final String? type; // "Annuel", "Mensuel", "Etudiant"
  final DateTime dateDebut;
  final DateTime dateFin;

  Abonnement({
    required this.id,
    required this.userId,
    this.type,
    required this.dateDebut,
    required this.dateFin,
  });

  bool get estActif {
    final now = DateTime.now();
    return now.isAfter(dateDebut) && now.isBefore(dateFin);
  }
  
  /// Days remaining in the subscription
  int get joursRestants {
    final now = DateTime.now();
    if (now.isAfter(dateFin)) return 0;
    return dateFin.difference(now).inDays;
  }
  
  /// Progress percentage (0.0 to 1.0)
  double get progression {
    final total = dateFin.difference(dateDebut).inDays;
    final elapsed = DateTime.now().difference(dateDebut).inDays;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  factory Abonnement.fromJson(Map<String, dynamic> json) {
    return Abonnement(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      dateDebut: DateTime.parse(json['date_debut']),
      dateFin: DateTime.parse(json['date_fin']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'date_debut': dateDebut.toIso8601String().split('T')[0],
      'date_fin': dateFin.toIso8601String().split('T')[0],
    };
  }
  
  /// Create a new subscription
  static Map<String, dynamic> forPurchase({
    required String userId,
    required String type,
    required int durationMonths,
  }) {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month + durationMonths, now.day);
    return {
      'user_id': userId,
      'type': type,
      'date_debut': now.toIso8601String().split('T')[0],
      'date_fin': endDate.toIso8601String().split('T')[0],
    };
  }
}

class Amende {
  final String id;
  final String userId;       // Le fraudeur
  final String controleurId; // Celui qui a mis l'amende
  final double montant;
  final String motif;        // "Pas de titre", "Titre invalide"
  final DateTime dateEmission;
  final bool estPayee;

  Amende({
    required this.id,
    required this.userId,
    required this.controleurId,
    required this.montant,
    required this.motif,
    required this.dateEmission,
    this.estPayee = false,
  });

  factory Amende.fromJson(Map<String, dynamic> json) {
    return Amende(
      id: json['id'],
      userId: json['user_id'],
      controleurId: json['controleur_id'],
      montant: (json['montant'] as num).toDouble(),
      motif: json['motif'],
      dateEmission: DateTime.parse(json['date_emission']),
      estPayee: json['est_payee'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'controleur_id': controleurId,
      'montant': montant,
      'motif': motif,
      'est_payee': estPayee,
    };
  }
  
  /// Create a new amende (for controleurs)
  static Map<String, dynamic> forCreation({
    required String userId,
    required String controleurId,
    required double montant,
    required String motif,
  }) {
    return {
      'user_id': userId,
      'controleur_id': controleurId,
      'montant': montant,
      'motif': motif,
    };
  }
}