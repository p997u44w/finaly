import 'dart:ui';
import 'package:flutter/material.dart';

/// یک کارت شیشه‌ای نیمه‌شفاف با افکت بلور پشتش (glassmorphism)، برای قرار گرفتن
/// روی پس‌زمینه‌های انیمیشنی. حاشیه‌ی نازک نورانی هم داره که حس «شیشه» رو تقویت می‌کنه.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double opacity;

  /// وقتی false باشه (کاربر جلوه‌های پویا رو خاموش کرده)، به‌جای BackdropFilter
  /// سنگین، یه پس‌زمینه‌ی تیره‌ی نیمه‌شفاف ساده و سبک نشون داده می‌شه.
  final bool blurEnabled;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.borderRadius = 26,
    this.opacity = 0.14,
    this.blurEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!blurEnabled) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF141B2E).withOpacity(0.94),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.1),
          ),
          child: child,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 14)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// همون کارت ولی برای وقتی پس‌زمینه‌ی روشنه (نه انیمیشنی)، پس زمینه‌ی سفید تقریبا کامل + سایه‌ی ملایم
class SolidCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const SolidCard({super.key, required this.child, this.padding = const EdgeInsets.all(22), this.borderRadius = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}
