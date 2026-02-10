import 'package:flutter/material.dart';
import 'package:sntf/core/theme/app_colors.dart';

/// Animated train widget for splash/auth screens
class TrainAnimation extends StatefulWidget {
  final double size;
  final Color? color;

  const TrainAnimation({
    super.key,
    this.size = 80,
    this.color,
  });

  @override
  State<TrainAnimation> createState() => _TrainAnimationState();
}

class _TrainAnimationState extends State<TrainAnimation>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _pulseController;
  late Animation<double> _moveAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _moveAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _moveController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _moveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;

    return AnimatedBuilder(
      animation: Listenable.merge([_moveAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_moveAnimation.value * 20, 0),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          ),
        );
      },
      child: Icon(
        Icons.train_rounded,
        size: widget.size,
        color: color,
      ),
    );
  }
}

/// Animated logo with train icon for SNTF
class AnimatedLogo extends StatefulWidget {
  final double size;
  final bool showText;

  const AnimatedLogo({
    super.key,
    this.size = 120,
    this.showText = true,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeOut),
    );

    _scaleController.forward();
    _rotateController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _rotateAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(widget.size * 0.3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.train_rounded,
              size: widget.size * 0.6,
              color: Colors.white,
            ),
          ),
          if (widget.showText) ...[
            const SizedBox(height: 20),
            Text(
              'SNTF',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Voyagez en toute sérénité',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Track/Rail animation decoration
class TrackDecoration extends StatefulWidget {
  const TrackDecoration({super.key});

  @override
  State<TrackDecoration> createState() => _TrackDecorationState();
}

class _TrackDecorationState extends State<TrackDecoration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 40),
          painter: TrackPainter(
            progress: _animation.value,
            color: isDark ? AppColors.grey700 : AppColors.grey300,
            accentColor: AppColors.primary,
          ),
        );
      },
    );
  }
}

class TrackPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color accentColor;

  TrackPainter({
    required this.progress,
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw rails
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      paint,
    );

    // Draw sleepers
    paint.strokeWidth = 2;
    for (double i = 0; i < size.width; i += 30) {
      final offset = (progress * 30) % 30;
      canvas.drawLine(
        Offset(i + offset, size.height * 0.2),
        Offset(i + offset, size.height * 0.8),
        paint,
      );
    }

    // Draw moving accent
    final accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final accentX = progress * size.width;
    canvas.drawLine(
      Offset(accentX - 20, size.height * 0.3),
      Offset(accentX + 20, size.height * 0.3),
      accentPaint,
    );
    canvas.drawLine(
      Offset(accentX - 20, size.height * 0.7),
      Offset(accentX + 20, size.height * 0.7),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TrackPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
