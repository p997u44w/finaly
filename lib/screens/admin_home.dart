import 'package:flutter/material.dart';
import '../widgets/dashboard_scaffold.dart';
import 'pending_schools_screen.dart';
import 'school_list_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'پنل ادمین کل',
      subtitle: 'مدیریت مدرسه‌ها و تنظیمات کلی سیستم',
      items: [
        DashboardItem(
          title: 'درخواست‌های مدرسه',
          icon: Icons.pending_actions_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingSchoolsScreen())),
        ),
        DashboardItem(
          title: 'لیست مدرسه‌ها',
          icon: Icons.school_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolListScreen())),
        ),
        DashboardItem(
          title: 'تم هر مدرسه',
          icon: Icons.palette_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'تنظیم تم مدرسه'))),
        ),
        DashboardItem(
          title: 'محدودیت پیام آزاد',
          icon: Icons.chat_bubble_outline_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'محدودیت پیام آزاد'))),
        ),
      ],
    );
  }
}
