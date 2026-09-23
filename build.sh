#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# MedTrack — one-shot build script
# Run this from inside the unzipped project folder:
#   chmod +x build.sh && ./build.sh
#
# Assumes: Linux x86-64, internet access, Java 11+ already installed
#          (installs Java 17 via apt if not found)
# ─────────────────────────────────────────────────────────────────────────────
set -e

FLUTTER_VERSION="3.24.5"
FLUTTER_DIR="$HOME/flutter"
ANDROID_SDK_DIR="$HOME/android-sdk"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   MedTrack APK Builder                       ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Java ──────────────────────────────────────────────────────────────────
if ! command -v java &>/dev/null; then
  echo "→ Installing Java 17..."
  sudo apt-get update -qq
  sudo apt-get install -y openjdk-17-jdk
else
  echo "✅ Java found: $(java -version 2>&1 | head -1)"
fi

# ── 2. Flutter SDK ────────────────────────────────────────────────────────────
if [ ! -f "$FLUTTER_DIR/bin/flutter" ]; then
  echo "→ Downloading Flutter $FLUTTER_VERSION (~690 MB)..."
  curl -L --progress-bar \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    -o /tmp/flutter.tar.xz
  echo "→ Extracting Flutter..."
  tar xf /tmp/flutter.tar.xz -C "$HOME"
  rm /tmp/flutter.tar.xz
else
  echo "✅ Flutter already at $FLUTTER_DIR"
fi

export PATH="$PATH:$FLUTTER_DIR/bin"

# ── 3. Android SDK (cmdline-tools) ───────────────────────────────────────────
CMDLINE_TOOLS_ZIP="/tmp/cmdline-tools.zip"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

if [ ! -d "$ANDROID_SDK_DIR/cmdline-tools/latest/bin" ]; then
  echo "→ Downloading Android command-line tools (~135 MB)..."
  curl -L --progress-bar "$CMDLINE_TOOLS_URL" -o "$CMDLINE_TOOLS_ZIP"
  mkdir -p "$ANDROID_SDK_DIR/cmdline-tools"
  unzip -q "$CMDLINE_TOOLS_ZIP" -d "$ANDROID_SDK_DIR/cmdline-tools"
  # Google ships it as 'cmdline-tools/', rename to 'latest/'
  mv "$ANDROID_SDK_DIR/cmdline-tools/cmdline-tools" "$ANDROID_SDK_DIR/cmdline-tools/latest" 2>/dev/null || true
  rm "$CMDLINE_TOOLS_ZIP"
else
  echo "✅ Android cmdline-tools already installed"
fi

export ANDROID_HOME="$ANDROID_SDK_DIR"
export PATH="$PATH:$ANDROID_SDK_DIR/cmdline-tools/latest/bin:$ANDROID_SDK_DIR/platform-tools"

# ── 4. Android SDK packages ──────────────────────────────────────────────────
echo "→ Installing Android SDK packages (platform-34, build-tools)..."
yes | sdkmanager --licenses > /dev/null 2>&1 || true
sdkmanager \
  "platforms;android-34" \
  "build-tools;34.0.0" \
  "platform-tools"

# ── 5. Tell Flutter where the Android SDK is ─────────────────────────────────
flutter config --android-sdk "$ANDROID_SDK_DIR" --no-analytics 2>/dev/null || true
yes | flutter doctor --android-licenses > /dev/null 2>&1 || true

# ── 6. Build ─────────────────────────────────────────────────────────────────
echo ""
echo "→ Getting Flutter packages..."
cd "$PROJECT_DIR"
flutter pub get

echo ""
echo "→ Building release APK..."
flutter build apk --release

APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   ✅ BUILD SUCCESSFUL                        ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  APK: $APK_PATH"
echo "  Size: $(du -h "$APK_PATH" | cut -f1)"
echo ""
echo "  Transfer to your phone and install."
echo "  (Enable 'Install from unknown sources' in Android settings first)"
echo ""
