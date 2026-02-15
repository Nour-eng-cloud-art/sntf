import 'package:flutter/material.dart';
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

class _CardReductionPageState extends State<CardReductionPage> {
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Mes Cartes"),
        backgroundColor: colorScheme.surface, 
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _cards.length + 1, // +1 for the Header
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          // Header Section
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Portefeuille numérique",
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Retrouvez ici vos cartes d'abonnement et de réduction actives.",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            );
          }

          // Card Items
          final card = _cards[index - 1];
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