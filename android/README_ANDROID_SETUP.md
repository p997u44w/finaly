# فایل‌های android آماده — راهنمای جایگزینی

این پوشه (`frontend/android/`) از قبل کامل ساخته شده: تنظیمات Gradle با
نسخه‌های پایدار (نه آخرین نسخه‌ی ناپایدار)، همه‌ی مجوزهای لازم برای کلاس
آنلاین، و آیکون واقعی Nexa برای همه‌ی رزولوشن‌ها.

## چون قبلاً خودت `flutter create` زدی

روی سیستم خودت یه پوشه‌ی `android/` داری که از قبل کار می‌کنه (Gradle Wrapper
دانلود شده و غیره) — فقط تنظیمات نسخه‌هاش (AGP 8.7.3) باعث خطا شده بود.
پس لازم نیست همه‌چیز رو از نو بسازی؛ فقط **این فایل‌ها رو کپی کن روی همون
اسم‌ها** تو پروژه‌ی خودت (جایگزین کن):

```
android/settings.gradle.kts
android/build.gradle.kts
android/gradle.properties
android/gradle/wrapper/gradle-wrapper.properties
android/app/build.gradle.kts
android/app/proguard-rules.pro
android/app/src/main/AndroidManifest.xml
android/app/src/main/kotlin/com/nexa/app/MainActivity.kt   (اگه پکیجت فرق داره، مسیر پوشه رو هم مطابقش کن)
android/app/src/main/res/**  (همه‌ی این پوشه، شامل آیکون‌ها)
```

**این سه‌تا رو دست نزن** (از قبل داری و درستن، این‌ها فایل باینری‌ان که
از اینترنت دانلود شدن، جایگزین‌شون نکن):
```
android/gradlew
android/gradlew.bat
android/gradle/wrapper/gradle-wrapper.jar
android/local.properties   (این خودکار توسط ابزار فلاتر ساخته/آپدیت می‌شه)
```

## بعد از جایگزینی

```bash
cd frontend
flutter clean
flutter pub get
flutter build apk --release
```

## اگه بازم همون خطای دانلود پلاگین رو دیدی

یعنی قطعاً مشکل شبکه‌ست (دسترسی به `dl.google.com` / `plugins.gradle.org`)،
نه تنظیمات — یه VPN روشن کن و دوباره امتحان کن (نسخه‌های AGP 8.3.2 و
Gradle 8.4 که اینجا گذاشتم خیلی رایج و پایدارن، پس بعیده خودشون مشکل باشن).

## نکات مهم این تنظیمات

- **امضا (signing)**: اگه فایل `android/key.properties` رو (طبق راهنمای
  قبلی) ساخته باشی، خودکار باهاش امضا می‌کنه؛ اگه نساخته باشی، با کلید
  debug می‌سازه (که یعنی build هیچ‌وقت به‌خاطر نبود کلید امضا خطا نمی‌ده،
  ولی برای انتشار واقعی حتماً باید `key.properties` رو بسازی).
- **minSdk = 21** صریح ست شده (نه پیش‌فرض فلاتر) چون `flutter_webrtc` بهش
  نیاز داره.
- **minify خاموشه** (`isMinifyEnabled = false`) تا خطاهای رایج ProGuard/R8
  مربوط به WebRTC و Socket.IO پیش نیاد؛ فقط یعنی حجم APK کمی بزرگ‌تره.
- **آیکون واقعی Nexa** از قبل تو همه‌ی رزولوشن‌ها (mipmap-mdpi تا
  xxxhdpi، هم legacy هم adaptive) ساخته شده — دیگه لازم نیست
  `flutter_launcher_icons` رو جدا اجرا کنی.
- اگه موقع تست، بک‌اندت هنوز `http://` (نه https) هست (مثلاً رو شبکه‌ی
  محلی)، تو `AndroidManifest.xml` مقدار `android:usesCleartextTraffic`
  رو موقتاً `true` کن، وگرنه اندروید درخواست‌های غیر-HTTPS رو بلاک می‌کنه.
