import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../screens/login_screen.dart';
import 'animated_mesh_background.dart';
import 'effects_toggle.dart';

class DashboardItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  DashboardItem({required this.title, required this.icon, required this.onTap});
}

class DashboardScaffold extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<DashboardItem> items;

  const DashboardScaffold({super.key, required this.title, required this.subtitle, required this.items});

  @override
  State<DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends State<DashboardScaffold> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    await ApiService.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: const LoginScreen()),
      ),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = appTheme.value.primary;
    final secondary = appTheme.value.secondary;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: primary,
            actions: [
              const Padding(padding: EdgeInsets.only(top: 6), child: EffectsToggle()),
              const SizedBox(width: 6),
              IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () => _logout(context)),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(right: 20, bottom: 16),
              title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              background: ValueListenableBuilder<bool>(
                valueListenable: SettingsService.animationsEnabled,
                builder: (context, effectsOn, _) => AnimatedMeshBackground(
                  enabled: effectsOn,
                  primary: primary,
                  secondary: secondary,
                  showParticles: false,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20, bottom: 44),
                      child: Text(widget.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(18),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = widget.items[i];
                  // هر کارت با تاخیر کمی نسبت به قبلی fade+slide می‌شه (حس ورود مرحله‌ای)
                  final start = (i * 0.08).clamp(0.0, 0.7);
                  final anim = CurvedAnimation(
                    parent: _controller,
                    curve: Interval(start, (start + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
                  );
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim),
                      child: _DashboardCard(item: item, secondary: secondary),
                    ),
                  );
                },
                childCount: widget.items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatefulWidget {
  final DashboardItem item;
  final Color secondary;
  const _DashboardCard({required this.item, required this.secondary});

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.item.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: widget.secondary.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(widget.item.icon, color: widget.secondary, size: 28),
              ),
              const SizedBox(height: 12),
              Text(widget.item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// صفحه‌ی خیلی ساده برای بخش‌هایی که هنوز کامل پیاده‌سازی نشدن (قابل توسعه در آینده)
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('این بخش به‌زودی تکمیل می‌شود')),
    );
  }
}
