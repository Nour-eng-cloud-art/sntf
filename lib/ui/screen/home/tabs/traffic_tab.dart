import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';

class TrafficTab extends StatefulWidget {
  const TrafficTab({super.key});

  @override
  State<TrafficTab> createState() => _TrafficTabState();
}

class _TrafficTabState extends State<TrafficTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _busSearchController = TextEditingController();

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
    _busSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Traffic info',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le traffic en temps réel pour tous les modes de transport',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              // Train Section
              _buildTransportSection(
                theme: theme,
                isDark: isDark,
                icon: _buildTrainIcon(),
                title: 'Train',
                child: _buildTrainGrid(),
              ),
              const SizedBox(height: 24),
              // Tramway Section
              _buildTransportSection(
                theme: theme,
                isDark: isDark,
                icon: _buildTramwayIcon(),
                title: 'Tramway',
                child: _buildTramwayGrid(),
              ),
              const SizedBox(height: 24),
              // Bus Section
              _buildTransportSection(
                theme: theme,
                isDark: isDark,
                icon: _buildBusIcon(),
                title: 'Bus',
                child: _buildBusSearch(theme, isDark),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransportSection({
    required ThemeData theme,
    required bool isDark,
    required Widget icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey200,
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  // Transport Icon Builders
  Widget _buildTrainIcon() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(
        child: Icon(LucideIcons.trainFront, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildTramwayIcon() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(
        child: Icon(LucideIcons.tramFront, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildBusIcon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'BUS',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // Train Grid
  Widget _buildTrainGrid() {
    final lines = [
      _LineBadgeData('A', AppColors.primary),
      _LineBadgeData('B', AppColors.secondary),
      _LineBadgeData('C', const Color(0xFF00A651)),
      _LineBadgeData('D', const Color(0xFF5291CE)),
      _LineBadgeData('E', const Color(0xFFF7A600), textColor: Colors.black),
      _LineBadgeData('F', const Color(0xFFBD76A1)),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: lines.map((line) => _buildTrainLineBadge(line)).toList(),
    );
  }

  // Tramway Grid
  Widget _buildTramwayGrid() {
    final lines = [
      _LineBadgeData('T1', AppColors.accent, hasInfo: true),
      _LineBadgeData('T2', const Color(0xFFBE408E)),
      _LineBadgeData('T3', const Color(0xFF00A651), hasAlert: true),
      _LineBadgeData('T4', const Color(0xFFF7931D)),
      _LineBadgeData('T5', const Color(0xFF003CA6)),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: lines.map((line) => _buildTramBadge(line)).toList(),
    );
  }

  // Bus Search
  Widget _buildBusSearch(ThemeData theme, bool isDark) {
    final busLines = [
      _LineBadgeData('A', const Color(0xFF003CA6), hasInfo: true),
      _LineBadgeData('B', const Color(0xFF00A651)),
      _LineBadgeData('C', const Color(0xFFF7931D)),
      _LineBadgeData('E', const Color(0xFFE31E24)),
      _LineBadgeData('G', const Color(0xFF8B5CF6)),
      _LineBadgeData('H', const Color(0xFF06B6D4)),
      _LineBadgeData('11', const Color(0xFF10B981), hasAlert: true),
      _LineBadgeData('34', const Color(0xFFF59E0B)),
      _LineBadgeData('37', const Color(0xFF3B82F6)),
      _LineBadgeData('42', const Color(0xFFEF4444)),
      _LineBadgeData('51', const Color(0xFF6366F1)),
      _LineBadgeData('102', const Color(0xFFEC4899)),
      _LineBadgeData('U', const Color(0xFF14B8A6)),
    ];

    return Column(
      children: [
        TextField(
          controller: _busSearchController,
          decoration: InputDecoration(
            hintText: 'Search for a bus line',
            hintStyle: TextStyle(color: AppColors.grey500),
            prefixIcon: Icon(LucideIcons.search, color: AppColors.grey500),
            filled: true,
            fillColor: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: busLines.map((line) => _buildBusLineBadge(line)).toList(),
        ),
      ],
    );
  }

  // Badge Builders
  Widget _buildBusLineBadge(_LineBadgeData data) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: data.color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            data.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: data.textColor,
            ),
          ),
        ),
        if (data.hasAlert)
          Positioned(
            right: -6,
            top: -6,
            child: _buildAlertIndicator(),
          ),
        if (data.hasInfo)
          Positioned(
            right: -6,
            top: -6,
            child: _buildInfoIndicator(),
          ),
      ],
    );
  }

  Widget _buildTrainLineBadge(_LineBadgeData data) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: data.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            data.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: data.textColor,
            ),
          ),
        ),
        if (data.hasAlert)
          Positioned(
            right: -6,
            top: -6,
            child: _buildAlertIndicator(),
          ),
        if (data.hasInfo)
          Positioned(
            right: -6,
            top: -6,
            child: _buildInfoIndicator(),
          ),
      ],
    );
  }

  Widget _buildTramBadge(_LineBadgeData data) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: data.color, width: 3),
          ),
          child: Text(
            data.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: data.color,
            ),
          ),
        ),
        if (data.hasAlert)
          Positioned(
            right: -6,
            top: -6,
            child: _buildAlertIndicator(),
          ),
        if (data.hasInfo)
          Positioned(
            right: -6,
            top: -6,
            child: _buildInfoIndicator(),
          ),
      ],
    );
  }

  Widget _buildAlertIndicator() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.warning,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Center(
        child: Icon(
          LucideIcons.trainFront,
          size: 10,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoIndicator() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.info,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Center(
        child: Text(
          'i',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _LineBadgeData {
  final String label;
  final Color color;
  final Color textColor;
  final bool hasAlert;
  final bool hasInfo;

  _LineBadgeData(
    this.label,
    this.color, {
    this.textColor = Colors.white,
    this.hasAlert = false,
    this.hasInfo = false,
  });
}
