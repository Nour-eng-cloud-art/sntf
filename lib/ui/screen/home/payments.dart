import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/core/theme/app_text_styles.dart';
import 'package:sntf/data/services/supabase_service.dart';
import 'package:sntf/providers/auth_provider.dart';
import 'package:sntf/data/services/supabase_service.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late PageController _pageController;

  int _selectedMethod = 0;
  int _currentCardIndex = 0;
  bool _isLoading = true;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _services = [];

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
    _pageController = PageController(viewportFraction: 0.85);
    _animationController.forward();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final services = await SupabaseService().getPriceServices();

      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de chargement: $e')));
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _getDisplayType(String? type) {
    if (type == null) return 'STANDARD';
    switch (type.toLowerCase()) {
      case 'sntf_1_day_pass':
        return 'JOURNALIER';
      case 'sntf_weekly_pass':
        return 'HEBDO';
      case 'sntf_monthly_pass':
        return 'MENSUEL';
      case 'university_reduce_tram':
        return 'ÉTUDIANT';
      case 'bus_tram':
        return 'BUS+TRAM';
      case 'children_reduce_tram_bus':
        return 'ENFANT';
      case 'airport_reduce_tram_bus':
        return 'AÉROPORT';
      default:
        return type.toUpperCase();
    }
  }

  LinearGradient _getGradientForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'sntf_1_day_pass':
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'sntf_weekly_pass':
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'sntf_monthly_pass':
        return const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'university_reduce_tram':
        return const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'bus_tram':
        return const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'children_reduce_tram_bus':
        return const LinearGradient(
          colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'airport_reduce_tram_bus':
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getIconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'sntf_1_day_pass':
        return LucideIcons.calendar;
      case 'sntf_weekly_pass':
        return LucideIcons.calendarRange;
      case 'sntf_monthly_pass':
        return LucideIcons.calendarDays;
      case 'university_reduce_tram':
        return LucideIcons.graduationCap;
      case 'bus_tram':
        return LucideIcons.bus;
      case 'children_reduce_tram_bus':
        return LucideIcons.baby;
      case 'airport_reduce_tram_bus':
        return LucideIcons.plane;
      default:
        return LucideIcons.ticket;
    }
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurfaceVariant
                                        : AppColors.grey100,
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
                            'Abonnements',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Glissez pour découvrir nos offres',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Swipeable Cards
                    _services.isEmpty
                        ? Container(
                            height: 280,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.grey100,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.ticketX,
                                    size: 48,
                                    color: AppColors.grey400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun abonnement disponible',
                                    style: TextStyle(color: AppColors.grey400),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 280,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: _services.length,
                              onPageChanged: (index) {
                                setState(() => _currentCardIndex = index);
                              },
                              itemBuilder: (context, index) {
                                final service = _services[index];
                                return _buildSubscriptionCard(
                                  service,
                                  index,
                                  isDark,
                                  theme,
                                );
                              },
                            ),
                          ),

                    // Page Indicator
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _services.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentCardIndex == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentCardIndex == index
                                ? AppColors.primary
                                : AppColors.grey400,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Payment Section
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Moyen de paiement",
                              style: AppTextStyles.titleLarge.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _paymentMethodItem(
                              index: 0,
                              title: "Carte Edahabia",
                              subtitle: "Algérie Poste",
                              icon: Icons.credit_card,
                              color: AppColors.warning,
                              isDark: isDark,
                              theme: theme,
                            ),
                            _paymentMethodItem(
                              index: 1,
                              title: "Carte CIB",
                              subtitle: "Services Interbancaires",
                              icon: Icons.payments_outlined,
                              color: AppColors.success,
                              isDark: isDark,
                              theme: theme,
                            ),
                            const SizedBox(height: 20),

                            // Pay Button
                            if (_services.isNotEmpty) _buildPayButton(theme),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(
    Map<String, dynamic> service,
    int index,
    bool isDark,
    ThemeData theme,
  ) {
    final isSelected = _currentCardIndex == index;
    final serviceType = service['type'] as String?;
    final gradient = _getGradientForType(serviceType);
    final icon = _getIconForType(serviceType);

    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: isSelected ? 1.0 : 0.7,
        duration: const Duration(milliseconds: 300),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background Pattern
              Positioned(
                right: -30,
                top: -30,
                child: Icon(
                  icon,
                  size: 150,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getDisplayType(serviceType),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Icon(icon, color: Colors.white, size: 32),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      service['name'] ?? 'Abonnement',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        service['description'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'transDZ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${service['price'] ?? 0} DZD',
                            style: TextStyle(
                              color: gradient.colors.first,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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

  Widget _buildPayButton(ThemeData theme) {
    final currentService = _services[_currentCardIndex];
    final price = currentService['price'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total à payer",
                style: AppTextStyles.bodyLarge.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                "$price DZD",
                style: AppTextStyles.price.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Confirmer le paiement",
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || authProvider.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour continuer')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final currentService = _services[_currentCardIndex];
      final serviceType = currentService['type'] as String?;
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 365)); // 1 year subscription

      final abonnement = {
        'user_id': authProvider.userId,
        'type': serviceType,
        'date_debut': now.toIso8601String().split('T')[0],
        'date_fin': endDate.toIso8601String().split('T')[0],
      };

      await SupabaseService().createAbonnement(abonnement);

      setState(() => _isProcessing = false);
      _showConfirmation(currentService);
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _showConfirmation(Map<String, dynamic> service) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: theme.colorScheme.surface,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Paiement Réussi !",
              style: AppTextStyles.headlineSmall.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Votre abonnement ${service['name']} a été activé avec succès. Vous pouvez le consulter dans Mes Cartes.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      "Fermer",
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      // Navigate to card_reduction page
                      Navigator.pushNamed(context, '/card-reduction');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      "Mes Cartes",
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
