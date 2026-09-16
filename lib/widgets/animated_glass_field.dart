import 'package:flutter/material.dart';

/// فیلد متنی که موقع فوکوس، حاشیه‌ش با انیمیشن رنگی و کمی بزرگ‌تر می‌شه.
/// برای استفاده روی پس‌زمینه‌ی شیشه‌ای (تیره) طراحی شده.
class AnimatedGlassField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const AnimatedGlassField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  State<AnimatedGlassField> createState() => _AnimatedGlassFieldState();
}

class _AnimatedGlassFieldState extends State<AnimatedGlassField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _focused ? accent : Colors.white.withOpacity(0.25), width: _focused ? 1.6 : 1.1),
        color: Colors.white.withOpacity(_focused ? 0.16 : 0.10),
        boxShadow: _focused ? [BoxShadow(color: accent.withOpacity(0.25), blurRadius: 14)] : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscure,
        keyboardType: widget.keyboardType,
        style: const TextStyle(color: Colors.white),
        cursorColor: accent,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(widget.icon, color: _focused ? accent : Colors.white70),
          suffixIcon: widget.suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }
}
