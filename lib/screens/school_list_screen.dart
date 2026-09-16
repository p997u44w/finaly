import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../main.dart';

class SchoolListScreen extends StatefulWidget {
  const SchoolListScreen({super.key});
  @override
  State<SchoolListScreen> createState() => _SchoolListScreenState();
}

class _SchoolListScreenState extends State<SchoolListScreen> {
  List<dynamic> _schools = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiService.get('admin/list-schools');
    setState(() {
      _schools = res['success'] == true ? res['data'] : [];
      _loading = false;
    });
  }

  Future<void> _openBrandingDialog(Map school) async {
    final nameCtrl = TextEditingController(text: school['app_name'] ?? school['name']);
    String? pickedIconPath;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF141B2E),
          title: Text('برندینگ «${school['name']}»', style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'این‌ها فوراً روی اپ نصب‌شده اثر نمی‌ذارن؛ فقط موقع گرفتنِ یه build اختصاصی برای این مدرسه (workflow android_whitelabel تو Codemagic) استفاده می‌شن.',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'اسم اپ برای این مدرسه', labelStyle: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () async {
                  final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (img != null) setDialogState(() => pickedIconPath = img.path);
                },
                icon: const Icon(Icons.image_outlined),
                label: Text(pickedIconPath == null ? 'انتخاب آیکون جدید' : 'آیکون انتخاب شد ✓'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            TextButton(
              onPressed: () async {
                final res = await ApiService.uploadMultipart(
                  'admin/set-school-branding',
                  {'school_id': school['id'].toString(), 'app_name': nameCtrl.text.trim()},
                  filePath: pickedIconPath,
                  fileField: 'icon',
                );
                if (context.mounted) Navigator.pop(context);
                if (res['success'] == true) _load();
              },
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لیست مدرسه‌ها')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _schools.isEmpty
              ? const Center(child: Text('هنوز مدرسه‌ای ثبت نشده'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _schools.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = _schools[i];
                    return Card(
                      child: ListTile(
                        title: Text(s['name']),
                        subtitle: Text('کد: ${s['code']} — وضعیت: ${s['status']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.palette_outlined),
                          tooltip: 'برندینگ اختصاصی',
                          onPressed: () => _openBrandingDialog(s),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
