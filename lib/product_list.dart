import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/cart_state_model.dart';
import 'product_details.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry/sentry.dart';


class ItemsList extends StatefulWidget {
  _ItemListState createState() => _ItemListState();
}

class _ItemListState extends State<ItemsList> {
  final String _uri = 'https://application-monitoring-flask-dot-sales-engineering-sf.appspot.com/products';
  late Future<ResponseData> shopItems;
  final transaction = Sentry.startTransaction(
    'webrequest',
    'request',
    bindToScope: true,
  );

  var client = SentryHttpClient();

  Future<ResponseData> fetchShopItems() async {
    final response = await client.get(Uri.parse(_uri));
    if (response.statusCode == 200) {
      return ResponseData.fromJson((jsonDecode(response.body)));
    } else {
      throw Exception("Failed to load shop items data");
    }
  }

  void initState() {
    super.initState();
    // final transaction = Sentry.startTransaction('fetchShopItems()', 'task', bindToScope: true,);
    // try {
      shopItems= fetchShopItems();
    // } catch (exception) {
    //   transaction.throwable = exception;
    //   transaction.status = SpanStatus.internalError();
    // }finally {
    //   transaction.finish();
    // }
    //var faker = new Faker();
    final email = "flutterdemo@email.com";
    Sentry.configureScope(
      (scope) => scope.setUser(SentryUser(id: email)),
    );
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
              throw new Exception("Error fetching shop data");
            }
            return SingleChildScrollView(
                child: Container(
                    child: Column(children: [
              Container(
                  alignment: Alignment.centerLeft,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: EdgeInsets.fromLTRB(20, 30, 0, 10),
                            child: Text("Empower your plants",
                                style: TextStyle(
                                    fontSize: 35.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black))),
                        Padding(
                            padding: EdgeInsets.fromLTRB(20, 10, 0, 0),
                            child: Text("Keep your houseplants happy 🪴",
                                style: TextStyle(
                                    fontSize: 20.0,
                                    color: Colors.black)))
                      ])),
              Container(
                  child: GridView.count(
                      physics: NeverScrollableScrollPhysics(),
                      primary: false,
                      shrinkWrap: true,
                      childAspectRatio: (itemHeight / itemWidth),
                      padding: const EdgeInsets.all(20.0),
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 20.0,
                      crossAxisCount: 2,
                      children: snapshot.data?.items.map<Widget>((shopItem) {
                        return _buildRow(ResponseItem.fromJson(shopItem));
                      }).toList()))
            ])));
          } else {
            return CircularProgressIndicator();
          }
        });
  }

  Widget _buildRow(ResponseItem pair) {
    //move consumer down here, each row item will be a consumer
    return Consumer<CartModel>(
      builder: (context, cart, child) {
        return Flex(direction: Axis.vertical, children: [
          Expanded(
              child: TextButton(
            onPressed: () {
              Navigator.pushNamed(context, ProductDetails.routeName,
                  arguments: ProductArguments(
                      pair.id,
                      pair.title,
                      pair.description,
                      pair.img,
                      pair.price,
                      callback: cart.add));
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image(
                    height: 150.0,
                    image: AssetImage(
                      'assets/images/${pair.img.replaceAll(RegExp('https://storage.googleapis.com/application-monitoring/'), '')}',
                    )),

                Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 5.0),
                  child: Text(pair.title,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blue[800], fontSize: 18)),
                ),

                  Text('\$${pair.price.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.red[900], fontSize: 17))

                // Expanded(child: Text(pair.price.toString())
              ],
            ),
          ))
        ]);
      },
    );
  }
}

class ResponseData {
  final items;

  ResponseData({this.items});

  factory ResponseData.fromJson(List<dynamic> json) {
    return ResponseData(items: json);
  }

  int getLength() {
    return this.items.length;
  }
}

class ResponseItem {
  final int id;
  final String title;
  final String description;
  final String img;
  final int price;

  ResponseItem(
      {required this.id,
      required this.title,
      required this.description,
      required this.img,
      required this.price});

  factory ResponseItem.fromJson(Map<String, dynamic> json) {
    return ResponseItem(
        id: json['id'],
        title: json['title'],
        description: "This is a generic description.",
        img: json['img'],
        price: json['price'],
        );
  }
}
