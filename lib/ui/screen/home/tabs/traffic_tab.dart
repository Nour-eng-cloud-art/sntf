import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/data/services/supabase_service.dart';

class TrafficTab extends StatefulWidget {
  const TrafficTab({super.key});

  @override
  State<TrafficTab> createState() => _TrafficTabState();
}

class _TrafficTabState extends State<TrafficTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _busSearchController = TextEditingController();

  List<Map<String, dynamic>> _telepheriqueLines = [];
  List<Map<String, dynamic>> _tramLines = [];
  List<Map<String, dynamic>> _busLines = [];
  bool _isLoading = true;
  String? _error;
  SupabaseService supabaseService = SupabaseService();

  Future<void> fetchTrafficData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final lignes = await supabaseService.getAllLignes();
      
      setState(() {
        _telepheriqueLines = lignes
            .where((l) => l['type'] == 'telepherique')
            .toList();
        _tramLines = lignes
            .where((l) => l['type'] == 'tramway')
            .toList();
        _busLines = lignes
            .where((l) => l['type'] == 'bus')
            .toList();
        _isLoading = false;
      });
      
      print('Téléphérique: $_telepheriqueLines');
      print('Tramway: $_tramLines');
      print('Bus: $_busLines');
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des données: $error')),
      );
    }
  }

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

    fetchTrafficData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _busSearchController.dispose();
    super.dispose();
  }

  /// Show stations for a specific line
  void _showLineStations(String lineId, String lineName, Color lineColor) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LineStationsSheet(
        lineId: lineId,
        lineName: lineName,
        lineColor: lineColor,
        supabaseService: supabaseService,
        onStationTap: (stationId, stationName) {
          Navigator.pop(context);
          _showStationSchedules(lineId, lineName, stationId, stationName, lineColor);
        },
      ),
    );
  }

  /// Show schedules for a station on a specific line
  void _showStationSchedules(String lineId, String lineName, String stationId, String stationName, Color lineColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StationSchedulesSheet(
        lineId: lineId,
        lineName: lineName,
        stationId: stationId,
        stationName: stationName,
        lineColor: lineColor,
        supabaseService: supabaseService,
      ),
    );
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
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Center(
                  child: Column(
                    children: [
                      Text('Erreur: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchTrafficData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              else ...[
                // Telepherique Section
                _buildTransportSection(
                  theme: theme,
                  isDark: isDark,
                  icon: _buildTelepheriqueIcon(),
                  title: 'Téléphérique',
                  child: _buildTelepheriqueGrid(),
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
              ],
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
  Widget _buildTelepheriqueIcon() {
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

  // Helper to parse color from hex string or return default
  Color _parseColor(dynamic colorValue, Color defaultColor) {
    if (colorValue == null) return defaultColor;
    if (colorValue is String && colorValue.startsWith('#')) {
      try {
        return Color(int.parse(colorValue.substring(1), radix: 16) + 0xFF000000);
      } catch (_) {
        return defaultColor;
      }
    }
    return defaultColor;
  }

  // Train Grid
  Widget _buildTelepheriqueGrid() {
    if (_telepheriqueLines.isEmpty) {
      return const Text('Aucune ligne de téléphérique disponible');
    }

    final defaultColors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFF00A651),
      const Color(0xFF5291CE),
      const Color(0xFFF7A600),
      const Color(0xFFBD76A1),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _telepheriqueLines.asMap().entries.map((entry) {
        final index = entry.key;
        final line = entry.value;
        final color = _parseColor(line['couleur'], defaultColors[index % defaultColors.length]);
        return _buildTelepheriqueLineBadge(
          _LineBadgeData(line['id']?.toString() ?? '', line['nom_court'] ?? '', color),
        );
      }).toList(),
    );
  }

  // Tramway Grid
  Widget _buildTramwayGrid() {
    if (_tramLines.isEmpty) {
      return const Text('Aucune ligne de tramway disponible');
    }

    final defaultColors = [
      AppColors.accent,
      const Color(0xFFBE408E),
      const Color(0xFF00A651),
      const Color(0xFFF7931D),
      const Color(0xFF003CA6),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _tramLines.asMap().entries.map((entry) {
        final index = entry.key;
        final line = entry.value;
        final color = _parseColor(line['couleur'], defaultColors[index % defaultColors.length]);
        return _buildTramBadge(
          _LineBadgeData(line['id']?.toString() ?? '', line['nom_court'] ?? '', color),
        );
      }).toList(),
    );
  }

  // Bus Search
  Widget _buildBusSearch(ThemeData theme, bool isDark) {
    final defaultColors = [
      const Color(0xFF003CA6),
      const Color(0xFF00A651),
      const Color(0xFFF7931D),
      const Color(0xFFE31E24),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];

    // Filter bus lines based on search
    final searchQuery = _busSearchController.text.toLowerCase();
    final filteredBusLines = _busLines.where((line) {
      final nom = (line['nom_court'] ?? '').toString().toLowerCase();
      return searchQuery.isEmpty || nom.contains(searchQuery);
    }).toList();

    return Column(
      children: [
        TextField(
          controller: _busSearchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Rechercher une ligne de bus',
            hintStyle: TextStyle(color: AppColors.grey500),
            prefixIcon: Icon(LucideIcons.search, color: AppColors.grey500),
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.grey100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        if (filteredBusLines.isEmpty)
          const Text('Aucune ligne de bus trouvée')
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: filteredBusLines.asMap().entries.map((entry) {
              final index = entry.key;
              final line = entry.value;
              final color = _parseColor(line['couleur'], defaultColors[index % defaultColors.length]);
              return _buildBusLineBadge(
                _LineBadgeData(line['id']?.toString() ?? '', line['nom_court'] ?? '', color),
              );
            }).toList(),
          ),
      ],
    );
  }

  // Badge Builders
  Widget _buildBusLineBadge(_LineBadgeData data) {
    return GestureDetector(
      onTap: () => _showLineStations(data.id, data.label, data.color),
      child: Container(
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
    );
  }

  Widget _buildTelepheriqueLineBadge(_LineBadgeData data) {
    return GestureDetector(
      onTap: () => _showLineStations(data.id, data.label, data.color),
      child: Container(
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
    );
  }

  Widget _buildTramBadge(_LineBadgeData data) {
    return GestureDetector(
      onTap: () => _showLineStations(data.id, data.label, data.color),
      child: Container(
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
        child: Icon(LucideIcons.trainFront, size: 10, color: Colors.white),
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
  final String id;
  final String label;
  final Color color;
  final Color textColor;

  _LineBadgeData(
    this.id,
    this.label,
    this.color, {
    this.textColor = Colors.white,
  });
}

/// Bottom sheet showing all stations for a line
class _LineStationsSheet extends StatefulWidget {
  final String lineId;
  final String lineName;
  final Color lineColor;
  final SupabaseService supabaseService;
  final Function(String stationId, String stationName) onStationTap;

  const _LineStationsSheet({
    required this.lineId,
    required this.lineName,
    required this.lineColor,
    required this.supabaseService,
    required this.onStationTap,
  });

  @override
  State<_LineStationsSheet> createState() => _LineStationsSheetState();
}

class _LineStationsSheetState extends State<_LineStationsSheet> {
  List<Map<String, dynamic>> _stations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    try {
      final stations = await widget.supabaseService.getStationsForLigne(widget.lineId);
      setState(() {
        _stations = stations;
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.lineColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.lineName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Stations',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Erreur: $_error'))
                    : _stations.isEmpty
                        ? const Center(child: Text('Aucune station trouvée'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _stations.length,
                            itemBuilder: (context, index) {
                              final arret = _stations[index];
                              final station = arret['stations'] as Map<String, dynamic>?;
                              final stationId = station?['id']?.toString() ?? arret['station_id']?.toString() ?? '';
                              final stationName = station?['nom'] ?? 'Station ${index + 1}';
                              final ordre = arret['ordre_passage'] ?? (index + 1);

                              return InkWell(
                                onTap: () => widget.onStationTap(stationId, stationName),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.grey200,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Order number
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: widget.lineColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: widget.lineColor, width: 2),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$ordre',
                                            style: TextStyle(
                                              color: widget.lineColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Station name
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              stationName,
                                              style: theme.textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (station?['adresse'] != null)
                                              Text(
                                                station!['adresse'],
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: AppColors.grey500,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Arrow
                                      Icon(
                                        LucideIcons.chevronRight,
                                        color: AppColors.grey400,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet showing schedules for a station on a line
class _StationSchedulesSheet extends StatefulWidget {
  final String lineId;
  final String lineName;
  final String stationId;
  final String stationName;
  final Color lineColor;
  final SupabaseService supabaseService;

  const _StationSchedulesSheet({
    required this.lineId,
    required this.lineName,
    required this.stationId,
    required this.stationName,
    required this.lineColor,
    required this.supabaseService,
  });

  @override
  State<_StationSchedulesSheet> createState() => _StationSchedulesSheetState();
}

class _StationSchedulesSheetState extends State<_StationSchedulesSheet> {
  List<Map<String, dynamic>> _horaires = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      final horaires = await widget.supabaseService.getHorairesForLigneAtStation(
        widget.lineId,
        widget.stationId,
      );
      setState(() {
        _horaires = horaires;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return '--:--';
    if (time is String) {
      // Handle ISO datetime format like "2026-02-15T06:30:00"
      if (time.contains('T')) {
        final timePart = time.split('T').last;
        final parts = timePart.split(':');
        if (parts.length >= 2) {
          return '${parts[0]}:${parts[1]}';
        }
        return timePart;
      }
      // Handle simple time format like "08:30:00"
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return time;
    }
    return time.toString();
  }

  String _normalizeDay(String? day) {
    if (day == null) return 'Tous les jours';
    final lower = day.toLowerCase().trim();
    
    // Map various day formats to standard French names
    final dayMappings = {
      'lundi': 'Lundi',
      'lun': 'Lundi',
      'monday': 'Lundi',
      'mon': 'Lundi',
      'mardi': 'Mardi',
      'mar': 'Mardi',
      'tuesday': 'Mardi',
      'tue': 'Mardi',
      'mercredi': 'Mercredi',
      'mer': 'Mercredi',
      'wednesday': 'Mercredi',
      'wed': 'Mercredi',
      'jeudi': 'Jeudi',
      'jeu': 'Jeudi',
      'thursday': 'Jeudi',
      'thu': 'Jeudi',
      'vendredi': 'Vendredi',
      'ven': 'Vendredi',
      'friday': 'Vendredi',
      'fri': 'Vendredi',
      'samedi': 'Samedi',
      'sam': 'Samedi',
      'saturday': 'Samedi',
      'sat': 'Samedi',
      'dimanche': 'Dimanche',
      'dim': 'Dimanche',
      'sunday': 'Dimanche',
      'sun': 'Dimanche',
    };
    
    return dayMappings[lower] ?? day;
  }

  IconData _getDayIcon(String day) {
    switch (day) {
      case 'Lundi':
        return LucideIcons.calendarDays;
      case 'Mardi':
        return LucideIcons.calendarDays;
      case 'Mercredi':
        return LucideIcons.calendarDays;
      case 'Jeudi':
        return LucideIcons.calendarDays;
      case 'Vendredi':
        return LucideIcons.calendarCheck;
      case 'Samedi':
        return LucideIcons.sun;
      case 'Dimanche':
        return LucideIcons.coffee;
      default:
        return LucideIcons.calendar;
    }
  }

  Color _getDayAccentColor(String day, Color baseColor) {
    switch (day) {
      case 'Samedi':
        return Colors.orange;
      case 'Dimanche':
        return Colors.red.shade400;
      default:
        return baseColor;
    }
  }

  Map<String, List<String>> _groupByDay() {
    final groups = <String, List<String>>{};
    
    for (final horaire in _horaires) {
      final rawDay = horaire['jour']?.toString() ?? horaire['day']?.toString();
      final day = _normalizeDay(rawDay);
      final time = _formatTime(horaire['heure_passage']);
      
      groups.putIfAbsent(day, () => []);
      if (!groups[day]!.contains(time)) {
        groups[day]!.add(time);
      }
    }
    
    // Sort times within each day
    for (final day in groups.keys) {
      groups[day]!.sort();
    }
    
    // Sort days in week order
    final orderedDays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche', 'Tous les jours'];
    final sortedGroups = <String, List<String>>{};
    for (final day in orderedDays) {
      if (groups.containsKey(day)) {
        sortedGroups[day] = groups[day]!;
      }
    }
    // Add any remaining days not in the ordered list
    for (final day in groups.keys) {
      if (!sortedGroups.containsKey(day)) {
        sortedGroups[day] = groups[day]!;
      }
    }
    
    return sortedGroups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Gradient Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.lineColor,
                  widget.lineColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.lineColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.clock,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Horaires de passage',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.lineName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.stationName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: widget.lineColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chargement des horaires...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                LucideIcons.messageCircleWarning,
                                size: 48,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur de chargement',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.grey500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _horaires.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: widget.lineColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    LucideIcons.calendarX,
                                    size: 56,
                                    color: widget.lineColor,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Aucun horaire disponible',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Les horaires pour cette station\nne sont pas encore disponibles',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.grey500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : _buildScheduleList(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(ThemeData theme, bool isDark) {
    final groupedSchedules = _groupByDay();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedSchedules.length,
      itemBuilder: (context, index) {
        final day = groupedSchedules.keys.elementAt(index);
        final times = groupedSchedules[day]!;
        final dayColor = _getDayAccentColor(day, widget.lineColor);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: dayColor.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: dayColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getDayIcon(day),
                        size: 20,
                        color: dayColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: dayColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: dayColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${times.length} passage${times.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: dayColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Time chips grid
              Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: times.map((time) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            dayColor.withOpacity(isDark ? 0.25 : 0.08),
                            dayColor.withOpacity(isDark ? 0.15 : 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: dayColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}