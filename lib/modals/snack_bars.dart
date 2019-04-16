import 'package:flutter/material.dart';

class ColorSnackBars {
  final BuildContext context;
  final String text;

  ColorSnackBars({this.context, this.text});

  SnackBar _create(IconData icon, Color color) {
    return SnackBar(
      content: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(icon),
          ),
          Expanded(
            child: Text(
              this.text,
            ),
          ),
        ],
      ),
      backgroundColor: color,
    );
  }

  SnackBar success() {
    return _create(Icons.check, Colors.green);
  }

  SnackBar failure() {
    return _create(Icons.clear, Colors.red);
  }
}
