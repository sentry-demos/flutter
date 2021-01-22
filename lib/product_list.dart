import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/cart_state_model.dart';
import 'package:http/http.dart' as http;
import 'product_details.dart';

class ItemsList extends StatefulWidget {
  _ItemListState createState() => _ItemListState();
}

class _ItemListState extends State<ItemsList> {
  final String _uri = 'https://neilmanvar-flask-m3uuizd7iq-uc.a.run.app/tools';
  Future<ResponseData> shopItems;

  Future<ResponseData> fetchShopItems() async {
    final response = await http.get(_uri);
    if (response.statusCode == 200) {
      return ResponseData.fromJson((jsonDecode(response.body)));
    } else {
      throw Exception("Failed to load shop items data");
    }
  }

  void initState() {
    super.initState();
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
                            child: Text("Tools",
                                style: TextStyle(
                                    fontSize: 35.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800]))),
                        Padding(
                            padding: EdgeInsets.fromLTRB(20, 10, 0, 0),
                            child: Text("Recommended for you",
                                style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
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
                      children: snapshot.data.items.map<Widget>((shopItem) {
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
              child: FlatButton(
            onPressed: () {
              Navigator.pushNamed(context, ProductDetails.routeName,
                  arguments: ProductArguments(
                      pair.id,
                      pair.description,
                      pair.thumbNail,
                      pair.authors,
                      pair.title,
                      pair.price,
                      pair.type,
                      callback: cart.add));
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image(
                    height: 150.0,
                    image: AssetImage(
                      'assets/images/${pair.thumbNail}',
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
  final String smallThumbnail;
  final String thumbNail;
  final String description;
  final String title;
  final int price;
  final String id;
  final String type;
  final String mediumImage;
  final authors;

  ResponseItem(
      {this.id,
      this.smallThumbnail,
      this.thumbNail,
      this.description,
      this.title,
      this.price,
      this.mediumImage,
      this.authors,
      this.type});

  factory ResponseItem.fromJson(Map<String, dynamic> json) {
    return ResponseItem(
        id: json['sku'],
        authors: json['sku'],
        // mediumImage:json['volumeInfo']['imageLinks']['medium'],
        // smallThumbnail: json['volumeInfo']['imageLinks']['smallThumbnail'],
        thumbNail: json['image'],
        description: "This is a generic description of a tool.",
        title: json['name'],
        price: json['price'],
        type: json['type']);
  }
}
