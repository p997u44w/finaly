import 'package:flutter/material.dart';
import '../main.dart';
import '../services/settings_service.dart';
import '../widgets/animated_mesh_background.dart';
import 'manager_login_screen.dart';
import 'deputy_login_screen.dart';
import 'teacher_login_screen.dart';
import 'student_login_screen.dart';

class LoginChooserScreen extends StatelessWidget {
  const LoginChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = appTheme.value.primary;
    final secondary = appTheme.value.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('ورود'), backgroundColor: Colors.transparent, elevation: 0),
      body: ValueListenableBuilder<bool>(
        valueListenable: SettingsService.animationsEnabled,
        builder: (context, effectsOn, _) {
          return AnimatedMeshBackground(
            enabled: effectsOn,
            primary: primary,
            secondary: secondary,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Btn(icon: Icons.school_rounded, label: 'ورود مدیر', color: secondary,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerLoginScreen()))),
                      const SizedBox(height: 14),
                      _Btn(icon: Icons.badge_rounded, label: 'ورود معاون', color: secondary,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeputyLoginScreen()))),
                      const SizedBox(height: 14),
                      _Btn(icon: Icons.co_present_rounded, label: 'ورود معلم', color: secondary,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherLoginScreen()))),
                      const SizedBox(height: 14),
                      _Btn(icon: Icons.backpack_rounded, label: 'ورود دانش‌آموز', color: secondary,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentLoginScreen()))),
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

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.chevron_left_rounded, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
