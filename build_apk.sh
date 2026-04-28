#!/bin/bash
# ============================================================
# Smart Timetable Builder — APK Build Script
# Run this script from inside the smart_timetable_builder folder
# ============================================================

set -e

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║    Smart Timetable Builder — APK Build   ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Check Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first:"
    echo "   👉 https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"
echo ""

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get
echo ""

# Run a quick analysis
echo "🔍 Checking code..."
flutter analyze --no-fatal-infos || true
echo ""

# Build release APK
echo "🔨 Building release APK..."
flutter build apk --release

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$APK_PATH" ]; then
    SIZE=$(du -sh "$APK_PATH" | cut -f1)
    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║          ✅ BUILD SUCCESSFUL!            ║"
    echo "╠══════════════════════════════════════════╣"
    echo "║  APK: $APK_PATH"
    echo "║  Size: $SIZE"
    echo "╚══════════════════════════════════════════╝"
    echo ""
    echo "📲 To install on a connected Android device:"
    echo "   flutter install"
    echo ""
    echo "📋 Or copy the APK to your Android phone and open it to install."
else
    echo "❌ Build failed — APK not found."
    exit 1
fi
