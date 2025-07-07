import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/cart_state_model.dart';
import 'product_details.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:sentry/sentry.dart';

class ItemsList extends StatefulWidget {
  const ItemsList({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ItemListState createState() => _ItemListState();
}

class _ItemListState extends State<ItemsList> {
  final String _uri =
      'https://application-monitoring-flask-dot-sales-engineering-sf.appspot.com/products';
  late Future<ResponseData> shopItems;

  var client = SentryHttpClient();

  Future<ResponseData> fetchShopItems() async {
    final response = await client.get(Uri.parse(_uri));
    if (response.statusCode == 200) {
      return ResponseData.fromJson((jsonDecode(response.body)));
    } else {
      throw Exception("Failed to load shop items data");
    }
  }

  @override
  void initState() {
    super.initState();

    final email = getRandomEmail();
    Sentry.configureScope((scope) => scope.setUser(SentryUser(id: email)));

    shopItems = fetchShopItems();
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

// Returns a randomized email address for demo/testing
String getRandomEmail() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return 'user_$timestamp@example.com';
}
