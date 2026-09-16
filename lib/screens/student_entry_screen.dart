import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../widgets/animated_mesh_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_glass_field.dart';
import '../widgets/animated_primary_button.dart';
import 'student_home.dart';

/// ورودی دانش‌آموز: اول کد کلاس، بعد نام/کد ملی/موبایل خودش (اختیاری) و
/// موبایل والد (اجباری). همین فرم هم ثبت‌نام اولیه‌ست هم ورودهای بعدی.
class StudentEntryScreen extends StatefulWidget {
  const StudentEntryScreen({super.key});
  @override
  State<StudentEntryScreen> createState() => _StudentEntryScreenState();
}

class _StudentEntryScreenState extends State<StudentEntryScreen> {
  final _classCodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _nationalCodeCtrl = TextEditingController();
  final _studentPhoneCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.post('auth/register-student', {
      'class_code': _classCodeCtrl.text.trim(),
      'full_name': _nameCtrl.text.trim(),
      'national_code': _nationalCodeCtrl.text.trim(),
      if (_studentPhoneCtrl.text.trim().isNotEmpty) 'student_phone': _studentPhoneCtrl.text.trim(),
      'parent_phone': _parentPhoneCtrl.text.trim(),
    });

    if (res['success'] == true) {
      await ApiService.saveSession(res['token'], res['user']);
      appTheme.value = await SchoolTheme.fetch();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentHome()));
    } else {
      setState(() {
        _error = res['message'] ?? 'خطا در ورود';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = appTheme.value.primary;
    final secondary = appTheme.value.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('ورود دانش‌آموز')),
      body: ValueListenableBuilder<bool>(
        valueListenable: SettingsService.animationsEnabled,
        builder: (context, effectsOn, _) {
          return AnimatedMeshBackground(
            enabled: effectsOn,
            primary: primary,
            secondary: secondary,
            showParticles: false,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 84, 20, 30),
                child: GlassCard(
                  blurEnabled: effectsOn,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('کد کلاس', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('این کد رو از معلم یا مدیر بگیرید', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 12),
                      AnimatedGlassField(controller: _classCodeCtrl, label: 'کد کلاس', icon: Icons.qr_code_rounded),
                      const SizedBox(height: 18),
                      const Text('اطلاعات دانش‌آموز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      const SizedBox(height: 12),
                      AnimatedGlassField(controller: _nameCtrl, label: 'نام و نام‌خانوادگی', icon: Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                      AnimatedGlassField(
                        controller: _nationalCodeCtrl,
                        label: 'کد ملی',
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      AnimatedGlassField(
                        controller: _studentPhoneCtrl,
                        label: 'شماره موبایل دانش‌آموز (اختیاری)',
                        icon: Icons.phone_iphone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      AnimatedGlassField(
                        controller: _parentPhoneCtrl,
                        label: 'شماره موبایل والد',
                        icon: Icons.family_restroom_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
                      ],
                      const SizedBox(height: 18),
                      AnimatedPrimaryButton(label: 'ورود', loading: _loading, color: secondary, onPressed: _submit),
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
