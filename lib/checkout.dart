import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:sentry/sentry.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    // Report TTFD after the frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SentryDisplayWidget.of(context).reportFullyDisplayed();
      }
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
      if (kDebugMode) {
        print(orderPayload);
      }
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

        if (checkoutResult.statusCode != 200) {
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
