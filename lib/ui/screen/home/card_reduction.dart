import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/core/theme/app_text_styles.dart';
import 'package:sntf/ui/widgets/animated_text_field.dart';
import 'package:sntf/ui/widgets/reduction_card.dart';
import 'package:sntf/data/models/cardmodel.dart';



class CardReductionPage extends StatefulWidget {
  const CardReductionPage({super.key});

  @override
  State<CardReductionPage> createState() => _CardReductionPageState();
}

class _CardReductionPageState extends State<CardReductionPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // 2. State: Manage the list of cards here
  final List<CardModel> _cards = [
    CardModel(
      title: "Carte Abonnement",
      subtitle: "Navette Alger - Zeralda",
      price: "1 500 DZD/mois",
      expiryDate: "Exp: 12/2026",
      gradient: AppColors.primaryGradient,
      clientId: "ABO001",
      clientName: "Ali Mohamed",
      cardType: "Abonnement",
    ),
    CardModel(
      title: "Carte Étudiant",
      subtitle: "Réduction -50% Grandes Lignes",
      price: "Gratuit",
      expiryDate: "Exp: 09/2026",
      gradient: AppColors.secondaryGradient,
      clientId: "ETU001",
      clientName: "Ahmed Benali",
      cardType: "Étudiant",
    ),
    CardModel(
      title: "Carte Senior",
      subtitle: "Retraité SNTF",
      price: "500 DZD/an",
      expiryDate: "Exp: 01/2027",
      gradient: AppColors.accentGradient,
      clientId: "SENIOR001",
      clientName: "Fatima Zohra",
      cardType: "Senior",
    ),
  ];

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

  void _addNewCard(String cardNumber) {
    setState(() {
      _cards.add(CardModel(
        title: "Nouvelle Carte",
        subtitle: "Ajouté récemment",
        price: "N/A",
        expiryDate: "Exp: 12/2030",
        gradient: AppColors.primaryGradient,
        clientId: cardNumber,
        clientName: "Utilisateur",
        cardType: "Standard",
      ));
    });
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
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _cards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return ReductionCard(
                      title: card.title,
                      subtitle: card.subtitle,
                      price: card.price,
                      expiryDate: card.expiryDate,
                      gradient: card.gradient,
                      clientId: card.clientId,
                      clientName: card.clientName,
                      cardType: card.cardType,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCardSheet(context),
        backgroundColor: AppColors.primaryDark,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
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
          _addNewCard(cardNumber); 
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