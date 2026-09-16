import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'online_class_list_screen.dart';

/// قبل از دیدن جلسات کلاس آنلاین، باید مشخص بشه برای کدوم کلاس.
/// معلم فقط کلاس‌های خودش رو می‌بینه، مدیر همه‌ی کلاس‌های مدرسه رو.
class ClassPickerScreen extends StatefulWidget {
  final String role; // 'teacher' | 'manager'
  const ClassPickerScreen({super.key, required this.role});

  @override
  State<ClassPickerScreen> createState() => _ClassPickerScreenState();
}

class _ClassPickerScreenState extends State<ClassPickerScreen> {
  List<dynamic> _classes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final path = widget.role == 'teacher' ? 'teacher/list-classes' : 'manager/list-classes';
    final res = await ApiService.get(path);
    setState(() {
      _classes = res['success'] == true ? res['data'] : [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('انتخاب کلاس')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? const Center(child: Text('کلاسی یافت نشد'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _classes.length,
                  itemBuilder: (context, i) {
                    final c = _classes[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.meeting_room_rounded),
                        title: Text(c['name']),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OnlineClassListScreen(classId: c['id'], className: c['name']),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
