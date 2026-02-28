import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/data/services/places_service.dart';

/// Data class for picked location
class LocationData {
  final LatLng latLng;
  final String address;
  final String name;
  final Map<String, String> addressData;

  LocationData({
    required this.latLng,
    required this.address,
    this.name = '',
    this.addressData = const {},
  });
}

class FullScreenMapPicker extends StatefulWidget {
  final LatLng initialPosition;
  final double initialZoom;
  final String title;
  final String selectButtonText;
  final Color primaryColor;
  final bool showCurrentLocationButton;
  final bool showSearchBar;
  final String searchHintText;
  final LatLng? searchCenterOverride;
  final int? searchRadius;

  const FullScreenMapPicker({
    super.key,
    this.initialPosition = const LatLng(35.6969, -0.6331), // Oran
    this.initialZoom = 12,
    this.title = 'Choisir un lieu',
    this.selectButtonText = 'Confirmer ce lieu',
    this.primaryColor = AppColors.primary,
    this.showCurrentLocationButton = true,
    this.showSearchBar = true,
    this.searchHintText = 'Rechercher un lieu...',
    this.searchCenterOverride,
    this.searchRadius,
  });

  /// Static method to show the map picker and return the selected location
  static Future<LocationData?> show(
    BuildContext context, {
    LatLng? initialPosition,
    String title = 'Choisir un lieu',
    String selectButtonText = 'Confirmer ce lieu',
    Color primaryColor = AppColors.primary,
    LatLng? searchCenterOverride,
    int? searchRadius,
  }) {
    return Navigator.of(context).push<LocationData>(
      MaterialPageRoute(
        builder: (context) => FullScreenMapPicker(
          initialPosition: initialPosition ?? const LatLng(35.6969, -0.6331),
          title: title,
          selectButtonText: selectButtonText,
          primaryColor: primaryColor,
          searchCenterOverride: searchCenterOverride,
          searchRadius: searchRadius,
        ),
      ),
    );
  }

  @override
  State<FullScreenMapPicker> createState() => _FullScreenMapPickerState();
}

class _FullScreenMapPickerState extends State<FullScreenMapPicker>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late LatLng _currentTarget;
  String _currentAddress = '';
  String _currentName = '';
  Map<String, String> _addressData = {};
  bool _isLoadingAddress = false;
  bool _isDragging = false;
  
  // Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<PlacePrediction> _searchPredictions = [];
  bool _showSearchResults = false;
  Timer? _searchDebounce;
  MapTilerService? _maptilerService;
  String? _apiKey;
  
  // Animation
  late AnimationController _markerAnimController;
  late Animation<double> _markerBounceAnim;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentTarget = widget.initialPosition;
    _initMapTilerService();
    _getAddressFromLatLng(_currentTarget);
    
    // Marker bounce animation
    _markerAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _markerBounceAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _markerAnimController, curve: Curves.easeOut),
    );
    
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() => _showSearchResults = false);
      }
    });
  }

  void _initMapTilerService() {
    _apiKey = dotenv.env['MAP_TILER_API_KEY'];
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _maptilerService = MapTilerService(apiKey: _apiKey!);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    _markerAnimController.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    if (_maptilerService == null) return;
    
    setState(() => _isLoadingAddress = true);
    
    try {
      final details = await _maptilerService!.reverseGeocode(position);
      
      if (details != null) {
        setState(() {
          _currentName = details.name;
          _currentAddress = details.formattedAddress;
          _addressData = details.addressComponents;
        });
      } else {
        setState(() {
          _currentAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _currentName = 'Coordonnées';
          _addressData = {'display_name': _currentAddress};
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _currentName = 'Coordonnées';
        _addressData = {'display_name': _currentAddress};
      });
    }
    
    setState(() => _isLoadingAddress = false);
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      if (!_isDragging) {
        setState(() => _isDragging = true);
        _markerAnimController.forward();
      }
      _currentTarget = camera.center;
    }
  }

  void _onMapMoveEnd(MapCamera camera) {
    if (_isDragging) {
      setState(() => _isDragging = false);
      _markerAnimController.reverse();
      _getAddressFromLatLng(camera.center);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    _mapController.move(position, _mapController.camera.zoom);
    setState(() => _currentTarget = position);
    _getAddressFromLatLng(position);
  }

  Future<void> _goToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Permission de localisation refusée');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Activez la localisation dans les paramètres');
        return;
      }
      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      final latLng = LatLng(position.latitude, position.longitude);
      _mapController.move(latLng, 16);
      setState(() => _currentTarget = latLng);
      _getAddressFromLatLng(latLng);
    } catch (e) {
      _showSnackBar('Impossible d\'obtenir votre position');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchPredictions = [];
        _showSearchResults = false;
      });
      return;
    }
    
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (_maptilerService == null) return;
    
    try {
      final searchCenter = widget.searchCenterOverride ?? _currentTarget;
      final searchRadius = widget.searchRadius ?? 50000; // Default 50km
      
      final predictions = await _maptilerService!.getPlacePredictions(
        query,
        location: searchCenter,
        radius: searchRadius,
        countrySet: 'DZ', // Algeria
      );
      
      setState(() {
        _searchPredictions = predictions;
        _showSearchResults = predictions.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _searchPredictions = [];
        _showSearchResults = false;
      });
    }
  }

  Future<void> _onPredictionSelected(PlacePrediction prediction) async {
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() {
      _searchPredictions = [];
      _showSearchResults = false;
    });
    
    LatLng? targetLocation = prediction.position;
    
    if (targetLocation != null) {
      _mapController.move(targetLocation, 16);
      setState(() {
        _currentTarget = targetLocation;
        _currentName = prediction.mainText;
        _currentAddress = prediction.description;
      });
      _getAddressFromLatLng(targetLocation);
    }
  }

  void _confirmSelection() {
    Navigator.of(context).pop(LocationData(
      latLng: _currentTarget,
      address: _currentAddress,
      name: _currentName,
      addressData: _addressData,
    ));
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_apiKey == null || _apiKey!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'MapTiler API key not configured.\nPlease add MAP_TILER_API_KEY to your .env file.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // MapTiler Map - Full Screen
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialPosition,
              initialZoom: widget.initialZoom,
              minZoom: 3,
              maxZoom: 18,
              onTap: _onMapTap,
              onPositionChanged: _onMapPositionChanged,
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _onMapMoveEnd(_mapController.camera);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapTilerService.getTileUrl(_apiKey!),
                userAgentPackageName: 'com.sntf.app',
                maxZoom: 18,
              ),
            ],
          ),
          
          // Center Pin Marker
          Center(
            child: AnimatedBuilder(
              animation: _markerBounceAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _markerBounceAnim.value - 25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: widget.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isLoadingAddress
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isDragging ? 'Glissez pour choisir' : _currentName.isNotEmpty
                                    ? (_currentName.length > 20 
                                        ? '${_currentName.substring(0, 20)}...' 
                                        : _currentName)
                                    : 'Lieu sélectionné',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      CustomPaint(
                        size: const Size(20, 10),
                        painter: _TrianglePainter(color: widget.primaryColor),
                      ),
                      Icon(
                        LucideIcons.mapPin,
                        color: widget.primaryColor,
                        size: 40,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Pin shadow
          Center(
            child: Transform.translate(
              offset: const Offset(0, 20),
              child: Container(
                width: 10,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),

          // Top Bar with Search
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                LucideIcons.arrowLeft,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 48), // Balance the back button
                          ],
                        ),
                      ),
                      
                      // Search field
                      if (widget.showSearchBar)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: widget.searchHintText,
                              hintStyle: TextStyle(
                                color: isDark ? AppColors.grey400 : AppColors.grey500,
                              ),
                              prefixIcon: Icon(
                                LucideIcons.search,
                                color: isDark ? AppColors.grey400 : AppColors.grey500,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        LucideIcons.x,
                                        color: isDark ? AppColors.grey400 : AppColors.grey500,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchPredictions = [];
                                          _showSearchResults = false;
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: isDark ? AppColors.darkSurfaceVariant : AppColors.grey100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: _onSearchChanged,
                            onTap: () {
                              if (_searchPredictions.isNotEmpty) {
                                setState(() => _showSearchResults = true);
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Search Results
                if (_showSearchResults && _searchPredictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    constraints: BoxConstraints(maxHeight: screenHeight * 0.4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _searchPredictions.length,
                      itemBuilder: (context, index) {
                        final prediction = _searchPredictions[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              LucideIcons.mapPin,
                              color: widget.primaryColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            prediction.mainText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: prediction.secondaryText.isNotEmpty
                              ? Text(
                                  prediction.secondaryText,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          onTap: () => _onPredictionSelected(prediction),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Map Controls (zoom, current location)
          Positioned(
            right: 16,
            bottom: 180,
            child: Column(
              children: [
                _MapControlButton(
                  icon: LucideIcons.plus,
                  onTap: _zoomIn,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: LucideIcons.minus,
                  onTap: _zoomOut,
                  isDark: isDark,
                ),
                if (widget.showCurrentLocationButton) ...[
                  const SizedBox(height: 16),
                  _MapControlButton(
                    icon: LucideIcons.locateFixed,
                    onTap: _goToCurrentLocation,
                    isDark: isDark,
                    highlighted: true,
                    primaryColor: widget.primaryColor,
                  ),
                ],
              ],
            ),
          ),

          // Bottom Card - Selected Location Info
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.mapPin,
                          color: widget.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isLoadingAddress
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 14,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.grey700 : AppColors.grey200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 12,
                                    width: 200,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.grey700 : AppColors.grey200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentName.isNotEmpty ? _currentName : 'Lieu sélectionné',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currentAddress.isNotEmpty
                                        ? _currentAddress
                                        : 'Déplacez la carte pour choisir',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark ? AppColors.grey400 : AppColors.grey600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoadingAddress ? null : _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.check, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            widget.selectButtonText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool highlighted;
  final Color? primaryColor;

  const _MapControlButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.highlighted = false,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted
          ? (primaryColor ?? AppColors.primary)
          : (isDark ? AppColors.darkSurface : Colors.white),
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 22,
            color: highlighted ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
