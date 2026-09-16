import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
import '../widgets/animated_mesh_background.dart';
import '../widgets/effects_toggle.dart';
import 'register_manager_screen.dart';
import 'student_entry_screen.dart';
import 'teacher_entry_screen.dart';
import 'deputy_entry_screen.dart';

class RegisterChooserScreen extends StatefulWidget {
  const RegisterChooserScreen({super.key});
  @override
  State<RegisterChooserScreen> createState() => _RegisterChooserScreenState();
}

class _RegisterChooserScreenState extends State<RegisterChooserScreen> with TickerProviderStateMixin {
  // انیمیشن ورود مرحله‌ای: لوگو -> عنوان -> دکمه‌ها
  late final AnimationController _entrance;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<double> _buttonsFade;
  late final Animation<Offset> _buttonsSlide;

  // شناور موندن آرومِ لوگو بعد از ورود (فقط وقتی جلوه‌ها روشنه)
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _logoScale = CurvedAnimation(parent: _entrance, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack));
    _titleFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.25, 0.65, curve: Curves.easeOut));
    _buttonsFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));
    _buttonsSlide = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entrance, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)));
    _entrance.forward();

    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
    if (SettingsService.animationsEnabled.value) _float.repeat(reverse: true);
    SettingsService.animationsEnabled.addListener(_syncFloat);

    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    final update = await UpdateService.checkForUpdate();
    if (update == null || !mounted) return;
    showDialog(
      context: context,
      barrierDismissible: !update.forceUpdate,
      builder: (context) => PopScope(
        canPop: !update.forceUpdate,
        child: AlertDialog(
          backgroundColor: const Color(0xFF141B2E),
          title: Text('نسخه‌ی جدید ${update.versionName} موجود است', style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: Text(update.changelog, style: const TextStyle(color: Colors.white70)),
          actions: [
            if (!update.forceUpdate)
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('بعدا')),
            TextButton(
              onPressed: () => launchUrl(Uri.parse(update.apkUrl), mode: LaunchMode.externalApplication),
              child: const Text('دانلود نسخه جدید'),
            ),
          ],
        ),
      ),
    );
  }

  void _syncFloat() {
    if (SettingsService.animationsEnabled.value) {
      _float.repeat(reverse: true);
    } else {
      _float.stop();
      _float.value = 0;
    }
  }

  @override
  void dispose() {
    SettingsService.animationsEnabled.removeListener(_syncFloat);
    _entrance.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = appTheme.value.primary;
    final secondary = appTheme.value.secondary;

    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: SettingsService.animationsEnabled,
        builder: (context, effectsOn, _) {
          return AnimatedMeshBackground(
            enabled: effectsOn,
            primary: primary,
            secondary: secondary,
            child: SafeArea(
              child: Stack(
                children: [
                  const Positioned(top: 6, left: 6, child: EffectsToggle()),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
                      child: Column(
                        children: [
                          ScaleTransition(
                            scale: _logoScale,
                            child: FadeTransition(
                              opacity: _logoScale,
                              child: AnimatedBuilder(
                                animation: _float,
                                builder: (context, child) {
                                  final dy = effectsOn ? (-6 + 12 * _float.value) : 0.0;
                                  return Transform.translate(offset: Offset(0, dy), child: child);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: secondary.withOpacity(0.45), blurRadius: 60, spreadRadius: 6),
                                      BoxShadow(color: primary.withOpacity(0.35), blurRadius: 40, spreadRadius: 0),
                                    ],
                                  ),
                                  child: Image.asset('assets/logo/nexa_logo.png', width: 150, fit: BoxFit.contain),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeTransition(
                            opacity: _titleFade,
                            child: Column(
                              children: [
                                Text(
                                  'Nexa',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text('همه‌چیز مدرسه، یک‌جا', style: TextStyle(color: Colors.white60, fontSize: 13)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          FadeTransition(
                            opacity: _buttonsFade,
                            child: SlideTransition(
                              position: _buttonsSlide,
                              child: Column(
                                children: [
                                  _EntryButton(
                                    icon: Icons.school_rounded,
                                    label: 'ورود مدیر',
                                    color: secondary,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const RegisterManagerScreen()),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _EntryButton(
                                    icon: Icons.backpack_rounded,
                                    label: 'ورود دانش‌آموز',
                                    color: secondary,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const StudentEntryScreen()),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _EntryButton(
                                    icon: Icons.co_present_rounded,
                                    label: 'ورود معلم',
                                    color: secondary,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const TeacherEntryScreen()),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _EntryButton(
                                    icon: Icons.badge_rounded,
                                    label: 'ورود معاون',
                                    color: secondary,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const DeputyEntryScreen()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EntryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _EntryButton({required this.icon, required this.label, required this.color, required this.onTap});

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
