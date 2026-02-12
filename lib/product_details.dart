import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:sentry/sentry.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ProductDetails extends StatefulWidget {
  static const routeName = '/productDetails';

  const ProductDetails({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final channel = const MethodChannel('example.flutter.sentry.io');

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

  //https://flutter.dev/docs/cookbook/navigation/navigate-with-arguments

  @override
  Widget build(BuildContext context) {
    ProductArguments? args =
        ModalRoute.of(context)?.settings.arguments as ProductArguments?;
    String? imgURI = args?.imgcropped.replaceAll(
      RegExp('https://storage.googleapis.com/application-monitoring/'),
      '',
    ); //Remove header
    String? _ = args?.description;
    String? longDescription = args?.descriptionfull ?? args?.description;
    return Scaffold(
      appBar: AppBar(title: Text("Product Details")),
      body: Builder(
        builder: (BuildContext context) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Centered product image
                  if (imgURI != null && imgURI.isNotEmpty)
                    Center(
                      child: Image(
                        image: AssetImage('assets/images/$imgURI'),
                        height: 250.0,
                      ),
                    ),
                  SizedBox(height: 24),
                  // Centered product title
                  Text(
                    args?.title ?? '',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  // Centered product description
                  Text(
                    longDescription ?? '',
                    style: TextStyle(height: 1.5, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  // Centered Add to Cart button
                  Center(
                    child: ElevatedButton(
                      onPressed: args != null
                          ? () {
                              final productArgs = ProductArguments(
                                args.id,
                                args.title,
                                args.description,
                                args.imgcropped,
                                args.price,
                                callback: args.callback,
                              );
                              args.callback(productArgs);
                              final snackBar = SnackBar(
                                backgroundColor: Colors.green[400],
                                content: Center(
                                  child: Text(
                                    '${args.title} added to cart',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                duration: Duration(milliseconds: 500),
                              );
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(snackBar);
                            }
                          : null,
                      child: Text('Add to cart'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
  final int id;
  final String title;
  final String description;
  final String? descriptionfull;
  final String imgcropped;
  final int price;

  final Function(ProductArguments args) callback;

  ProductArguments(
    this.id,
    this.title,
    this.description,
    this.imgcropped,
    this.price, {
    this.descriptionfull,
    required this.callback,
  });
}
