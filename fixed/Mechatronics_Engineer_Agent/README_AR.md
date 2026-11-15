# Mechatronics Engineer Agent — Flutter Android + Windows

هذا مشروع Flutter مستقل عن التطبيق الآخر. له اسم حزمة وسجل محادثة ومفتاح API خاص به.

## المتطلبات
- Flutter SDK حديث (يفضل stable).
- Android Studio وAndroid SDK لبناء Android.
- Visual Studio 2022 مع workload: Desktop development with C++ لبناء Windows.
- اتصال إنترنت ومفتاح OpenAI API.

## إنشاء ملفات المنصات أول مرة
من داخل مجلد المشروع:
```bash
flutter create --platforms=android,windows .
flutter pub get
```

## تشغيل تجريبي
```bash
flutter run
```
اختر جهاز Android أو Windows من قائمة الأجهزة.

## بناء Android APK
```bash
flutter build apk --release
```
الملف الناتج عادة:
`build/app/outputs/flutter-apk/app-release.apk`

## بناء Windows
```bash
flutter build windows --release
```
المجلد الناتج:
`build/windows/x64/runner/Release/`

## ملاحظات مهمة
- افتح إعدادات التطبيق وأدخل مفتاح OpenAI API. المفتاح يُحفظ في التخزين الآمن بالجهاز.
- المحادثات محفوظة محلياً على نفس الجهاز، ولا تتم مزامنتها بين Android وWindows تلقائياً.
- المرفقات المدعومة حالياً: TXT وMD وCSV وJSON وLOG حتى 2 ميجابايت. دعم PDF وDOCX وExcel يحتاج إضافة قارئات متخصصة في مرحلة لاحقة.
- لا تضع مفتاح API داخل الكود أو تشارك ملفاً يحتوي عليه. تخزين المفتاح على جهاز المستخدم أفضل من تضمينه في التطبيق، لكنه لا يعادل حماية مفتاح عبر خادم وسيط في تطبيق منشور لعدة مستخدمين.
- هذه حزمة مصدر Flutter؛ لم يتم إنشاء APK أو EXE نهائي هنا. يلزم Flutter SDK وأدوات البناء لإنتاجهما.
