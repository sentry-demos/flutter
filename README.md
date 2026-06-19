# Empower Plant - Flutter Sentry Demo

A Flutter e-commerce application showcasing comprehensive Sentry instrumentation for error monitoring, performance tracking, session replay, and user feedback.

**For Solution Engineers:** This guide focuses on **Android** setup, which has been fully tested. **Web** and **macOS** now build and run as well (see "Other Platforms" below). iOS, Linux, and Windows have not been fully validated yet.

---

## Quick Start for Solution Engineers

### Prerequisites

1. **Flutter SDK** >= 3.22.0 ([Install Guide](https://docs.flutter.dev/get-started/install))
2. **Android Studio** or Android SDK command-line tools
3. **Android Emulator** or physical device
4. **Sentry Account** with a project created
5. **(Optional) Sentry CLI** for size analysis: `brew install sentry-cli` (macOS) or [other platforms](https://docs.sentry.io/cli/installation/)

### Initial Setup (5 minutes)

1. **Clone and navigate:**
   ```bash
   git clone https://github.com/sentry-demos/flutter.git
   cd flutter
   ```

2. **Configure your Sentry credentials:**
   ```bash
   cp .env.example .env
   ```

   Edit `.env` with your Sentry project details:
   ```bash
   SENTRY_AUTH_TOKEN=sntryu_your_token_here
   SENTRY_DSN=https://your_key@o123456.ingest.us.sentry.io/123456
   SENTRY_RELEASE=com.example.empower_flutter@9.22.0+1
   SENTRY_ENVIRONMENT=development
   SENTRY_ORG=your-org-slug
   SENTRY_PROJECT=your-project-slug
   SENTRY_SIZE_ANALYSIS_ENABLED=true  # Optional
   ```

3. **Set your engineer identifier:**

   Edit `lib/se_config.dart`:
   ```dart
   const String se = 'your-name';  // Replace with your name
   ```

   This tags all your Sentry events with your identifier, allowing multiple SEs to use the same project without interference.

4. **Verify setup:**
   ```bash
   ./demo.sh verify
   ```

### Building for Android (Recommended Method)

Use the unified build script which handles everything automatically:

```bash
# Build Android APK with full Sentry integration
./demo.sh build android

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```

**What the script does:**
- ✅ Creates Sentry release
- ✅ Builds APK with obfuscation
- ✅ Uploads debug symbols for readable stack traces
- ✅ Uploads ProGuard mapping (Android)
- ✅ (Optional) Uploads build for size analysis
- ✅ Finalizes release

### Installing on Android Emulator

**Method 1: Drag & Drop (Easiest)**
1. Start your Android emulator (via Android Studio or `emulator -avd <device-name>`)
2. Locate the APK: `build/app/outputs/flutter-apk/app-release.apk`
3. Drag and drop the APK file into the emulator window
4. App will install automatically

**Method 2: ADB Install**
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Method 3: Run Script (Build + Install + Create Deploy)**
```bash
./demo.sh run android
```
This builds, installs, launches the app, and creates a Sentry deploy marker.

### Installing on Physical Android Device

1. Enable USB debugging on your device:
   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable USB Debugging

2. Connect device via USB and run:
   ```bash
   ./demo.sh run android
   ```

---

## Testing Sentry Features

### 1. Error Tracking

All errors appear in your Sentry Issues dashboard with:
- Full stack traces (readable thanks to uploaded symbols)
- Session replay showing what led to the error
- Device context and breadcrumbs
- Your engineer tag (`se:your-name`)

### 2. Performance Monitoring

- **TTID (Time to Initial Display)** - Automatic on all screens
- **TTFD (Time to Full Display)** - Manual, measured when content fully loads
- **HTTP Requests** - API calls with timing
- **User Interactions** - Taps, swipes, navigation
- **Database Operations** - Simulated performance issues

Navigate through the app (Home → Product Details → Cart → Checkout) and check the Performance tab in Sentry.

### 3. Session Replay

- Trigger any error from the drawer menu
- Go to Sentry Issues → Click on the error
- View the attached session replay showing user actions leading up to the error
- Financial information (prices in cart/checkout) is shown in full in the app UI but automatically masked in Session Replay for privacy (the `maskCallback` in `lib/sentry_setup.dart` masks any `$…` Text)

### 4. Metrics & Logging

Complete a checkout flow to see:
- **Structured logs** with searchable attributes
- **Custom metrics** (counters, gauges, distributions)
- **API latency tracking**
- **Promo code validation attempts**

View in Sentry → Metrics and Logs sections.

### 5. ANR Detection (Android-Specific)

Trigger from drawer menu: **ANR (Android)**
- Freezes main thread for 10 seconds
- Creates ANR event in Sentry with thread states
- Shows which operations were blocking

### 6. Web View (Distributed Tracing) — Cross-Platform

Trigger from drawer menu: **Web View**
- Opens the Empower Plant React web app (`https://empower-plant.com/products`) inside an in-app WebView (Android/iOS), a `dart:ui_web` iframe (Flutter web), or the system browser (desktop)
- Starts its own Sentry transaction (`webview/empower-plant`, op `navigation`) on a fresh trace
- Performs **Flutter → web distributed tracing**: the active `sentry-trace`/`baggage` are attached to the loaded URL as query params so the web page's Sentry browser SDK continues the same trace (Flutter → React → backend = one trace)
- The transaction finishes when the page loads

### 7. OTLP Backend Journey — Cross-Platform

Trigger from drawer menu: **OTLP**
- Opens the home/product experience but routes all backend calls (`/products`, `/checkout`) to the OpenTelemetry-instrumented backend `https://flask-otlp.empower-plant.com` instead of the default `https://flask.empower-plant.com`
- Runs as its own new trace and continues into the OTLP backend via propagated trace headers
- Backend selection is centralized in `lib/backend_config.dart`

---

## Demo Features Reference

### Error Triggers (All Platforms)
- Dart Exception, Timeout, Platform, State, Range, Type errors
- Assertion failures
- Missing plugin exceptions

### Performance Issues (Auto-triggered on Home Screen)
- File I/O on main thread

### Platform-Specific (Android)
- C++ segfault via method channel
- Kotlin exceptions
- ANR detection (5-second threshold)
- ProGuard obfuscation with symbol upload

---

## Build Outputs & Artifacts

After running `./demo.sh build android`:

```
build/app/outputs/
├── flutter-apk/
│   └── app-release.apk              # Install this on emulator/device
├── bundle/release/
│   └── app-release.aab              # For Google Play Store
└── mapping/release/
    └── mapping.txt                  # ProGuard mapping (auto-uploaded)
```

Debug symbols location:
- Obfuscation map: `build/app/obfuscation.map.json`
- Debug info: `build/debug-info/`

All symbols are automatically uploaded to Sentry by the build script.

## Size Analysis (Optional)

Track your app's build size over time in Sentry.

**Setup:**
1. Install Sentry CLI: `brew install sentry-cli` (or [other methods](https://docs.sentry.io/cli/installation/))
2. Ensure `SENTRY_SIZE_ANALYSIS_ENABLED=true` in `.env`
3. Build: `./demo.sh build android`

View results at:
```
https://sentry.io/organizations/your-org/projects/your-project/size-analysis/
```

Both APK and AAB are uploaded with detailed DEX breakdown (thanks to ProGuard mapping).

For more details, see [SIZE_ANALYSIS_GUIDE.md](SIZE_ANALYSIS_GUIDE.md).

## Build Distribution (Optional)

Upload a built app to Sentry Build Distribution so testers can install it:

```bash
./demo.sh distribute <android|aab|ios> [file]
```

This uploads the build via `sentry-cli build upload` (resolving the default release artifact per platform), reusing the same uploader as size analysis.

---

## Troubleshooting

### Build fails with "Flutter not found"
```bash
# Ensure Flutter is in PATH
flutter doctor
```

### "No devices found" when running
```bash
# List available devices
flutter devices

# Start Android emulator
emulator -list-avds
emulator -avd <device-name>
```

### Events not appearing in Sentry
1. Verify DSN in `.env` is correct
2. Check Sentry project settings
3. Ensure you're on the correct environment filter in Sentry UI
4. Look for errors in app logs: `adb logcat | grep Sentry`

### Spotlight debugging (development mode)
Spotlight is a local Sentry event viewer — events sent in debug mode appear here without going to the cloud.

**Install (one-time):**
```bash
npm install -g @spotlightjs/spotlight
```

**Usage:**
```bash
# 1. Start the Spotlight sidecar server (in a separate terminal):
spotlight

# 2. Run the app in debug mode:
flutter run -d emulator-5554

# 3. Open in browser:
# http://localhost:8969/
```

The Sentry SDK automatically forwards events to Spotlight when running in `kDebugMode`.

### Stack traces are not readable
Make sure you used `./demo.sh build android` (not `flutter build`), which uploads debug symbols automatically.

---

## Project Structure

```
lib/
├── main.dart                    # App entry point, home page
├── sentry_setup.dart            # Comprehensive Sentry configuration
├── se_config.dart               # Engineer identifier (EDIT THIS)
├── navbar_destination.dart      # Navigation drawer + error triggers
├── product_list.dart            # Product catalog, performance demos
├── product_details.dart         # Product detail view
├── cart.dart                    # Shopping cart (shows real prices)
├── checkout.dart                # Checkout with metrics/logging
├── backend_config.dart          # Backend base URL selection (standard vs OTLP)
├── platform/                    # Web-safe platform abstraction (conditional imports)
├── webview/                     # Web View journey + Flutter→web trace handoff
└── models/
    └── cart_state_model.dart    # Shopping cart state (Provider)

demo.sh                          # Unified build script (USE THIS)
.env                            # Sentry credentials (CONFIGURE THIS)
.env.example                    # Configuration template
pubspec.yaml                    # Dependencies and version
```

---

## Key Configuration Files

**`.env`** - Sentry credentials and configuration (git-ignored)
**`lib/se_config.dart`** - Your engineer identifier for event tagging
---

## Sentry SDK Features Enabled

This demo showcases **all** Sentry Flutter features:

✅ Error tracking (Dart, native crashes)
✅ Performance monitoring (transactions, spans, TTFD/TTID)
✅ Session replay (100% capture for demo)
✅ User interactions tracing
✅ HTTP request tracking (SentryHttpClient, Dio)
✅ File I/O instrumentation
✅ Structured logging with attributes
✅ Custom metrics (counters, gauges, distributions)
✅ ANR detection (Android)
✅ App hang detection (iOS/macOS - not tested)
✅ Profiling (iOS/macOS/Android)
✅ User feedback collection
✅ Breadcrumbs and context
✅ Screenshot capture
✅ View hierarchy attachments
✅ Thread information
✅ Spotlight debugging (development)

All features are configured at 100% sampling for demo purposes. Adjust in `lib/sentry_setup.dart` for production.

---

## Additional Documentation

- **[CLAUDE.md](CLAUDE.md)** - Comprehensive project context for AI assistance
- **[BUILD_GUIDE.md](BUILD_GUIDE.md)** - Detailed build instructions for all platforms
- **[SIZE_ANALYSIS_GUIDE.md](SIZE_ANALYSIS_GUIDE.md)** - Size analysis setup and usage
- **[SENTRY_FEATURES.md](SENTRY_FEATURES.md)** - Complete Sentry feature documentation

---

## Other Platforms

In addition to Android, **Web and macOS now build and run**:

```bash
# Web (build + run)
flutter build web
flutter run -d chrome

# macOS
flutter run -d macos
```

The shared code path is web-safe (`dart:io` removed via conditional-import modules in `lib/platform/`, platform checks use `kIsWeb`/`defaultTargetPlatform`). macOS apps are sandboxed, so the `com.apple.security.network.client` entitlement is enabled in `macos/Runner/DebugProfile.entitlements` and `Release.entitlements` so the app can reach the network.

iOS, Linux, and Windows builds may work but have not been fully validated by the team:

```bash
# iOS (requires macOS + Xcode)
./demo.sh build ios

# Others
./demo.sh build linux
./demo.sh build windows
```

---

## Support & Resources

- **Sentry Flutter Docs:** https://docs.sentry.io/platforms/flutter/
- **Sentry CLI Docs:** https://docs.sentry.io/cli/
- **Flutter Docs:** https://docs.flutter.dev/

For issues with this demo, check existing documentation or reach out to the SE team.

---

**Current Version:** 9.22.0+1 (matches Sentry SDK)
**Tested Platforms:** Android (primary), Web, macOS
**App Name:** Empower Plant (com.example.empower_flutter)
