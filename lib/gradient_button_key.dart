import 'package:flutter/material.dart';

class GradientButtonKey extends StatelessWidget {
  final Widget? child;
  final double height;
  final String text;
  final Function() onPressed;
  final Key? buttonKey;

  const GradientButtonKey({
    super.key,
    this.child,
    this.height = 50,
    required this.text,
    required this.onPressed,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.brown),
        borderRadius: BorderRadius.circular(3.0),
        gradient: LinearGradient(
          begin: FractionalOffset.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.orange, Colors.yellow],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: buttonKey,
          onTap: onPressed,
          child: Center(
            child:
                child ??
                Text(text, style: TextStyle(fontSize: 17, color: Colors.black)),
          ),
        ),
      ),
    );
  }
}
