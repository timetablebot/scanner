import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SourcePickerModal extends StatelessWidget {
  SourcePickerModal(this._pickedSource);

  final PickedSource _pickedSource;

  Widget _generateSourceCard(IconData icon, String text, ImageSource source) {
    return new Card(
      margin: EdgeInsets.all(15.0),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: new Column(
          children: <Widget>[
            new IconButton(
                icon: new Icon(icon),
                iconSize: 24.0 * 5,
                onPressed: () => _pickedSource(source)),
            new Text(text)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new FittedBox(
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _generateSourceCard(Icons.image, "Files", ImageSource.gallery),
          _generateSourceCard(Icons.camera_alt, "Camera", ImageSource.camera),
        ],
      ),
    );
  }
}

typedef PickedSource = void Function(ImageSource source);
