import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'services/settings_service.dart';
import 'theme/nexa_tokens.dart';
import 'screens/root_screen.dart';

/// تم فعلی اپ. بعد از لاگین، با رنگ‌های اختصاصیِ همون مدرسه
/// (که ادمین از پنل خودش تنظیم کرده) آپدیت می‌شه.
final ValueNotifier<SchoolTheme> appTheme = ValueNotifier(SchoolTheme.defaultTheme);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.load(); // خوندن تنظیم روشن/خاموش بودن جلوه‌های پویا
  runApp(const NexaApp());
}

class NexaApp extends StatelessWidget {
  const NexaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SchoolTheme>(
      valueListenable: appTheme,
      builder: (context, theme, _) {
        return MaterialApp(
          title: 'Nexa',
          debugShowCheckedModeBanner: false,
          locale: const Locale('fa', 'IR'),
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            textTheme: GoogleFonts.vazirmatnTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: NexaTokens.bgDeep,
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.primary,
              primary: theme.primary,
              secondary: theme.secondary,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              labelStyle: const TextStyle(color: Colors.white60),
              hintStyle: const TextStyle(color: Colors.white38),
            ),
          ),
          builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const RootScreen(),
        );
      },
    );
  }
}
