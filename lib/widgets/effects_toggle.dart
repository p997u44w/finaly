import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// دکمه‌ی کوچیک برای روشن/خاموش کردن افکت پس‌زمینه‌ی «شیشه‌ی مایع».
/// برای گوشی‌های ضعیف‌تر یا صرفه‌جویی باتری، کاربر می‌تونه خاموشش کنه.
class EffectsToggle extends StatelessWidget {
  const EffectsToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SettingsService.animationsEnabled,
      builder: (context, enabled, _) {
        return Material(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => SettingsService.setAnimationsEnabled(!enabled),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(enabled ? Icons.water_drop_rounded : Icons.water_drop_outlined, size: 15, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    enabled ? 'جلوه‌ها: روشن' : 'جلوه‌ها: خاموش',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
