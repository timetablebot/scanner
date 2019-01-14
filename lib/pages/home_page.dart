import 'dart:io';

import 'package:cafeteria_scanner/data/cafetertia.dart';
import 'package:cafeteria_scanner/data/meal_scanner.dart';
import 'package:cafeteria_scanner/modals/key_input_dialog.dart';
import 'package:cafeteria_scanner/modals/source_picker.dart';
import 'package:cafeteria_scanner/pages/black_loading_page.dart';
import 'package:cafeteria_scanner/pages/crop_page.dart';
import 'package:cafeteria_scanner/pages/select_page.dart';
import 'package:cafeteria_scanner/pages/show_page.dart';
import 'package:cafeteria_scanner/web/web_key.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hasWebKey = false;

  _HomePageState() {
    _checkForWebKey();
  }

  void _checkForWebKey() async {
    final key = await WebKey.instance();
    setState(() {
      _hasWebKey = key.isSet();
    });
  }

  void _enterWebKey(BuildContext context) async {
    final webKey = await WebKey.instance();
    await showKeyInputDialog(context, webKey: webKey);
    checkNSnack(webKey, context);
    setState(() {
      _hasWebKey = webKey.isSet();
    });
  }

  void _pickImageSource() async {
    showModalBottomSheet(
        context: context, builder: (context) => SourcePickerModal(_pickImage));
  }

  void _pickImage(ImageSource source) async {
    Navigator.pop(context);

    final image = await ImagePicker.pickImage(source: source);
    if (image == null) {
      return;
    }

    _scanFlow(image);
  }

  void _scanFlow(File image) async {
    final nav = Navigator.of(context);

    // Cropping

    File cropped = await nav.push(new MaterialPageRoute(
      builder: (context) => new CropPage(image),
    ));

    if (cropped == null) {
      return;
    }

    // Scanner Init

    nav.push(new MaterialPageRoute(
      builder: (context) => new BlackLoadingPage(),
    ));

    var scanner = new MealScanner(cropped);
    await scanner.scan();

    nav.pop();

    // Select boxes

    List<Meal> meals = await nav.push(new MaterialPageRoute(
      builder: (context) => new SelectSwipePage(scanner: scanner),
    ));

    if (meals == null) {
      return;
    }

    // Show

    nav.push(new MaterialPageRoute(
      builder: (context) => new ShowPage(scanner: scanner),
    ));
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('CafeteriaScanner'),
      actions: <Widget>[
        Builder(builder: (context) {
          return IconButton(
            icon: new Icon(Icons.vpn_key),
            onPressed: () => _enterWebKey(context),
            tooltip: "Set a key",
          );
        }),
      ],
    );
  }

  Widget _buildBody() {
    return Center(
      child: Text(
        _hasWebKey ? 'Select a image' : 'Set a key',
        style: Theme.of(context).textTheme.display1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _PhotoKeyActionButton(
        hasKey: _hasWebKey,
        onTap: (context) =>
            _hasWebKey ? _pickImageSource() : _enterWebKey(context),
      ),
    );
  }
}

typedef ContextCallback = void Function(BuildContext context);

class _PhotoKeyActionButton extends StatelessWidget {
  final bool hasKey;
  final ContextCallback onTap;

  _PhotoKeyActionButton({this.hasKey, this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => onTap(context),
      tooltip: hasKey ? 'Photo' : 'Key',
      child: new Icon(hasKey ? Icons.camera_alt : Icons.vpn_key),
    );
  }
}
