import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text("Aide & FAQ"), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFaqItem("Comment réserver un billet en ligne ?", 
            "Vous pouvez réserver via l'onglet 'Recherche' et payer par carte CIB ou Edahabia."),
          _buildFaqItem("Quels sont les tarifs pour les étudiants ?", 
            "La SNTF propose une réduction de 50% sur présentation de la carte d'étudiant valide."),
          _buildFaqItem("Puis-je annuler mon voyage ?", 
            "L'annulation est possible au guichet jusqu'à 2 heures avant le départ."),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      iconColor: Colors.purpleAccent,
      collapsedIconColor: Colors.white,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}