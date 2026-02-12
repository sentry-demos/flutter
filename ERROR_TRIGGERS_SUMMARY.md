# Error Triggers Implementation Summary

## Overview
Moved 10 error demonstrations from the navigation drawer to automatically trigger on app startup for realistic Sentry demo purposes.

## Changes Made

### 1. [lib/product_list.dart](lib/product_list.dart)

**Added Imports:**
```dart
import 'dart:async';
import 'package:flutter/services.dart';
```

**Added Method Channel:**
```dart
final channel = const MethodChannel('example.flutter.sentry.io');
```

**Added 10 Error Trigger Methods:**

1. **`_triggerCppSegfault()`** - Triggers native C++ segmentation fault
2. **`_triggerKotlinException()`** - Triggers Kotlin exception (Android only)
3. **`_triggerDartException()`** - Triggers generic Dart exception
4. **`_triggerTimeoutException()`** - Triggers timeout exception
5. **`_triggerPlatformException()`** - Triggers platform-specific exception
6. **`_triggerMissingPluginException()`** - Triggers missing plugin exception
7. **`_triggerAssertionError()`** - Triggers assertion error
8. **`_triggerStateError()`** - Triggers state error
9. **`_triggerRangeError()`** - Triggers range error
10. **`_triggerTypeError()`** - Triggers type error

**Updated initState():**
- Added `Future.microtask()` call to trigger all errors asynchronously after startup
- Errors are triggered in sequence without blocking the UI
- Kotlin Exception only triggers on Android platform

**Fixed File I/O Implementation:**
- Changed from `File('plant_cache.txt')` to `File('${tempDir.path}/plant_cache.txt')`
- Uses `Directory.systemTemp` for cross-platform compatibility
- Prevents "Read-only file system" errors on Android

### 2. [lib/navbar_destination.dart](lib/navbar_destination.dart)

**Removed 10 ListTile Widgets:**
- C++ Segfault
- Kotlin Exception
- Dart Exception
- Timeout Exception
- Platform Exception
- Missing Plugin Exception
- Assertion Error
- State Error
- Range Error
- Type Error

**Added Section Header:**
```dart
ListTile(
  title: Text('🔴 Error Demonstrations',
      style: TextStyle(fontWeight: FontWeight.bold)),
  subtitle: Text('10 error types trigger on app startup',
      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
  enabled: false,
),
```

**Kept in Navigation Drawer:**
- ANR (Android) - Manual trigger for Application Not Responding
- App Hang (iOS/macOS) - Manual trigger for app hang detection
- Performance Issues section remains as before

## Error Trigger Details

### Platform-Specific Behavior

| Error Type | Platform | Trigger Timing |
|------------|----------|----------------|
| C++ Segfault | All | App startup |
| Kotlin Exception | Android only | App startup |
| Dart Exception | All | App startup |
| Timeout Exception | All | App startup |
| Platform Exception | All | App startup |
| Missing Plugin Exception | All | App startup |
| Assertion Error | All | App startup |
| State Error | All | App startup |
| Range Error | All | App startup |
| Type Error | All | App startup |

### Error Transaction Naming

All errors use consistent transaction naming:
- Pattern: `startup.<error_type>`
- Examples:
  - `startup.cpp_segfault`
  - `startup.kotlin_exception`
  - `startup.dart_exception`

This makes it easy to filter and group errors in Sentry by the `startup.` prefix.

### Span Operations

Each error uses appropriate span operations:
- Native errors: `native.crash`, `native.exception`
- Dart errors: `dart.exception`, `dart.timeout`, `dart.assertion`, `dart.state`, `dart.range`, `dart.type`
- Platform errors: `platform.exception`, `plugin.exception`

## Verification

### Console Output (Android)
When the app starts, you should see in logcat:
```
I flutter : DB query completed on main thread, result: 1999999000000
I flutter : File I/O on main thread, size: 5500000
I flutter : JSON decoded 15000 items on main thread
E MethodChannel#example.flutter.sentry.io: java.lang.RuntimeException: Simulated Kotlin Exception from native code
```

### Expected Sentry Dashboard

After running the app, check Sentry for:

**Errors (10 types):**
1. C++ Segfault
2. Kotlin Exception (Android only)
3. Dart Exception
4. TimeoutException
5. PlatformException
6. MissingPluginException
7. AssertionError
8. StateError
9. RangeError
10. TypeError

**Performance Issues (3 types - already implemented):**
1. File I/O on Main Thread
2. Database on Main Thread
3. JSON Decoding on Main Thread

All should be associated with the `products.page_load` or `startup.*` transactions.

## Benefits for Demo

1. **Automatic**: Errors trigger without manual interaction
2. **Realistic**: Simulates real-world error scenarios
3. **Non-Blocking**: Uses `Future.microtask()` so UI loads normally
4. **Platform-Aware**: Kotlin exception only on Android
5. **Organized**: Clear separation between auto-triggered and manual triggers
6. **Traceable**: All errors use consistent naming and span operations

## Navigation Drawer Usage

The navigation drawer now contains:
- **Back** - Navigate back to home
- **🔴 Error Demonstrations** (header) - Indicates 10 errors auto-trigger
- **ANR (Android)** - Manual trigger to demonstrate ANR detection
- **App Hang (iOS/macOS)** - Manual trigger to demonstrate app hang detection
- **⚡ Performance Issues** (header) - Indicates 3 issues auto-trigger on startup
- **Image Decoding on Main Thread** - Manual trigger
- **Regex on Main Thread** - Manual trigger
- **N+1 API Calls** - Manual trigger
- **Frame Drop** - Manual trigger
- **Function Regression** - Manual trigger

## Technical Notes

### Why Future.microtask()?
- Prevents blocking the main thread during app initialization
- Allows UI to render normally while errors are captured
- Executes after the current synchronous code completes
- Ideal for triggering multiple async operations in sequence

### File I/O Fix
The original implementation used:
```dart
File('plant_cache.txt')
```

This failed on Android with "Read-only file system" because:
- Android apps have restricted write permissions
- Cannot write to app's root directory
- Must use proper cache or temp directories

The fix uses:
```dart
final tempDir = Directory.systemTemp;
final file = File('${tempDir.path}/plant_cache.txt')
```

This works across all platforms (Android, iOS, macOS, Linux, Windows).

## Related Files

- [PERFORMANCE_ISSUES_DEBUG.md](PERFORMANCE_ISSUES_DEBUG.md) - Performance issue detection troubleshooting
- [SENTRY_FEATURES.md](SENTRY_FEATURES.md) - Comprehensive Sentry features documentation
- [BUILD_GUIDE.md](BUILD_GUIDE.md) - Build instructions
