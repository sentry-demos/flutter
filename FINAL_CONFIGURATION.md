# Final Sentry Demo Configuration

## Overview
The Flutter app is now configured to automatically trigger all Sentry error and performance demonstrations on app startup, with only ANR (Android) and App Hang (iOS/macOS) remaining as manual triggers.

## Automatic Triggers on App Startup

### Performance Issues (8 total)
Triggered synchronously on main thread during `products.page_load`:
1. **Database Query on Main Thread** - 2M iterations, >16ms
2. **File I/O on Main Thread** - 500K string writes, >16ms
3. **JSON Decoding on Main Thread** - 15K objects, >40ms

Triggered asynchronously after startup:
4. **Image Decoding on Main Thread** - 1M element array processing
5. **Regex on Main Thread** - Complex pattern matching on 10K strings
6. **N+1 API Calls** - 15 sequential GET requests
7. **Frame Drop** - 5 iterations of 20ms blocking
8. **Function Regression** - 500ms simulated slow function

### Error Demonstrations (10 total)
All triggered asynchronously after startup:
1. **C++ Segfault** - Native crash via method channel
2. **Kotlin Exception** (Android only) - Native Kotlin exception
3. **Dart Exception** - Generic Exception throw
4. **Timeout Exception** - TimeoutException with 2s duration
5. **Platform Exception** - PlatformException with PLATFORM_ERROR code
6. **Missing Plugin Exception** - MissingPluginException
7. **Assertion Error** - Failed assert(false)
8. **State Error** - StateError throw
9. **Range Error** - RangeError throw
10. **Type Error** - TypeError throw

## Navigation Drawer Contents

The drawer now contains only manual triggers:

### All Platforms
- **Back** - Navigate back to home

### Android Only
- **ANR (Android)** - Blocks main thread for 10 seconds to trigger Application Not Responding

### iOS/macOS Only
- **App Hang (iOS/macOS)** - Blocks main thread for 3 seconds to trigger App Hang detection

## Transaction Naming Convention

All automatic triggers use consistent naming:

**Performance Issues:**
- Synchronous: Part of `products.page_load` transaction
- Asynchronous: `startup.<type>_main_thread` or `startup.<type>`

**Error Demonstrations:**
- All use: `startup.<error_type>`

Examples:
- `startup.cpp_segfault`
- `startup.kotlin_exception`
- `startup.dart_exception`
- `startup.image_decode_main_thread`
- `startup.n_plus_one_api_calls`

## File Changes

### [lib/product_list.dart](lib/product_list.dart)

**Added Methods (15 total):**
- `_performDatabaseQuery()` - Synchronous DB simulation
- `_performFileIO()` - Synchronous file operations
- `_performJSONDecoding()` - Synchronous JSON parsing
- `_triggerCppSegfault()` - C++ crash trigger
- `_triggerKotlinException()` - Kotlin exception (Android only)
- `_triggerDartException()` - Dart exception
- `_triggerTimeoutException()` - Timeout error
- `_triggerPlatformException()` - Platform error
- `_triggerMissingPluginException()` - Missing plugin error
- `_triggerAssertionError()` - Assertion failure
- `_triggerStateError()` - State error
- `_triggerRangeError()` - Range error
- `_triggerTypeError()` - Type error
- `_triggerImageDecoding()` - Image decode simulation
- `_triggerRegex()` - Regex processing
- `_triggerNPlusOneAPICalls()` - Sequential API calls
- `_triggerFrameDrop()` - Frame dropping simulation
- `_triggerFunctionRegression()` - Slow function simulation

**Updated initState():**
```dart
@override
void initState() {
  super.initState();

  // Set user context
  final email = getRandomEmail();
  Sentry.configureScope((scope) => scope.setUser(SentryUser(id: email)));

  // Start page load transaction
  final transaction = Sentry.startTransaction(
    'products.page_load',
    'ui.load',
    bindToScope: true,
  );

  // PERFORMANCE ISSUES (synchronous - block main thread)
  _performDatabaseQuery(transaction);
  _performFileIO(transaction);
  _performJSONDecoding(transaction);

  // ERROR DEMONSTRATIONS (asynchronous - don't block UI)
  Future.microtask(() async {
    await _triggerCppSegfault();
    await _triggerKotlinException(); // Android only
    await _triggerDartException();
    await _triggerTimeoutException();
    await _triggerPlatformException();
    await _triggerMissingPluginException();
    await _triggerAssertionError();
    await _triggerStateError();
    await _triggerRangeError();
    await _triggerTypeError();
  });

  // ADDITIONAL PERFORMANCE ISSUES (asynchronous)
  Future.microtask(() async {
    await _triggerImageDecoding();
    await _triggerRegex();
    await _triggerNPlusOneAPICalls();
    await _triggerFrameDrop();
    await _triggerFunctionRegression();
  });

  // Fetch products from API
  shopItems = fetchShopItems()...
}
```

### [lib/navbar_destination.dart](lib/navbar_destination.dart)

**Removed:**
- "🔴 Error Demonstrations" header
- "⚡ Performance Issues" header
- All 5 performance issue ListTiles (Image Decoding, Regex, N+1 API, Frame Drop, Function Regression)

**Kept:**
- Back navigation
- ANR (Android) manual trigger
- App Hang (iOS/macOS) manual trigger

## Expected Sentry Dashboard Results

### Issues Tab

**Performance Issues (8):**
1. File I/O on Main Thread
2. Database on Main Thread
3. JSON Decoding on Main Thread
4. Image Decoding on Main Thread (if detected by profiler)
5. Regex on Main Thread (if detected)
6. N+1 API Calls
7. Frame Drop (if detected by profiler)
8. Function Regression (if detected)

**Errors (10 on Android, 9 on iOS/macOS):**
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

### Transactions Tab

**Main Transaction:**
- `products.page_load` - Contains DB, File I/O, and JSON spans

**Error Transactions:**
- `startup.cpp_segfault`
- `startup.kotlin_exception`
- `startup.dart_exception`
- `startup.timeout_exception`
- `startup.platform_exception`
- `startup.missing_plugin_exception`
- `startup.assertion_error`
- `startup.state_error`
- `startup.range_error`
- `startup.type_error`

**Performance Transactions:**
- `startup.image_decode_main_thread`
- `startup.regex_main_thread`
- `startup.n_plus_one_api_calls`
- `startup.frame_drop`
- `startup.function_regression`

## User Experience

1. **App Opens** - User sees product list loading
2. **Immediately** - 3 performance issues trigger on main thread (DB, File I/O, JSON)
3. **Within 1-2 seconds** - 10 errors trigger in sequence
4. **Within 3-5 seconds** - 5 additional performance issues trigger
5. **All captured** - Sentry receives all 18 demonstrations automatically

## Manual Testing (Optional)

Users can still manually trigger:
- **ANR** - Open drawer, tap "ANR (Android)" on Android devices
- **App Hang** - Open drawer, tap "App Hang (iOS/macOS)" on iOS/macOS devices

## Benefits

1. **Fully Automated** - No user interaction needed for demo
2. **Comprehensive** - 18 total Sentry features demonstrated
3. **Non-Blocking** - App remains responsive during demonstrations
4. **Platform-Aware** - Kotlin exception only on Android
5. **Clean UI** - Navigation drawer simplified to essential manual triggers only
6. **Easy to Find** - All issues use consistent `startup.*` naming convention

## Technical Notes

### Why Two Future.microtask() Calls?

Errors and additional performance issues are split into two separate microtasks:
1. **First microtask** - All 10 error demonstrations
2. **Second microtask** - 5 additional performance issues

This separation allows:
- Errors to complete before starting performance-heavy operations
- Better organization in the codebase
- Easier debugging and maintenance

### File I/O Path

Uses `Directory.systemTemp` for cross-platform compatibility:
```dart
final tempDir = Directory.systemTemp;
final file = File('${tempDir.path}/plant_cache.txt').sentryTrace();
```

This ensures the app can write files on all platforms (Android, iOS, macOS, etc.) without permission errors.

### Platform Check for Kotlin Exception

```dart
if (!Platform.isAndroid) return;
```

The Kotlin exception method exits immediately on non-Android platforms to prevent method channel errors.

## Verification Commands

Check Android logs after app launches:
```bash
adb logcat | grep -E "flutter : (DB query|File I/O|JSON decoded|startup)"
```

Expected output:
```
I flutter : DB query completed on main thread, result: 1999999000000
I flutter : File I/O on main thread, size: 5500000
I flutter : JSON decoded 15000 items on main thread
E MethodChannel#example.flutter.sentry.io: java.lang.RuntimeException: Simulated Kotlin Exception from native code
```

## Related Documentation

- [ERROR_TRIGGERS_SUMMARY.md](ERROR_TRIGGERS_SUMMARY.md) - Initial error triggers implementation
- [PERFORMANCE_ISSUES_DEBUG.md](PERFORMANCE_ISSUES_DEBUG.md) - Performance issue detection troubleshooting
- [SENTRY_FEATURES.md](SENTRY_FEATURES.md) - Comprehensive Sentry features documentation
- [BUILD_GUIDE.md](BUILD_GUIDE.md) - Build and deployment instructions
