import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter_app/styled_button.dart';
import 'package:sentry_flutter_app/models/cart_state_model.dart';
import 'package:sentry_flutter_app/checkout.dart';

class CartView extends StatefulWidget {
  @override
  _CartViewState createState() {
    return _CartViewState();
  }
}

class _CartViewState extends State<CartView> {
  //TODO: Add share icon and native functionality to product details page
  @override
  build(BuildContext buildContext) {
    return Consumer<CartModel>(builder: (context, cart, child) {
      return CustomScrollView(slivers: [
        SliverFixedExtentList(
            delegate: SliverChildListDelegate([
              Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(children: [
                    Text('Subtotal (${cart.computeNumItems()} items):',
                        style: TextStyle(fontSize: 17)),
                    Text('\$${cart.computeSubtotal().toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900])),
                  ]))
            ]),
            itemExtent: 100.0),
        SliverAppBar(
          leading: new Container(),
          pinned: true,
          shadowColor: Colors.transparent,
          backgroundColor: Colors.white,
          expandedHeight: 90,
          collapsedHeight: 90,
          flexibleSpace: Center(
              child: Container(
                  decoration: BoxDecoration(
                      border: Border(
                    bottom: BorderSide(width: 1.0, color: Colors.grey),
                  )),
                  child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        children: [
                          GradientButton(
                            text: "Proceed to checkout",
                            onPressed: () {
                              //not clear that this callback is our add to cart
                              Navigator.pushNamed(
                                  context, CheckoutView.routeName,
                                  arguments: CheckoutArguments(
                                      subtotal: cart.computeSubtotal(),
                                      numItems: cart.computeNumItems(),
                                      cart: cart.items));
                            },
                            height: 50,
                          ),
                        ],
                      )))),
        ),
        SliverPadding(
            padding: EdgeInsets.fromLTRB(20.0, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildRow(cart.items[index], cartModel: cart),
                childCount: cart.computeNumUniqueItems(),
              ),
            )),
      ]);
    });
  }

  Column _buildRow(ItemData cartItem, {required CartModel cartModel}) {
    return Column(children: [
      Row(children: [
        Image(
          image: AssetImage('assets/images/${cartItem.thumbnail}'),
          height: 130.0,
        ),
        Flexible(
            child: Container(
                padding: EdgeInsets.only(left: 20),
                height: 130,
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        cartItem.title,
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
                      ),
                      Text(
                        cartItem.sku,
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
                      ),
                      Text('\$${cartItem.price}',
                          style:
                              TextStyle(color: Colors.red[900], fontSize: 17))
                    ])))
      ]),
      Row(children: [
        Container(
          height: 40,
          width: 100,
          decoration: BoxDecoration(
              border: Border(
            top: BorderSide(width: 1.0, color: Colors.grey),
            left: BorderSide(width: 1.0, color: Colors.grey),
            right: BorderSide(width: 1.0, color: Colors.grey),
            bottom: BorderSide(width: 1.0, color: Colors.grey),
          )),
          child: ButtonBar(alignment: MainAxisAlignment.center, children: [
            DropdownButtonHideUnderline(
                child: DropdownButton(
              value: cartItem.quantity.toString(),
              onChanged: (String? newValue) {
                cartModel.changeItemQuantityById(
                    cartItem.sku, int.parse(newValue ?? '0'));
              },
              items: <String>['1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                    value: value, child: Text(value.toString()));
              }).toList(),
            )),
          ]),
        ),
        Padding(padding: EdgeInsets.fromLTRB(10, 0, 0, 0)),
        TextButton(
          child: Text("Delete"),
          onPressed: () {
            cartModel.deleteItemById(cartItem.sku);
          },
        ),
      ]),
      Divider(color: Colors.grey)
    ]);
  }
}
