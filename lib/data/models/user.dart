enum UserRole { client, chauffeur, controleur }

enum Genre { homme, femme, autre, nonSpecifie }

enum CarteReduction { 
  aucune,
  jeune,       
  senior,      
  famille,     
  handicape,   
  militaire,   
  etudiant,    
}

enum TypeDocument { cin, passeport, permisConduire }

class AppUser {
  final String id; 
  final String? email;
  final String? nom;
  final String? prenom;
  final UserRole role;
  final DateTime? dateNaissance;
  final String? photoUrl;
  final DateTime createdAt;
  final int ewalletMontant;

  AppUser({
    required this.id,
    this.email,
    this.nom,
    this.prenom,
    this.role = UserRole.client,
    this.dateNaissance,
    this.photoUrl,
    DateTime? createdAt,
    this.ewalletMontant = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  String get fullName => '${prenom ?? ''} ${nom ?? ''}'.trim();
  
  bool get isComplete => nom != null && prenom != null && email != null;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      nom: json['nom'],
      prenom: json['prenom'],
      role: _parseRole(json['role']),
      dateNaissance: json['date_naissance'] != null 
          ? DateTime.parse(json['date_naissance']) 
          : null,
      photoUrl: json['photo_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      ewalletMontant: json['ewallet_montant'] ?? 0,
    );
  }
  
  static UserRole _parseRole(dynamic role) {
    if (role == null) return UserRole.client;
    final roleStr = role.toString().toLowerCase();
    return UserRole.values.firstWhere(
      (e) => e.name == roleStr,
      orElse: () => UserRole.client,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'role': role.name,
      'date_naissance': dateNaissance?.toIso8601String().split('T')[0],
      'photo_url': photoUrl,
      'ewallet_montant': ewalletMontant,
    };
  }
  
  AppUser copyWith({
    String? id,
    String? email,
    String? nom,
    String? prenom,
    UserRole? role,
    DateTime? dateNaissance,
    String? photoUrl,
    DateTime? createdAt,
    int? ewalletMontant,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      role: role ?? this.role,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      ewalletMontant: ewalletMontant ?? this.ewalletMontant,
    );
  }
}

/// Chauffeur (Driver) - linked to profiles table
class Chauffeur {
  final String id; // Same as profile id
  final String matricule;
  final DateTime? dateEmbauche;
  final AppUser? profile; // Populated when joined

  Chauffeur({
    required this.id,
    required this.matricule,
    this.dateEmbauche,
    this.profile,
  });

  factory Chauffeur.fromJson(Map<String, dynamic> json) {
    return Chauffeur(
      id: json['id'],
      matricule: json['matricule'],
      dateEmbauche: json['date_embauche'] != null 
          ? DateTime.parse(json['date_embauche']) 
          : null,
      profile: json['profiles'] != null 
          ? AppUser.fromJson(json['profiles']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricule': matricule,
      'date_embauche': dateEmbauche?.toIso8601String().split('T')[0],
    };
  }
}

class Controleur {
  final String id; // Same as profile id
  final String matricule;
  final String? secteurZone;
  final AppUser? profile; // Populated when joined

  Controleur({
    required this.id,
    required this.matricule,
    this.secteurZone,
    this.profile,
  });

  factory Controleur.fromJson(Map<String, dynamic> json) {
    return Controleur(
      id: json['id'],
      matricule: json['matricule'],
      secteurZone: json['secteur_zone'],
      profile: json['profiles'] != null 
          ? AppUser.fromJson(json['profiles']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricule': matricule,
      'secteur_zone': secteurZone,
    };
  }
}

class Client {
  final String id;
  final String userId; 
  
  final String telephone;
  final DateTime? dateNaissance;
  final Genre genre;
  final String? adresse;
  final String? ville;
  final String? codePostal;
  final String? wilaya;
  
  
  final TypeDocument? typeDocument;
  final String? numeroDocument;
  
  final CarteReduction carteReduction;
  final String? numeroCarteReduction;
  final bool notificationsActives;
  final bool emailsPromotionnels;
  
  final List<String>? garesFavorites;
  
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