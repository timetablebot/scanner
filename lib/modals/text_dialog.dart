import 'package:flutter/material.dart';

class TextDialog extends StatelessWidget {
  final String title;
  final String text;

  TextDialog({this.title, this.text});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(this.title),
      contentPadding: EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
          child: SingleChildScrollView(
            child: Text(this.text),
          ),
        ),
        ButtonBar(
          children: <Widget>[
            FlatButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            )
          ],
        )
      ],
    );
  }
}
