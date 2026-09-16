import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../widgets/animated_mesh_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_glass_field.dart';
import '../widgets/animated_primary_button.dart';
import 'manager_home.dart';
import 'admin_home.dart';

/// ورودی مدیر: اسم مدرسه + نام‌خانوادگی/کد ملی/شماره موبایل خودِ مدیر.
/// همین فرم هم ثبت‌نام اولیه‌ست هم ورودهای بعدی (با همون کد ملی + موبایل).
class RegisterManagerScreen extends StatefulWidget {
  const RegisterManagerScreen({super.key});
  @override
  State<RegisterManagerScreen> createState() => _RegisterManagerScreenState();
}

class _RegisterManagerScreenState extends State<RegisterManagerScreen> {
  final _schoolNameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _nationalCodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.post('auth/register-manager', {
      'school_name': _schoolNameCtrl.text.trim(),
      'manager_full_name': _nameCtrl.text.trim(),
      'manager_national_code': _nationalCodeCtrl.text.trim(),
      'manager_phone': _phoneCtrl.text.trim(),
    });

    if (res['success'] == true) {
      await ApiService.saveSession(res['token'], res['user']);
      appTheme.value = await SchoolTheme.fetch();
      if (!mounted) return;

      if (res['school'] != null && res['school']['code'] != null) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF141B2E),
            title: const Text('کد مدرسه‌ی شما', style: TextStyle(color: Colors.white)),
            content: Text(
              'کد مدرسه: ${res['school']['code']}\n\nاین کد رو به معاون‌ها بدید تا بتونن وارد بشن. بعداً هم می‌تونید از پنل مدیر ببینیدش.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('متوجه شدم'))],
          ),
        );
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManagerHome()));
    } else if (res['status'] == 'pending') {
      setState(() => _loading = false);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF141B2E),
          title: const Text('در انتظار تایید ادمین', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Text(res['message'] ?? 'درخواست شما ثبت شد و در انتظار تایید است.', style: const TextStyle(color: Colors.white70)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('متوجه شدم'))],
        ),
      );
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
      appBar: AppBar(title: const Text('ورود مدیر')),
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
                      const Text('اطلاعات مدرسه و مدیر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('اگه قبلاً ثبت‌نام کردید، دوباره همین اطلاعات رو بزنید تا واردتون کنه',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 14),
                      AnimatedGlassField(controller: _schoolNameCtrl, label: 'نام مدرسه', icon: Icons.school_outlined),
                      const SizedBox(height: 12),
                      AnimatedGlassField(controller: _nameCtrl, label: 'نام و نام‌خانوادگی مدیر', icon: Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                      AnimatedGlassField(
                        controller: _nationalCodeCtrl,
                        label: 'کد ملی مدیر',
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      AnimatedGlassField(
                        controller: _phoneCtrl,
                        label: 'شماره موبایل مدیر',
                        icon: Icons.phone_iphone_rounded,
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
