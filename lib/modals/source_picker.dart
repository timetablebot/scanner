import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SourcePickerModal extends StatelessWidget {

  ListTile _generateTile(IconData icon, String text, ImageSource source,
      BuildContext context) {
    return new ListTile(
        title: new Text(text),
        leading: new Icon(icon),
        onTap: () => Navigator.of(context).pop(source));
  }

  @override
  Widget build(BuildContext context) {
    return new Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _generateTile(Icons.image, "Files", ImageSource.gallery, context),
        _generateTile(Icons.camera, "Camera", ImageSource.camera, context),
      ],
    );
  }
}

typedef PickedSource = void Function(ImageSource source);
