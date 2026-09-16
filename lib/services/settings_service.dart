import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نگه‌داری تنظیم ظاهری کاربر: آیا افکت‌های پس‌زمینه‌ی «شیشه‌ی مایع» فعال باشن یا نه.
/// روی گوشی‌های ضعیف‌تر یا برای صرفه‌جویی باتری، کاربر از همین‌جا خاموشش می‌کنه
/// و به‌جاش یه پس‌زمینه‌ی ساده و سبک نشون داده می‌شه.
class SettingsService {
  static const _key = 'nexa_animations_enabled';

  static final ValueNotifier<bool> animationsEnabled = ValueNotifier(true);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    animationsEnabled.value = prefs.getBool(_key) ?? true;
  }

  static Future<void> setAnimationsEnabled(bool value) async {
    animationsEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
