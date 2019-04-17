import 'dart:io';

import 'package:cafeteria_scanner/data/cafetertia.dart';
import 'package:cafeteria_scanner/data/meal_scanner.dart';
import 'package:cafeteria_scanner/modals/snack_bars.dart';
import 'package:cafeteria_scanner/modals/source_picker.dart';
import 'package:cafeteria_scanner/pages/black_loading_page.dart';
import 'package:cafeteria_scanner/pages/connect_page.dart';
import 'package:cafeteria_scanner/pages/crop_page.dart';
import 'package:cafeteria_scanner/pages/select_page.dart';
import 'package:cafeteria_scanner/pages/show_page.dart';
import 'package:cafeteria_scanner/web/connection_storage.dart';
import 'package:cafeteria_scanner/web/web_api.dart';
import 'package:cafeteria_scanner/web/web_connection.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  WebConnection connection;

  _HomePageState() {
    _fetchWebConnection();
  }

  void _fetchWebConnection() async {
    connection = await ConnectionStorage().fetchConnection();
    if (connection != null) {
      // The connection changed and we update the view
      setState(() {});
    }
  }

  void _onCredentialsInvalid() async {
    setState(() {
      connection = null;
    });
    ConnectionStorage().deleteConnection();
  }

  bool _isConnAvailable() {
    return connection != null;
  }

  void _openConnectPage() async {
    final newConn = await Navigator.of(context).push<WebConnection>(
      MaterialPageRoute(
          builder: (context) =>
              ConnectPage(
                initialConnection: connection,
              )),
    );

    if (newConn != null) {
      connection = newConn;
      ConnectionStorage().saveConnection(connection);
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('CafeteriaScanner'),
      actions: <Widget>[
        Builder(builder: (context) {
          return IconButton(
            icon: new Icon(Icons.language),
            onPressed: _openConnectPage,
            tooltip: "Open the connect page",
          );
        }),
      ],
    );
  }

  Widget _buildConnectBodyText() {
    final theme = Theme
        .of(context)
        .textTheme;

    return Column(
      children: <Widget>[
        FlatButton(
          onPressed: _openConnectPage,
          child: Text('Connect', style: theme.display1),
        ),
        Text(
          'to upload the menu',
          style: theme.headline.copyWith(color: theme.display1.color),
          textAlign: TextAlign.center,
        ),
      ],
      mainAxisSize: MainAxisSize.min,
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: _isConnAvailable()
            ? Text('Select a image',
            style: Theme
                .of(context)
                .textTheme
                .display1)
            : _buildConnectBodyText(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _PhotoActionButton(
        connection: connection,
        onCredentialsInvalid: _onCredentialsInvalid,
      ),
    );
  }
}

class _PhotoActionButton extends StatefulWidget {
  final WebConnection connection;
  final VoidCallback onCredentialsInvalid;

  _PhotoActionButton({this.connection, this.onCredentialsInvalid});

  @override
  _PhotoActionButtonState createState() => _PhotoActionButtonState();
}

class _PhotoActionButtonState extends State<_PhotoActionButton> {
  bool _testingConnection = false;

  bool _isConnAvailable() {
    return this.widget.connection != null;
  }

  Future<bool> _checkConnectionBeforeStart(BuildContext context) async {
    if (!_isConnAvailable()) {
      widget.onCredentialsInvalid();
      return false;
    }

    setState(() {
      _testingConnection = true;
    });
    final result = await TimetableApi.testKeyConn(widget.connection);
    setState(() {
      _testingConnection = false;
    });
    if (result == TestResult.success) {
      return true;
    }

    SnackBar snackBar;

    if (result == TestResult.no_connection) {
      snackBar = ColorSnackBars(
        text: 'There is no connection to the internet',
        actionText: 'Ignore',
        onActionPressed: () => _pickImage(context, false),
      ).warning();
    } else if (result == TestResult.timeout) {
      snackBar = ColorSnackBars(
        text: 'Couldn\'t connect to the API (timeout)',
        actionText: 'Ignore',
        onActionPressed: () => _pickImage(context, false),
      ).warning();
    } else {
      snackBar = ColorSnackBars(
        text: 'Please reconnect to your API. There was an error!',
      ).failure();
      Scaffold.of(context).showSnackBar(snackBar);

      widget.onCredentialsInvalid();
    }

    Scaffold.of(context).hideCurrentSnackBar();
    Scaffold.of(context).showSnackBar(snackBar);

    return false;
  }

  void _pickImage(BuildContext context, bool checkCredentials) async {
    if (checkCredentials) {
      // Abort if the credentials changed and are now invalid
      if (!await _checkConnectionBeforeStart(context)) {
        return;
      }
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SourcePickerModal(),
    );
    if (source == null) {
      return;
    }

    final image = await ImagePicker.pickImage(source: source);
    if (image == null) {
      return;
    }

    _scanFlow(image, context);
  }

  void _scanFlow(File image, BuildContext context) async {
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

    MealScanner scanner;
    try {
      scanner = new MealScanner(cropped);
      await scanner.scan();
    } catch (e) {
      nav.pop();

      final snackBar = ColorSnackBars(
          text: 'The scanner could find any results: ${e.runtimeType}')
          .failure();
      Scaffold.of(context).showSnackBar(snackBar);

      return;
    }

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
      builder: (context) =>
      new ShowPage(
        scanner: scanner,
        connection: widget.connection,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.camera_alt),
      backgroundColor:
      _isConnAvailable() && !_testingConnection ? null : Colors.grey,
      tooltip: _isConnAvailable()
          ? 'Take a photo'
          : 'First connect, then you can take a photo',
      onPressed: _isConnAvailable() && !_testingConnection
          ? () => _pickImage(context, true)
          : null,
    );
  }
}
