import 'package:package_info_plus/package_info_plus.dart';
import 'api_service.dart';

class UpdateInfo {
  final String versionName;
  final String apkUrl;
  final String changelog;
  final bool forceUpdate;
  UpdateInfo({required this.versionName, required this.apkUrl, required this.changelog, required this.forceUpdate});
}

/// چون این اپ از گوگل‌پلی توزیع نمی‌شه، خودش باید بفهمه نسخه‌ی جدیدتری
/// منتشر شده یا نه (با خوندن backend/app_version.json از روی بک‌اند).
class UpdateService {
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final res = await ApiService.get('app/version', auth: false);
      if (res['success'] != true) return null;

      final data = res['data'];
      final remoteCode = data['latest_version_code'] as int;

      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 0;

      if (remoteCode > currentCode) {
        return UpdateInfo(
          versionName: data['latest_version_name'] ?? '',
          apkUrl: data['apk_url'] ?? '',
          changelog: data['changelog'] ?? '',
          forceUpdate: data['force_update'] ?? false,
        );
      }
    } catch (_) {
      // اگه چک آپدیت شکست خورد، جلوی استفاده از اپ رو نمی‌گیریم
    }
    return null;
  }
}
