# Empower Plant - Flutter Sentry Demo Application

## Project Overview

**Application:** Empower Plant (`empower_flutter`)
**Version:** 9.13.0+1 (matches Sentry SDK version)
**Purpose:** Production-ready Flutter e-commerce app with comprehensive Sentry instrumentation demonstrating best practices for error monitoring, performance tracking, session replay, and user feedback.

**Type:** Full-featured plant shopping app + Sentry demo platform
**Platforms:** iOS, Android, Web, macOS, Linux, Windows

---

## Critical Information

### Branch & Git Status
- **Current Branch:** `feature/comprehensive-sentry-integration`
- **Main Branch:** `main`
- **Latest Commit:** `bf17e76` - Refactor TTFD tracking to use SentryDisplayWidget strategically

### Environment Configuration
- Secrets in `.env` (git-ignored, based on `.env.example`)
- Engineer ID in `lib/se_config.dart` for event separation
- Sentry config: DSN, ORG, PROJECT, AUTH_TOKEN required

### Version Management
- **Format:** `package@version+build` (e.g., `com.example.empower_flutter@9.13.0+1`)
- Version source: `pubspec.yaml`
- Must match Sentry SDK version for consistency
- Distribution set to build number (currently `'1'`)

---

## Architecture Overview

### Directory Structure
```
lib/
├── main.dart                    # Entry point, home page, global setup
├── sentry_setup.dart            # Comprehensive Sentry init (280+ lines)
├── se_config.dart               # Engineer identifier
├── navbar_destination.dart      # Navigation drawer + error triggers
├── product_list.dart            # Home screen, catalog, demo triggers (750+ lines)
├── product_details.dart         # Product detail view
├── cart.dart                    # Shopping cart
├── checkout.dart                # Checkout flow with metrics/logging
└── models/
    └── cart_state_model.dart    # Provider-based cart state

assets/
├── images/                      # Plant product images
├── config/                      # Feature configuration JSONs
└── docs/                        # Dummy documentation files

demo.sh                          # Unified build script for all platforms
```

### Key Files & Purposes

| File | Lines | Purpose |
|------|-------|---------|
| `lib/main.dart` | ~500 | App initialization, home page, navigation, TTFD setup |
| `lib/sentry_setup.dart` | 280+ | Complete Sentry configuration, all features enabled |
| `lib/product_list.dart` | 750+ | Product catalog, API fetching, error/perf triggers |
| `lib/checkout.dart` | ~500 | Checkout flow, metrics, structured logging |
| `demo.sh` | ~940 | Build automation, release management, symbol upload |

---

## Technology Stack

### Core Dependencies
```yaml
Flutter SDK: >= 3.22.0 < 4.0.0
Dart SDK: >= 3.5.0 < 4.0.0

# Sentry
sentry_flutter: ^9.13.0          # Main SDK
sentry_dio: ^9.13.0              # HTTP client integration
sentry_file: ^9.13.0             # File I/O tracking
sentry_logging: ^9.13.0          # Logging integration

# State Management & Utils
provider: ^6.1.5                 # State management
flutter_dotenv: ^6.0.0           # Environment variables
dio: ^5.9.1                      # HTTP client
logging: ^1.3.0                  # Structured logging
```

### External Services
- **Backend API:** `https://flask.empower-plant.com/` (products, checkout)
- **Sentry:** Error monitoring, performance, session replay
- **Sentry CLI:** Optional for symbol upload and size analysis

---

## Sentry Integration - Complete Reference

### Initialization Flow
1. `SentryWidgetsFlutterBinding.ensureInitialized()` - Set up bindings
2. `dotenv.load()` - Load environment variables
3. `initSentry()` - Full Sentry initialization from `sentry_setup.dart`
4. Global scope tags: app name, platform, OS, locale, screen size

### Configuration - All Features Enabled (Demo Mode)

```dart
// Sampling (100% for demo)
sampleRate: 1.0                         # All errors captured
tracesSampleRate: 1.0                   # All performance traces
profilesSampleRate: 1.0                 # All profiling (iOS/macOS/Android)

// Session Replay (100% for demo)
replay.onErrorSampleRate: 1.0           # All error sessions
replay.sessionSampleRate: 1.0           # All normal sessions

// Performance Tracking
enableAutoPerformanceTracing: true      # Automatic spans
enableTimeToFullDisplayTracing: true    # TTFD/TTID tracking
enableUserInteractionTracing: true      # Tap/swipe tracking
enableUserInteractionBreadcrumbs: true  # User action breadcrumbs

// Attachments
attachStacktrace: true                  # Stack traces on all events
attachScreenshot: false                 # Disabled for demo
attachViewHierarchy: true               # UI hierarchy
attachThreads: true                     # Thread info

// Crash Handling
enableNativeCrashHandling: true         # Native crash capture
enableNdkScopeSync: true                # Android NDK scope sync
reportSilentFlutterErrors: true         # Report ErrorWidget errors
anrEnabled: true                        # Android ANR detection (5s)
anrTimeoutInterval: Duration(seconds: 5)
appHangTimeoutInterval: Duration(seconds: 2)  # iOS/macOS hang detection
enableWatchdogTerminationTracking: true # iOS/macOS watchdog

// Logging & Metrics
enableLogs: true                        # Structured logs to Sentry
enableMetrics: true                     # Custom metrics support
maxBreadcrumbs: 100                     # Breadcrumb limit
enableAutoNativeBreadcrumbs: true       # Native breadcrumbs

// Privacy (Demo settings)
sendDefaultPii: true                    # Send PII for demo environment
```

### Custom Hooks & Privacy

**beforeSend Hook:**
- Adds `se` tag from engineer config for per-developer separation
- Sets fingerprint: `['{{ default }}', 'se:$se']`

**Session Replay Privacy Masking:**
- Masks Text widgets containing BOTH a financial label AND dollar sign
- Financial labels: `items (`, `shipping & handling`, `total before tax`, `estimated tax`, `order total`, `subtotal`
- Ensures labels remain visible, only values with $ are masked
- Everything else in replays is visible

### Integrations Enabled

1. **SentryNavigatorObserver** - Navigation tracking, automatic TTID
2. **SentryHttpClient** - HTTP request tracing
3. **SentryDio** - Dio HTTP client integration (`dio.addSentry()`)
4. **SentryFile** - File I/O instrumentation (`.sentryTrace()`)
5. **LoggingIntegration** - Captures `Logger()` calls as breadcrumbs/events
6. **Spotlight** - Local debugging UI (enabled in `kDebugMode`)

### TTFD/TTID Implementation

**TTID (Time to Initial Display):**
- Automatic via `SentryNavigatorObserver`
- Triggered when route becomes visible

**TTFD (Time to Full Display):**
- Manual via `SentryDisplayWidget.of(context).reportFullyDisplayed()`
- Wrap screen in `SentryDisplayWidget` widget
- Call `reportFullyDisplayed()` when content is fully loaded
- Currently implemented on home page product list

### Engineer Separation Pattern

- Each developer sets their name in `lib/se_config.dart`: `const se = 'your-name';`
- Added as tag on all events: `se: your-name`
- Added to fingerprint for per-engineer issue grouping
- Allows multiple engineers to use same Sentry project without interference

---

## Code Patterns & Conventions

### State Management
- **Pattern:** Provider with `ChangeNotifier`
- **Cart State:** `CartModel` extends `ChangeNotifier`
- **UI Updates:** `Consumer<CartModel>` for reactive updates
- **Global Keys:** `navigatorKey` for programmatic navigation

### Navigation
- **Named Routes:** `/productDetails`, `/checkout`
- **Arguments:** Custom classes (`ProductArguments`, `CheckoutArguments`)
- **Observer:** `SentryNavigatorObserver` tracks all navigation

### Error Handling
```dart
try {
  // Operation
} catch (error, stackTrace) {
  await Sentry.captureException(error, stackTrace: stackTrace);
  // Show user feedback dialog if needed
}
```

### Performance Instrumentation
```dart
// Transaction
final transaction = Sentry.startTransaction('operation_name', 'operation_type');

// Span
final span = transaction.startChild('child_operation', description: 'Details');
// ... work ...
await span.finish();

await transaction.finish(status: SpanStatus.ok());
```

### Structured Logging
```dart
// Setup
final log = Logger('ComponentName');

// Usage with Sentry.logger.fmt (captures to Sentry)
Sentry.logger.fmt.info('User %s clicked button', [userId],
  attributes: {
    'user_id': SentryLogAttribute.string(userId),
    'button_name': SentryLogAttribute.string('checkout'),
  }
);

// Standard logging (captured as breadcrumbs via LoggingIntegration)
log.info('Standard log message');
log.severe('Error occurred', error, stackTrace);
```

### Metrics
```dart
// Counter
Sentry.metrics.count('promo_code_attempts', 1,
  attributes: {'code': code, 'result': 'failed'}
);

// Gauge (current value)
Sentry.metrics.gauge('order_value', total,
  unit: SentryMetricUnit.none
);

// Distribution (statistical measurement)
Sentry.metrics.distribution('api_latency', latencyMs,
  unit: SentryMetricUnit.millisecond
);
```

### HTTP Requests
```dart
// Dio integration (automatic tracing)
final dio = Dio();
dio.addSentry();  // Done in sentry_setup.dart

// SentryHttpClient (automatic tracing)
final client = SentryHttpClient();
await client.get(Uri.parse('https://example.com'));
```

---

## Build System - demo.sh

### Commands

```bash
# Build for platform (default: release)
./demo.sh build [platform] [build-type]

# Run on device and create Sentry deploy
./demo.sh run [platform]

# Verify setup (Flutter, Sentry CLI, .env)
./demo.sh verify

# Show help
./demo.sh help
```

### Supported Platforms

| Platform | Command | Output Location |
|----------|---------|-----------------|
| Android APK | `./demo.sh build android` | `build/app/outputs/flutter-apk/app-release.apk` |
| Android AAB | `./demo.sh build aab` | `build/app/outputs/bundle/release/app-release.aab` |
| iOS | `./demo.sh build ios` | `build/ios/iphoneos/Runner.app` |
| Web | `./demo.sh build web` | `build/web/` |
| macOS | `./demo.sh build macos` | `build/macos/Build/Products/Release/` |
| Linux | `./demo.sh build linux` | `build/linux/x64/release/bundle/` |
| Windows | `./demo.sh build windows` | `build/windows/x64/runner/Release/` |

### Build Types
- `release` (default) - Obfuscation, symbol upload, release management
- `profile` - No obfuscation, no release management
- `debug` - No obfuscation, no release management

### Build Process (Release Mode)

1. Validates environment (.env variables)
2. Checks Flutter and Sentry CLI installation
3. Runs `flutter pub get`
4. Builds with obfuscation and debug symbol generation
5. Creates Sentry release: `sentry-cli releases new`
6. Uploads debug symbols and source maps
7. (Optional) Uploads ProGuard mapping for Android
8. (Optional) Uploads build for size analysis
9. Finalizes release: `sentry-cli releases finalize`

### Environment Variables Required

```bash
SENTRY_AUTH_TOKEN=sntryu_xxx              # Sentry auth token
SENTRY_DSN=https://xxx@xxx.ingest.sentry.io/xxx
SENTRY_RELEASE=com.example.empower_flutter@9.13.0+1
SENTRY_ENVIRONMENT=development            # development/staging/production
SENTRY_ORG=your-org-slug
SENTRY_PROJECT=your-project-slug
SENTRY_SIZE_ANALYSIS_ENABLED=true         # Optional: enable size tracking
```

---

## Demo Features & Error Triggers

### Available Error Types (via Drawer Menu)

**Dart Errors:**
- Dart Exception - Simple throw
- Timeout Exception - Simulated timeout
- Platform Exception - Native communication error
- Missing Plugin Exception - Plugin not found
- Assertion Error - Failed assertion
- State Error - Invalid state
- Range Error - Out of bounds
- Type Error - Type mismatch

**Native Errors:**
- C++ Segfault - Native crash via method channel
- Kotlin Exception - Android-only native exception

### Performance Issues (Auto-triggered on Home)

**Main Thread Blocking:**
- Database query simulation (2M iterations)
- File I/O on main thread
- JSON decoding (15k items)
- Image decoding on main thread
- Complex regex operations

**Async Issues:**
- N+1 API calls (15 sequential requests)
- Function regression (500ms delay)
- Frame drops (rapid setState calls)

**ANR/Hangs:**
- Android ANR: 10-second freeze
- iOS/macOS App Hang: 3-second freeze

### Checkout Flow Instrumentation

- Promo code validation with metrics
- API latency tracking with distributions
- Structured logging with attributes
- Order value gauge metrics
- User feedback collection on errors

---

## Development Workflow

### Initial Setup

1. Clone repository
2. Copy `.env.example` to `.env`
3. Fill in Sentry credentials (DSN, ORG, PROJECT, AUTH_TOKEN)
4. Update engineer name in `lib/se_config.dart`
5. Run `./demo.sh verify` to check configuration
6. Run `./demo.sh build android` (or your target platform)

### Daily Development

```bash
# Get dependencies
flutter pub get

# Run in debug mode (no Sentry release management)
flutter run -d <device-id>

# Verify code quality
flutter analyze

# Build for testing
./demo.sh build android debug

# Build and run with release management
./demo.sh build android
./demo.sh run android
```

### Testing Sentry Features

1. **Error Tracking:** Use drawer menu to trigger errors
2. **Performance:** Navigate app, check Performance tab in Sentry
3. **Session Replay:** Perform actions, check replay in Sentry Issues
4. **TTFD:** Navigate to home, wait for products to load
5. **Metrics:** Complete checkout flow, check Metrics in Sentry
6. **Logs:** Check Logs section in Sentry Issues
7. **Spotlight:** Run in debug mode, visit `http://localhost:8969` for local Sentry events

### Common Tasks

**Update Version:**
1. Edit `pubspec.yaml` - change version
2. Update `.env` - change `SENTRY_RELEASE`
3. Commit changes
4. Build: `./demo.sh build android`

**Add New Error Trigger:**
1. Add method in `navbar_destination.dart`
2. Add drawer item with trigger
3. Implement error scenario
4. Use `Sentry.captureException()` to capture

**Add Performance Instrumentation:**
1. Start transaction: `Sentry.startTransaction()`
2. Add spans for sub-operations
3. Finish with appropriate status
4. Add metrics if needed

---

## Important Conventions

### File Editing
- **NEVER** use Bash commands for file operations (cat, sed, awk, echo)
- **ALWAYS** use dedicated tools: Read, Edit, Write for files
- **NEVER** run `grep` or `find` commands - use Grep and Glob tools

### Git Workflow
- **Check with user** before destructive operations (force push, reset --hard, etc.)
- **Create NEW commits** after hook failures (not amend)
- **Add files by name** when staging, avoid `git add -A`
- **Never skip hooks** (--no-verify) unless explicitly requested

### Code Style
- Follow `analysis_options.yaml` linting rules
- Keep functions focused and single-purpose
- Use meaningful variable names
- Add comments only where logic isn't self-evident
- Don't add features beyond what's requested

### Sentry Best Practices
- Set `se` tag consistently from `se_config.dart`
- Use structured logging with attributes for searchability
- Add context to transactions with tags/data
- Use appropriate span operations for clarity
- Capture user feedback on critical errors

---

## Size Analysis (Optional Feature)

**Purpose:** Track APK/AAB file size over time in Sentry

**Enable:**
```bash
# In .env
SENTRY_SIZE_ANALYSIS_ENABLED=true
```

**Requirements:**
- Sentry CLI installed (`brew install sentry-cli`)
- Auth token configured
- Release build (not debug/profile)

**Automatic Uploads:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- ProGuard mapping: `build/app/outputs/mapping/release/mapping.txt`

**Disable:** Set to `false` or comment out in `.env` for faster local builds

---

## Troubleshooting

### Build Fails
- Run `./demo.sh verify` to check setup
- Ensure `.env` exists with valid credentials
- Check Flutter installation: `flutter doctor`
- Clean build: `flutter clean && flutter pub get`

### Sentry Events Not Appearing
- Verify DSN in `.env`
- Check Sentry project settings
- Verify sampling rates (should be 1.0 for demo)
- Check Spotlight in debug mode: `http://localhost:8969`

### Symbol Upload Fails
- Verify `SENTRY_AUTH_TOKEN` has upload permissions
- Check `SENTRY_ORG` and `SENTRY_PROJECT` are correct
- Ensure release was created before symbol upload

### TTFD Not Working
- Ensure screen is wrapped in `SentryDisplayWidget`
- Call `reportFullyDisplayed()` when content is ready
- Check that `enableTimeToFullDisplayTracing = true`

---

## Quick Reference

### Key URLs
- **Backend API:** `https://flask.empower-plant.com/`
- **Spotlight (Debug):** `http://localhost:8969/`
- **GitHub (Sentry SDK):** `https://github.com/getsentry/sentry-dart`

### Important Version Numbers
- **App Version:** 9.13.0+1
- **Flutter SDK:** >= 3.22.0
- **Sentry SDK:** ^9.13.0

### File Locations
- **Config:** `.env`, `lib/se_config.dart`, `pubspec.yaml`
- **Sentry Setup:** `lib/sentry_setup.dart`
- **Build Output:** `build/` directory
- **Debug Symbols:** `build/debug-info/`, `build/app/obfuscation.map.json`

---

*Last Updated: Session creating this CLAUDE.md*
*Current Branch: feature/comprehensive-sentry-integration*
*App Version: 9.13.0+1*
