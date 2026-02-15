import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/core/theme/app_text_styles.dart';
import 'package:sntf/ui/widgets/reduction_card.dart';


class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedMethod = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.arrowLeft,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Paiement',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Finalisez votre achat en toute sécurité',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Text("Résumé de l'abonnement", style: AppTextStyles.titleLarge.copyWith(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 15),
            const ReductionCard(
              title: "Abonnement Annuel",
              subtitle: "Réseau Banlieue Alger",
              price: "12 000 DZD",
              expiryDate: "31/12/2026",
              clientName: "Mohamed El-Bahri",
              clientId: "SNTF-DZ-2026",
              cardType: "Étudiant",
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),

            const SizedBox(height: 20),
            Text("Moyen de paiement", style: AppTextStyles.titleLarge.copyWith(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 15),

            // Liste des moyens de paiement
            _paymentMethodItem(
              index: 0,
              title: "Carte Edahabia",
              subtitle: "Algérie Poste",
              icon: Icons.credit_card,
              color: AppColors.warning, // Jaune/Orange Poste
              isDark: isDark,
              theme: theme,
            ),
            _paymentMethodItem(
              index: 1,
              title: "Carte CIB",
              subtitle: "Services Interbancaires",
              icon: Icons.payments_outlined,
              color: AppColors.success, // Vert Bancaire
              isDark: isDark,
              theme: theme,
            ),
            _paymentMethodItem(
              index: 2,
              title: "Paiement à la Gare",
              subtitle: "Espèces ou TPE au guichet",
              icon: Icons.train_outlined,
              color: AppColors.primary,
              isDark: isDark,
              theme: theme,
            ),

            const SizedBox(height: 30),
            
            // Total et Bouton
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.3) 
                        : AppColors.grey900.withOpacity(0.05), 
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total à payer", style: AppTextStyles.bodyLarge.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      Text("12 000 DZD", style: AppTextStyles.price.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        _showConfirmation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: Text(
                        "Confirmer le paiement",
                        style: AppTextStyles.buttonLarge.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentMethodItem({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required ThemeData theme,
  }) {
    bool isSelected = _selectedMethod == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.2) 
                  : AppColors.grey900.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMedium.copyWith(color: theme.colorScheme.onSurface)),
                  Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Radio(
              value: index,
              groupValue: _selectedMethod,
              activeColor: color,
              onChanged: (int? value) {
                setState(() => _selectedMethod = value!);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      backgroundColor: theme.colorScheme.surface,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 80),
            const SizedBox(height: 20),
            Text("Demande Envoyée !", style: AppTextStyles.headlineSmall.copyWith(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 10),
            Text(
              "Votre demande d'abonnement est en cours de traitement. Vous recevrez une notification dès validation.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Fermer", style: AppTextStyles.buttonMedium.copyWith(color: theme.colorScheme.primary)),
              ),
            )
          ],
        ),
      ),
    );
  }
}