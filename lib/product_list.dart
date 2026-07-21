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
import 'backend_config.dart';
import 'platform/platform_info.dart';
import 'platform/file_io_demo.dart';
import 'sentry_setup.dart';
import 'se_config.dart';
// ignore: depend_on_referenced_packages

class ItemsList extends StatefulWidget {
  const ItemsList({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ItemListState createState() => _ItemListState();
}

class _ItemListState extends State<ItemsList> {
  late Future<ResponseData> shopItems;

  var client = SentryHttpClient();
  final channel = const MethodChannel('example.flutter.sentry.io');

  Future<ResponseData> fetchShopItems() async {
    try {
      // Resolve the products endpoint at request time so the OTLP journey
      // (which switches BackendConfig.base) targets flask-otlp instead.
      final response = await client.get(Uri.parse(BackendConfig.products));
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

    // Vary the user cohort per session (randomized email) while keeping the
    // engineer + customer segment context so events stay attributable.
    final email = getRandomEmail();
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: email,
        username: se,
        email: email,
        data: {'customerType': sessionCustomerType, 'segment': sessionCustomerType},
      ));
    });
    Sentry.addBreadcrumb(Breadcrumb(
      category: 'navigation',
      message: 'Opened product catalog',
      level: SentryLevel.info,
      data: {'screen': 'product_list', 'customerType': sessionCustomerType},
    ));

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

  // Simulate slow file I/O on main thread (native: real dart:io file via
  // sentry_file; web: equivalent heavy main-thread work — see platform/file_io_demo).
  void _performFileIO() {
    try {
      final size = performFileIODemo();

      if (kDebugMode) {
        print('File I/O on main thread, size: $size');
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
    await Sentry.startSpan('startup.cpp_segfault', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('error'));
      span.setAttribute('plant_action', SentryAttribute.string('cpp_segfault'));
      await Sentry.startSpan('Trigger C++ Segfault: Plant root failure', (child) async {
        child.setAttribute('sentry.op', SentryAttribute.string('native.crash'));
        child.setAttribute('triggered_on', SentryAttribute.string('startup'));
        try {
          await channel.invokeMethod('cppSegfault');
        } catch (error, stackTrace) {
          child.status = SentrySpanStatusV2.error;
          await Sentry.captureException(error, stackTrace: stackTrace);
        }
      });
    }, parentSpan: null);
  }

  // Trigger Kotlin Exception on startup (Android only)
  Future<void> _triggerKotlinException() async {
    if (!isAndroid) return;

    await Sentry.startSpan('startup.kotlin_exception', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('error'));
      span.setAttribute('plant_action', SentryAttribute.string('kotlin_exception'));
      await Sentry.startSpan('Trigger Kotlin Exception: Plant leaf error', (child) async {
        child.setAttribute('sentry.op', SentryAttribute.string('native.exception'));
        child.setAttribute('triggered_on', SentryAttribute.string('startup'));
        try {
          await channel.invokeMethod('kotlinException');
        } catch (error, stackTrace) {
          child.status = SentrySpanStatusV2.error;
          await Sentry.captureException(error, stackTrace: stackTrace);
        }
      });
    }, parentSpan: null);
  }

  // Trigger Dart Exception on startup
  Future<void> _triggerDartException() async {
    await Sentry.startSpan('startup.dart_exception', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('error'));
      span.setAttribute('plant_action', SentryAttribute.string('dart_exception'));
      await Sentry.startSpan('Trigger Dart Exception: Plant soil error', (child) async {
        child.setAttribute('sentry.op', SentryAttribute.string('dart.exception'));
        child.setAttribute('triggered_on', SentryAttribute.string('startup'));
        try {
          throw Exception('Simulated Dart Exception');
        } catch (error, stackTrace) {
          child.status = SentrySpanStatusV2.error;
          await Sentry.captureException(error, stackTrace: stackTrace);
        }
      });
    }, parentSpan: null);
  }

  // Trigger Timeout Exception on startup
  Future<void> _triggerTimeoutException() async {
    await Sentry.startSpan('startup.timeout_exception', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('error'));
      span.setAttribute('plant_action', SentryAttribute.string('timeout_exception'));
      await Sentry.startSpan('Trigger Timeout: Plant growth timeout', (child) async {
        child.setAttribute('sentry.op', SentryAttribute.string('dart.timeout'));
        child.setAttribute('triggered_on', SentryAttribute.string('startup'));
        try {
          throw TimeoutException('Operation timed out', Duration(seconds: 2));
        } catch (error, stackTrace) {
          child.status = SentrySpanStatusV2.error;
          await Sentry.captureException(error, stackTrace: stackTrace);
        }
      });
    }, parentSpan: null);
  }

  // Trigger Platform Exception on startup
  Future<void> _triggerPlatformException() async {
    await Sentry.startSpan('startup.platform_exception', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('error'));
      span.setAttribute('plant_action', SentryAttribute.string('platform_exception'));
      await Sentry.startSpan('Trigger Platform Exception: Plant pot error', (child) async {
        child.setAttribute('sentry.op', SentryAttribute.string('platform.exception'));
        child.setAttribute('triggered_on', SentryAttribute.string('startup'));
        try {
          throw PlatformException(
            code: 'PLATFORM_ERROR',
            message: 'Simulated platform error',
          );
        } catch (error, stackTrace) {
          child.status = SentrySpanStatusV2.error;
          await Sentry.captureException(error, stackTrace: stackTrace);
        }
      });
    }, parentSpan: null);
  }

  // Trigger Missing Plugin Exception on startup
  Future<void> _triggerMissingPluginException() async {
    await Sentry.startSpan('startup.missing_plugin_exception', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('error'));
      span.setAttribute('plant_action', SentryAttribute.string('missing_plugin_exception'));
      await Sentry.startSpan('Trigger Missing Plugin: Plant fertilizer missing', (child) async {
        child.setAttribute('sentry.op', SentryAttribute.string('plugin.exception'));
        child.setAttribute('triggered_on', SentryAttribute.string('startup'));
        try {
          throw MissingPluginException('Simulated missing plugin');
        } catch (error, stackTrace) {
          child.status = SentrySpanStatusV2.error;
          await Sentry.captureException(error, stackTrace: stackTrace);
        }
      });
    }, parentSpan: null);
  }

  // Trigger Assertion Error on startup
  Future<void> _triggerAssertionError() async {
    await Sentry.startSpan('startup.assertion_error', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('error'));
      span.setAttribute('plant_action', SentryAttribute.string('assertion_error'));
      await Sentry.startSpan('Trigger Assertion Error: Plant sunlight assertion', (child) async {
        child.setAttribute('sentry.op', SentryAttribute.string('dart.assertion'));
        child.setAttribute('triggered_on', SentryAttribute.string('startup'));
        try {
          assert(false, 'Simulated assertion error');
        } catch (error, stackTrace) {
          child.status = SentrySpanStatusV2.error;
          await Sentry.captureException(error, stackTrace: stackTrace);
        }
      });
    }, parentSpan: null);
  }

  // Trigger State Error on startup
  Future<void> _triggerStateError() async {
    await Sentry.startSpan('startup.state_error', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('error'));
      span.setAttribute('plant_action', SentryAttribute.string('state_error'));
      await Sentry.startSpan('Trigger State Error: Plant state error', (child) async {
        child.setAttribute('sentry.op', SentryAttribute.string('dart.state'));
        child.setAttribute('triggered_on', SentryAttribute.string('startup'));
        try {
          throw StateError('Simulated state error');
        } catch (error, stackTrace) {
          child.status = SentrySpanStatusV2.error;
          await Sentry.captureException(error, stackTrace: stackTrace);
        }
      });
    }, parentSpan: null);
  }

  // Trigger Range Error on startup
  Future<void> _triggerRangeError() async {
    await Sentry.startSpan('startup.range_error', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('error'));
      span.setAttribute('plant_action', SentryAttribute.string('range_error'));
      await Sentry.startSpan('Trigger Range Error: Plant root range error', (child) async {
        child.setAttribute('sentry.op', SentryAttribute.string('dart.range'));
        child.setAttribute('triggered_on', SentryAttribute.string('startup'));
        try {
          throw RangeError('Simulated range error');
        } catch (error, stackTrace) {
          child.status = SentrySpanStatusV2.error;
          await Sentry.captureException(error, stackTrace: stackTrace);
        }
      });
    }, parentSpan: null);
  }

  // Trigger Type Error on startup
  Future<void> _triggerTypeError() async {
    await Sentry.startSpan('startup.type_error', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('error'));
      span.setAttribute('plant_action', SentryAttribute.string('type_error'));
      await Sentry.startSpan('Trigger Type Error: Plant type error', (child) async {
        child.setAttribute('sentry.op', SentryAttribute.string('dart.type'));
        child.setAttribute('triggered_on', SentryAttribute.string('startup'));
        try {
          throw TypeError();
        } catch (error, stackTrace) {
          child.status = SentrySpanStatusV2.error;
          await Sentry.captureException(error, stackTrace: stackTrace);
        }
      });
    }, parentSpan: null);
  }

  // Trigger Image Decoding on Main Thread
  Future<void> _triggerImageDecoding() async {
    await Sentry.startSpan('startup.image_decode_main_thread', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('performance'));
      span.setAttribute('plant_action', SentryAttribute.string('image_decode_main_thread'));
      await Sentry.startSpan('Large Image Decoding on Main Thread', (child) async {
        child.setAttribute('sentry.op', SentryAttribute.string('image.decode.main_thread'));
        child.setAttribute('triggered_on', SentryAttribute.string('startup'));

        // Simulate image decoding by creating large in-memory data
        final imageData = List.filled(1000000, 255);
        imageData.reduce((a, b) => a + b);
      });
    }, parentSpan: null);
  }

  // Trigger Regex on Main Thread
  Future<void> _triggerRegex() async {
    await Sentry.startSpan('startup.regex_main_thread', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('performance'));
      span.setAttribute('plant_action', SentryAttribute.string('regex_main_thread'));
      await Sentry.startSpan('Complex Regex on Main Thread', (child) async {
        child.setAttribute('sentry.op', SentryAttribute.string('regex.main_thread'));
        child.setAttribute('triggered_on', SentryAttribute.string('startup'));

        // Perform complex regex operations on main thread
        final text = List.filled(10000, 'Plant name: Monstera deliciosa, Price: \$25.99. ').join();
        final regex = RegExp(r'\b[A-Z][a-z]+ [a-z]+\b');
        regex.allMatches(text).toList();
      });
    }, parentSpan: null);
  }

  // Trigger N+1 API Calls
  Future<void> _triggerNPlusOneAPICalls() async {
    await Sentry.startSpan('startup.n_plus_one_api_calls', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('performance'));
      span.setAttribute('plant_action', SentryAttribute.string('n_plus_one_api_calls'));

      // Make sequential calls to trigger N+1 detection.
      // SentryHttpClient automatically creates child http.client spans under the
      // currently-active span (this one, propagated via the startSpan zone).
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
      }
    }, parentSpan: null);
  }

  // Trigger Frame Drop
  Future<void> _triggerFrameDrop() async {
    await Sentry.startSpan('startup.frame_drop', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('performance'));
      span.setAttribute('plant_action', SentryAttribute.string('frame_drop'));
      await Sentry.startSpan('Trigger Frame Drops', (child) async {
        child.setAttribute('sentry.op', SentryAttribute.string('ui.frame_drop'));
        child.setAttribute('triggered_on', SentryAttribute.string('startup'));

        // Perform heavy computation to cause frame drops
        for (int i = 0; i < 5; i++) {
          final start = DateTime.now();
          // Block for ~20ms to cause dropped frames (target is 16ms for 60fps)
          while (DateTime.now().difference(start).inMilliseconds < 20) {
            // Busy wait
          }
          await Future.delayed(Duration(milliseconds: 10));
        }
      });
    }, parentSpan: null);
  }

  // Trigger Function Regression
  Future<void> _triggerFunctionRegression() async {
    await Sentry.startSpan('startup.function_regression', (span) async {
      span.setAttribute('sentry.op', SentryAttribute.string('performance'));
      span.setAttribute('plant_action', SentryAttribute.string('function_regression'));
      await Sentry.startSpan('Slow Function Performance Regression', (child) async {
        child.setAttribute('sentry.op', SentryAttribute.string('function.slow'));
        child.setAttribute('triggered_on', SentryAttribute.string('startup'));
        child.setAttribute('duration_ms', SentryAttribute.int(500));

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
      });
    }, parentSpan: null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResponseData>(
      future: shopItems,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            throw Exception("Error fetching shop data");
          }
          return SingleChildScrollView(
            // Cap the catalog width and center it so wide web/desktop windows
            // don't stretch the 2-column grid into giant tiles (which pushed
            // the products far down the page). Mobile is unaffected since its
            // width is already below this cap.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
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
                      // Stable portrait card ratio across all platforms.
                      childAspectRatio: 0.72,
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
              ),
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
