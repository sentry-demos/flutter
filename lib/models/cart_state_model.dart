import 'dart:collection';
import 'package:sentry_flutter_app/product_details.dart';
import 'package:flutter/cupertino.dart';

class CartModel extends ChangeNotifier {
  /// Internal, private state of the cart.
  final Map<String, ItemData> _items = new Map();

  /// An unmodifiable view of the items in the cart.
  UnmodifiableListView get items {
    List<ItemData> intermediate = [];
    _items.forEach((k, v) => intermediate.add(v));
    return UnmodifiableListView(intermediate);
  }

  int computeNumUniqueItems() {
    List<ItemData> intermediate = [];
    _items.forEach((k, v) => intermediate.add(v));
    return intermediate.length;
  }

  void changeItemQuantityById(String itemId, int newQuantity) {
    _items[itemId].quantity = newQuantity;
    notifyListeners();
  }

  void deleteItemById(String itemId) {
    _items.remove(itemId);
    notifyListeners();
  }

  double computeSubtotal() {
    double total = 0;
    _items.forEach((key, value) {
      total = total + value.quantity * value.price;
    });
    return total;
  }

  int computeNumItems() {
    int intermediate = 0;
    _items.forEach((k, v) => intermediate += v.quantity);
    return intermediate;
  }

  void add(ProductArguments item) {
    String productId = item.sku;
    bool alreadyInCart = _items.containsKey(productId);
    if (alreadyInCart) {
      _items[productId].quantity++;
    } else {
      ItemData newCartAddition = new ItemData.fromProductArguments(item);
      _items[productId] = newCartAddition;
    }
    print(_items);
    // This call tells the widgets that are listening to this model to rebuild.
    notifyListeners();
  }

  /// Removes all items from the cart.
  void removeAll() {
    _items.clear();
    // This call tells the widgets that are listening to this model to rebuild.
    notifyListeners();
  }
}

class ItemData {
  int quantity = 1;
  final String id;
  final String description;
  final String thumbnail;
  final String sku;
  final String title;
  final String type;
  final int price;
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'thumbnail': thumbnail,
      'sku': sku,
      'title': title,
      'price': price,
      'type': type
    };
  }

  ItemData(
      {this.id,
      this.description,
      this.thumbnail,
      this.sku,
      this.title,
      this.price,
      this.type});
  factory ItemData.fromProductArguments(ProductArguments productArgs) {
    return ItemData(
      id: productArgs.title,
      description: productArgs.description,
      thumbnail: productArgs.thumbnail,
      sku: productArgs.sku,
      title: productArgs.title,
      price: productArgs.price,
      type: productArgs.type,
    );
  }
}
