import 'package:flutter/material.dart';

class ConditionsUtilisationPage extends StatelessWidget {
  const ConditionsUtilisationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Conditions d'utilisation"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white), 
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "CONDITIONS GÉNÉRALES DE VENTE ET D'UTILISATION (CGVU) - SNTF",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Version applicable au 14 février 2026",
              style: TextStyle(color: Colors.purpleAccent.withOpacity(0.7), fontSize: 13),
            ),
            const Divider(color: Colors.white24, height: 40),
            
            _buildArticle(
              "Article 1 : Objet du service",
              "L'application mobile SNTF permet aux usagers de consulter les horaires des trains, de réserver des titres de transport et d'accéder aux informations relatives au réseau ferroviaire algérien. En utilisant cette application, vous acceptez sans réserve les présentes conditions."
            ),
            
            _buildArticle(
              "Article 2 : Création de compte",
              "L'accès à certains services, notamment l'achat de billets, nécessite la création d'un compte utilisateur. L'usager s'engage à fournir des informations exactes. L'utilisation d'une fausse identité peut entraîner l'annulation du billet sans remboursement."
            ),
            
            _buildArticle(
              "Article 3 : Tarification et Paiement",
              "Les tarifs affichés sont exprimés en Dinars Algériens (DZD). Le paiement s'effectue via les moyens de paiement électronique agréés (Carte CIB, Edahabia). Une fois la transaction confirmée, le billet électronique est généré instantanément dans l'application."
            ),
            
            _buildArticle(
              "Article 4 : Validité des billets",
              "Le billet électronique est personnel et non transmissible. Il doit être présenté lors du contrôle, soit sur l'écran du smartphone, soit imprimé. L'usager doit également être en mesure de présenter une pièce d'identité officielle en cours de validité."
            ),
            
            _buildArticle(
              "Article 5 : Retards et Annulations",
              "La SNTF s'efforce de respecter les horaires prévus. Toutefois, en cas de force majeure, de travaux sur les voies ou d'incidents techniques, des retards peuvent survenir. L'indemnisation ou le remboursement dépendra des conditions spécifiques à chaque type de trajet (Banlieue, Grande Ligne, Inter-villes)."
            ),
            
            _buildArticle(
              "Article 6 : Comportement à bord",
              "Les voyageurs doivent respecter les règles de sécurité et de civisme à bord des rames. Il est strictement interdit de fumer, de dégrader le matériel ou d'entraver la fermeture des portes. Tout contrevenant s'expose à des amendes ou à une expulsion du train."
            ),
            
            _buildArticle(
              "Article 7 : Transport de bagages",
              "Chaque voyageur a droit à un quota de bagages à main gratuit. Les objets encombrants ou dangereux sont interdits. La SNTF décline toute responsabilité en cas de perte, de vol ou de détérioration des bagages laissés sans surveillance."
            ),
            
            _buildArticle(
              "Article 8 : Modifications des conditions",
              "La SNTF se réserve le droit de modifier les présentes CGU à tout moment. Les utilisateurs seront informés des mises à jour via une notification interne à l'application."
            ),
            
            const SizedBox(height: 30),
            const Center(
              child: Text(
                "Pour toute réclamation, veuillez contacter le service client via la rubrique 'Nous contacter'.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildArticle(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.purpleAccent,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}