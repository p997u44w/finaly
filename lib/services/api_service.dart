import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // آدرس هاب مرکزی — اولین جایی که اپ برای پیدا کردن هاست هر مدرسه بهش وصل می‌شه.
  static const String hubUrl = 'https://hub.nexa-school.ir';

  static String? _resolvedBaseUrl;

  /// آدرس بک‌اندی که الان باهاش کار می‌کنیم.
  /// همه‌ی درخواست‌ها از ریشه دامنه رد می‌شن و به Router (index.php) می‌رسن.
  static Future<String> get baseUrl async {
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('host_url');
    if (saved != null) {
      _resolvedBaseUrl = saved;
      return saved;
    }
    // ⭐ ریشه دامنه — مسیرهای ماژول‌ها رو توی path پاس می‌دیم
    return 'https://nexa-school.ir';
  }

  /// از هاب مرکزی می‌پرسه «این کد مدرسه مال کدوم هاسته» و نتیجه رو ذخیره می‌کنه.
  static Future<Map<String, dynamic>> resolveSchool(String schoolCode) async {
    final res = await http.get(Uri.parse('$hubUrl/schools/resolve?school_code=$schoolCode'));
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      final hostUrl = data['data']['host_url'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('host_url', hostUrl);
      await prefs.setString('school_code', schoolCode);
      _resolvedBaseUrl = hostUrl;
    }
    return data;
  }

  /// کاربر می‌تونه از یه مدرسه‌ی دیگه دوباره وارد بشه
  static Future<void> forgetSchool() async {
    _resolvedBaseUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('host_url');
    await prefs.remove('school_code');
  }

  static Future<String?> get savedSchoolCode async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('school_code');
  }

  static const bool useHub = false;

  static Future<String?> get _token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> get rawToken => _token;

  static Future<void> saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> get currentUser async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user');
    return raw == null ? null : jsonDecode(raw);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, String>> _headers({bool auth = true, bool json = true}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (auth) {
      final t = await _token;
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  /// ⭐ POST با timeout و try/catch — دیگه اسپینر بی‌نهایت نمی‌چرخه
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final base = await baseUrl;
    final url = '$base/$path';
    debugPrint('🌐 POST: $url');

    try {
      final res = await http
          .post(
            Uri.parse(url),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('📥 Status: ${res.statusCode}');
      debugPrint('📥 Body: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'خطای سرور (${res.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('❌ POST Error: $e');
      return {
        'success': false,
        'message': 'خطا در اتصال به سرور: $e',
      };
    }
  }

  /// ⭐ GET با timeout و try/catch
  static Future<Map<String, dynamic>> get(String path, {bool auth = true}) async {
    final base = await baseUrl;
    final url = '$base/$path';
    debugPrint('🌐 GET: $url');

    try {
      final res = await http
          .get(
            Uri.parse(url),
            headers: await _headers(auth: auth, json: false),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('📥 Status: ${res.statusCode}');
      debugPrint('📥 Body: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'خطای سرور (${res.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('❌ GET Error: $e');
      return {
        'success': false,
        'message': 'خطا در اتصال به سرور: $e',
      };
    }
  }

  /// آپلود فرم چندبخشی (برای تکلیف، پیام عکس/ویس و ...)
  static Future<Map<String, dynamic>> uploadMultipart(
    String path,
    Map<String, String> fields, {
    String? filePath,
    String fileField = 'file',
  }) async {
    final base = await baseUrl;
    final uri = Uri.parse('$base/$path');
    debugPrint('🌐 UPLOAD: $uri');

    try {
      final request = http.MultipartRequest('POST', uri);
      final t = await _token;
      if (t != null) request.headers['Authorization'] = 'Bearer $t';
      request.fields.addAll(fields);
      if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
      }
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);

      debugPrint('📥 Status: ${res.statusCode}');
      debugPrint('📥 Body: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'خطای سرور (${res.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('❌ UPLOAD Error: $e');
      return {
        'success': false,
        'message': 'خطا در آپلود: $e',
      };
    }
  }
}

/// تم اختصاصی هر مدرسه که ادمین از پنل خودش تنظیم می‌کنه.
class SchoolTheme {
  final Color primary;
  final Color secondary;
  final String? logoUrl;

  SchoolTheme({required this.primary, required this.secondary, this.logoUrl});

  static SchoolTheme get defaultTheme =>
      SchoolTheme(primary: const Color(0xFF2F5FFF), secondary: const Color(0xFFFFB020));

  static Future<SchoolTheme> fetch() async {
    try {
      // ⭐ مسیر Router: school/get-theme (نه modules/school/get-theme.php)
      final res = await ApiService.get('school/get-theme', auth: false);
      if (res['success'] == true) {
        final data = res['data'];
        final base = await ApiService.baseUrl;
        return SchoolTheme(
          primary: _hexToColor(data['theme_primary_color']) ?? defaultTheme.primary,
          secondary: _hexToColor(data['theme_secondary_color']) ?? defaultTheme.secondary,
          logoUrl: data['logo_path'] != null ? '$base/${data['logo_path']}' : null,
        );
      }
    } catch (_) {}
    return defaultTheme;
  }

  static Color? _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
