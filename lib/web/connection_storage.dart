import 'package:cafeteria_scanner/web/web_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefPrefix = 'web_connection_';
const _prefBaseUrl = _prefPrefix + 'base_url';
const _prefPushKey = _prefPrefix + 'push_key';

class ConnectionStorage {
  SharedPreferences _preferences;

  Future<SharedPreferences> _openPreferences() async {
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }

    return _preferences;
  }

  Future<WebConnection> fetchConnection() async {
    final preferences = await _openPreferences();

    final baseUrl = preferences.getString(_prefBaseUrl);
    final pushKey = preferences.getString(_prefPushKey);

    if (baseUrl == null || pushKey == null) {
      return null;
    }

    return WebConnection(baseUrl: baseUrl, pushKey: pushKey);
  }

  Future<void> saveConnection(WebConnection connection) async {
    final preferences = await _openPreferences();

    preferences.setString(_prefBaseUrl, connection.baseUrl);
    preferences.setString(_prefPushKey, connection.pushKey);
  }

  Future<void> deleteConnection() async {
    final preferences = await _openPreferences();

    preferences.remove(_prefBaseUrl);
    preferences.remove(_prefPushKey);
  }
}
