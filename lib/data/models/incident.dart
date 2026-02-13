import 'package:sntf/data/models/transport.dart';

class Panne {
  final String id;
  final String? vehiculeId;
  final String? description;
  final DateTime dateSignalement;
  final bool estResolu;
  final Vehicule? vehicule; // Populated when joined

  Panne({
    required this.id,
    this.vehiculeId,
    this.description,
    required this.dateSignalement,
    this.estResolu = false,
    this.vehicule,
  });
  
  /// Check if this is a recent incident (within last 24 hours)
  bool get estRecent {
    return DateTime.now().difference(dateSignalement).inHours < 24;
  }
  
  /// Duration since the incident was reported
  Duration get dureePanne => DateTime.now().difference(dateSignalement);

  factory Panne.fromJson(Map<String, dynamic> json) {
    return Panne(
      id: json['id'],
      vehiculeId: json['vehicule_id'],
      description: json['description'],
      dateSignalement: DateTime.parse(json['date_signalement']),
      estResolu: json['est_resolu'] ?? false,
      vehicule: json['vehicules'] != null 
          ? Vehicule.fromJson(json['vehicules']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'vehicule_id': vehiculeId,
      'description': description,
      'est_resolu': estResolu,
    };
  }
  
  /// Create a new panne report
  static Map<String, dynamic> forReport({
    required String vehiculeId,
    required String description,
  }) {
    return {
      'vehicule_id': vehiculeId,
      'description': description,
    };
  }
}