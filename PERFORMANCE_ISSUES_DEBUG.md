# Performance Issues Detection Troubleshooting

## Problem
Performance issues were not being detected in Sentry despite spans being created and visible in the transaction waterfall.

## Root Cause Analysis

### Why Detection Failed
Sentry's performance issue detection requires **specific span operation names** and proper instrumentation. The operations were executing, but Sentry couldn't recognize them as performance issues because:

1. **Missing Span Wrappers**: Operations were running without being wrapped in Sentry spans with the correct operation names
2. **Incorrect Operation Names**: Generic operations like 'task' or 'computation' won't trigger detection
3. **Threshold Not Met**: Computation wasn't heavy enough to exceed detection thresholds
4. **Missing Transaction Context**: Spans weren't children of an active transaction

### Detection Requirements by Issue Type

#### File I/O on Main Thread
- **Required**: `file.write` or `file.read` span operation
- **Threshold**: >16ms non-overlapping duration
- **Implementation**: Use `sentry_file` package with `.sentryTrace()` extension
  ```dart
  final file = File('plant_cache.txt').sentryTrace();
  final span = transaction.startChild('file.write', description: '...');
  file.writeAsStringSync(data);
  span.finish();
  ```

#### Database on Main Thread
- **Required**: `db.sql.query` span operation
- **Threshold**: >16ms non-overlapping duration
- **Implementation**:
  ```dart
  final span = transaction.startChild('db.sql.query', description: 'SELECT * FROM products WHERE active = 1');
  span.setData('db.system', 'sqlite');
  // Perform operation
  span.finish();
  ```

#### JSON Decoding on Main Thread
- **Required**: `json.decode` span operation
- **Threshold**: >40ms (needs ~4 profiler samples at 10ms intervals)
- **Requires**: Profiling enabled (`profilesSampleRate > 0`)
- **Implementation**:
  ```dart
  final span = transaction.startChild('json.decode', description: 'Decode cached products JSON');
  final decoded = jsonDecode(largeJson);
  span.finish();
  ```

#### N+1 API Calls
- **Required**: 10+ GET requests with `http.client` operation
- **Threshold**: Within 5ms of each other, >300ms total
- **Implementation**: Use `SentryHttpClient` which automatically adds proper operations

## Solution Implemented

### Changes Made to [product_list.dart](lib/product_list.dart)

1. **Added Imports**:
   ```dart
   import 'package:sentry_file/sentry_file.dart';
   ```

2. **Created `_performDatabaseQuery()` Method** (lines 80-98):
   - Uses proper `db.sql.query` operation
   - Increased to 2,000,000 iterations to ensure >16ms duration
   - Added `db.system` metadata

3. **Created `_performFileIO()` Method** (lines 102-129):
   - Uses `.sentryTrace()` extension from `sentry_file`
   - Uses proper `file.write` and `file.read` operations
   - Writes 500,000 "Plant data " strings to ensure >16ms

4. **Created `_performJSONDecoding()` Method** (lines 132-158):
   - Uses proper `json.decode` operation
   - Creates 15,000 objects to ensure >40ms for profiler detection
   - Wrapped in transaction span

5. **Updated initState()** (lines 45-76):
   - Calls all three performance issue methods on app startup
   - Ensures all spans are children of `products.page_load` transaction

### Configuration Changes

Profiling was enabled for all platforms in [sentry_setup.dart](lib/sentry_setup.dart:70):
```dart
options.profilesSampleRate = 1.0;
```
This is **required** for JSON Decoding, Image Decoding, and Frame Drop detection.

## Verification

After implementing these changes, check Sentry for:

1. **File I/O on Main Thread** issue - Should appear immediately on app load
2. **Database on Main Thread** issue - Should appear immediately on app load
3. **JSON Decoding on Main Thread** issue - Should appear immediately on app load (requires profiling)

Each should show:
- The specific span with duration >16ms (or >40ms for JSON)
- Proper operation name in the span
- Associated with the `products.page_load` transaction

## Key Learnings

1. **Operation Names Matter**: Generic span operations won't trigger detection
2. **Thresholds Must Be Exceeded**: The computation must actually take longer than the threshold
3. **Profiling Required**: Some issues (JSON, Image, Frame Drop) require profiling enabled
4. **Transaction Context**: All performance issue spans must be children of an active transaction
5. **Use Official Integrations**: `sentry_file`, `SentryHttpClient`, etc. automatically use correct operations
