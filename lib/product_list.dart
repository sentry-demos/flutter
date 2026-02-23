import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/cart_state_model.dart';
import 'product_details.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_file/sentry_file.dart';
import 'dart:io';
import 'se_config.dart';
// ignore: depend_on_referenced_packages

class ItemsList extends StatefulWidget {
  const ItemsList({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ItemListState createState() => _ItemListState();
}

class _ItemListState extends State<ItemsList> {
  final String _uri = 'https://flask.empower-plant.com/products';
  late Future<ResponseData> shopItems;

  var client = SentryHttpClient();
  final channel = const MethodChannel('example.flutter.sentry.io');

  Future<ResponseData> fetchShopItems() async {
    try {
      final response = await client.get(Uri.parse(_uri));
      // Simulate full response processing
      final data = ResponseData.fromJson((jsonDecode(response.body)));
      return data;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();

    final email = getRandomEmail();
    Sentry.configureScope((scope) => scope.setUser(SentryUser(id: email)));

    // PERFORMANCE ISSUES (triggered synchronously on main thread)
    // 1. Simulate Database Query on Main Thread (triggers DB on Main Thread issue)
    _performDatabaseQuery();

    // 2. Simulate File I/O on Main Thread (triggers File I/O issue)
    _performFileIO();

    // 3. Simulate JSON Decoding on Main Thread (triggers JSON Decoding issue)
    _performJSONDecoding();

    // ERROR DEMONSTRATIONS (triggered asynchronously to not block UI)
    // Trigger various error types for Sentry demo
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

    // ADDITIONAL PERFORMANCE ISSUES (triggered asynchronously)
    Future.microtask(() async {
      await _triggerImageDecoding();
      await _triggerRegex();
      await _triggerNPlusOneAPICalls();
      await _triggerFrameDrop();
      await _triggerFunctionRegression();
    });

    // Fetch products from API and report TTFD when complete
    shopItems = fetchShopItems().whenComplete(() {
      // Report TTFD as soon as fetching the shop items is done
      if (mounted) {
        SentryDisplayWidget.of(context).reportFullyDisplayed();
      }
    });
  }

  // Simulate slow database query on main thread
  void _performDatabaseQuery() {
    try {
      // Perform heavy computation to simulate slow DB query (>16ms)
      int sum = 0;
      for (int i = 0; i < 2000000; i++) {
        sum += i;
      }
      if (kDebugMode) {
        print('DB query completed on main thread, result: $sum');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DB query error: $e');
      }
    }
  }

  // Simulate slow file I/O on main thread
  void _performFileIO() {
    try {
      // Use system temp directory for cross-platform compatibility
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/plant_cache.txt').sentryTrace();

      // Write large file synchronously on main thread (>16ms)
      file.writeAsStringSync(List.filled(500000, 'Plant data ').join());

      final content = file.readAsStringSync();

      if (kDebugMode) {
        print('File I/O on main thread, size: ${content.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('File I/O error: $e');
      }
    }
  }

  // Simulate JSON decoding on main thread
  void _performJSONDecoding() {
    try {
      // Create and decode large JSON (>40ms for profiler detection)
      final largeJson = jsonEncode(List.generate(
        15000,
        (i) => {
          'id': i,
          'name': 'Plant $i',
          'description': 'A beautiful plant with detailed information $i',
          'price': i * 10.0,
          'stock': i % 100,
          'category': 'category_${i % 10}',
        },
      ));
      final decoded = jsonDecode(largeJson);
      if (kDebugMode) {
        print('JSON decoded ${decoded.length} items on main thread');
      }
    } catch (e) {
      if (kDebugMode) {
        print('JSON decode error: $e');
      }
    }
  }

  // Trigger C++ Segfault on startup
  Future<void> _triggerCppSegfault() async {
    final transaction = Sentry.startTransaction(
      'startup.cpp_segfault',
      'error',
    );
    final span = transaction.startChild(
      'native.crash',
      description: 'Trigger C++ Segfault: Plant root failure',
    );
    transaction.setData('plant_action', 'cpp_segfault');
    span.setData('triggered_on', 'startup');
    try {
      await channel.invokeMethod('cppSegfault');
    } catch (error, stackTrace) {
      span.throwable = error;
      span.status = SpanStatus.internalError();
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
    await span.finish();
    await transaction.finish();
  }

  // Trigger Kotlin Exception on startup (Android only)
  Future<void> _triggerKotlinException() async {
    if (!Platform.isAndroid) return;

    final transaction = Sentry.startTransaction(
      'startup.kotlin_exception',
      'error',
    );
    final span = transaction.startChild(
      'native.exception',
      description: 'Trigger Kotlin Exception: Plant leaf error',
    );
    transaction.setData('plant_action', 'kotlin_exception');
    span.setData('triggered_on', 'startup');
    try {
      await channel.invokeMethod('kotlinException');
    } catch (error, stackTrace) {
      span.throwable = error;
      span.status = SpanStatus.internalError();
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
    await span.finish();
    await transaction.finish();
  }

  // Trigger Dart Exception on startup
  Future<void> _triggerDartException() async {
    final transaction = Sentry.startTransaction(
      'startup.dart_exception',
      'error',
    );
    final span = transaction.startChild(
      'dart.exception',
      description: 'Trigger Dart Exception: Plant soil error',
    );
    transaction.setData('plant_action', 'dart_exception');
    span.setData('triggered_on', 'startup');
    try {
      throw Exception('Simulated Dart Exception');
    } catch (error, stackTrace) {
      span.throwable = error;
      span.status = SpanStatus.internalError();
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
    await span.finish();
    await transaction.finish();
  }

  // Trigger Timeout Exception on startup
  Future<void> _triggerTimeoutException() async {
    final transaction = Sentry.startTransaction(
      'startup.timeout_exception',
      'error',
    );
    final span = transaction.startChild(
      'dart.timeout',
      description: 'Trigger Timeout: Plant growth timeout',
    );
    transaction.setData('plant_action', 'timeout_exception');
    span.setData('triggered_on', 'startup');
    try {
      throw TimeoutException('Operation timed out', Duration(seconds: 2));
    } catch (error, stackTrace) {
      span.throwable = error;
      span.status = SpanStatus.internalError();
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
    await span.finish();
    await transaction.finish();
  }

  // Trigger Platform Exception on startup
  Future<void> _triggerPlatformException() async {
    final transaction = Sentry.startTransaction(
      'startup.platform_exception',
      'error',
    );
    final span = transaction.startChild(
      'platform.exception',
      description: 'Trigger Platform Exception: Plant pot error',
    );
    transaction.setData('plant_action', 'platform_exception');
    span.setData('triggered_on', 'startup');
    try {
      throw PlatformException(
        code: 'PLATFORM_ERROR',
        message: 'Simulated platform error',
      );
    } catch (error, stackTrace) {
      span.throwable = error;
      span.status = SpanStatus.internalError();
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
    await span.finish();
    await transaction.finish();
  }

  // Trigger Missing Plugin Exception on startup
  Future<void> _triggerMissingPluginException() async {
    final transaction = Sentry.startTransaction(
      'startup.missing_plugin_exception',
      'error',
    );
    final span = transaction.startChild(
      'plugin.exception',
      description: 'Trigger Missing Plugin: Plant fertilizer missing',
    );
    transaction.setData('plant_action', 'missing_plugin_exception');
    span.setData('triggered_on', 'startup');
    try {
      throw MissingPluginException('Simulated missing plugin');
    } catch (error, stackTrace) {
      span.throwable = error;
      span.status = SpanStatus.internalError();
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
    await span.finish();
    await transaction.finish();
  }

  // Trigger Assertion Error on startup
  Future<void> _triggerAssertionError() async {
    final transaction = Sentry.startTransaction(
      'startup.assertion_error',
      'error',
    );
    final span = transaction.startChild(
      'dart.assertion',
      description: 'Trigger Assertion Error: Plant sunlight assertion',
    );
    transaction.setData('plant_action', 'assertion_error');
    span.setData('triggered_on', 'startup');
    try {
      assert(false, 'Simulated assertion error');
    } catch (error, stackTrace) {
      span.throwable = error;
      span.status = SpanStatus.internalError();
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
    await span.finish();
    await transaction.finish();
  }

  // Trigger State Error on startup
  Future<void> _triggerStateError() async {
    final transaction = Sentry.startTransaction(
      'startup.state_error',
      'error',
    );
    final span = transaction.startChild(
      'dart.state',
      description: 'Trigger State Error: Plant state error',
    );
    transaction.setData('plant_action', 'state_error');
    span.setData('triggered_on', 'startup');
    try {
      throw StateError('Simulated state error');
    } catch (error, stackTrace) {
      span.throwable = error;
      span.status = SpanStatus.internalError();
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
    await span.finish();
    await transaction.finish();
  }

  // Trigger Range Error on startup
  Future<void> _triggerRangeError() async {
    final transaction = Sentry.startTransaction(
      'startup.range_error',
      'error',
    );
    final span = transaction.startChild(
      'dart.range',
      description: 'Trigger Range Error: Plant root range error',
    );
    transaction.setData('plant_action', 'range_error');
    span.setData('triggered_on', 'startup');
    try {
      throw RangeError('Simulated range error');
    } catch (error, stackTrace) {
      span.throwable = error;
      span.status = SpanStatus.internalError();
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
    await span.finish();
    await transaction.finish();
  }

  // Trigger Type Error on startup
  Future<void> _triggerTypeError() async {
    final transaction = Sentry.startTransaction(
      'startup.type_error',
      'error',
    );
    final span = transaction.startChild(
      'dart.type',
      description: 'Trigger Type Error: Plant type error',
    );
    transaction.setData('plant_action', 'type_error');
    span.setData('triggered_on', 'startup');
    try {
      throw TypeError();
    } catch (error, stackTrace) {
      span.throwable = error;
      span.status = SpanStatus.internalError();
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
    await span.finish();
    await transaction.finish();
  }

  // Trigger Image Decoding on Main Thread
  Future<void> _triggerImageDecoding() async {
    final transaction = Sentry.startTransaction(
      'startup.image_decode_main_thread',
      'performance',
      bindToScope: true,
    );
    final span = transaction.startChild(
      'image.decode.main_thread',
      description: 'Large Image Decoding on Main Thread',
    );
    transaction.setData('plant_action', 'image_decode_main_thread');
    span.setData('triggered_on', 'startup');

    // Simulate image decoding by creating large in-memory data
    final imageData = List.filled(1000000, 255);
    imageData.reduce((a, b) => a + b);

    await span.finish();
    await transaction.finish();
  }

  // Trigger Regex on Main Thread
  Future<void> _triggerRegex() async {
    final transaction = Sentry.startTransaction(
      'startup.regex_main_thread',
      'performance',
      bindToScope: true,
    );
    final span = transaction.startChild(
      'regex.main_thread',
      description: 'Complex Regex on Main Thread',
    );
    transaction.setData('plant_action', 'regex_main_thread');
    span.setData('triggered_on', 'startup');

    // Perform complex regex operations on main thread
    final text = List.filled(10000, 'Plant name: Monstera deliciosa, Price: \$25.99. ').join();
    final regex = RegExp(r'\b[A-Z][a-z]+ [a-z]+\b');
    regex.allMatches(text).toList();

    await span.finish();
    await transaction.finish();
  }

  // Trigger N+1 API Calls
  Future<void> _triggerNPlusOneAPICalls() async {
    final transaction = Sentry.startTransaction(
      'startup.n_plus_one_api_calls',
      'performance',
      bindToScope: true,
    );
    transaction.setData('plant_action', 'n_plus_one_api_calls');

    // Make sequential calls to trigger N+1 detection
    // SentryHttpClient automatically creates http.client spans
    final url = 'https://httpbin.org/delay/0';  // Use faster endpoint for demo
    final apiClient = SentryHttpClient();

    try {
      // Make 15 sequential GET requests (required for N+1 detection)
      for (int i = 0; i < 15; i++) {
        final uri = Uri.parse('$url?id=$i');
        try {
          await apiClient.get(uri);
        } catch (e, st) {
          await Sentry.captureException(e, stackTrace: st);
        }
      }
    } finally {
      apiClient.close();
      await transaction.finish(status: SpanStatus.ok());
    }
  }

  // Trigger Frame Drop
  Future<void> _triggerFrameDrop() async {
    final transaction = Sentry.startTransaction(
      'startup.frame_drop',
      'performance',
      bindToScope: true,
    );
    final span = transaction.startChild(
      'ui.frame_drop',
      description: 'Trigger Frame Drops',
    );
    transaction.setData('plant_action', 'frame_drop');
    span.setData('triggered_on', 'startup');

    // Perform heavy computation to cause frame drops
    for (int i = 0; i < 5; i++) {
      final start = DateTime.now();
      // Block for ~20ms to cause dropped frames (target is 16ms for 60fps)
      while (DateTime.now().difference(start).inMilliseconds < 20) {
        // Busy wait
      }
      await Future.delayed(Duration(milliseconds: 10));
    }

    await span.finish();
    await transaction.finish();
  }

  // Trigger Function Regression
  Future<void> _triggerFunctionRegression() async {
    final transaction = Sentry.startTransaction(
      'startup.function_regression',
      'performance',
      bindToScope: true,
    );
    final span = transaction.startChild(
      'function.slow',
      description: 'Slow Function Performance Regression',
    );
    transaction.setData('plant_action', 'function_regression');
    span.setData('triggered_on', 'startup');
    span.setData('duration_ms', 500);

    // Simulate a slow function that has regressed in performance
    await Future.delayed(Duration(milliseconds: 500));

    // Do some computation
    int sum = 0;
    for (int i = 0; i < 100000; i++) {
      sum += i;
    }
    if (kDebugMode) {
      print('Function regression completed, sum: $sum');
    }

    await span.finish();
    await transaction.finish();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    /*24 is for notification bar on Android*/
    final double itemHeight = (size.height - kToolbarHeight - 24) / 2;
    final double itemWidth = size.width * 1.3;

    return FutureBuilder<ResponseData>(
      future: shopItems,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            throw Exception("Error fetching shop data");
          }
          return SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(20, 30, 0, 10),
                          child: Text(
                            "Empower your plants",
                            style: TextStyle(
                              fontSize: 35.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(20, 10, 0, 0),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              "Keep your houseplants happy 🪴",
                              style: TextStyle(
                                fontSize: 20.0,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GridView.count(
                    physics: NeverScrollableScrollPhysics(),
                    primary: false,
                    shrinkWrap: true,
                    childAspectRatio: (itemHeight / itemWidth),
                    padding: const EdgeInsets.all(20.0),
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 20.0,
                    crossAxisCount: 2,
                    children:
                        (snapshot.data?.items.take(4).map<Widget>((shopItem) {
                          return _buildRow(
                            ResponseItem.fromJson(shopItem),
                            shopItem,
                          );
                        }).toList() ??
                        []),
                  ),
                ],
              ),
            );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }

  Widget _buildRow(ResponseItem pair, [Map<String, dynamic>? shopItem]) {
    //move consumer down here, each row item will be a consumer
    return Consumer<CartModel>(
      builder: (context, cart, child) {
        return Flex(
          direction: Axis.vertical,
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    ProductDetails.routeName,
                    arguments: ProductArguments(
                      pair.id,
                      pair.title,
                      pair.description,
                      pair.img,
                      pair.price,
                      descriptionfull: shopItem != null
                          ? (shopItem['descriptionfull'] ?? '')
                          : null,
                      callback: cart.add,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pair.img.isNotEmpty)
                        Image(
                          height: 100,
                          image: AssetImage(
                            'assets/images/${pair.img.replaceAll(RegExp('https://storage.googleapis.com/application-monitoring/'), '')}',
                          ),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.broken_image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                      SizedBox(height: 8),
                      Text(
                        pair.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '\$${pair.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red[900],
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          final productArgs = ProductArguments(
                            pair.id,
                            pair.title,
                            pair.description,
                            pair.img,
                            pair.price,
                            callback: cart.add,
                          );
                          cart.add(productArgs);
                          final snackBar = SnackBar(
                            backgroundColor: Colors.green[400],
                            content: Center(
                              child: Text(
                                '${pair.title} added to cart',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            duration: Duration(milliseconds: 500),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        },
                        child: Text('Add to cart'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ResponseData {
  // ignore: prefer_typing_uninitialized_variables, strict_top_level_inference
  final items;

  ResponseData({this.items});

  factory ResponseData.fromJson(List<dynamic> json) {
    return ResponseData(items: json);
  }

  int getLength() {
    return items.length;
  }
}

class ResponseItem {
  final int id;
  final String title;
  final String description;
  final String img;
  final int price;

  ResponseItem({
    required this.id,
    required this.title,
    required this.description,
    required this.img,
    required this.price,
  });

  factory ResponseItem.fromJson(Map<String, dynamic> json) {
    return ResponseItem(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      img: json['img'],
      price: json['price'],
    );
  }
}

// Returns an email address for demo/testing.
// - If se is set (not 'tda'): returns se@example.com for easy attribution.
// - If se is 'tda' (default): returns john.logs@example.com ~10 times per day
//   (once per 144-minute window, seeded by day+window so it's deterministic),
//   otherwise returns a unique timestamped address.
String getRandomEmail() {
  if (se != 'tda') {
    return '$se@example.com';
  }
  final now = DateTime.now();
  // Divide the day into 10 equal windows of 144 minutes each (1440 min / 10).
  final minuteOfDay = now.hour * 60 + now.minute;
  final windowIndex = minuteOfDay ~/ 144; // 0–9
  // Seed is unique per calendar day + window, so result is fixed within a window.
  final seed = now.year * 10000 + now.month * 100 + now.day * 10 + windowIndex;
  if (Random(seed).nextBool()) {
    return 'john.logs@example.com';
  }
  return 'user_${now.millisecondsSinceEpoch}@example.com';
}
