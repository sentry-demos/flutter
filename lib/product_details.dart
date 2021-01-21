import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'styled_button.dart';
import 'package:sentry/sentry.dart';
import 'package:flutter/services.dart';

class ProductDetails extends StatefulWidget {
  static const routeName = '/productDetails';

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final channel = const MethodChannel('example.flutter.sentry.io');
  //TODO: Implement channels to simulate native crashes on both IOS and android
  //TODO: Start with android https://flutter.dev/docs/development/platform-integration/platform-channels#step-3-add-an-android-platform-specific-implementation

  //https://flutter.dev/docs/cookbook/navigation/navigate-with-arguments

  @override
  Widget build(BuildContext context) {
    //TODO:need access to context in order to receive product id from ModalRoute.of(context).settings.arguments. Context unavailable outside of build
    //TODO: consider https://stackoverflow.com/questions/49457717/flutter-get-context-in-initstate-method

    ProductArguments args = ModalRoute.of(context).settings.arguments;
    String imgURI = args.thumbnail;
    return Scaffold(
        appBar: AppBar(
          title: Text("Product Details"),
        ),
        body: Builder(builder: (BuildContext context) {
          return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: SingleChildScrollView(
                  child: Container(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                      child: Text(args.sku,
                          style:
                              TextStyle(fontSize: 16, color: Colors.blue[900])),
                    ),
                    Padding(
                        padding: EdgeInsets.fromLTRB(0, 10, 0, 30),
                        child: Text(
                          args.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                    Center(
                      child: Image(
                          image: AssetImage('assets/images/$imgURI'),
                          height: 200.0),
                    ),
                    Center(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Padding(
                              padding: EdgeInsets.fromLTRB(0, 40, 0, 20),
                              child: Text("Product Description",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold))),
                          Text(args.description,
                              style: TextStyle(height: 1.5, fontSize: 16)),
                          RaisedButton(
                              child: Text("C++ SEGFAULT"),
                              onPressed: () async {
                                await execute('crash');
                              })
                        ])),
                    Padding(
                        padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                        child: GradientButton(
                            height: 50.0,
                            text: "Add to Cart",
                            onPressed: () {
                              Sentry.addBreadcrumb(Breadcrumb(
                                  message: "User added ${args.title} to cart"));
                              args.callback(args);

                              Scaffold.of(context).showSnackBar(SnackBar(
                                backgroundColor: Colors.green[400],
                                duration: Duration(seconds: 2),
                                content: Container(
                                    height: 30.0,
                                    alignment: Alignment(0.0, 0.0),
                                    child: RichText(
                                        text: TextSpan(children: [
                                      TextSpan(
                                          text: "Added to cart ",
                                          style: TextStyle(fontSize: 18)),
                                      WidgetSpan(
                                          child: Icon(Icons.check_circle,
                                              size: 18))
                                    ]))),
                              ));
                              //not clear that this callback is our add to cart
                            },
                            child: Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        begin: FractionalOffset.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                      Colors.orange[100],
                                      Colors.yellow[700],
                                    ])),
                                child: Text(
                                  "Add to Cart",
                                  style: TextStyle(
                                      fontSize: 17, color: Colors.black),
                                )))),
                  ]))));
        }));
  }

  Future<void> execute(String method) async {
    try {
      await channel.invokeMethod<void>(method);
    } catch (error, stackTrace) {
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }
}

class ProductArguments {
  final String id;
  final String description;
  final String thumbnail;
  final String sku;
  final String title;
  final int price;
  final String type;
  final Function callback;

  ProductArguments(this.id, this.description, this.thumbnail, this.sku,
      this.title, this.price, this.type,
      {this.callback});
}
