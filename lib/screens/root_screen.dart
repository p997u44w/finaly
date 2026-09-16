import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'school_code_screen.dart';

/// اولین صفحه‌ای که باز می‌شه. اگه از هاب مرکزی استفاده می‌کنید و هنوز کد
/// مدرسه resolve نشده، اول SchoolCodeScreen رو نشون می‌ده؛ وگرنه مستقیم لاگین.
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  Future<Widget> _decide() async {
    if (!ApiService.useHub) return const LoginScreen();
    final code = await ApiService.savedSchoolCode;
    return code == null ? const SchoolCodeScreen() : const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _decide(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0E17),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        return snapshot.data!;
      },
    );
  }
}
