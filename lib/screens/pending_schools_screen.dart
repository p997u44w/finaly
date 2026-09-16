import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

class PendingSchoolsScreen extends StatefulWidget {
  const PendingSchoolsScreen({super.key});
  @override
  State<PendingSchoolsScreen> createState() => _PendingSchoolsScreenState();
}

class _PendingSchoolsScreenState extends State<PendingSchoolsScreen> {
  List<dynamic> _requests = [];
  List<dynamic> _hosts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('admin/list-pending-schools');
    final hostsRes = await ApiService.get('admin/list-hosts');
    setState(() {
      _requests = res['success'] == true ? res['data'] : [];
      _hosts = hostsRes['success'] == true ? hostsRes['data'] : [];
      _loading = false;
    });
  }

  Future<void> _reject(int schoolId) async {
    final res = await ApiService.post('admin/reject-school', {'school_id': schoolId});
    if (res['success'] == true) _load();
  }

  Future<void> _openApproveDialog(Map request) async {
    int? selectedHostId;
    final features = <String, bool>{
      'exams': true,
      'late_penalty': true,
      'resubmit': true,
      'points': true,
      'online_class': true,
    };
    const labels = {
      'exams': 'امتحان',
      'late_penalty': 'کسر نمره‌ی تاخیر',
      'resubmit': 'ارسال مجدد تکلیف',
      'points': 'امتیاز مثبت/منفی',
      'online_class': 'کلاس آنلاین',
    };

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF141B2E),
          title: Text('تایید «${request['school_name']}»', style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('هاست/سرور (اختیاری)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButton<int?>(
                  value: selectedHostId,
                  dropdownColor: const Color(0xFF141B2E),
                  isExpanded: true,
                  hint: const Text('بدون تخصیص خاص', style: TextStyle(color: Colors.white38)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('بدون تخصیص خاص', style: TextStyle(color: Colors.white))),
                    ..._hosts.map((h) => DropdownMenuItem(
                          value: h['id'] as int,
                          child: Text(h['name'], style: const TextStyle(color: Colors.white)),
                        )),
                  ],
                  onChanged: (v) => setDialogState(() => selectedHostId = v),
                ),
                const SizedBox(height: 16),
                const Text('قابلیت‌های این مدرسه', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ...features.keys.map((key) => CheckboxListTile(
                      value: features[key],
                      onChanged: (v) => setDialogState(() => features[key] = v ?? true),
                      title: Text(labels[key]!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      activeColor: appTheme.value.secondary,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            TextButton(
              onPressed: () async {
                final res = await ApiService.post('admin/approve-school', {
                  'school_id': request['school_id'],
                  if (selectedHostId != null) 'host_id': selectedHostId,
                  'features': features,
                });
                if (context.mounted) Navigator.pop(context);
                if (res['success'] == true) _load();
              },
              child: const Text('تایید'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('درخواست‌های مدرسه')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('درخواست در انتظاری وجود ندارد'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = _requests[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['school_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('مدیر: ${r['manager_name']} — کد ملی: ${r['manager_national_code']}'),
                            Text('موبایل: ${r['manager_phone']}'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _reject(r['school_id']),
                                    child: const Text('رد کردن'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _openApproveDialog(r),
                                    child: const Text('تایید'),
                                  ),
                                ),
                              ],
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
