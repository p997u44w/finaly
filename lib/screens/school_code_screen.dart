import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../widgets/animated_mesh_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_glass_field.dart';
import '../widgets/animated_primary_button.dart';
import 'login_screen.dart';

/// این صفحه فقط وقتی لازمه که از سیستم چندهاستی (هاب مرکزی) استفاده می‌کنید.
/// اگه فقط یه بک‌اند دارید، همین‌جا ApiService.useHub رو false کنید تا این
/// مرحله کلا رد بشه و مستقیم بره صفحه‌ی ورود.
class SchoolCodeScreen extends StatefulWidget {
  const SchoolCodeScreen({super.key});

  @override
  State<SchoolCodeScreen> createState() => _SchoolCodeScreenState();
}

class _SchoolCodeScreenState extends State<SchoolCodeScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _continue() async {
    if (_codeCtrl.text.trim().isEmpty) {
      setState(() => _error = 'کد مدرسه را وارد کنید');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.resolveSchool(_codeCtrl.text.trim().toUpperCase());
    if (res['success'] == true) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      setState(() {
        _error = res['message'] ?? 'کد مدرسه معتبر نیست';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: SettingsService.animationsEnabled,
        builder: (context, effectsOn, _) {
          return AnimatedMeshBackground(
            enabled: effectsOn,
            primary: appTheme.value.primary,
            secondary: appTheme.value.secondary,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text('Nexa',
                          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      const Text('کد مدرسه‌ی خود را وارد کنید', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      const SizedBox(height: 32),
                      GlassCard(
                        blurEnabled: effectsOn,
                        child: Column(
                          children: [
                            AnimatedGlassField(
                              controller: _codeCtrl,
                              label: 'کد مدرسه (مثلا NEXA-4821)',
                              icon: Icons.qr_code_rounded,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
                              ),
                            ],
                            const SizedBox(height: 18),
                            AnimatedPrimaryButton(
                              label: 'ادامه',
                              loading: _loading,
                              color: appTheme.value.secondary,
                              onPressed: _continue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'کد مدرسه رو مدیر یا ادمین مدرسه‌تون بهتون داده',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
