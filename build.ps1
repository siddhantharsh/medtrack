# ─────────────────────────────────────────────────────────────────────────────
# MedTrack — Windows one-shot build script (PowerShell)
#
# Run from inside the unzipped project folder in PowerShell:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\build.ps1
#
# Requires: Windows 10/11 x64, internet access
# Installs:  Flutter SDK, Android cmdline-tools, JDK 17 (via winget if missing)
# ─────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

$FLUTTER_VERSION  = "3.24.5"
$FLUTTER_DIR      = "$env:USERPROFILE\flutter"
$ANDROID_SDK_DIR  = "$env:USERPROFILE\android-sdk"
$PROJECT_DIR      = $PSScriptRoot

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   MedTrack APK Builder (Windows)             ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── 1. Java ──────────────────────────────────────────────────────────────────
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "→ Installing Java 17 via winget..." -ForegroundColor Yellow
    winget install --id Microsoft.OpenJDK.17 --accept-source-agreements --accept-package-agreements -e
    # Reload PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH","User")
} else {
    Write-Host "✅ Java found: $(java -version 2>&1 | Select-Object -First 1)" -ForegroundColor Green
}

# ── 2. Flutter SDK ────────────────────────────────────────────────────────────
if (-not (Test-Path "$FLUTTER_DIR\bin\flutter.bat")) {
    Write-Host "→ Downloading Flutter $FLUTTER_VERSION for Windows (~700 MB)..." -ForegroundColor Yellow
    $flutterZip = "$env:TEMP\flutter.zip"
    $url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_${FLUTTER_VERSION}-stable.zip"
    Invoke-WebRequest -Uri $url -OutFile $flutterZip -UseBasicParsing
    Write-Host "→ Extracting Flutter (this takes a minute)..." -ForegroundColor Yellow
    Expand-Archive -Path $flutterZip -DestinationPath $env:USERPROFILE -Force
    Remove-Item $flutterZip
} else {
    Write-Host "✅ Flutter already at $FLUTTER_DIR" -ForegroundColor Green
}

$env:PATH = "$FLUTTER_DIR\bin;" + $env:PATH

# ── 3. Android cmdline-tools ─────────────────────────────────────────────────
$sdkmanager = "$ANDROID_SDK_DIR\cmdline-tools\latest\bin\sdkmanager.bat"
if (-not (Test-Path $sdkmanager)) {
    Write-Host "→ Downloading Android command-line tools (~135 MB)..." -ForegroundColor Yellow
    $ctZip = "$env:TEMP\cmdline-tools.zip"
    $ctUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
    Invoke-WebRequest -Uri $ctUrl -OutFile $ctZip -UseBasicParsing
    $extractTmp = "$env:TEMP\cmdline-tools-extract"
    Expand-Archive -Path $ctZip -DestinationPath $extractTmp -Force
    New-Item -ItemType Directory -Path "$ANDROID_SDK_DIR\cmdline-tools" -Force | Out-Null
    # Google ships folder named 'cmdline-tools', rename to 'latest'
    Move-Item "$extractTmp\cmdline-tools" "$ANDROID_SDK_DIR\cmdline-tools\latest" -Force
    Remove-Item $ctZip
    Remove-Item $extractTmp -Recurse -Force
} else {
    Write-Host "✅ Android cmdline-tools already installed" -ForegroundColor Green
}

$env:ANDROID_HOME = $ANDROID_SDK_DIR
$env:PATH = "$ANDROID_SDK_DIR\cmdline-tools\latest\bin;" +
            "$ANDROID_SDK_DIR\platform-tools;" + $env:PATH

# ── 4. Android SDK packages ──────────────────────────────────────────────────
Write-Host "→ Installing Android SDK packages..." -ForegroundColor Yellow
"y" | & $sdkmanager --licenses 2>$null
& $sdkmanager "platforms;android-34" "build-tools;34.0.0" "platform-tools"

# ── 5. Tell Flutter about the SDK ────────────────────────────────────────────
flutter config --android-sdk $ANDROID_SDK_DIR --no-analytics 2>$null
"y" | flutter doctor --android-licenses 2>$null

# ── 6. Build ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "→ Getting Flutter packages..." -ForegroundColor Yellow
Set-Location $PROJECT_DIR
flutter pub get

Write-Host ""
Write-Host "→ Building release APK..." -ForegroundColor Yellow
flutter build apk --release

$apkPath = "$PROJECT_DIR\build\app\outputs\flutter-apk\app-release.apk"
$apkSize = (Get-Item $apkPath).Length / 1MB

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ BUILD SUCCESSFUL                        ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  APK : $apkPath" -ForegroundColor White
Write-Host "  Size: $([math]::Round($apkSize,1)) MB" -ForegroundColor White
Write-Host ""
Write-Host "  Copy the APK to your phone and install it." -ForegroundColor Gray
Write-Host "  (Enable 'Install from unknown sources' in Android settings first)" -ForegroundColor Gray
Write-Host ""
