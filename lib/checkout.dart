import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:sentry/sentry.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:logging/logging.dart';
import 'sentry_setup.dart';

class CheckoutView extends StatefulWidget {
  static const String routeName = "/checkout";

  const CheckoutView({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CheckoutViewState createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final _uri = "https://flask.empower-plant.com/checkout";
  final _promoCodeController = TextEditingController(text: 'SAVE20');
  final _log = Logger('CheckoutLogger');
  String? _promoErrorMessage;

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> applyPromoCode(String code) async {
    // Clear any previous error
    setState(() {
      _promoErrorMessage = null;
    });

    if (code.isEmpty) return;

    // Track promo code application attempt with metrics
    Sentry.metrics.count(
      'promo_code_attempts',
      1,
      attributes: {
        'code': SentryAttribute.string(code),
        'code_length': SentryAttribute.int(code.length),
      },
    );

    // Log info message with new Sentry.logger API
    Sentry.logger.fmt.info('Applying promo code: %s', [code], attributes: {
      'promo_code': SentryLogAttribute.string(code),
      'action': SentryLogAttribute.string('promo_apply'),
    });

    // Also use legacy logger for backwards compatibility
    _log.info("applying promo code '$code'...");

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Always fail with error - simulate expired promo code
    final errorBody = jsonEncode({
      "error": {
        "code": "expired",
        "message": "Provided coupon code has expired."
      }
    });

    // Track failure with metrics
    Sentry.metrics.count(
      'promo_code_failures',
      1,
      attributes: {
        'error_code': SentryAttribute.string('expired'),
        'code': SentryAttribute.string(code),
      },
    );

    // Log error with new Sentry.logger API including structured attributes
    Sentry.logger.fmt.error(
      'Failed to apply promo code %s: HTTP 410 | Error: %s',
      [code, 'expired'],
      attributes: {
        'promo_code': SentryLogAttribute.string(code),
        'http_status': SentryLogAttribute.int(410),
        'error_code': SentryLogAttribute.string('expired'),
        'error_message': SentryLogAttribute.string('Provided coupon code has expired.'),
        'response_body': SentryLogAttribute.string(errorBody),
      },
    );

    // Also use legacy logger for backwards compatibility (info level since this is expected behavior)
    _log.info("failed to apply promo code: HTTP 410 | body: $errorBody");

    // Update UI with error message
    setState(() {
      _promoErrorMessage = "Unknown error applying promo code";
    });
  }

  @override
  Widget build(BuildContext context) {
    var key = GlobalKey<ScaffoldState>();
    final CheckoutArguments? args =
        ModalRoute.of(context)?.settings.arguments as CheckoutArguments?;
    const double salesTax = .0725;
    final List<dynamic>? orderPayload = args?.cart
        .map((item) => item.toJson())
        .toList();
    Map<String, int>? quantity = args?.quantity;
    double? subTotal = args?.subtotal;

    var client = SentryHttpClient();

    void completeCheckout(var key) async {
      // Track checkout attempt with metrics
      Sentry.metrics.count('checkout_attempts', 1, attributes: {
        'num_items': SentryAttribute.int(args?.numItems ?? 0),
      });

      // Log checkout start
      Sentry.logger.fmt.info(
        'Starting checkout: %s items, total %s',
        [args?.numItems ?? 0, subTotal?.toStringAsFixed(2) ?? '0.00'],
        attributes: {
          'num_items': SentryLogAttribute.int(args?.numItems ?? 0),
          'subtotal': SentryLogAttribute.double(subTotal ?? 0.0),
          'action': SentryLogAttribute.string('checkout_start'),
        },
      );

      if (kDebugMode) {
        print(orderPayload);
      }

      // Track API latency
      final startTime = DateTime.now();

      try {
        final checkoutResult = await client.post(
          Uri.parse(_uri),
          body: jsonEncode(<String, dynamic>{
            "email": getRandomEmail(),
            "cart": {
              "items": orderPayload,
              "quantities": quantity,
              "total": subTotal,
            },
            "form": {
              "address": null,
              "city": null,
              "country": null,
              "email": getRandomEmail(),
              "firstName": null,
              "lastName": null,
              "state": null,
              "subscribe": null,
              "zipCode": null,
            },
          }),
        );

        // Track API response time
        final latency = DateTime.now().difference(startTime).inMilliseconds;
        Sentry.metrics.distribution(
          'checkout_api_latency',
          latency.toDouble(),
          unit: SentryMetricUnit.millisecond,
          attributes: {
            'status_code': SentryAttribute.int(checkoutResult.statusCode),
          },
        );

        if (checkoutResult.statusCode != 200) {
          // Track checkout failure
          Sentry.metrics.count('checkout_failures', 1, attributes: {
            'status_code': SentryAttribute.int(checkoutResult.statusCode),
            'error_type': SentryAttribute.string('http_error'),
          });

          // Log checkout failure with details
          Sentry.logger.fmt.error(
            'Checkout failed with status %s',
            [checkoutResult.statusCode],
            attributes: {
              'http_status': SentryLogAttribute.int(checkoutResult.statusCode),
              'num_items': SentryLogAttribute.int(args?.numItems ?? 0),
              'subtotal': SentryLogAttribute.double(subTotal ?? 0.0),
              'latency_ms': SentryLogAttribute.int(latency),
            },
          );
          Sentry.runZonedGuarded(
            () async {
              // Show error to user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red[400],
                  duration: Duration(seconds: 2),
                  content: Container(
                    height: 30.0,
                    alignment: Alignment(0.0, 0.0),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "We're having some trouble :(",
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              // Capture message and context
              final eventId = await Sentry.captureMessage(
                'Checkout endpoint failed with status: \\${checkoutResult.statusCode}',
                level: SentryLevel.error,
              );
              // Show user feedback dialog
              if (mounted) {
                // ignore: use_build_context_synchronously
                showUserFeedbackDialog(context, eventId);
              }
            },
            (error, stackTrace) {
              Sentry.captureException(error, stackTrace: stackTrace);
            },
          );
          if (kDebugMode) {
            print(
              "${checkoutResult.statusCode} + ${checkoutResult.reasonPhrase}",
            );
          }
        }
      } catch (error, stackTrace) {
        // Track exception
        Sentry.metrics.count('checkout_exceptions', 1, attributes: {
          'error_type': SentryAttribute.string(error.runtimeType.toString()),
        });

        // Log exception with context
        Sentry.logger.fmt.error(
          'Checkout exception: %s',
          [error.toString()],
          attributes: {
            'error_type': SentryLogAttribute.string(error.runtimeType.toString()),
            'num_items': SentryLogAttribute.int(args?.numItems ?? 0),
            'subtotal': SentryLogAttribute.double(subTotal ?? 0.0),
          },
        );

        Sentry.runZonedGuarded(
          () async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red[400],
                duration: Duration(seconds: 2),
                content: Container(
                  height: 30.0,
                  alignment: Alignment(0.0, 0.0),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "We're having some trouble :(",
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            final eventId = await Sentry.captureException(
              error,
              stackTrace: stackTrace,
            );
            if (mounted) {
              // ignore: use_build_context_synchronously
              showUserFeedbackDialog(context, eventId);
            }
          },
          (err, st) {
            Sentry.captureException(err, stackTrace: st);
          },
        );
      } finally {
        client.close();
      }
    }

    return Scaffold(
      key: key,
      appBar: AppBar(title: Text("Place Your Order")),
      body: Padding(
        padding: EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 0.0),
        child: Builder(
          builder: (BuildContext context) {
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(width: 1.0, color: Colors.grey),
                        left: BorderSide(width: 1.0, color: Colors.grey),
                        right: BorderSide(width: 1.0, color: Colors.grey),
                        bottom: BorderSide(width: 1.0, color: Colors.grey),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Items (${args?.numItems}):"),
                              Text("\$${subTotal?.toStringAsFixed(2)}"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Shipping & handling:"),
                              Text("\$0.00"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total before tax:"),
                              Text("\$${subTotal?.toStringAsFixed(2)}"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Estimated tax to be collected:"),
                              Text(
                                "\$${((subTotal ?? 0) * salesTax).toStringAsFixed(2)}",
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Order Total:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                "\$${((subTotal ?? 0) + (subTotal ?? 0) * salesTax).toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[900],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                // Promo Code Section
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Have a promo code?",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promoCodeController,
                              decoration: InputDecoration(
                                hintText: "Enter promo code",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              applyPromoCode(_promoCodeController.text);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: Text('Apply'),
                          ),
                        ],
                      ),
                      if (_promoErrorMessage != null) ...[
                        SizedBox(height: 8),
                        Text(
                          _promoErrorMessage!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Sentry.addBreadcrumb(
                      Breadcrumb(
                        category: "cart.action",
                        message: "User clicked checkout.",
                      ),
                    );
                    completeCheckout(key);
                  },
                  child: Text('Place your order'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Returns a randomized email address for demo/testing
String getRandomEmail() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return 'user_$timestamp@example.com';
}

class CheckoutArguments {
  final double subtotal;
  final int numItems;
  final List cart;
  final Map<String, int> quantity;

  CheckoutArguments({
    required this.subtotal,
    required this.numItems,
    required this.cart,
    required this.quantity,
  });
}
