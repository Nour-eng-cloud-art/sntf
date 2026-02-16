import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/data/models/routing.dart';
import 'package:sntf/data/models/transport.dart';

/// Card widget displaying an itinerary option
class ItineraryCard extends StatelessWidget {
  final Itinerary itinerary;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showDetails;

  const ItineraryCard({
    super.key,
    required this.itinerary,
    this.isSelected = false,
    this.onTap,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Duration and badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Duration
                  Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        itinerary.formattedDuration,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Badges
                  Row(
                    children: [
                      if (itinerary.transfers == 0)
                        _Badge(
                          label: 'Direct',
                          color: AppColors.success,
                        )
                      else
                        _Badge(
                          label: '${itinerary.transfers} corresp.',
                          color: AppColors.warning,
                        ),
                      const SizedBox(width: 8),
                      _Badge(
                        label: '${itinerary.totalStops} arrêts',
                        color: isDark ? AppColors.grey600 : AppColors.grey400,
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Ligne chips row
              _LigneChipsRow(segments: itinerary.segments),
              
              const SizedBox(height: 12),
              
              // Summary text
              Text(
                itinerary.summary,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                ),
              ),
              
              // Walking distances
              if (itinerary.walkingDistanceStart != null || 
                  itinerary.walkingDistanceEnd != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.footprints,
                        size: 16,
                        color: isDark ? AppColors.grey500 : AppColors.grey500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatWalkingDistance(itinerary),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Detailed segments
              if (showDetails) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _DetailedSegments(segments: itinerary.segments),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatWalkingDistance(Itinerary it) {
    final parts = <String>[];
    if (it.walkingDistanceStart != null && it.walkingDistanceStart! > 0) {
      parts.add('${it.walkingDistanceStart!.round()}m à pied au départ');
    }
    if (it.walkingDistanceEnd != null && it.walkingDistanceEnd! > 0) {
      parts.add('${it.walkingDistanceEnd!.round()}m à pied à l\'arrivée');
    }
    return parts.join(' • ');
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _LigneChipsRow extends StatelessWidget {
  final List<RouteSegment> segments;

  const _LigneChipsRow({required this.segments});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < segments.length; i++) ...[
          _LigneChip(ligne: segments[i].ligne),
          if (i < segments.length - 1)
            Icon(
              LucideIcons.arrowRight,
              size: 16,
              color: AppColors.grey500,
            ),
        ],
      ],
    );
  }
}

class _LigneChip extends StatelessWidget {
  final Ligne ligne;

  const _LigneChip({required this.ligne});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(ligne.couleurHex) ?? AppColors.primary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTransportIcon(ligne.type),
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            ligne.nomCourt,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransportIcon(TransportType type) {
    switch (type) {
      case TransportType.bus:
        return LucideIcons.bus;
      case TransportType.metro:
        return LucideIcons.trainFront;
      case TransportType.rer:
        return LucideIcons.trainTrack;
      case TransportType.tramway:
        return LucideIcons.tramFront;
      case TransportType.train:
        return LucideIcons.trainFront;
    }
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return null;
    }
  }
}

class _DetailedSegments extends StatelessWidget {
  final List<RouteSegment> segments;

  const _DetailedSegments({required this.segments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        for (int i = 0; i < segments.length; i++) ...[
          _SegmentDetail(
            segment: segments[i],
            isFirst: i == 0,
            isLast: i == segments.length - 1,
          ),
          if (i < segments.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.arrowRightLeft,
                      size: 14,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Correspondance à ${segments[i].arrivalStation.nom}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.grey300 : AppColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _SegmentDetail extends StatelessWidget {
  final RouteSegment segment;
  final bool isFirst;
  final bool isLast;

  const _SegmentDetail({
    required this.segment,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _parseColor(segment.color) ?? AppColors.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Departure
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                Container(
                  width: 2,
                  height: 40,
                  color: color,
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segment.departureStation.nom,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _LigneChip(ligne: segment.ligne),
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.arrowRight,
                        size: 14,
                        color: isDark ? AppColors.grey400 : AppColors.grey600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          segment.ligne.directionTerminus,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.grey400 : AppColors.grey600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // Intermediate stops info
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 2,
                height: 32,
                color: color,
              ),
              const SizedBox(width: 17),
              Text(
                '${segment.stopCount} arrêt${segment.stopCount > 1 ? 's' : ''} • ${segment.estimatedDuration.inMinutes} min',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.grey500 : AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
        
        // Arrival
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                segment.arrivalStation.nom,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return null;
    }
  }
}
