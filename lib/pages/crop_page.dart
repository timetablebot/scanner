import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';

// https://pub.dartlang.org/packages/image_crop
// TODO: Problem when first opening the app -> Nothing to crop

class CropPage extends StatefulWidget {
  final File image;

  CropPage(this.image);

  @override
  State createState() => CropPageState(image);
}

class CropPageState extends State<CropPage> {
  final _cropKey = GlobalKey<CropState>();
  final File image;

  CropPageState(this.image);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
      child: _buildCropping(context),
    );
  }

  Widget _buildCropping(BuildContext context) {
    final _buttonStyle =
        Theme.of(context).textTheme.button.copyWith(color: Colors.white);

    return Column(
      children: <Widget>[
        Expanded(
          child: Crop.file(
            image,
            key: _cropKey,
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 20.0),
          alignment: AlignmentDirectional.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              FlatButton(
                child: Text('Crop & Scan', style: _buttonStyle),
                onPressed: onCropFinished,
              )
            ],
          ),
        )
      ],
    );
  }

  void onCropFinished() async {
    final scale = _cropKey.currentState.scale;
    final area = _cropKey.currentState.area;
    if (area == null) {
      // couldn't crop
      Navigator.of(context).pop();
    }

    final cropped = await ImageCrop.cropImage(
      file: this.image,
      area: area,
      scale: scale,
    );
    Navigator.of(context).pop(cropped);
  }
}
