import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/data/models/national_train.dart';
import 'package:sntf/data/services/national_train_service.dart';
import 'package:sntf/providers/auth_provider.dart';

class TrainSearchResultsScreen extends StatefulWidget {
  final String departure;
  final String arrival;
  final DateTime date;
  final int passengers;

  const TrainSearchResultsScreen({
    super.key,
    required this.departure,
    required this.arrival,
    required this.date,
    required this.passengers,
  });

  @override
  State<TrainSearchResultsScreen> createState() => _TrainSearchResultsScreenState();
}

class _TrainSearchResultsScreenState extends State<TrainSearchResultsScreen> {
  final NationalTrainService _trainService = NationalTrainService();
  List<TrainSearchResult> _trains = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrains();
  }

  Future<void> _loadTrains() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trains = await _trainService.searchTrains(
        villeDepart: widget.departure,
        villeArrivee: widget.arrival,
        date: widget.date,
      );
      
      setState(() {
        _trains = trains;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Trains disponibles'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search summary card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.circleDot, color: AppColors.success, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            widget.departure,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Container(
                          width: 2,
                          height: 20,
                          color: AppColors.grey300,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            widget.arrival,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${widget.date.day}/${widget.date.month}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${widget.passengers} voyageur${widget.passengers > 1 ? 's' : ''}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recherche des trains...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.messageCircleWarning,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTrains,
                icon: const Icon(LucideIcons.refreshCw),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_trains.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${_trains.length} train${_trains.length > 1 ? 's' : ''} disponible${_trains.length > 1 ? 's' : ''}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Train list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _trains.length,
            itemBuilder: (context, index) {
              final train = _trains[index];
              return _TrainResultCard(
                train: train,
                isDark: isDark,
                onTap: () => _showBookingDialog(context, train),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.grey200.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.trainFront,
              size: 48,
              color: AppColors.grey400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun train disponible',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez une autre date ou destination',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context, TrainSearchResult train) {
    final theme = Theme.of(context);
    final totalPrice = (train.prixBase * widget.passengers).round();
    bool isBooking = false;
    int selectedPaymentMethod = 0; // 0 = wallet, 1 = card
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final authProvider = context.watch<AuthProvider>();
          final walletBalance = authProvider.walletBalance;
          final hasSufficientBalance = walletBalance >= totalPrice;
          
          return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Confirmer la réservation',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _BookingDetailRow(label: 'Trajet', value: '${widget.departure} → ${widget.arrival}'),
              _BookingDetailRow(label: 'Date', value: '${widget.date.day}/${widget.date.month}/${widget.date.year}'),
              _BookingDetailRow(label: 'Train', value: train.numeroTrain),
              _BookingDetailRow(label: 'Type', value: train.typeTrain),
              _BookingDetailRow(label: 'Horaire', value: '${train.heureDepartFormatted} - ${train.heureArriveeFormatted}'),
              _BookingDetailRow(label: 'Durée', value: train.dureeFormatted),
              _BookingDetailRow(label: 'Voyageurs', value: '${widget.passengers}'),
              const Divider(height: 32),
              
              // Payment Method Selection
              Text(
                'Moyen de paiement',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // Wallet Option
              GestureDetector(
                onTap: () => setModalState(() => selectedPaymentMethod = 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: selectedPaymentMethod == 0 
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedPaymentMethod == 0 
                          ? AppColors.primary 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.wallet,
                        color: selectedPaymentMethod == 0 
                            ? AppColors.primary 
                            : AppColors.grey600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Portefeuille SNTF',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selectedPaymentMethod == 0 
                                    ? AppColors.primary 
                                    : null,
                              ),
                            ),
                            Text(
                              'Solde: $walletBalance DA',
                              style: TextStyle(
                                fontSize: 12,
                                color: hasSufficientBalance 
                                    ? AppColors.success 
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!hasSufficientBalance)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Solde insuffisant',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Radio(
                        value: 0,
                        groupValue: selectedPaymentMethod,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setModalState(() => selectedPaymentMethod = v!),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Card Option
              GestureDetector(
                onTap: () => setModalState(() => selectedPaymentMethod = 1),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selectedPaymentMethod == 1 
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedPaymentMethod == 1 
                          ? AppColors.warning 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.creditCard,
                        color: selectedPaymentMethod == 1 
                            ? AppColors.warning 
                            : AppColors.grey600,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Carte bancaire',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selectedPaymentMethod == 1 
                              ? AppColors.warning 
                              : null,
                        ),
                      ),
                      const Spacer(),
                      Radio(
                        value: 1,
                        groupValue: selectedPaymentMethod,
                        activeColor: AppColors.warning,
                        onChanged: (v) => setModalState(() => selectedPaymentMethod = v!),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prix total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$totalPrice DA',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (isBooking || (selectedPaymentMethod == 0 && !hasSufficientBalance)) 
                      ? null 
                      : () async {
                    setModalState(() => isBooking = true);
                    
                    try {
                      // Deduct from wallet if using wallet payment
                      if (selectedPaymentMethod == 0) {
                        final success = await authProvider.deductFromWallet(
                          totalPrice,
                          'Billet: ${widget.departure} → ${widget.arrival}',
                        );
                        if (!success) {
                          throw Exception('Échec du paiement');
                        }
                      }
                      
                      await _trainService.createReservation(
                        horaireId: train.horaireId,
                        dateVoyage: widget.date,
                        nombrePassagers: widget.passengers,
                        prixTotal: totalPrice.toDouble(),
                      );
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Réservation confirmée ! Votre billet a été ajouté.'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        Navigator.pop(context); // Return to home
                      }
                    } catch (e) {
                      setModalState(() => isBooking = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: ${e.toString()}'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isBooking 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirmer et payer'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }
}

class _TrainResultCard extends StatelessWidget {
  final TrainSearchResult train;
  final bool isDark;
  final VoidCallback onTap;

  const _TrainResultCard({
    required this.train,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Time and duration row
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          train.heureDepartFormatted,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Départ',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: isDark ? AppColors.grey600 : AppColors.grey300,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(
                                    LucideIcons.trainFront,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: isDark ? AppColors.grey600 : AppColors.grey300,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              train.dureeFormatted,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          train.heureArriveeFormatted,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Arrivée',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Info row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        train.typeTrain,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      LucideIcons.hash,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      train.numeroTrain,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      LucideIcons.armchair,
                      size: 14,
                      color: train.placesDisponibles > 20 ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${train.placesDisponibles} places',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: train.placesDisponibles > 20 ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${train.prixBase.round()} DA',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _BookingDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
