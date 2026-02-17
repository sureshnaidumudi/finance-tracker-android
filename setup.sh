#!/bin/bash
# Quick setup script for Finance Tracker app

set -e

echo "🚀 Finance Tracker - Setup Script"
echo "=================================="
echo ""

# Add Flutter to PATH for this session
export PATH="$HOME/flutter/bin:$PATH"

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found in PATH"
    echo "Please add to your ~/.bashrc or ~/.zshrc:"
    echo '  export PATH="$HOME/flutter/bin:$PATH"'
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"
echo ""

# Check Java version
if ! command -v java &> /dev/null; then
    echo "⚠️  Java not found. You need Java 17+ to build Android apps."
else
    echo "✅ Java found: $(java -version 2>&1 | head -1)"
fi
echo ""

# Install dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo ""
echo "🏗️  Building release APK..."
flutter build apk --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "📱 Your APK is ready at:"
    echo "   build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "To install on device:"
    echo "  1. Connect your Android device via USB"
    echo "  2. Enable USB debugging in Developer Options"
    echo "  3. Run: flutter install"
    echo "  4. Or: adb install build/app/outputs/flutter-apk/app-release.apk"
    echo ""
else
    echo "❌ Build failed"
    echo ""
    echo "Common issues:"
    echo "  - Make sure Java 17+ is installed"
    echo "  - Check Android SDK is properly configured"
    echo "  - Try: flutter doctor"
    exit 1
fi
