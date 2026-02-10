import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';

class TicketsTab extends StatefulWidget {
  const TicketsTab({super.key});

  @override
  State<TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends State<TicketsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'À venir'),
                Tab(text: 'Passés'),
                Tab(text: 'Annulés'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _UpcomingTickets(isDark: isDark),
                _PastTickets(isDark: isDark),
                _CancelledTickets(isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingTickets extends StatelessWidget {
  final bool isDark;

  const _UpcomingTickets({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _TicketCard(
          from: 'Alger',
          fromCode: 'ALG',
          to: 'Oran',
          toCode: 'ORA',
          date: 'Sam. 15 Fév 2026',
          time: '08:30',
          duration: '2h 30min',
          trainNumber: 'TR-1245',
          seat: 'Voiture 3, Place 24',
          price: '1200 DA',
          status: 'confirmed',
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _TicketCard(
          from: 'Constantine',
          fromCode: 'CST',
          to: 'Annaba',
          toCode: 'ANB',
          date: 'Mar. 18 Fév 2026',
          time: '14:15',
          duration: '1h 45min',
          trainNumber: 'TR-0892',
          seat: 'Voiture 1, Place 12',
          price: '850 DA',
          status: 'confirmed',
          isDark: isDark,
        ),
      ],
    );
  }
}

class _PastTickets extends StatelessWidget {
  final bool isDark;

  const _PastTickets({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _TicketCard(
          from: 'Alger',
          fromCode: 'ALG',
          to: 'Blida',
          toCode: 'BLI',
          date: 'Lun. 05 Fév 2026',
          time: '09:00',
          duration: '45min',
          trainNumber: 'TR-0342',
          seat: 'Voiture 2, Place 8',
          price: '250 DA',
          status: 'completed',
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _TicketCard(
          from: 'Sétif',
          fromCode: 'SET',
          to: 'Constantine',
          toCode: 'CST',
          date: 'Ven. 01 Fév 2026',
          time: '16:30',
          duration: '1h 15min',
          trainNumber: 'TR-0567',
          seat: 'Voiture 4, Place 32',
          price: '600 DA',
          status: 'completed',
          isDark: isDark,
        ),
      ],
    );
  }
}

class _CancelledTickets extends StatelessWidget {
  final bool isDark;

  const _CancelledTickets({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
              LucideIcons.ticketX,
              size: 48,
              color: AppColors.grey400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun billet annulé',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos billets annulés apparaîtront ici',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final String from;
  final String fromCode;
  final String to;
  final String toCode;
  final String date;
  final String time;
  final String duration;
  final String trainNumber;
  final String seat;
  final String price;
  final String status;
  final bool isDark;

  const _TicketCard({
    required this.from,
    required this.fromCode,
    required this.to,
    required this.toCode,
    required this.date,
    required this.time,
    required this.duration,
    required this.trainNumber,
    required this.seat,
    required this.price,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = status == 'completed';

    return Container(
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
              gradient: isCompleted
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
              color: isCompleted
                  ? (isDark ? AppColors.grey800 : AppColors.grey200)
                  : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StationInfo(
                      code: fromCode,
                      name: from,
                      isLight: !isCompleted,
                    ),
                    Column(
                      children: [
                        Icon(
                          LucideIcons.trainFront,
                          color: isCompleted
                              ? (isDark ? AppColors.grey400 : AppColors.grey600)
                              : Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.grey400.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            duration,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isCompleted
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
                      isLight: !isCompleted,
                      isEnd: true,
                    ),
                  ],
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
                      value: date,
                    ),
                    const Spacer(),
                    _DetailItem(
                      icon: LucideIcons.clock,
                      label: 'Heure',
                      value: time,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _DetailItem(
                      icon: LucideIcons.hash,
                      label: 'Train',
                      value: trainNumber,
                    ),
                    const Spacer(),
                    _DetailItem(
                      icon: LucideIcons.armchair,
                      label: 'Place',
                      value: seat,
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
                          price,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (!isCompleted)
                      Row(
                        children: [
                          _ActionButton(
                            icon: LucideIcons.qrCode,
                            label: 'QR Code',
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: LucideIcons.download,
                            label: 'PDF',
                            onTap: () {},
                            isPrimary: true,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
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
