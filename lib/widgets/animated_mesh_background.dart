import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// پس‌زمینه‌ی انیمیشنی «mesh gradient»: چند دایره‌ی رنگی بزرگ که به‌آرومی
/// دور خودشون می‌چرخن و بلور می‌شن، به‌علاوه چندتا ذره‌ی نورانی که شناورن.
/// کاملا native فلاتره (بدون نیاز به asset یا پکیج اضافه)، پس سبک و روونه.
class AnimatedMeshBackground extends StatefulWidget {
  final Color primary;
  final Color secondary;
  final Widget? child;
  final bool showParticles;
  final bool enabled;

  const AnimatedMeshBackground({
    super.key,
    required this.primary,
    required this.secondary,
    this.child,
    this.showParticles = true,
    this.enabled = true,
  });

  @override
  State<AnimatedMeshBackground> createState() =>
      _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState
    extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );

    if (widget.enabled) {
      _controller.repeat();
    } else {
      _controller.value = 0.15;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedMeshBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark =
        Color.lerp(widget.primary, Colors.black, 0.35)!;

    return Stack(
      fit: StackFit.expand,
      children: [
        // پایه: گرادیان تیره و شیک
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                dark,
                widget.primary,
                Color.lerp(
                  widget.primary,
                  widget.secondary,
                  0.4,
                )!,
              ],
            ),
          ),
        ),

        // بلاب‌های رنگی که شناور و بلور می‌شن
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * math.pi;

            return Stack(
              children: [
                _blob(
                  t: t,
                  phase: 0.0,
                  size: 300,
                  color: widget.secondary.withOpacity(0.45),
                  align: const Alignment(-1.1, -1.0),
                  dx: 0.22,
                  dy: 0.16,
                ),
                _blob(
                  t: t,
                  phase: 2.2,
                  size: 340,
                  color: widget.primary.withOpacity(0.55),
                  align: const Alignment(1.2, -0.7),
                  dx: 0.18,
                  dy: 0.24,
                ),
                _blob(
                  t: t,
                  phase: 4.1,
                  size: 240,
                  color: widget.secondary.withOpacity(0.30),
                  align: const Alignment(0.9, 1.3),
                  dx: 0.16,
                  dy: 0.2,
                ),
                _blob(
                  t: t,
                  phase: 1.3,
                  size: 220,
                  color: Colors.white.withOpacity(0.10),
                  align: const Alignment(-1.0, 1.2),
                  dx: 0.14,
                  dy: 0.12,
                ),
              ],
            );
          },
        ),

        // بلور کردن همه‌ی لایه‌های بالا
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 70,
            sigmaY: 70,
          ),
          child: Container(
            color: Colors.transparent,
          ),
        ),

        // ذرات نورانی شناور
        if (widget.showParticles && widget.enabled)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _ParticlesPainter(
                progress: _controller.value,
              ),
              size: Size.infinite,
            ),
          ),

        if (widget.child != null) widget.child!,
      ],
    );
  }

  Widget _blob({
    required double t,
    required double phase,
    required double size,
    required Color color,
    required Alignment align,
    required double dx,
    required double dy,
  }) {
    final x = (align.x + math.sin(t + phase) * dx)
        .clamp(-1.6, 1.6);

    final y = (align.y + math.cos(t + phase) * dy)
        .clamp(-1.6, 1.6);

    return Align(
      alignment: Alignment(x, y),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double progress;

  static const int count = 26;

  _ParticlesPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final rnd = math.Random(7);

    for (int i = 0; i < count; i++) {
      final seedX = rnd.nextDouble();
      final speed = 0.4 + rnd.nextDouble() * 0.8;
      final radius = 1.0 + rnd.nextDouble() * 2.0;
      final sway = 8 + rnd.nextDouble() * 18;

      final yProgress =
          (progress * speed + seedX) % 1.0;

      final dy =
          size.height * (1 - yProgress);

      final dx =
          seedX * size.width +
          math.sin(
                progress * 2 * math.pi + i,
              ) *
              sway;

      final opacity =
          (math.sin(yProgress * math.pi))
                  .clamp(0.0, 1.0) *
              0.5;

      paint.color =
          Colors.white.withOpacity(opacity);

      canvas.drawCircle(
        Offset(dx, dy),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _ParticlesPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}