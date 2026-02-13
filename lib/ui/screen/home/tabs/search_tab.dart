import 'package:flutter/material.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _arrivalController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _passengers = 1;
  bool _isRoundTrip = false;

  final List<Map<String, dynamic>> _popularStations = [
    {'name': 'Alger', 'lat': 36.7538, 'lng': 3.0588},
    {'name': 'Oran', 'lat': 35.6969, 'lng': -0.6331},
    {'name': 'Constantine', 'lat': 36.3650, 'lng': 6.6147},
    {'name': 'Annaba', 'lat': 36.9000, 'lng': 7.7667},
    {'name': 'Sétif', 'lat': 36.1898, 'lng': 5.4108},
    {'name': 'Blida', 'lat': 36.4722, 'lng': 2.8278},
    {'name': 'Béjaïa', 'lat': 36.7500, 'lng': 5.0667},
    {'name': 'Tlemcen', 'lat': 34.8828, 'lng': -1.3167},
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
    _departureController.dispose();
    _arrivalController.dispose();
    super.dispose();
  }

  void _swapStations() {
    final temp = _departureController.text;
    setState(() {
      _departureController.text = _arrivalController.text;
      _arrivalController.text = temp;
    });
  }

  void _openLocationPicker({required bool isDeparture}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.grey700 : AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isDeparture ? LucideIcons.circleDot : LucideIcons.mapPin,
                    color: isDeparture ? AppColors.success : AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isDeparture ? 'Gare de départ' : 'Gare d\'arrivée',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      LucideIcons.x,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Location Picker
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: FlutterLocationPicker(
                  userAgent: 'com.sntf.app/1.0.0',
                  initPosition: LatLong(36.7538, 3.0588), // Alger
                  trackMyPosition: false,
                  showCurrentLocationPointer: true,
                  initZoom: 10,
                  minZoomLevel: 5,
                  maxZoomLevel: 18,
                  stepZoom: 1,
                  searchBarHintText: 'Rechercher une gare...',
                  searchBarBackgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                  searchBarTextColor: isDark ? Colors.white : Colors.black87,
                  searchBarHintColor: isDark ? AppColors.grey400 : AppColors.grey600,
                  zoomButtonsColor: AppColors.primary,
                  zoomButtonsBackgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  locationButtonBackgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  locationButtonsColor: AppColors.primary,
                  markerIcon: Icon(
                    isDeparture ? LucideIcons.circleDot : LucideIcons.mapPin,
                    color: isDeparture ? AppColors.success : AppColors.error,
                    size: 40,
                  ),
                  selectLocationButtonText: 'Sélectionner cette gare',
                  selectLocationButtonStyle: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      isDeparture ? AppColors.success : AppColors.error,
                    ),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    elevation: WidgetStateProperty.all(0),
                  ),
                  selectLocationButtonLeadingIcon: const Icon(
                    LucideIcons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPicked: (PickedData pickedData) {
                    Navigator.pop(context);
                    final locationName = pickedData.addressData['name'] ??
                        pickedData.addressData['city'] ??
                        pickedData.addressData['town'] ??
                        pickedData.addressData['village'] ??
                        pickedData.address.split(',').first;
                    setState(() {
                      if (isDeparture) {
                        _departureController.text = locationName;
                      } else {
                        _arrivalController.text = locationName;
                      }
                    });
                  },
                  onError: (e) {
                    debugPrint('Location picker error: $e');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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
                'Rechercher',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Trouvez le train idéal pour votre voyage',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Trip Type Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TripTypeButton(
                        label: 'Aller simple',
                        isSelected: !_isRoundTrip,
                        onTap: () => setState(() => _isRoundTrip = false),
                      ),
                    ),
                    Expanded(
                      child: _TripTypeButton(
                        label: 'Aller-retour',
                        isSelected: _isRoundTrip,
                        onTap: () => setState(() => _isRoundTrip = true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Search Form
              Container(
                padding: const EdgeInsets.all(20),
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
                    // Departure
                    _StationField(
                      controller: _departureController,
                      label: 'Départ',
                      icon: LucideIcons.circleDot,
                      iconColor: AppColors.success,
                      onTap: () => _openLocationPicker(isDeparture: true),
                    ),
                    
                    // Swap Button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark ? AppColors.grey700 : AppColors.grey300,
                            ),
                          ),
                          GestureDetector(
                            onTap: _swapStations,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.arrowUpDown,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark ? AppColors.grey700 : AppColors.grey300,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrival
                    _StationField(
                      controller: _arrivalController,
                      label: 'Arrivée',
                      icon: LucideIcons.mapPin,
                      iconColor: AppColors.error,
                      onTap: () => _openLocationPicker(isDeparture: false),
                    ),
                    const SizedBox(height: 20),

                    // Date & Passengers
                    Row(
                      children: [
                        Expanded(
                          child: _DateSelector(
                            date: _selectedDate,
                            onTap: _selectDate,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _PassengerSelector(
                            count: _passengers,
                            onChanged: (value) => setState(() => _passengers = value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Search Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Perform search
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.search, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Rechercher',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Popular Stations
              Text(
                'Gares populaires',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _popularStations.map((station) {
                  return _PopularStationChip(
                    station: station['name'] as String,
                    onTap: () {
                      if (_departureController.text.isEmpty) {
                        setState(() => _departureController.text = station['name'] as String);
                      } else if (_arrivalController.text.isEmpty) {
                        setState(() => _arrivalController.text = station['name'] as String);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Recent Searches
              Text(
                'Recherches récentes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _RecentSearchCard(
                from: 'Alger',
                to: 'Oran',
                date: '15 Fév 2026',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _RecentSearchCard(
                from: 'Constantine',
                to: 'Annaba',
                date: '10 Fév 2026',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TripTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _StationField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _StationField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: IgnorePointer(
              ignoring: onTap != null,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: label,
                  border: InputBorder.none,
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: onTap != null
                      ? Icon(
                          LucideIcons.mapPinned,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        )
                      : null,
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateSelector({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.calendar,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerSelector extends StatelessWidget {
  final int count;
  final ValueChanged<int> onChanged;

  const _PassengerSelector({required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.users,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Passagers',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$count',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _CounterButton(
                icon: LucideIcons.minus,
                onTap: count > 1 ? () => onChanged(count - 1) : null,
              ),
              const SizedBox(width: 8),
              _CounterButton(
                icon: LucideIcons.plus,
                onTap: count < 9 ? () => onChanged(count + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.grey300.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? AppColors.primary : AppColors.grey400,
        ),
      ),
    );
  }
}

class _PopularStationChip extends StatelessWidget {
  final String station;
  final VoidCallback onTap;

  const _PopularStationChip({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.trainFront,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              station,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSearchCard extends StatelessWidget {
  final String from;
  final String to;
  final String date;
  final bool isDark;

  const _RecentSearchCard({
    required this.from,
    required this.to,
    required this.date,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.history,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$from → $to',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
