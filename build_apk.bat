@echo off
REM ============================================================
REM Smart Timetable Builder — APK Build Script (Windows)
REM Run this script from inside the smart_timetable_builder folder
REM ============================================================

echo.
echo ╔══════════════════════════════════════════╗
echo ║    Smart Timetable Builder — APK Build   ║
echo ╚══════════════════════════════════════════╝
echo.

REM Check Flutter
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Flutter not found. Please install Flutter first:
    echo    https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo ✅ Flutter found.
echo.

echo 📦 Installing dependencies...
flutter pub get
echo.

echo 🔨 Building release APK...
flutter build apk --release

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo.
    echo ╔══════════════════════════════════════════╗
    echo ║         ✅  BUILD SUCCESSFUL!            ║
    echo ╚══════════════════════════════════════════╝
    echo.
    echo APK saved at:
    echo   build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo 📲 To install on a connected Android device:
    echo    flutter install
) else (
    echo ❌ Build failed.
)

pause
