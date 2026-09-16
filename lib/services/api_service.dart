import 'package:flutter/material.dart';
import 'register_manager_screen.dart';
import 'register_deputy_screen.dart';
import 'register_teacher_screen.dart';
import 'register_student_screen.dart';

class RegisterChooserScreen extends StatefulWidget {
  const RegisterChooserScreen({super.key});

  @override
  State<RegisterChooserScreen> createState() => _RegisterChooserScreenState();
}

class _RegisterChooserScreenState extends State<RegisterChooserScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت‌نام'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'نوع حساب خود را انتخاب کنید',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildRoleCard(
                      context: context,
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'مدیر مدرسه',
                      subtitle: 'مدیریت کل مدرسه، کلاس‌ها و کاربران',
                      color: const Color(0xFF2F5FFF),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterManagerScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRoleCard(
                      context: context,
                      icon: Icons.school_outlined,
                      title: 'معاون',
                      subtitle: 'مدیریت کلاس‌ها و امور آموزشی',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterDeputyScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRoleCard(
                      context: context,
                      icon: Icons.person_outline,
                      title: 'معلم',
                      subtitle: 'ثبت تکالیف، نمرات و حضور و غیاب',
                      color: const Color(0xFF10B981),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterTeacherScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRoleCard(
                      context: context,
                      icon: Icons.child_care_outlined,
                      title: 'دانش‌آموز',
                      subtitle: 'مشاهده تکالیف، نمرات و پیام‌ها',
                      color: const Color(0xFFFFB020),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterStudentScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
