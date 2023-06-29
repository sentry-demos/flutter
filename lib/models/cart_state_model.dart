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
    _items[itemId]?.quantity = newQuantity;
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

  Map<String, int> computeQuantity() {
    Map<String, int> mapData = {};
    _items.forEach((key, value) {
      mapData.addAll({key: value.quantity});
    });
    return mapData;
  }

  int computeNumItems() {
    int intermediate = 0;
    _items.forEach((k, v) => intermediate += v.quantity);
    return intermediate;
  }

  void add(ProductArguments item) {
    String productId = item.id.toString();
    bool alreadyInCart = _items.containsKey(productId);
    if (alreadyInCart) {
      _items[productId]?.quantity++;
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
  final int id;
  final String title;
  final String description;
  final String imgcropped;
  final int price;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imgcropped': imgcropped,
      'price': price,
    };
  }

  ItemData({
    required this.id,
    required this.title,
    required this.description,
    required this.imgcropped,
    required this.price,
  });

  factory ItemData.fromProductArguments(ProductArguments productArgs) {
    return ItemData(
      id: productArgs.id,
      title: productArgs.title,
      description: productArgs.description,
      imgcropped: productArgs.imgcropped,
      price: productArgs.price,
    );
  }
}
