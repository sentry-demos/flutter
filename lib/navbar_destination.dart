import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class Destination {
  IconData icon;
  String title;
  Widget child;

  Destination(this.icon,this.title);

  Destination.withChild(this.icon,this.title,this.child);
}

class DestinationView extends StatefulWidget{
  const DestinationView({Key key, this.destination}):super(key:key);
  final Destination destination;
  @override
  _DestinationViewState createState() => _DestinationViewState();

}

class _DestinationViewState extends State<DestinationView>{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
      title:Text(widget.destination.title)),
        body:Container(

          padding: const EdgeInsets.all(0.0),
          alignment: Alignment.center,
          child: widget.destination.child
        )

    );


  }
}