import 'package:flutter/material.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/core/theme/app_text_styles.dart';
import 'package:sntf/ui/widgets/reduction_card.dart';

class CardReductionPage extends StatefulWidget {
  const CardReductionPage({super.key});

  @override
  State<CardReductionPage> createState() => _CardReductionPageState();
}

class _CardReductionPageState extends State<CardReductionPage> {
  @override
  Widget build(BuildContext context) {
    // Utilisation du thème sombre ou clair selon le contexte
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Mes Cartes"),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Portefeuille numérique",
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Retrouvez ici vos cartes d'abonnement et de réduction actives.",
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey500,
              ),
            ),
            const SizedBox(height: 30),

            const ReductionCard(
              title: "Carte Abonnement",
              subtitle: "Navette Alger - Zeralda",
              price: "1 500 DZD/mois",
              expiryDate: "Exp: 12/2026",
              gradient: AppColors.primaryGradient,
              clientId: "ABO001",
              clientName: "Ali Mohamed",
              cardType: "Abonnement",
            ),

            const ReductionCard(
              title: "Carte Étudiant",
              subtitle: "Réduction -50% Grandes Lignes",
              price: "Gratuit",
              expiryDate: "Exp: 09/2026",
              gradient: AppColors.secondaryGradient,
              clientId: "ETU001",
              clientName: "Ahmed Benali",
              cardType: "Étudiant",
            ),

            const ReductionCard(
              title: "Carte Senior",
              subtitle: "Retraité SNTF",
              price: "500 DZD/an",
              expiryDate: "Exp: 01/2027",
              gradient: AppColors.accentGradient,
              clientId: "SENIOR001",
              clientName: "Fatima Zohra",
              cardType: "Senior",
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
