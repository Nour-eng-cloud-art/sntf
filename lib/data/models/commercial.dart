class Ticket {
  final String id;
  final String userId;
  final String type; // "Unitaire", "Carnet", "Navigo Jour"
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
}

class Abonnement {
  final String id;
  final String userId;
  final String type; // "Annuel", "Mensuel", "Etudiant"
  final DateTime dateDebut;
  final DateTime dateFin;

  Abonnement({
    required this.id,
    required this.userId,
    required this.type,
    required this.dateDebut,
    required this.dateFin,
  });

  bool get estActif {
    final now = DateTime.now();
    return now.isAfter(dateDebut) && now.isBefore(dateFin);
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
  
  // Utile pour envoyer l'update à Supabase quand le user paie
  Map<String, dynamic> toJson() {
    return {
      'est_payee': estPayee,
    };
  }
}