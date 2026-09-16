import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'online_class_screen.dart';
import 'create_online_class_screen.dart';

class OnlineClassListScreen extends StatefulWidget {
  final int classId;
  final String className;

  const OnlineClassListScreen({super.key, required this.classId, required this.className});

  @override
  State<OnlineClassListScreen> createState() => _OnlineClassListScreenState();
}

class _OnlineClassListScreenState extends State<OnlineClassListScreen> {
  List<dynamic> _sessions = [];
  bool _loading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await ApiService.currentUser;
    final res = await ApiService.get('onlineclass/list?class_id=${widget.classId}');
    setState(() {
      _role = user?['role'];
      _sessions = res['success'] == true ? res['data'] : [];
      _loading = false;
    });
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'live':
        return 'در حال برگزاری';
      case 'ended':
        return 'پایان‌یافته';
      default:
        return 'زمان‌بندی‌شده';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'live':
        return const Color(0xFF2ECC71);
      case 'ended':
        return Colors.white38;
      default:
        return const Color(0xFFFFB020);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _role == 'manager' || _role == 'admin';

    return Scaffold(
      appBar: AppBar(title: Text('کلاس آنلاین — ${widget.className}')),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add_rounded),
              label: const Text('جلسه جدید'),
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateOnlineClassScreen(classId: widget.classId)),
                );
                if (created == true) _load();
              },
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(child: Text('هنوز جلسه‌ای برای این کلاس ثبت نشده'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = _sessions[i];
                    final canJoin = s['status'] != 'ended';
                    return Card(
                      child: ListTile(
                        title: Text(s['title'] ?? 'جلسه‌ی کلاس آنلاین'),
                        subtitle: Text('معلم اصلی: ${s['main_teacher_name']}'),
                        trailing: Chip(
                          label: Text(_statusLabel(s['status']), style: const TextStyle(color: Colors.white, fontSize: 11)),
                          backgroundColor: _statusColor(s['status']),
                        ),
                        onTap: canJoin
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OnlineClassScreen(sessionId: s['id'], classTitle: widget.className),
                                  ),
                                )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
