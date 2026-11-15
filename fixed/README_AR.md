# حزمة بناء 4 تطبيقات (قهوة + ميكاترونكس) × (Android + Windows)

التطبيقين مبنيين بـ Flutter. كل تطبيق له مفتاح API وسجل محادثة مستقل.

## الطريقة 1: على جهاز Windows
1. ثبّت: Flutter SDK، Android Studio (مع Android SDK)، Visual Studio 2022 مع **Desktop development with C++** وعلّم كمان **C++ ATL for latest build tools**.
2. فعّل **Developer Mode** في إعدادات Windows (مطلوب للإضافات).
3. فك الضغط في مسار قصير بدون مسافات أو حروف عربي (مثال `C:\agents`).
4. شغّل `CHECK_SETUP_WINDOWS.bat` وراجع النتيجة، ونفّذ `flutter doctor --android-licenses`.
5. شغّل `BUILD_ALL_WINDOWS.bat`. النتيجة تظهر في مجلد `OUTPUT`:
   - `Coffee_Business_Agent.apk` و `Mechatronics_Engineer_Agent.apk`
   - مجلدا Windows لكل تطبيق (وزّع المجلد كامل، مش ملف exe لوحده).

لبناء تطبيق واحد: شغّل `build_android.bat` أو `build_windows.bat` داخل مجلده.

## الطريقة 2: بدون تثبيت أي حاجة (GitHub Actions)
ارفع محتوى المجلد ده على مستودع GitHub خاص، وادخل Actions ثم Build apps ثم Run workflow. هتحمّل APK وملفات Windows من Artifacts.

## الإعداد
افتح التطبيق، الإعدادات، وحط مفتاح OpenAI API. المفتاح بيتخزن في التخزين الآمن للجهاز.

## ما تم إصلاحه في هذه النسخة
- السكربتات كانت بتنادي `flutter` بدون `call` فكانت بتقف بعد أول أمر.
- صلاحية الإنترنت (INTERNET) كانت ناقصة في نسخة Release من Android، فالتطبيق ما كانش هيتصل.
- `flutter doctor` كان بيوقف البناء لأي تحذير بسيط.
- تحديد اسم الحزمة صراحة، وحذف ملف الاختبار الافتراضي اللي بيعمل خطأ تحليل.
- تحديد حجم الملف المرفق بـ 60 ألف حرف.

## تنبيهات
- APK بيتوقّع بمفتاح debug وده مناسب للاستخدام الشخصي. للنشر في Google Play محتاج توقيع خاص.
- لو هتوزع التطبيقات لناس تانية، الأفضل خادم وسيط يحفظ مفتاح API.
- المحادثات محلية على كل جهاز.
