import 'dart:io';

import 'package:cafeteria_scanner/data/cafetertia.dart';
import 'package:cafeteria_scanner/data/meal_scanner.dart';
import 'package:cafeteria_scanner/modals/key_input_dialog.dart';
import 'package:cafeteria_scanner/modals/source_picker.dart';
import 'package:cafeteria_scanner/pages/black_loading_page.dart';
import 'package:cafeteria_scanner/pages/crop_page.dart';
import 'package:cafeteria_scanner/pages/home_page.dart';
import 'package:cafeteria_scanner/pages/select_page.dart';
import 'package:cafeteria_scanner/pages/show_page.dart';
import 'package:cafeteria_scanner/web/web_key.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'CafeteriaScanner',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.

        // https://material.io/tools/color/#!/?view.left=0&view.right=0&primary.color=FFA000

        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _hasWebKey = false;

  _MyHomePageState() {
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

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
        actions: <Widget>[
          new IconButton(
              icon: new Icon(Icons.vpn_key),
              onPressed: () => _enterWebKey(context),
              tooltip: "Set a key"),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: new FloatingActionButton(
        onPressed: _hasWebKey ? _pickImageSource : () => _enterWebKey(context),
        tooltip: _hasWebKey ? 'Photo' : 'Key',
        child: new Icon(_hasWebKey ? Icons.camera_alt : Icons.vpn_key),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return new Center(
      child: new Text(
        _hasWebKey ? 'Select a image' : 'Set a key',
        style: Theme.of(context).textTheme.display1,
      ),
    );
  }
}
