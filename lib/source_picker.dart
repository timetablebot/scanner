import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SourcePickerModal extends StatelessWidget {
  SourcePickerModal(this._pickedSource);

  final PickedSource _pickedSource;

  ListTile _generateTile(IconData icon, String text, ImageSource source) {
    return new ListTile(
      title: new Text(text),
      leading: new Icon(icon),
      onTap: () => _pickedSource(source),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _generateTile(Icons.image, "Files", ImageSource.gallery),
        _generateTile(Icons.camera, "Camera", ImageSource.camera),
      ],
    );
  }
}

typedef PickedSource = void Function(ImageSource source);
