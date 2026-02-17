# empower_flutter

A demo Flutter application with full Sentry instrumentation and best practices for error monitoring, performance, and user feedback.

## Getting Started

### Prerequisites

- [Flutter SDK >= 3.22.0 (Dart >= 3.8.1)](https://docs.flutter.dev/get-started/install)
- Xcode (for iOS/macOS builds - macOS only)
- Android Studio (for Android builds)
- Visual Studio/Build Tools (for Windows builds - Windows only)
- Linux development tools (for Linux builds - Linux only)
- Sentry account (for error monitoring)

### Setup

1. **Clone the repository:**
   ```sh
   git clone https://github.com/sentry-demos/flutter.git
   cd flutter
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   ```
3. **Configure Sentry credentials:**
   - Copy `.env.example` to `.env` and set your SENTRY_DSN, SENTRY_RELEASE, SENTRY_ENVIRONMENT.
   - Each engineer should set their identifier in `lib/se_config.dart`:
     ```dart
     const String se = 'YourName';
     ```

### Building and Running with `demo.sh`

The unified `demo.sh` script supports building for **all platforms** with automatic Sentry release management, debug symbol upload, and deploy tracking.

#### Usage

```bash
./demo.sh build [platform] [build-type]
./demo.sh run [platform]
./demo.sh verify
```

**Platforms:**
- `android` - Build Android APK (works on all OS)
- `aab` - Build Android App Bundle (preferred for Play Store)
- `ios` - Build iOS app (macOS only)
- `web` - Build web app (works on all OS)
- `macos` - Build macOS app (macOS only)
- `linux` - Build Linux app (best on Linux)
- `windows` - Build Windows app (Windows only)

**Build Types:**
- `debug` - Debug build (no obfuscation, no release)
- `profile` - Profile build
- `release` - Release build with obfuscation and release management (default)

#### Examples

```bash
# Verify setup
./demo.sh verify

# Build Android APK with release management
./demo.sh build android

# Build Android App Bundle (preferred)
./demo.sh build aab

# Build iOS app (debug)
./demo.sh build ios debug

# Build web app
./demo.sh build web

# Run Android app and create deploy
./demo.sh run android

# Show help
./demo.sh help
```

#### Android Build

After building with `./demo.sh build android`, locate the APK:
```bash
find . -name '*.apk'
```
The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

Drag and drop this APK into your Android emulator to install and run.

#### iOS Build

After building with `./demo.sh build ios`, the app is located at:
```
build/ios/iphoneos/Runner.app
```

Open in Xcode or deploy to simulator/device.

**Important:** For readable stacktraces in Sentry, always use release builds with the `demo.sh` script, which ensures proper symbol file uploads and automatic release management.

### Running on iOS Simulator (manual)

For iOS, you can still use Xcode or the simulator, but symbolication may be limited unless you build and deploy a release build with symbols.

1. Open the project in Xcode or run:
   ```sh
   flutter run -d ios
   ```
2. If you see build errors, ensure CocoaPods are installed and run:
   ```sh
   cd ios && pod install && cd ..
   flutter clean && flutter pub get
   flutter run -d ios
   ```

### Running on Android Emulator (manual)

**Recommended:** Use the APK from the release build as described above for best Sentry stacktrace results.

## Sentry Instrumentation & Features

### Latest SDK Versions (Updated 2026)

- **sentry_flutter**: 9.10.0
- **sentry_dio**: 9.10.0
- **sentry_logging**: 9.10.0
- **sentry_file**: 9.10.0
- **sentry_dart_plugin**: 3.2.1

### Core Features

- **Sentry SDK Integration:**
  - Uses `sentry_flutter` for comprehensive Dart/Flutter error and performance monitoring
  - Initialized in `lib/sentry_setup.dart` with production-ready best practices
  - Credentials and environment loaded from `.env` or `sentry.properties`
  - Multi-platform support: iOS, Android, Web, macOS, Linux, Windows

- **Performance Monitoring:**
  - **TTFD (Time to Full Display)** tracking on all screens
  - **TTID (Time to Initial Display)** automatic tracking
  - User interaction tracing (taps, swipes, navigation)
  - HTTP request tracking via `SentryHttpClient` and Dio integration
  - Full transaction and span instrumentation
  - Custom performance metrics
  - Profiling enabled for iOS/macOS (`profilesSampleRate = 1.0`)

- **Session Replay:**
  - 100% error session replay capture
  - 100% normal session replay capture
  - High-quality screenshots

- **Error Tracking:**
  - Automatic error capture and reporting
  - Native crash handling (iOS, Android)
  - ANR (Application Not Responding) detection
  - Watchdog termination tracking
  - File I/O instrumentation via `sentry_file`

- **Error Tagging & Grouping:**
  - All events tagged with engineer identifier (`se` tag) from `lib/se_config.dart`
  - Custom fingerprinting for per-engineer grouping
  - Platform and device context automatically captured

- **User Feedback:**
  - Custom feedback dialog for Dart exceptions
  - Associated with specific error events
  - Native exception filtering

- **Attachments & Context:**
  - Screenshot capture on errors
  - View hierarchy attachments
  - Stack traces with full context
  - Breadcrumbs (navigation, user actions, HTTP)
  - Thread information

- **Structured Logging:**
  - Integration with Dart `logging` package
  - Automatic log capture and breadcrumbs
  - Configurable log levels

- **Debug Symbol Upload:**
  - Automated via `sentry_dart_plugin` 3.2.1
  - Configured through `sentry.properties` or `.env`
  - Source maps for web builds
  - Obfuscation map support for release builds

## Project Structure

- `lib/main.dart` — App entrypoint
- `lib/sentry_setup.dart` — Sentry initialization and configuration
- `lib/se_config.dart` — Engineer tag configuration
- `lib/navbar_destination.dart`, `lib/checkout.dart` — Demo error triggers and feedback

## Configuring Debug Symbol Upload

To enable automatic debug symbol uploads to Sentry:

1. **Copy the example configuration:**
   ```bash
   cp sentry.properties.example sentry.properties
   ```

2. **Edit `sentry.properties` with your values:**
   ```properties
   org=your-org-slug
   project=your-project-name
   auth_token=your-sentry-auth-token
   ```

3. **Create a Sentry auth token:**
   - Visit: https://sentry.io/settings/account/api/auth-tokens/
   - Required scopes: `project:releases` (or `project:write`), `org:read`

4. **Build with the script:**
   ```bash
   ./demo.sh build android
   ```

The script will automatically upload debug symbols after building.

**Note:** `sentry.properties` is in `.gitignore` to prevent committing secrets.

## Size Analysis (Optional)

Monitor your app's build size and detect regressions with Sentry's Size Analysis feature.

### Quick Setup

1. **Install Sentry CLI:**
   ```bash
   curl -sL https://sentry.io/get-cli/ | bash
   ```

2. **Add to .env:**
   ```bash
   SENTRY_ORG=your-org-slug
   SENTRY_PROJECT=your-project-slug
   SENTRY_SIZE_ANALYSIS_ENABLED=true
   ```

3. **Build and upload:**
   ```bash
   ./demo.sh build android
   ```

The script automatically uploads your builds for size analysis. View results at:
```
https://sentry.io/organizations/your-org/projects/your-project/size-analysis/
```

For detailed instructions, see [SIZE_ANALYSIS_GUIDE.md](SIZE_ANALYSIS_GUIDE.md).

## Testing the Application

### Test Error Tracking

Use the navigation drawer menu to trigger various error scenarios:
- **ANR** - Application Not Responding simulation
- **C++ Segfault** - Native crash
- **Kotlin Exception** - Platform exception
- **Dart Exception** - Flutter exception
- **Timeout Exception** - Async timeout
- **N+1 API Calls** - Performance issue demo

### Test TTFD Tracking

1. Navigate between screens (Home → Cart → Product Details → Checkout)
2. Check Sentry Performance tab to see TTID and TTFD metrics
3. Verify all screens report accurate timing data

### Test Session Replay

1. Trigger an error from the drawer menu
2. Check Sentry Issues to see the replay attached to the error
3. Review user interactions leading up to the error

## Platform-Specific Notes

### iOS/macOS
- Profiling is enabled on these platforms
- Watchdog termination tracking available
- Requires Xcode for building

### Android
- ANR detection enabled (5-second threshold)
- Native crash handling via NDK
- Supports obfuscation with symbol upload

### Web
- Source maps automatically generated and uploaded
- Requires `--source-maps` flag during build
- Debug IDs supported (SDK 9.1.0+)

### Desktop (Linux/Windows)
- Full error and performance tracking
- Platform-specific crash handling
- Build on respective platforms for best results

## Notes

- For production, adjust sampling rates in `lib/sentry_setup.dart`:
  - `sampleRate`: Error capture rate (currently 1.0 = 100%)
  - `tracesSampleRate`: Performance trace rate (currently 1.0 = 100%)
  - `replay.sessionSampleRate`: Normal session replay rate (currently 1.0 = 100%)
  - `replay.onErrorSampleRate`: Error session replay rate (currently 1.0 = 100%)
- Use `demo.sh` for automated builds with proper instrumentation and release management
- All configurations follow latest Sentry best practices (2026)

For more details, see [Sentry Flutter documentation](https://docs.sentry.io/platforms/flutter/).
