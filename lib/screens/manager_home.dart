import 'package:flutter/material.dart';
import '../widgets/dashboard_scaffold.dart';
import '../services/api_service.dart';
import 'class_picker_screen.dart';

class ManagerHome extends StatelessWidget {
  const ManagerHome({super.key});

  Future<void> _showSchoolCode(BuildContext context) async {
    final res = await ApiService.get('school/get-info');
    if (!context.mounted) return;
    final code = res['success'] == true ? res['data']['code'] : null;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141B2E),
        title: const Text('کد مدرسه', style: TextStyle(color: Colors.white)),
        content: Text(
          code ?? 'خطا در دریافت کد',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'پنل مدیر مدرسه',
      subtitle: 'مدیریت کلاس‌ها، دانش‌آموزان و معلم‌های مدرسه‌ی شما',
      items: [
        DashboardItem(
          title: 'کلاس‌ها',
          icon: Icons.meeting_room_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'کلاس‌ها'))),
        ),
        DashboardItem(
          title: 'دانش‌آموزان',
          icon: Icons.groups_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'دانش‌آموزان'))),
        ),
        DashboardItem(
          title: 'معلم‌ها',
          icon: Icons.co_present_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'معلم‌ها'))),
        ),
        DashboardItem(
          title: 'کلاس آنلاین',
          icon: Icons.videocam_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassPickerScreen(role: 'manager'))),
        ),
        DashboardItem(
          title: 'اطلاعیه‌ها',
          icon: Icons.campaign_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'اطلاعیه‌ها'))),
        ),
        DashboardItem(
          title: 'کد مدرسه',
          icon: Icons.qr_code_rounded,
          onTap: () => _showSchoolCode(context),
        ),
      ],
    );
  }
}

