import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final Widget child;
  final double height;
  final String text;
  final Function onPressed;
  GradientButton({this.child, this.height = 50, this.text, this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.brown[400]),
          borderRadius: BorderRadius.circular(3.0),
          gradient: LinearGradient(
              begin: FractionalOffset.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange[100],
                Colors.yellow[700],
              ])),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Text(
                text,
                style: TextStyle(fontSize: 17, color: Colors.black),
              ),
            )),
      ),
    );
  }
}
