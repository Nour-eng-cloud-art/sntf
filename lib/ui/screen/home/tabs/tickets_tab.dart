import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/data/models/national_train.dart';
import 'package:sntf/data/services/national_train_service.dart';

class TicketsTab extends StatefulWidget {
  const TicketsTab({super.key});

  @override
  State<TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends State<TicketsTab> {
  final NationalTrainService _trainService = NationalTrainService();
  List<ReservationNationale>? _tickets;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tickets = await _trainService.getUserReservations();
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes billets',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gérez tous vos billets de train',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.messageCircleWarning, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Erreur de chargement', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTickets,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_tickets == null || _tickets!.isEmpty) {
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
                LucideIcons.ticket,
                size: 48,
                color: AppColors.grey400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun billet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Réservez votre prochain voyage !',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _tickets!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final ticket = _tickets![index];
          return _TicketCard(
            reservation: ticket,
            isDark: isDark,
            onCancel: () => _cancelReservation(ticket.id),
          );
        },
      ),
    );
  }

  Future<void> _cancelReservation(String reservationId) async {
    try {
      await _trainService.cancelReservation(reservationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Billet annulé avec succès'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _loadTickets(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
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
  }
}

class _TicketCard extends StatelessWidget {
  final ReservationNationale reservation;
  final bool isDark;
  final VoidCallback? onCancel;

  const _TicketCard({
    required this.reservation,
    required this.isDark,
    this.onCancel,
  });

  String _getStationCode(String stationName) {
    // Generate 3-letter code from station name
    final codes = {
      'Alger': 'ALG',
      'Oran': 'ORA',
      'Constantine': 'CST',
      'Annaba': 'ANB',
      'Sétif': 'SET',
      'Tlemcen': 'TLM',
      'Béjaïa': 'BEJ',
    };
    return codes[stationName] ?? stationName.substring(0, 3).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = reservation.isPast;
    final isCancelled = reservation.isCancelled;
    final isUpcoming = reservation.isUpcoming;
    
    final from = reservation.villeDepart;
    final to = reservation.villeArrivee;
    final fromCode = _getStationCode(from);
    final toCode = _getStationCode(to);

    return GestureDetector(
      onLongPress: () => _showQRCodeDialog(context),
      child: Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: (isCompleted || isCancelled)
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
              color: (isCompleted || isCancelled)
                  ? (isDark ? AppColors.grey800 : AppColors.grey200)
                  : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StationInfo(
                  code: fromCode,
                  name: from,
                  isLight: !(isCompleted || isCancelled),
                ),
                Column(
                  children: [
                    Icon(
                      LucideIcons.trainFront,
                      color: (isCompleted || isCancelled)
                          ? (isDark ? AppColors.grey400 : AppColors.grey600)
                          : Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isCompleted || isCancelled)
                            ? AppColors.grey400.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        reservation.dureeFormatted,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: (isCompleted || isCancelled)
                              ? (isDark ? AppColors.grey400 : AppColors.grey600)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                _StationInfo(
                  code: toCode,
                  name: to,
                  isLight: !(isCompleted || isCancelled),
                  isEnd: true,
                ),
              ],
            ),
          ),

          // Dashed Line
          Row(
            children: List.generate(
              30,
              (index) => Expanded(
                child: Container(
                  height: 2,
                  color: index.isEven
                      ? (isDark ? AppColors.grey700 : AppColors.grey300)
                      : Colors.transparent,
                ),
              ),
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    _DetailItem(
                      icon: LucideIcons.calendar,
                      label: 'Date',
                      value: reservation.dateVoyageFormatted,
                    ),
                    const Spacer(),
                    _DetailItem(
                      icon: LucideIcons.clock,
                      label: 'Heure',
                      value: reservation.heureDepartFormatted,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _DetailItem(
                      icon: LucideIcons.hash,
                      label: 'N° Réservation',
                      value: reservation.numeroReservation,
                    ),
                    const Spacer(),
                    _DetailItem(
                      icon: LucideIcons.users,
                      label: 'Voyageurs',
                      value: '${reservation.nombrePassagers}',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${reservation.prixTotal.round()} DA',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (isUpcoming)
                      Row(
                        children: [
                          _ActionButton(
                            icon: LucideIcons.x,
                            label: 'Annuler',
                            onTap: () => _showCancelDialog(context),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: LucideIcons.qrCode,
                            label: 'QR Code',
                            onTap: () => _showQRCodeDialog(context),
                            isPrimary: true,
                          ),
                        ],
                      ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.grey400.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Terminé',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Annulé',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
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
    );
  }

  void _showQRCodeDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final qrSize = (screenSize.width * 0.5).clamp(150.0, 250.0);
    final maxSheetHeight = screenSize.height * 0.85;
    
    // Create QR data with all verification info
    final qrData = jsonEncode({
      'type': 'SNTF_TICKET',
      'reservation_id': reservation.id,
      'numero_reservation': reservation.numeroReservation,
      'user_id': reservation.userId,
      'trajet': {
        'depart': reservation.villeDepart,
        'arrivee': reservation.villeArrivee,
      },
      'date_voyage': reservation.dateVoyage.toIso8601String().split('T')[0],
      'heure_depart': reservation.heureDepartFormatted,
      'nombre_passagers': reservation.nombrePassagers,
      'voiture': reservation.voiture,
      'place': reservation.place,
      'prix_total': reservation.prixTotal,
      'statut': reservation.statut,
      'date_emission': reservation.dateReservation?.toIso8601String(),
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkTheme ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.qrCode, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Votre billet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Présentez ce QR code à l\'agent SNTF',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                
                // QR Code - Responsive size
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: qrSize,
                    height: qrSize,
                    child: PrettyQrView.data(
                      data: qrData,
                      decoration: const PrettyQrDecoration(
                        shape: PrettyQrSmoothSymbol(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              
              // Ticket info summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkTheme 
                      ? AppColors.darkSurfaceVariant 
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _QRInfoRow(
                      label: 'N° Réservation',
                      value: reservation.numeroReservation,
                      isHighlighted: true,
                    ),
                    const Divider(height: 16),
                    _QRInfoRow(
                      label: 'Trajet',
                      value: '${reservation.villeDepart} → ${reservation.villeArrivee}',
                    ),
                    const SizedBox(height: 8),
                    _QRInfoRow(
                      label: 'Date',
                      value: reservation.dateVoyageFormatted,
                    ),
                    const SizedBox(height: 8),
                    _QRInfoRow(
                      label: 'Heure',
                      value: reservation.heureDepartFormatted,
                    ),
                    const SizedBox(height: 8),
                    _QRInfoRow(
                      label: 'Voyageurs',
                      value: '${reservation.nombrePassagers}',
                    ),
                    if (reservation.voiture != null && reservation.place != null) ...[
                      const SizedBox(height: 8),
                      _QRInfoRow(
                        label: 'Place',
                        value: 'Voiture ${reservation.voiture}, Place ${reservation.place}',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation ?'),
        content: const Text('Cette action ne peut pas être annulée. Êtes-vous sûr de vouloir annuler ce billet ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onCancel?.call();
            },
            child: Text(
              'Oui, annuler',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationInfo extends StatelessWidget {
  final String code;
  final String name;
  final bool isLight;
  final bool isEnd;

  const _StationInfo({
    required this.code,
    required this.name,
    this.isLight = true,
    this.isEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: isEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          code,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isLight
                ? Colors.white
                : (isDark ? AppColors.grey300 : AppColors.grey700),
          ),
        ),
        Text(
          name,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isLight
                ? Colors.white.withValues(alpha: 0.8)
                : (isDark ? AppColors.grey400 : AppColors.grey600),
          ),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isPrimary ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QRInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _QRInfoRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: isHighlighted
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
