# Sentry Features - Complete Integration Guide

This document provides an overview of all Sentry features integrated into this Flutter application.

## Overview

This application demonstrates comprehensive Sentry integration with the latest SDK (9.13.0) and best practices for:
- ✅ Error & Exception Tracking
- ✅ Performance Monitoring (TTID, TTFD)
- ✅ Session Replay
- ✅ User Feedback
- ✅ Debug Symbol Upload
- ✅ **Size Analysis** (NEW)
- ✅ Multi-Platform Support

## Feature Matrix

| Feature | Status | Platforms | Configuration |
|---------|--------|-----------|---------------|
| **Error Tracking** | ✅ Enabled | All | Automatic |
| **Performance Monitoring** | ✅ Enabled | All | `tracesSampleRate: 1.0` |
| **TTID Tracking** | ✅ Enabled | Mobile | Automatic |
| **TTFD Tracking** | ✅ Enabled | Mobile | Manual reporting |
| **Session Replay** | ✅ Enabled | Mobile | `replay.sessionSampleRate: 1.0` |
| **Profiling** | ✅ Enabled | iOS/macOS | `profilesSampleRate: 1.0` |
| **User Feedback** | ✅ Enabled | All | Custom dialog |
| **Breadcrumbs** | ✅ Enabled | All | Automatic + Manual |
| **Screenshots** | ✅ Enabled | Mobile | `attachScreenshot: true` |
| **View Hierarchy** | ✅ Enabled | Mobile | `attachViewHierarchy: true` |
| **ANR Detection** | ✅ Enabled | Android | 5-second threshold |
| **Native Crashes** | ✅ Enabled | iOS/Android | NDK/Crashlytics |
| **HTTP Tracking** | ✅ Enabled | All | `SentryHttpClient` |
| **File I/O Tracking** | ✅ Enabled | All | `sentry_file` |
| **Structured Logging** | ✅ Enabled | All | `sentry_logging` |
| **Debug Symbols** | ✅ Enabled | Mobile | `sentry_dart_plugin` |
| **Size Analysis** | ⚙️ Optional | Mobile | `sentry-cli` |

## 1. Error & Exception Tracking

### What It Does
- Captures all unhandled exceptions
- Reports native crashes (iOS/Android)
- Tracks handled exceptions
- Groups similar errors automatically

### Configuration
```dart
// lib/sentry_setup.dart
options.sampleRate = 1.0; // 100% error capture
options.enableNativeCrashHandling = true;
options.reportSilentFlutterErrors = true;
```

### Usage
```dart
// Automatic capture
throw Exception('Something went wrong');

// Manual capture
try {
  riskyOperation();
} catch (error, stackTrace) {
  await Sentry.captureException(error, stackTrace: stackTrace);
}
```

### Demo Features
All error types are testable via the drawer menu:
- Dart exceptions
- Platform exceptions
- Timeout exceptions
- Native crashes (C++ segfault, Kotlin exception)
- ANR simulation

## 2. Performance Monitoring

### Time to Initial Display (TTID)
**Automatic** - Tracks time until first frame is rendered.

```dart
// Automatically captured by SentryNavigatorObserver
MaterialApp(
  navigatorObservers: [SentryNavigatorObserver()],
)
```

### Time to Full Display (TTFD)
**Manual** - Tracks time until all content is loaded.

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      SentryDisplayWidget.of(context).reportFullyDisplayed();
    }
  });
}
```

**Configured in:** [lib/main.dart](lib/main.dart), [lib/product_details.dart](lib/product_details.dart), [lib/checkout.dart](lib/checkout.dart), [lib/product_list.dart](lib/product_list.dart)

### Custom Transactions
```dart
final transaction = Sentry.startTransaction(
  'operation_name',
  'operation_type',
  bindToScope: true,
);

// Do work
await doSomething();

await transaction.finish(status: SpanStatus.ok());
```

### HTTP Tracking
```dart
// Automatic with SentryHttpClient
final client = SentryHttpClient();
await client.get(Uri.parse('https://api.example.com'));

// Automatic with Dio integration
final dio = Dio();
dio.addSentry();
```

## 3. Session Replay

### What It Does
- Records user sessions as video-like replays
- Captures interactions leading to errors
- Provides visual context for debugging

### Configuration
```dart
// lib/sentry_setup.dart
options.replay.onErrorSampleRate = 1.0; // 100% error sessions
options.replay.sessionSampleRate = 1.0; // 100% normal sessions
options.attachScreenshot = true;
options.screenshotQuality = SentryScreenshotQuality.high;
```

### How to View
1. Trigger any error from the drawer menu
2. Go to Sentry Issues
3. Click on the error
4. See "Replays" tab with recorded session

## 4. User Feedback

### What It Does
- Shows custom feedback dialog after errors
- Associates feedback with specific events
- Captures user descriptions of issues

### Implementation
```dart
// lib/sentry_setup.dart
void showUserFeedbackDialog(BuildContext context, SentryId eventId) async {
  // ... dialog implementation
  await Sentry.captureFeedback(
    SentryFeedback(
      message: description,
      associatedEventId: eventId,
      name: userName,
    ),
  );
}
```

### Demo
Trigger any Dart exception → Feedback dialog appears automatically

## 5. Debug Symbol Upload

### What It Does
- Uploads obfuscation maps for readable stack traces
- Uploads source files for source context
- Associates symbols with releases

### Configuration
**Via pubspec.yaml:**
```yaml
sentry:
  upload_debug_symbols: true
  upload_sources: true
  project: your-project
  org: your-org
```

**Via sentry.properties:**
```properties
org=your-org-slug
project=your-project-name
auth_token=your-auth-token
```

### Usage
```bash
# Automatic via build script
./demo.sh build android

# Manual upload
flutter pub run sentry_dart_plugin
```

**See:** [sentry.properties.example](sentry.properties.example)

## 6. Size Analysis (NEW)

### What It Does
- Monitors app build sizes over time
- Detects size regressions before release
- Provides size breakdown by component
- Tracks trends across builds

### Setup

1. **Install Sentry CLI:**
   ```bash
   curl -sL https://sentry.io/get-cli/ | bash
   ```

2. **Configure .env:**
   ```bash
   SENTRY_ORG=your-org-slug
   SENTRY_PROJECT=your-project-slug
   SENTRY_SIZE_ANALYSIS_ENABLED=true
   ```

3. **Build and upload:**
   ```bash
   ./demo.sh build android
   ```

### Supported Formats
- **Android:** APK, AAB
- **iOS:** IPA (requires manual archive)

### View Results
```
https://sentry.io/organizations/<org>/projects/<project>/size-analysis/
```

### Manual Upload
```bash
# Android
./demo.sh upload-size build/app/outputs/flutter-apk/app-release.apk android

# iOS
./demo.sh upload-size YourApp.ipa ios
```

**See:** [SIZE_ANALYSIS_GUIDE.md](SIZE_ANALYSIS_GUIDE.md)

## 7. Platform-Specific Features

### iOS/macOS
- ✅ Profiling enabled
- ✅ Watchdog termination tracking
- ✅ Native crash symbolication

```dart
if (Platform.isIOS || Platform.isMacOS) {
  options.profilesSampleRate = 1.0;
}
```

### Android
- ✅ ANR detection (5-second threshold)
- ✅ NDK crash handling
- ✅ Proguard/R8 symbol mapping

```dart
options.anrEnabled = true;
options.anrTimeoutInterval = const Duration(seconds: 5);
```

### Web
- ✅ Source maps for error reporting
- ✅ Debug IDs (SDK 9.1.0+)
- ✅ Breadcrumb tracking

### Desktop (Linux/Windows)
- ✅ Error tracking
- ✅ Performance monitoring
- ✅ Platform-specific crash handling

## 8. Breadcrumbs

### Automatic Breadcrumbs
- Navigation events
- User interactions (taps, swipes)
- HTTP requests
- Console logs
- Lifecycle events

### Manual Breadcrumbs
```dart
Sentry.addBreadcrumb(
  Breadcrumb(
    category: 'user.action',
    message: 'User clicked checkout',
    level: SentryLevel.info,
  ),
);
```

## 9. Context & Tagging

### Automatic Context
```dart
// lib/main.dart
Sentry.configureScope((scope) {
  scope.setTag('app.name', 'Empower Plant');
  scope.setTag('platform', 'flutter');
  scope.setTag('os', Platform.operatingSystem);
  // ... more tags
});
```

### User Context
```dart
Sentry.configureScope((scope) =>
  scope.setUser(SentryUser(id: email))
);
```

### Custom Context
```dart
transaction.setData('custom_key', 'custom_value');
span.setData('operation', 'database_query');
```

## Configuration Files

| File | Purpose |
|------|---------|
| [pubspec.yaml](pubspec.yaml) | Dependency versions, sentry_dart_plugin config |
| [lib/sentry_setup.dart](lib/sentry_setup.dart) | Main Sentry initialization |
| [.env](.env) | Runtime configuration (DSN, release, etc.) |
| [sentry.properties](sentry.properties) | Build-time configuration (symbols, size) |
| [demo.sh](demo.sh) | Unified build, run, and release management script |

## Build Scripts

| Script | Purpose |
|--------|---------|
| [demo.sh](demo.sh) | Multi-platform build with Sentry integration and release management |

## Documentation

| Document | Contents |
|----------|----------|
| [README.md](README.md) | Quick start and overview |
| [BUILD_GUIDE.md](BUILD_GUIDE.md) | Detailed build instructions |
| [SIZE_ANALYSIS_GUIDE.md](SIZE_ANALYSIS_GUIDE.md) | Size monitoring setup |
| [SENTRY_FEATURES.md](SENTRY_FEATURES.md) | This document |

## Testing Checklist

### Error Tracking
- [ ] Test Dart exception (drawer menu)
- [ ] Test platform exception
- [ ] Test timeout exception
- [ ] Test native crash (C++/Kotlin)
- [ ] Test ANR simulation
- [ ] Verify errors appear in Sentry Issues
- [ ] Check stack traces are readable

### Performance Monitoring
- [ ] Navigate between screens
- [ ] Check TTID metrics in Sentry Performance
- [ ] Check TTFD metrics for all screens
- [ ] Verify HTTP requests are tracked
- [ ] Test N+1 API calls demo

### Session Replay
- [ ] Trigger an error
- [ ] View replay in Sentry
- [ ] Verify interactions are captured
- [ ] Check screenshot quality

### User Feedback
- [ ] Trigger Dart exception
- [ ] Submit feedback via dialog
- [ ] Verify feedback in Sentry

### Size Analysis
- [ ] Enable size analysis
- [ ] Build release
- [ ] Verify upload success
- [ ] View size dashboard
- [ ] Check trend data

## Production Checklist

Before deploying to production:

- [ ] Adjust sampling rates in [lib/sentry_setup.dart](lib/sentry_setup.dart):
  - `sampleRate`: Consider 0.1-1.0 (10-100%)
  - `tracesSampleRate`: Consider 0.1-0.5 (10-50%)
  - `replay.sessionSampleRate`: Consider 0.01-0.1 (1-10%)
  - `replay.onErrorSampleRate`: Keep at 1.0 (100%)
  - `profilesSampleRate`: Consider 0.1-0.5 (10-50%)

- [ ] Configure proper release versioning
- [ ] Set up alerts for critical errors
- [ ] Enable size analysis in CI/CD
- [ ] Test on all target platforms
- [ ] Verify symbol upload in production builds
- [ ] Review privacy settings (`sendDefaultPii`)

## Resources

- [Sentry Flutter Documentation](https://docs.sentry.io/platforms/flutter/)
- [Sentry Size Analysis](https://docs.sentry.io/product/insights/size-analysis/)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf)
- [GitHub: sentry-dart](https://github.com/getsentry/sentry-dart)

## Support

For issues or questions:
- [GitHub Issues](https://github.com/getsentry/sentry-dart/issues)
- [Sentry Discord](https://discord.gg/sentry)
- [Sentry Documentation](https://docs.sentry.io/)
