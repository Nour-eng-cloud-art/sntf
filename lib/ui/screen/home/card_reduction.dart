import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/core/theme/app_text_styles.dart';
import 'package:sntf/ui/widgets/animated_text_field.dart';
import 'package:sntf/ui/widgets/reduction_card.dart';
import 'package:sntf/data/services/supabase_service.dart';
import 'package:sntf/providers/auth_provider.dart';

class CardReductionPage extends StatefulWidget {
  const CardReductionPage({super.key});

  @override
  State<CardReductionPage> createState() => _CardReductionPageState();
}

class _CardReductionPageState extends State<CardReductionPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Map<String, dynamic>> _abonnements = [];
  List<Map<String, dynamic>> _manualCards = []; // Cards added by ID
  bool _isLoading = true;

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
    _loadAbonnements();
  }

  Future<void> _loadAbonnements() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated || authProvider.userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final abonnements = await SupabaseService().getAbonnementsForUser(authProvider.userId!);
      setState(() {
        _abonnements = abonnements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    }
  }

  String _getDisplayType(String? type) {
    if (type == null) return 'STANDARD';
    switch (type.toLowerCase()) {
      case 'sntf_1_day_pass': return 'Pass Journalier';
      case 'sntf_weekly_pass': return 'Pass Hebdomadaire';
      case 'sntf_monthly_pass': return 'Pass Mensuel';
      case 'university_reduce_tram': return 'Étudiant';
      case 'bus_tram': return 'Bus + Tram';
      case 'children_reduce_tram_bus': return 'Enfant';
      case 'airport_reduce_tram_bus': return 'Navette Aéroport';
      default: return type;
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addManualCard(String cardId) {
    setState(() {
      _manualCards.add({
        'id': cardId,
        'type': 'standard',
        'date_debut': DateTime.now().toIso8601String().split('T')[0],
        'date_fin': DateTime.now().add(const Duration(days: 365)).toIso8601String().split('T')[0],
        'is_manual': true,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final allCards = [..._abonnements, ..._manualCards];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes Cartes',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gérez vos cartes de réduction et abonnements',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Cards list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : allCards.isEmpty
                        ? _buildEmptyState(theme)
                        : RefreshIndicator(
                            onRefresh: _loadAbonnements,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: allCards.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 20),
                              itemBuilder: (context, index) {
                                final card = allCards[index];
                                final type = card['type']?.toString() ?? 'standard';
                                final isManual = card['is_manual'] == true;
                                
                                return ReductionCard(
                                  title: isManual 
                                      ? 'Carte Station' 
                                      : _getDisplayType(type),
                                  subtitle: isManual
                                      ? 'Ajouté manuellement'
                                      : 'Abonnement transDZ',
                                  price: isManual ? 'N/A' : 'Actif',
                                  expiryDate: 'Exp: ${_formatDate(card['date_fin'])}',
                                  gradient: _getGradientForType(type),
                                  clientId: card['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A',
                                  clientName: authProvider.user?.prenom ?? 'Utilisateur',
                                  cardType: _getDisplayType(type),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCardSheet(context),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.creditCard,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune carte',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Achetez un abonnement ou ajoutez\nune carte avec son ID',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCardSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom, 
        ),
        child: AddCardForm(onCardAdded: (cardNumber) {
          Navigator.pop(ctx); 
          _addManualCard(cardNumber); 
          _showSuccessDialog();
        }),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Carte ajoutée"),
        content: const Text(
          "Votre carte de réduction a été ajoutée avec succès à votre portefeuille.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}

// 3. Extracted Widget: Handles the Form logic separately
class AddCardForm extends StatefulWidget {
  final Function(String) onCardAdded;

  const AddCardForm({super.key, required this.onCardAdded});

  @override
  State<AddCardForm> createState() => _AddCardFormState();
}

class _AddCardFormState extends State<AddCardForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onCardAdded(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Ajouter une carte",
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 20),
            AnimatedTextField(
              controller: _controller,
              label: 'Numéro de carte',
              hint: 'SNTF-123456',
              prefixIcon: Icons.card_membership_outlined,
              keyboardType: TextInputType.text,
              animationIndex: 1,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le numéro de carte';
                }
                if (!RegExp(r'^SNTF-\d{6}$').hasMatch(value)) {
                  return 'Format invalide (Ex: SNTF-123456)';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                "Ajouter",
                style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}