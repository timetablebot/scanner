import 'package:flutter/material.dart';

class TextDialog extends StatelessWidget {
  final String title;
  final String text;
  final FlatButton button;

  TextDialog({@required this.title, @required this.text, this.button});

  List<Widget> _buildButtons(BuildContext context) {
    final list = new List<Widget>();

    if (this.button != null) {
      list.length = 2;
      list.add(this.button);
    }

    list.add(FlatButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text('OK'),
    ));

    return list;
  }

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
        ButtonBar(children: _buildButtons(context))
      ],
    );
  }
}
