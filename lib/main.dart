import 'package:cafeteria_scanner/input_dialog.dart';
import 'package:cafeteria_scanner/show_page.dart';
import 'package:cafeteria_scanner/source_picker.dart';
import 'package:cafeteria_scanner/web_key.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(new MyApp());

// todo add bottomsheet for selecting source
// https://docs.flutter.io/flutter/material/BottomSheet-class.html
// todo add loader
// https://docs.flutter.io/flutter/material/CircularProgressIndicator-class.html
// todo add new page for thing with photo
// abort button left above & upload floating button & api diag

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
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'CafeteriaScanner'),
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
  Widget _sourcePicker;

  void _alertWebKey() async {
    final setKey = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return new AlertDialog(
          title: new Text("Warning"),
          content: new SingleChildScrollView(
            child: new Text("You have to set a web key"),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text("OK"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            new FlatButton(
              child: new Text("Set"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (setKey) {
      _enterWebKey();
    }
  }

  void _enterWebKey() async {
    final webKey = await WebKey.instance();
    final key = await showDialog(
        builder: (context) => new InputDialog(
              title: "Set a Web Key",
              initialText: webKey.get() ?? '',
            ),
        context: context);

    if (key == null) {
      return;
    }

    webKey.set(key);
  }

  void _pickImageSource() async {
    final webKey = await WebKey.instance();
    if (!webKey.isSet()) {
      _alertWebKey();
      return;
    }

    showModalBottomSheet(context: context, builder: (context) => _sourcePicker);
  }

  void _pickImage(ImageSource source) async {
    Navigator.pop(context);

    final image = await ImagePicker.pickImage(source: source);
    if (image == null) {
      return;
    }

    Navigator.of(context).push(new MaterialPageRoute(
      builder: (context) => ShowPage(image: image),
    ));
  }

  @override
  void initState() {
    super.initState();
    _sourcePicker = new SourcePickerModal(_pickImage);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
        actions: <Widget>[
          new IconButton(
              icon: new Icon(Icons.vpn_key),
              onPressed: _enterWebKey,
              tooltip: "Set the Web Key"),
        ],
      ),
      body: new Center(
        child: new Text(
          'Select a image',
          style: Theme.of(context).textTheme.display1,
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _pickImageSource,
        tooltip: 'Photo',
        child: new Icon(Icons.camera_alt),
      ),
    );
  }
}
