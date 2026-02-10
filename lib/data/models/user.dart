// Enum pour savoir qui est connecté
enum UserRole { client, chauffeur, controleur }

// Genre de l'utilisateur
enum Genre { homme, femme, autre, nonSpecifie }

// Type de carte de réduction
enum CarteReduction { 
  aucune,
  jeune,       // Carte jeune (< 26 ans)
  senior,      // Carte senior (> 60 ans)
  famille,     // Carte famille nombreuse
  handicape,   // Carte handicapé
  militaire,   // Carte militaire
  etudiant,    // Carte étudiant
}

// Type de document d'identité
enum TypeDocument { cin, passeport, permisConduire }

class AppUser {
  final String id; // L'ID unique de Supabase (auth.uid)
  final String nom;
  final String prenom;
  final String email;
  final UserRole role;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.photoUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      // On convertit la chaîne "controleur" en Enum
      role: UserRole.values.firstWhere((e) => e.toString().split('.').last == json['role']),
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role.toString().split('.').last,
      'photo_url': photoUrl,
    };
  }
}

/// Client voyageur - Utilisateur de l'application SNTF
class Client {
  final String id;
  final String userId; // Lien vers AppUser
  
  // Informations personnelles
  final String telephone;
  final DateTime? dateNaissance;
  final Genre genre;
  final String? adresse;
  final String? ville;
  final String? codePostal;
  final String? wilaya;
  
  // Document d'identité
  final TypeDocument? typeDocument;
  final String? numeroDocument;
  
  // Préférences de voyage
  final CarteReduction carteReduction;
  final String? numeroCarteReduction;
  final bool notificationsActives;
  final bool emailsPromotionnels;
  
  // Gares favorites
  final List<String>? garesFavorites;
  
  // Informations de fidélité
  final int pointsFidelite;
  final DateTime dateInscription;

  Client({
    required this.id,
    required this.userId,
    required this.telephone,
    this.dateNaissance,
    this.genre = Genre.nonSpecifie,
    this.adresse,
    this.ville,
    this.codePostal,
    this.wilaya,
    this.typeDocument,
    this.numeroDocument,
    this.carteReduction = CarteReduction.aucune,
    this.numeroCarteReduction,
    this.notificationsActives = true,
    this.emailsPromotionnels = false,
    this.garesFavorites,
    this.pointsFidelite = 0,
    required this.dateInscription,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      userId: json['user_id'],
      telephone: json['telephone'],
      dateNaissance: json['date_naissance'] != null 
          ? DateTime.parse(json['date_naissance']) 
          : null,
      genre: Genre.values.firstWhere(
        (e) => e.toString().split('.').last == json['genre'],
        orElse: () => Genre.nonSpecifie,
      ),
      adresse: json['adresse'],
      ville: json['ville'],
      codePostal: json['code_postal'],
      wilaya: json['wilaya'],
      typeDocument: json['type_document'] != null
          ? TypeDocument.values.firstWhere(
              (e) => e.toString().split('.').last == json['type_document'],
            )
          : null,
      numeroDocument: json['numero_document'],
      carteReduction: CarteReduction.values.firstWhere(
        (e) => e.toString().split('.').last == json['carte_reduction'],
        orElse: () => CarteReduction.aucune,
      ),
      numeroCarteReduction: json['numero_carte_reduction'],
      notificationsActives: json['notifications_actives'] ?? true,
      emailsPromotionnels: json['emails_promotionnels'] ?? false,
      garesFavorites: json['gares_favorites'] != null
          ? List<String>.from(json['gares_favorites'])
          : null,
      pointsFidelite: json['points_fidelite'] ?? 0,
      dateInscription: DateTime.parse(json['date_inscription']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'telephone': telephone,
      'date_naissance': dateNaissance?.toIso8601String(),
      'genre': genre.toString().split('.').last,
      'adresse': adresse,
      'ville': ville,
      'code_postal': codePostal,
      'wilaya': wilaya,
      'type_document': typeDocument?.toString().split('.').last,
      'numero_document': numeroDocument,
      'carte_reduction': carteReduction.toString().split('.').last,
      'numero_carte_reduction': numeroCarteReduction,
      'notifications_actives': notificationsActives,
      'emails_promotionnels': emailsPromotionnels,
      'gares_favorites': garesFavorites,
      'points_fidelite': pointsFidelite,
      'date_inscription': dateInscription.toIso8601String(),
    };
  }

  /// Calcule l'âge du client
  int? get age {
    if (dateNaissance == null) return null;
    final now = DateTime.now();
    int age = now.year - dateNaissance!.year;
    if (now.month < dateNaissance!.month ||
        (now.month == dateNaissance!.month && now.day < dateNaissance!.day)) {
      age--;
    }
    return age;
  }

  /// Vérifie si le client a droit à une réduction jeune
  bool get estJeune => age != null && age! < 26;

  /// Vérifie si le client a droit à une réduction senior
  bool get estSenior => age != null && age! >= 60;
}

class Controleur {
  final String id;
  final String userId; // Lien vers la table AppUser
  final String matricule;
  final String secteur; // Ex: "Zone Paris Centre"

  Controleur({
    required this.id,
    required this.userId,
    required this.matricule,
    required this.secteur,
  });

  factory Controleur.fromJson(Map<String, dynamic> json) {
    return Controleur(
      id: json['id'],
      userId: json['user_id'],
      matricule: json['matricule'],
      secteur: json['secteur'],
    );
  }
}