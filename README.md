# R8Force Glass Calculator

A modern, glassmorphic Android calculator built with **Flutter & Dart**, featuring a custom zero-dependency expression engine and an integrated 2D/3D geometry calculator.

[![Download APK](https://img.shields.io/badge/Download-Latest_APK-06B6D4?style=for-the-badge&logo=android&logoColor=white)](https://github.com/Amin8362/r8-glass-calculator/releases/latest)

---

## Features

- **Glassmorphic Dark UI:** Frosted-glass panels, responsive layout, tabular numerals, and toggleable haptic feedback.
- **Custom Math Engine:** Real-time expression preview, operator precedence, sign toggle, percentage handling, and calculation history.
- **2D & 3D Geometry Module:** Instant area, perimeter, volume, and surface area calculations for Square, Rectangle, Circle, Triangle (Heron's formula), Cube, Box, Sphere, and Cylinder — with one-tap send back to the main calculator.
- **Automated Cloud Builds:** Release APKs are built and published automatically via GitHub Actions.

## Project Structure

- `lib/main.dart` — Glassmorphic UI, state management, history & settings sheets.
- `lib/math_engine.dart` — Custom arithmetic parser and number formatter.
- `lib/geometry_view.dart` — 2D/3D geometry calculator with Persian & English digit support.
- `.github/workflows/build_apk.yml` — Automated Android release APK pipeline.

## Installation (Android)

1. Open the [**Releases**](https://github.com/Amin8362/r8-glass-calculator/releases/latest) page.
2. Download **`app-arm64-v8a-release.apk`** (recommended for modern Android phones).
3. Install the APK on your device.

---

<div dir="rtl">

### معرفی فارسی

**ماشین‌حساب شیشه‌ای R8Force** یک اپلیکیشن سبک و مدرن اندروید نوشته‌شده با فلاتر است که بدون وابستگی خارجی، محاسبات دقیق روزمره و ماژول کامل هندسه دوبعدی و سه‌بعدی (مساحت، محیط، حجم و مساحت رویه) را با رابط کاربری شیشه‌ای و تاریخچه محاسبات ارائه می‌دهد. برای نصب، فایل `app-arm64-v8a-release.apk` را از بخش **Releases** دانلود کنید.

</div>

---

**Author:** Amin Shirdeli (`R8Force`) • **License:** MIT
