#!/bin/bash

# FixManager Mobile App Code-Gen Assistant
# This script searches for the Flutter SDK in standard macOS directories and runs Drift SQLite code generation.

echo "=========================================================="
echo "⚡ FixManager Mobile App: Code Generation Assistant ⚡"
echo "=========================================================="

# Common Flutter installation paths on macOS
FLUTTER_PATHS=(
  "$HOME/developer/flutter/bin"
  "$HOME/development/flutter/bin"
  "$HOME/flutter/bin"
  "/opt/flutter/bin"
  "/usr/local/bin"
  "/opt/homebrew/bin"
)

FOUND_FLUTTER=""

# 1. Check if 'flutter' is already on PATH
if command -v flutter &> /dev/null; then
  FOUND_FLUTTER="flutter"
else
  # 2. Search common directories
  for path in "${FLUTTER_PATHS[@]}"; do
    if [ -f "$path/flutter" ]; then
      FOUND_FLUTTER="$path/flutter"
      break
    fi
  done
fi

if [ -n "$FOUND_FLUTTER" ]; then
  echo "✅ Found Flutter SDK at: $FOUND_FLUTTER"
  echo "📦 Fetching packages..."
  $FOUND_FLUTTER pub get
  
  echo "⚙️ Running Drift SQLite schema code generator..."
  $FOUND_FLUTTER pub run build_runner build --delete-conflicting-outputs
  
  echo "🎉 Code generation completed successfully!"
else
  echo "⚠️  Flutter SDK not detected in terminal PATH or common macOS locations."
  echo "Don't worry! You can easily generate the SQLite Drift database classes in your IDE:"
  echo ""
  echo "Option A: Visual Studio Code"
  echo "  1. Open the '/mobile' folder in VS Code."
  echo "  2. The IDE will automatically run 'flutter pub get'."
  echo "  3. Open the VS Code integrated terminal and run:"
  echo "     flutter pub run build_runner build --delete-conflicting-outputs"
  echo ""
  echo "Option B: Android Studio / IntelliJ"
  echo "  1. Open '/mobile' as a project."
  echo "  2. Click 'Pub get' in the top action bar when prompted by the pubspec.yaml file."
  echo "  3. Run the generator via the Terminal pane at the bottom."
  echo ""
  echo "Double check your Flutter installation or add it to your PATH by adding this to your ~/.zshrc:"
  echo "  export PATH=\"\$PATH:/path/to/your/flutter/bin\""
  echo "=========================================================="
fi
