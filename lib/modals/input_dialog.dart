import 'package:flutter/material.dart';

class InputDialog extends StatelessWidget {
  final String title;
  final String initialText;
  final TextInputType inputType;
  final TextEditingController _controller;

  InputDialog(
      {@required this.title,
      this.initialText: '',
      this.inputType: TextInputType.text}):
      _controller = _buildController(initialText);

  static TextEditingController _buildController(String initialText) {
    return TextEditingController.fromValue(TextEditingValue(
      text: initialText,
      selection: TextSelection.collapsed(offset: initialText.length),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
        title: Text(title),
        // Bottom 16 - 4, because we want only 20
        contentPadding: EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 0.0),
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
            child: new TextField(
              keyboardType: inputType,
              controller: _controller,
              onSubmitted: (text) => Navigator.of(context).pop(text),
              autofocus: true,
              maxLines: null,
            ),
          ),
          new ButtonTheme.bar(
            child: ButtonBar(
              children: <Widget>[
                FlatButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                FlatButton(
                  child: Text('Save'),
                  onPressed: () => Navigator.of(context).pop(_controller.text),
                ),
              ],
            ),
          )
        ]);
  }
}
