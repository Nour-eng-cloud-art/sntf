import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';

class PolicyPage extends StatefulWidget {
  const PolicyPage({super.key});

  @override
  State<PolicyPage> createState() => _PolicyPageState();
}

class _PolicyPageState extends State<PolicyPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                  'Conditions d\'utilisation',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dernière mise à jour : Janvier 2025',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                _buildSection(
                  theme: theme,
                  isDark: isDark,
                  title: 'Article 1 - Objet',
                  content: 'Les présentes conditions générales d\'utilisation ont pour objet de définir les modalités d\'utilisation de l\'application mobile TransDZ, mise à disposition par TransDZ.',
                ),
                
                _buildSection(
                  theme: theme,
                  isDark: isDark,
                  title: 'Article 2 - Accès au service',
                  content: 'L\'accès à l\'application est gratuit. Toutefois, certaines fonctionnalités peuvent nécessiter la création d\'un compte utilisateur et l\'acceptation des présentes conditions.',
                ),
                
                _buildSection(
                  theme: theme,
                  isDark: isDark,
                  title: 'Article 3 - Inscription',
                  content: 'Pour s\'inscrire, l\'utilisateur doit fournir des informations exactes et complètes. Il s\'engage à mettre à jour ces informations en cas de changement et à ne pas créer plusieurs comptes.',
                ),
                
                _buildSection(
                  theme: theme,
                  isDark: isDark,
                  title: 'Article 4 - Réservation et paiement',
                  content: 'Les réservations effectuées via l\'application sont soumises aux conditions tarifaires en vigueur. Le paiement peut être effectué par carte CIB ou Edahabia. La confirmation de réservation est envoyée par notification et email.',
                ),
                
                _buildSection(
                  theme: theme,
                  isDark: isDark,
                  title: 'Article 5 - Annulation et remboursement',
                  content: 'Les conditions d\'annulation et de remboursement sont conformes à la réglementation en vigueur de TransDZ. Toute demande doit être effectuée au moins 2 heures avant le départ prévu.',
                ),
                
                _buildSection(
                  theme: theme,
                  isDark: isDark,
                  title: 'Article 6 - Protection des données',
                  content: 'TransDZ s\'engage à protéger les données personnelles des utilisateurs conformément à la législation algérienne en vigueur. Les données collectées sont utilisées uniquement dans le cadre des services proposés.',
                ),
                
                _buildSection(
                  theme: theme,
                  isDark: isDark,
                  title: 'Article 7 - Responsabilité',
                  content: 'TransDZ ne saurait être tenue responsable des interruptions de service, des erreurs techniques ou de toute perte de données. L\'utilisateur est responsable de la confidentialité de ses identifiants de connexion.',
                ),
                
                _buildSection(
                  theme: theme,
                  isDark: isDark,
                  title: 'Article 8 - Modification des conditions',
                  content: 'TransDZ se réserve le droit de modifier les présentes conditions à tout moment. Les utilisateurs seront informés de toute modification par notification dans l\'application.',
                ),
                
                const SizedBox(height: 24),
                
                // Contact info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.info,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pour toute question, contactez-nous à contact@transdz.dz',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
