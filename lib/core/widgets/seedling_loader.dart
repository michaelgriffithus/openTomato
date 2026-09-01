import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animated seedling sprouting loader
class SeedlingLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const SeedlingLoader({
    super.key,
    this.size = 48.0,
    this.color,
  });

  @override
  State<SeedlingLoader> createState() => _SeedlingLoaderState();
}

class _SeedlingLoaderState extends State<SeedlingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _growthAnimation;
  late Animation<double> _leafAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Growth animation: stem grows from 0 to full height
    _growthAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Leaf animation: leaves unfurl after stem grows
    _leafAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    // Fade animation: fade out at the end, fade in at the start
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _SeedlingPainter(
                growthProgress: _growthAnimation.value,
                leafProgress: _leafAnimation.value,
                color: color,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SeedlingPainter extends CustomPainter {
  final double growthProgress;
  final double leafProgress;
  final Color color;

  _SeedlingPainter({
    required this.growthProgress,
    required this.leafProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height);
    final stemHeight = size.height * 0.7 * growthProgress;

    // Draw stem
    if (stemHeight > 0) {
      canvas.drawLine(
        center,
        Offset(center.dx, center.dy - stemHeight),
        paint,
      );
    }

    // Draw leaves (two leaves sprouting from the sides)
    if (leafProgress > 0 && stemHeight > 0) {
      final leafTop = Offset(center.dx, center.dy - stemHeight);
      final leafSize = size.width * 0.25 * leafProgress;

      // Left leaf
      final leftLeafPath = Path();
      leftLeafPath.moveTo(leafTop.dx, leafTop.dy);
      leftLeafPath.quadraticBezierTo(
        leafTop.dx - leafSize * 0.7,
        leafTop.dy - leafSize * 0.3,
        leafTop.dx - leafSize,
        leafTop.dy - leafSize * 0.5,
      );

      // Right leaf
      final rightLeafPath = Path();
      rightLeafPath.moveTo(leafTop.dx, leafTop.dy);
      rightLeafPath.quadraticBezierTo(
        leafTop.dx + leafSize * 0.7,
        leafTop.dy - leafSize * 0.3,
        leafTop.dx + leafSize,
        leafTop.dy - leafSize * 0.5,
      );

      canvas.drawPath(leftLeafPath, paint);
      canvas.drawPath(rightLeafPath, paint);

      // Add second pair of leaves slightly lower
      if (leafProgress > 0.5) {
        final secondLeafTop = Offset(
          leafTop.dx,
          leafTop.dy + size.height * 0.15,
        );
        final secondLeafSize = leafSize * 0.7;

        final leftLeaf2 = Path();
        leftLeaf2.moveTo(secondLeafTop.dx, secondLeafTop.dy);
        leftLeaf2.quadraticBezierTo(
          secondLeafTop.dx - secondLeafSize * 0.6,
          secondLeafTop.dy + secondLeafSize * 0.2,
          secondLeafTop.dx - secondLeafSize,
          secondLeafTop.dy + secondLeafSize * 0.3,
        );

        final rightLeaf2 = Path();
        rightLeaf2.moveTo(secondLeafTop.dx, secondLeafTop.dy);
        rightLeaf2.quadraticBezierTo(
          secondLeafTop.dx + secondLeafSize * 0.6,
          secondLeafTop.dy + secondLeafSize * 0.2,
          secondLeafTop.dx + secondLeafSize,
          secondLeafTop.dy + secondLeafSize * 0.3,
        );

        canvas.drawPath(leftLeaf2, paint);
        canvas.drawPath(rightLeaf2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SeedlingPainter oldDelegate) {
    return oldDelegate.growthProgress != growthProgress ||
        oldDelegate.leafProgress != leafProgress;
  }
}
