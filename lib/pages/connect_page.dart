import 'package:cafeteria_scanner/modals/snack_bars.dart';
import 'package:cafeteria_scanner/web/web_api.dart';
import 'package:cafeteria_scanner/web/web_connection.dart';
import 'package:flutter/material.dart';

class ConnectPage extends StatefulWidget {
  final WebConnection initialConnection;

  ConnectPage({this.initialConnection});

  @override
  State createState() => ConnectPageState();
}

class ConnectPageState extends State<ConnectPage> {
  Future<void> _checkConn(BuildContext context, WebConnection conn) async {
    final result = await TimetableApi.testKeyConn(conn);

    final colorSnackBar = ColorSnackBars(
      context: context,
      text: _getTestResultText(result),
    );
    final snackBar = result == TestResult.success
        ? colorSnackBar.success()
        : colorSnackBar.failure();

    Scaffold.of(context).hideCurrentSnackBar();
    Scaffold.of(context).showSnackBar(snackBar);

    if (result == TestResult.success) {
      Future.delayed(const Duration(milliseconds: 1000),
          () => Navigator.of(context).pop(conn));
    }
  }

  String _getTestResultText(TestResult result) {
    switch (result) {
      case TestResult.success:
        return 'Connected to the Scanner API';
      case TestResult.redirect:
        return 'The given URL redirects. Did you forget https://?';
      case TestResult.push_key_config:
        return 'You have to set a push key in the .env.local file';
      case TestResult.unauthorized:
        return 'The Push Key isn\'t correct';
      case TestResult.not_found:
        return 'Can\'t find a Scanner API at the given URL';
      case TestResult.timeout:
        return 'The request couldn\'t answered in time';
      case TestResult.no_connection:
        return 'There is no connection to the internet';
      case TestResult.error:
      default:
        return 'There was an error';
    }
  }

  // https://flutter.dev/docs/cookbook/forms/validation
  Widget _buildForm() {
    return SingleChildScrollView(
      child: ConnectForm(
        onCheckConnection: _checkConn,
        initialConn: widget.initialConnection != null
            ? widget.initialConnection
            : WebConnection(baseUrl: '', pushKey: ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect'),
      ),
      // backgroundColor: Colors.blue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Center(
            child: _buildForm(),
          ),
        ),
      ),
    );
  }
}

typedef ConnCheckCallback = Future<void> Function(
    BuildContext context, WebConnection conn);

class ConnectForm extends StatefulWidget {
  final ConnCheckCallback onCheckConnection;
  final WebConnection initialConn;

  ConnectForm({@required this.onCheckConnection, @required this.initialConn});

  @override
  State createState() => ConnectFormState();
}

class ConnectFormState extends State<ConnectForm> {
  final _formKey = GlobalKey<FormState>();
  final _focusKey = FocusNode();
  bool _checkingConnection = false;

  String _baseUrl;
  String _pushKey;

  void _checkForm(BuildContext context) async {
    if (_checkingConnection) {
      return;
    }

    if (!_formKey.currentState.validate()) {
      return;
    }

    _formKey.currentState.save();

    final conn = WebConnection(baseUrl: _baseUrl, pushKey: _pushKey);
    setState(() {
      _checkingConnection = true;
    });
    await widget.onCheckConnection(context, conn);
    setState(() {
      _checkingConnection = false;
    });
  }

  List<Widget> _buildList() {
    return <Widget>[
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Connect this app to your Scanner API\n by entering its details.',
          textAlign: TextAlign.center,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          decoration: InputDecoration(
            hintText: 'Server URL',
            icon: Icon(Icons.language),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          initialValue: widget.initialConn.baseUrl,
          onEditingComplete: () {
            FocusScope.of(context).requestFocus(_focusKey);
          },
          validator: (content) {
            if (content.isEmpty) {
              return 'Please enter a Server URL';
            } else if (!content.startsWith('http://') &&
                !content.startsWith('https://')) {
              return 'The Server URL must start with http:// or https://';
            } else if (content.contains(' ')) {
              return 'The Server URL may not contain spaces';
            }
          },
          onSaved: (content) => _baseUrl = content,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          focusNode: _focusKey,
          decoration: InputDecoration(
            hintText: 'Push Key',
            icon: Icon(Icons.vpn_key),
            border: OutlineInputBorder(),
          ),
          initialValue: widget.initialConn.pushKey,
          onEditingComplete: () {
            // Hiding the keyboard
            FocusScope.of(context).requestFocus(new FocusNode());
            _checkForm(context);
          },
          validator: (content) {
            if (content.isEmpty) {
              return 'Please enter a Push Key';
            }
          },
          onSaved: (content) => _pushKey = content,
        ),
      ),
      ConnectButton(
        checking: _checkingConnection,
        onCheckStart: _checkForm,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidate: false,
      child: Column(children: _buildList()),
    );
  }
}

typedef ContextCallback = void Function(BuildContext context);

class ConnectButton extends StatelessWidget {
  final bool checking;
  final ContextCallback onCheckStart;

  ConnectButton({this.checking, this.onCheckStart});

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: !checking ? () => onCheckStart(context) : null,
      child: Text(!checking ? 'Connect' : 'Checking...'),
    );
  }
}
