import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/data/models/routing.dart';
import 'package:sntf/data/models/transport.dart';

/// Enhanced segment details widget showing all stations with smooth animations
class SegmentDetailsExpanded extends StatefulWidget {
  final RouteSegment segment;
  final Color segmentColor;
  final bool isExpanded;

  const SegmentDetailsExpanded({
    super.key,
    required this.segment,
    required this.segmentColor,
    required this.isExpanded,
  });

  @override
  State<SegmentDetailsExpanded> createState() => _SegmentDetailsExpandedState();
}

class _SegmentDetailsExpandedState extends State<SegmentDetailsExpanded>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    if (widget.isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(SegmentDetailsExpanded oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded && !oldWidget.isExpanded) {
      _animationController.forward();
    } else if (!widget.isExpanded && oldWidget.isExpanded) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with stations count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stations d\'arrêt',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.segmentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.segment.stations.length} arrêts',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.segmentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Info row: Direction and Duration
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: LucideIcons.mapPin,
                        title: 'Direction',
                        subtitle: widget.segment.ligne.directionTerminus,
                        color: widget.segmentColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        icon: LucideIcons.clock,
                        title: 'Durée',
                        subtitle: '${widget.segment.estimatedDuration.inMinutes} min',
                        color: AppColors.info,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stations timeline - full width
              _StationsTimeline(
                segment: widget.segment,
                segmentColor: widget.segmentColor,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Info card for direction and duration
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 12,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.grey400 : AppColors.grey700,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Animated stations timeline
class _StationsTimeline extends StatefulWidget {
  final RouteSegment segment;
  final Color segmentColor;
  final bool isDark;

  const _StationsTimeline({
    required this.segment,
    required this.segmentColor,
    required this.isDark,
  });

  @override
  State<_StationsTimeline> createState() => _StationsTimelineState();
}

class _StationsTimelineState extends State<_StationsTimeline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(
        milliseconds: 300 + (widget.segment.stations.length * 50),
      ),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppColors.darkSurfaceVariant.withValues(alpha: 0.6)
            : AppColors.lightSurfaceVariant.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.segmentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.segmentColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stations list with staggered animation
          Column(
            children: List.generate(
              widget.segment.stations.length,
              (index) {
                final station = widget.segment.stations[index];
                final isOrigin = station == widget.segment.departureStation;
                final isDest = station == widget.segment.arrivalStation;
                final isLast = index == widget.segment.stations.length - 1;

                // Staggered animation
                final staggerDelay = (index * 50);
                final animation = Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Interval(
                      staggerDelay / _controller.duration!.inMilliseconds,
                      (staggerDelay + 300) / _controller.duration!.inMilliseconds,
                      curve: Curves.easeOut,
                    ),
                  ),
                );

                return ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(parent: _controller, curve: Curves.easeOut),
                  ),
                  child: FadeTransition(
                    opacity: animation,
                    child: _StationItem(
                      station: station,
                      isOrigin: isOrigin,
                      isDest: isDest,
                      isLast: isLast,
                      segmentColor: widget.segmentColor,
                      isDark: widget.isDark,
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

/// Individual station item in the timeline
class _StationItem extends StatelessWidget {
  final Station station;
  final bool isOrigin;
  final bool isDest;
  final bool isLast;
  final Color segmentColor;
  final bool isDark;

  const _StationItem({
    required this.station,
    required this.isOrigin,
    required this.isDest,
    required this.isLast,
    required this.segmentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEndpoint = isOrigin || isDest;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot and line
          Column(
            children: [
              // Dot with glow effect for endpoints
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isEndpoint
                      ? segmentColor
                      : segmentColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    width: 2.5,
                  ),
                  boxShadow: isEndpoint
                      ? [
                          BoxShadow(
                            color: segmentColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
              // Connecting line
              if (!isLast)
                Container(
                  width: 2.5,
                  height: 40,
                  color: segmentColor.withValues(alpha: 0.25),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Station info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Station name with better typography
                  Text(
                    station.nom,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isEndpoint ? FontWeight.w700 : FontWeight.w600,
                      fontSize: isEndpoint ? 13 : 12,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Badges row
                  if (isOrigin || isDest || station.accessibilite)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (isOrigin)
                            _Badge(
                              label: 'Départ',
                              color: AppColors.success,
                              icon: LucideIcons.mapPin,
                            )
                          else if (isDest)
                            _Badge(
                              label: 'Arrivée',
                              color: AppColors.warning,
                              icon: LucideIcons.flag,
                            ),
                          if (station.accessibilite)
                            _Badge(
                              label: 'Accessible',
                              color: AppColors.success,
                              icon: LucideIcons.accessibility,
                            ),
                        ],
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

/// Badge widget for labels
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 11,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 9.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
