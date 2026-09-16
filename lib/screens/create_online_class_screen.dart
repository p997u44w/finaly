import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/animated_glass_field.dart';
import '../widgets/animated_primary_button.dart';
import '../main.dart';

/// مدیر برای یک کلاس، جلسه‌ی کلاس آنلاین می‌سازه و معلم اصلیش رو انتخاب می‌کنه.
/// (ادمین هم می‌تونه از همین API مستقیم برای هر مدرسه‌ای استفاده کنه.)
class CreateOnlineClassScreen extends StatefulWidget {
  final int classId;
  const CreateOnlineClassScreen({super.key, required this.classId});

  @override
  State<CreateOnlineClassScreen> createState() => _CreateOnlineClassScreenState();
}

class _CreateOnlineClassScreenState extends State<CreateOnlineClassScreen> {
  final _titleCtrl = TextEditingController();
  List<dynamic> _teachers = [];
  int? _selectedTeacherId;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    final res = await ApiService.get('manager/list-teachers');
    if (res['success'] == true) {
      final all = res['data'] as List;
      // فقط معلم‌هایی که به همین کلاس تخصیص دارن قابل انتخاب به‌عنوان معلم اصلی‌ان
      _teachers = all.where((t) {
        final classes = (t['classes'] as List?) ?? [];
        return classes.any((c) => c['id'] == widget.classId);
      }).toList();
    }
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    if (_selectedTeacherId == null) {
      setState(() => _error = 'معلم اصلی را انتخاب کنید');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final res = await ApiService.post('onlineclass/create', {
      'class_id': widget.classId,
      'main_teacher_id': _selectedTeacherId,
      'title': _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
    }, auth: true);

    if (res['success'] == true) {
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _error = res['message'] ?? 'خطا در ساخت جلسه';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondary = appTheme.value.secondary;

    return Scaffold(
      appBar: AppBar(title: const Text('جلسه‌ی کلاس آنلاین جدید')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedGlassField(controller: _titleCtrl, label: 'عنوان جلسه (اختیاری)', icon: Icons.title_rounded),
                  const SizedBox(height: 18),
                  const Text('معلم اصلی این جلسه', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  if (_teachers.isEmpty)
                    const Text('هیچ معلمی به این کلاس تخصیص داده نشده', style: TextStyle(color: Colors.white38))
                  else
                    ..._teachers.map((t) => RadioListTile<int>(
                          value: t['id'],
                          groupValue: _selectedTeacherId,
                          onChanged: (v) => setState(() => _selectedTeacherId = v),
                          title: Text(t['full_name'], style: const TextStyle(color: Colors.white)),
                          activeColor: secondary,
                        )),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
                  ],
                  const SizedBox(height: 20),
                  AnimatedPrimaryButton(label: 'ساخت جلسه', loading: _submitting, color: secondary, onPressed: _create),
                ],
              ),
            ),
    );
  }
}
