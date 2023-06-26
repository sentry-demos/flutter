import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:sentry_flutter_app/styled_button.dart';
import 'package:sentry/sentry.dart';

class CheckoutView extends StatefulWidget {
  static const String routeName = "/checkout";

  @override
  _CheckoutViewState createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final _uri = "https://vu-flask-m3uuizd7iq-uc.a.run.app/checkout";
  @override
  Widget build(BuildContext context) {
    var _key = new GlobalKey<ScaffoldState>();
    final CheckoutArguments? args =
        ModalRoute.of(context)?.settings.arguments as CheckoutArguments?;
    const double salesTax = .0725;
    final List? orderPayload = args?.cart.map((item) => item.toJson()).toList();

    double? subTotal = args?.subtotal;

    void completeCheckout(var key) async {
      print(orderPayload);
      try {
        final checkoutResult = await http.post(Uri.parse(_uri),
            body: jsonEncode(<String, dynamic>{
              "email": "fake@email.com",
              "cart": orderPayload
            }));
        if (checkoutResult.statusCode == 200) {
          key.currentState.showSnackBar(SnackBar(
            backgroundColor: Colors.green[400],
            duration: Duration(seconds: 2),
            content: Container(
                height: 30.0,
                alignment: Alignment(0.0, 0.0),
                child: RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: "Order placed ", style: TextStyle(fontSize: 18)),
                  WidgetSpan(child: Icon(Icons.check_circle, size: 18))
                ]))),
          ));
        } else {
          throw Exception(
              "${checkoutResult.statusCode} + ${checkoutResult.reasonPhrase}");
        }
      } catch (err, stacktrace) {
        key.currentState.showSnackBar(SnackBar(
          backgroundColor: Colors.red[400],
          duration: Duration(seconds: 3),
          content: Container(
              height: 30.0,
              alignment: Alignment(0.0, 0.0),
              child: RichText(
                  text: TextSpan(children: [
                TextSpan(
                    text: "Error placing order ",
                    style: TextStyle(fontSize: 18)),
                WidgetSpan(child: Icon(Icons.warning_rounded, size: 18))
              ]))),
        ));
        await Sentry.captureException(
          err,
          stackTrace: stacktrace,
        );
      }
    }

    return Scaffold(
        key: _key,
        appBar: AppBar(title: Text("Place Your Order")),
        body: Padding(
            padding: EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 0.0),
            child: Builder(builder: (BuildContext context) {
              return Container(
                  child: Column(
                children: [
                  GradientButton(
                    text: "Place your order",
                    onPressed: () {
                      Sentry.addBreadcrumb(Breadcrumb(
                          category: "cart.action",
                          message: "User clicked checkout."));
                      completeCheckout(_key);
                    },
                    height: 50.0,
                  ),
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
                          )),
                          child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Items (${args?.numItems}):"),
                                        Text(
                                            "\$${subTotal?.toStringAsFixed(2)}")
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Shipping & handling:"),
                                        Text("\$0.00")
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Total before tax:"),
                                        Text(
                                            "\$${subTotal?.toStringAsFixed(2)}")
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Estimated tax to be collected:"),
                                        Text(
                                            "\$${((subTotal ?? 0) * salesTax).toStringAsFixed(2)}")
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Order Total:",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18)),
                                        Text(
                                            "\$${((subTotal ?? 0) + (subTotal ?? 0) * salesTax).toStringAsFixed(2)}",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red[900]))
                                      ],
                                    ),
                                  ]))))
                ],
              ));
            })));
  }
}

class CheckoutArguments {
  final double subtotal;
  final int numItems;
  final List cart;

  CheckoutArguments(
      {required this.subtotal, required this.numItems, required this.cart});
}
