import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/data/models/routing.dart';
import 'package:sntf/data/models/transport.dart';

/// Widget displaying transfer/correspondance between two segments
class TransferSeparator extends StatelessWidget {
  final RouteSegment fromSegment;
  final RouteSegment toSegment;

  const TransferSeparator({
    super.key,
    required this.fromSegment,
    required this.toSegment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.info.withAlpha(20),
            AppColors.info.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withAlpha(30),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Dotted line
          SizedBox(
            height: 16,
            child: CustomPaint(
              painter: _DottedLinePainter(
                color: AppColors.info.withAlpha(100),
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          // Transfer info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // From station
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Départ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fromSegment.departureStation?.nom ?? 'Station',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  LucideIcons.arrowRight,
                  size: 18,
                  color: AppColors.info,
                ),
              ),
              // To station
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Arrivée',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      toSegment.arrivalStation?.nom ?? 'Station',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Painter for dotted line
class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
