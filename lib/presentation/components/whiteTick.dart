import 'package:flutter/material.dart';

class Tick extends StatelessWidget {
  final DecorationImage image;
  Tick({this.image});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250.0,
      height: 250.0,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        image: image,
      ),
    );
  }
}
