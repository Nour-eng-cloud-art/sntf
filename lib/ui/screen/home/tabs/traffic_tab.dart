import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';

class TrafficTab extends StatefulWidget {
  const TrafficTab({super.key});

  @override
  State<TrafficTab> createState() => _TrafficTabState();
}

class _TrafficTabState extends State<TrafficTab> {
  bool _isOngoing = true;
  final TextEditingController _busSearchController = TextEditingController();

  @override
  void dispose() {
    _busSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        title: Text(
          'Traffic info',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Le traffic en temps réel pour tous les modes de transport',
                style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700, color: AppColors.grey600,),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 24),
              // Train - RER Section
              _buildTransportSection(
                theme: theme,
                isDark: isDark,
                icon: _buildRerIcon(),
                title: 'Train - RER',
                child: _buildTrainRerGrid(),
              ),
              const SizedBox(height: 24),
              // Metro Section
              _buildTransportSection(
                theme: theme,
                isDark: isDark,
                icon: _buildMetroIcon(),
                title: 'Metro',
                child: _buildMetroGrid(),
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
              // Cable Section
              _buildTransportSection(
                theme: theme,
                isDark: isDark,
                icon: _buildCableIcon(),
                title: 'Cable',
                child: _buildCableGrid(),
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

  Widget _buildToggleButtons(ThemeData theme, bool isDark) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey200,
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleButton(
              label: 'Ongoing',
              isSelected: _isOngoing,
              onTap: () => setState(() => _isOngoing = true),
              theme: theme,
              isDark: isDark,
            ),
            _buildToggleButton(
              label: 'Upcoming',
              isSelected: !_isOngoing,
              onTap: () => setState(() => _isOngoing = false),
              theme: theme,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : AppColors.grey600,
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
  Widget _buildRerIcon() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(
        child: Text(
          'RER',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.white ,
          ),
        ),
      ),
    );
  }

  Widget _buildMetroIcon() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.info, width: 2),
      ),
      child: const Center(
        child: Text(
          'M',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.info,
          ),
        ),
      ),
    );
  }

  Widget _buildTramwayIcon() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: const Center(
        child: Icon(LucideIcons.trainFront, size: 14, color: Colors.black),
      ),
    );
  }

  Widget _buildCableIcon() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: const Center(
        child: Icon(LucideIcons.cableCar, size: 14, color: Colors.black),
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

  // Train - RER Grid
  Widget _buildTrainRerGrid() {
    final lines = [
      _LineBadgeData('A', const Color(0xFFE3051C)),
      _LineBadgeData('B', const Color(0xFF5291CE)),
      _LineBadgeData('C', const Color(0xFFFFCD00), textColor: Colors.black, hasAlert: true),
      _LineBadgeData('D', const Color(0xFF00A651), hasInfo: true),
      _LineBadgeData('E', const Color(0xFFBD76A1), hasAlert: true),
      _LineBadgeData('H', const Color(0xFF8D5E2A)),
      _LineBadgeData('J', const Color(0xFFCDCD00), textColor: Colors.black),
      _LineBadgeData('K', const Color(0xFF9B993A)),
      _LineBadgeData('L', const Color(0xFF7B4339)),
      _LineBadgeData('N', const Color(0xFF00A092)),
      _LineBadgeData('P', const Color(0xFFF7A600), textColor: Colors.black),
      _LineBadgeData('R', const Color(0xFFE281B9), hasInfo: true),
      _LineBadgeData('U', const Color(0xFFDC373C)),
      _LineBadgeData('V', const Color(0xFF8D5E2A)),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: lines.map((line) => _buildLineBadge(line)).toList(),
    );
  }

  // Metro Grid
  Widget _buildMetroGrid() {
    final lines = [
      _LineBadgeData('1', const Color(0xFFFFCD00), textColor: Colors.black),
      _LineBadgeData('2', const Color(0xFF003CA6)),
      _LineBadgeData('3', const Color(0xFF9B993A)),
      _LineBadgeData('3bis', const Color(0xFF6EC4E8), textColor: Colors.black),
      _LineBadgeData('4', const Color(0xFFBE408E)),
      _LineBadgeData('5', const Color(0xFFF7931D)),
      _LineBadgeData('6', const Color(0xFF6ECA97)),
      _LineBadgeData('7', const Color(0xFFF3A4BA)),
      _LineBadgeData('7bis', const Color(0xFF6ECA97)),
      _LineBadgeData('8', const Color(0xFFE4A4BA)),
      _LineBadgeData('9', const Color(0xFFCDC83D), textColor: Colors.black),
      _LineBadgeData('10', const Color(0xFFE3B32A), textColor: Colors.black),
      _LineBadgeData('11', const Color(0xFF8D5E2A)),
      _LineBadgeData('12', const Color(0xFF00814F), hasInfo: true),
      _LineBadgeData('13', const Color(0xFF6EC4E8), textColor: Colors.black),
      _LineBadgeData('14', const Color(0xFF652C90)),
    ];

    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: lines.map((line) => _buildMetroBadge(line)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildAirportBadge('CDG'),
            const SizedBox(width: 12),
            _buildAirportBadge('Orly'),
          ],
        ),
      ],
    );
  }

  // Tramway Grid
  Widget _buildTramwayGrid() {
    final lines = [
      _LineBadgeData('T1', const Color(0xFF003CA6), hasAlert: true),
      _LineBadgeData('T2', const Color(0xFFBE408E), hasInfo: true),
      _LineBadgeData('T3a', const Color(0xFFE3B32A), textColor: Colors.black),
      _LineBadgeData('T3b', const Color(0xFF00A651)),
      _LineBadgeData('T4', const Color(0xFFF7931D)),
      _LineBadgeData('T5', const Color(0xFF6ECA97)),
      _LineBadgeData('T6', const Color(0xFFE4A4BA)),
      _LineBadgeData('T7', const Color(0xFF8D5E2A), hasInfo: true),
      _LineBadgeData('T8', const Color(0xFF9B993A)),
      _LineBadgeData('T9', const Color(0xFF003CA6), hasAlert: true),
      _LineBadgeData('T10', const Color(0xFF6EC4E8), textColor: Colors.black),
      _LineBadgeData('T11', const Color(0xFFF3A4BA)),
      _LineBadgeData('T12', const Color(0xFF00814F), hasInfo: true),
      _LineBadgeData('T13', const Color(0xFFCDC83D), textColor: Colors.black),
      _LineBadgeData('T14', const Color(0xFF6ECA97)),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: lines.map((line) => _buildTramBadge(line)).toList(),
    );
  }

  // Cable Grid
  Widget _buildCableGrid() {
    return Row(
      children: [
        _buildCableBadge('C1', Colors.black),
        const SizedBox(width: 12),
        _buildCableBadge('FUN', AppColors.grey600),
      ],
    );
  }

  // Bus Search
  Widget _buildBusSearch(ThemeData theme, bool isDark) {
    return TextField(
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
    );
  }

  // Badge Builders
  Widget _buildLineBadge(_LineBadgeData data) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: data.color,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Text(
              data.label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: data.textColor,
              ),
            ),
          ),
        ),
        if (data.hasAlert)
          Positioned(
            right: -4,
            bottom: -4,
            child: _buildAlertIndicator(),
          ),
        if (data.hasInfo)
          Positioned(
            right: -4,
            bottom: -4,
            child: _buildInfoIndicator(),
          ),
      ],
    );
  }

  Widget _buildMetroBadge(_LineBadgeData data) {
    final isWide = data.label.length > 2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: isWide ? 56 : 44,
          height: 44,
          decoration: BoxDecoration(
            color: data.color,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Text(
              data.label,
              style: TextStyle(
                fontSize: isWide ? 12 : 18,
                fontWeight: FontWeight.bold,
                color: data.textColor,
              ),
            ),
          ),
        ),
        if (data.hasAlert)
          Positioned(
            right: -4,
            bottom: -4,
            child: _buildAlertIndicator(),
          ),
        if (data.hasInfo)
          Positioned(
            right: -4,
            bottom: -4,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
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
            bottom: -6,
            child: _buildAlertIndicator(),
          ),
        if (data.hasInfo)
          Positioned(
            right: -6,
            bottom: -6,
            child: _buildInfoIndicator(),
          ),
      ],
    );
  }

  Widget _buildCableBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAirportBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey400, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.plane, size: 14, color: AppColors.grey700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
        ],
      ),
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
