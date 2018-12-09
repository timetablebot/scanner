// TODO: Add request
// https://flutter.io/cookbook/networking/fetch-data/
// https://pub.dartlang.org/packages/http
// https://flutter.io/cookbook/networking/background-parsing/

import 'dart:convert';

import 'package:cafeteria_scanner/data/cafetertia.dart';
import 'package:cafeteria_scanner/web/web_key.dart';
import 'package:http/http.dart' as http;

class TimetableApi {

  static const baseUrl = "https://api.stundenplanbot.ga/";

  static Future<String> _buildUrl(String method) async {
    final webKey = await WebKey.instance();
    if (!webKey.isSet()) {

    }

    return baseUrl + method + "?key=" + Uri.encodeQueryComponent(webKey.get());
  }

  static Future<PushAnswer> uploadChanges(List<Meal> meals) async {
    final url = await _buildUrl('push');
    await http.post(url, body: json.encode(meals));

    return null;
  }

}

class PushAnswer {

  /* final String message;
  final String extraFull;
  final String extraInvalid; */
  // TODO: Save changes

}