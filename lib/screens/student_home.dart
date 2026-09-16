import 'package:flutter/material.dart';
import '../widgets/dashboard_scaffold.dart';
import '../services/api_service.dart';
import 'online_class_list_screen.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  Future<void> _openOnlineClass(BuildContext context) async {
    final user = await ApiService.currentUser;
    final classId = user?['class_id'];
    if (classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شما هنوز به کلاسی اضافه نشده‌اید')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OnlineClassListScreen(classId: classId, className: 'کلاس شما')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'پنل دانش‌آموز',
      subtitle: 'تکالیف کلاس شما و پیام‌های معلم‌ها',
      items: [
        DashboardItem(
          title: 'تکالیف',
          icon: Icons.menu_book_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'تکالیف'))),
        ),
        DashboardItem(
          title: 'معلم‌های من',
          icon: Icons.co_present_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'معلم‌های من'))),
        ),
        DashboardItem(
          title: 'کلاس آنلاین',
          icon: Icons.videocam_rounded,
          onTap: () => _openOnlineClass(context),
        ),
      ],
    );
  }
}
