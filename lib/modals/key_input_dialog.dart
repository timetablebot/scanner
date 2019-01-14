import 'package:cafeteria_scanner/modals/input_dialog.dart';
import 'package:cafeteria_scanner/modals/snack_bars.dart';
import 'package:cafeteria_scanner/web/web_api.dart';
import 'package:cafeteria_scanner/web/web_key.dart';
import 'package:flutter/material.dart';

class _KeyInputDialog extends StatelessWidget {
  final WebKey webKey;

  _KeyInputDialog(this.webKey);

  @override
  Widget build(BuildContext context) {
    return new InputDialog(
      title: "Set a key",
      initialText: webKey.get() ?? '',
    );
  }
}

Future<String> showKeyInputDialog(BuildContext context, {WebKey webKey}) async {
  if (webKey == null) {
    webKey = await WebKey.instance();
  }

  final newKey = await showDialog<String>(
    context: context,
    builder: (context) => _KeyInputDialog(webKey),
  );

  if (newKey == null) {
    return '';
  }

  webKey.set(newKey);

  return newKey;
}

Future<void> checkNSnack(WebKey webKey, BuildContext context) async {
  final valid = await TimetableApi.testKey(webKey.get());

  SnackBar snackBar;
  if (valid) {
    snackBar = ColorSnackBars(
      context: context,
      text: 'The key is valid',
    ).success();
  } else {
    snackBar = ColorSnackBars(
      context: context,
      text: 'The key is invalid',
    ).failure();
  }

  Scaffold.of(context).hideCurrentSnackBar();
  Scaffold.of(context).showSnackBar(snackBar);
}
