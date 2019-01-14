import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class WebKey {

  static WebKey _instance;
  static Future<WebKey> instance() async {
    if (_instance == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _instance = new WebKey(prefs);
    }
    return _instance;
  }

  final SharedPreferences _prefs;
  String _key;

  WebKey(this._prefs): _key = _prefs.getString('web_key');

  String get() {
    return _key;
  }

  bool isSet() {
    return get() != null && get().isNotEmpty;
  }

  void set(String key) async {
    _key = key;
    // We're running this in the background
    _prefs.setString('web_key', _key);
  }

}