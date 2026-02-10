class Panne {
  final String id;
  final String vehiculeId; // ou LigneId
  final String description;
  final DateTime dateSignalement;
  final bool estResolu;

  Panne({
    required this.id,
    required this.vehiculeId,
    required this.description,
    required this.dateSignalement,
    this.estResolu = false,
  });

  factory Panne.fromJson(Map<String, dynamic> json) {
    return Panne(
      id: json['id'],
      vehiculeId: json['vehicule_id'],
      description: json['description'],
      dateSignalement: DateTime.parse(json['date_signalement']),
      estResolu: json['est_resolu'] ?? false,
    );
  }
}