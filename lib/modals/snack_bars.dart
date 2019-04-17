import 'package:flutter/material.dart';

class ColorSnackBars {
  final String text;
  final String actionText;
  final VoidCallback onActionPressed;

  ColorSnackBars({@required this.text, this.actionText, this.onActionPressed});

  SnackBar _create({IconData icon, Color foreground, Color background}) {
    return SnackBar(
      content: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              icon,
              color: foreground,
            ),
          ),
          Expanded(
            child: Text(
              this.text,
              style: TextStyle(color: foreground),
            ),
          ),
        ],
      ),
      action: actionText != null && onActionPressed != null
          ? SnackBarAction(
        label: actionText,
        onPressed: onActionPressed,
        textColor: foreground,
      )
          : null,
      backgroundColor: background,
    );
  }

  SnackBar success() {
    return _create(
      icon: Icons.check,
      background: Colors.green,
      foreground: Colors.white,
    );
  }

  SnackBar warning() {
    return _create(
      icon: Icons.announcement,
      background: Colors.orange,
      foreground: Colors.black87,
    );
  }

  SnackBar failure() {
    return _create(
      icon: Icons.clear,
      background: Colors.red,
      foreground: Colors.white,
    );
  }
}
