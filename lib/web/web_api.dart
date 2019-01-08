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
    if (!webKey.isSet()) {}

    return baseUrl + method + "?key=" + Uri.encodeQueryComponent(webKey.get());
  }

  static Future<PushAnswer> uploadChanges(List<Meal> meals) async {
    // TODO: Throw error
    final url = await _buildUrl('push');
    final response = await http.post(url, body: json.encode(meals));
    final contentType = response.headers['Content-Type'];

    if (response.statusCode == 200) {
      // Everything worked
      Map<String, dynamic> json = jsonDecode(response.body);
      // Map<int, Map<String, bool>>
      Map<String, dynamic> changes = json['changes'];
      final pushedMeals = new List<PushedMeal>();
      final baseTime = DateTime.utc(1970);

      for (var dayChanges in changes.entries) {
        final epochDay = int.parse(dayChanges.key);
        final day = baseTime.add(Duration(days: epochDay));

        Map<String, dynamic> dayTypesMap = dayChanges.value;
        for (var typeChanges in dayTypesMap.entries) {
          final vegetarian = typeChanges.key == 'vegetarian';
          final created = typeChanges.value;

          pushedMeals.add(PushedMeal(
            day: day,
            vegetarian: vegetarian,
            created: created,
          ));
        }
      }

      return PushAnswer(
        message: json['message'],
        updates: pushedMeals,
        error: null,
      );
    } else if ((contentType == 'text/javascript' ||
            contentType == 'application/json') &&
        response.statusCode == 400) {
      // It's a json error
      Map<String, dynamic> json = jsonDecode(response.body);
      Map<String, String> extra = json['extra'];

      return PushAnswer(
        message: json['message'],
        updates: null,
        error: PushError(
          full: extra['full'],
          invalidJson: extra['invalid'],
        ),
      );
    } else if (response.statusCode == 401) {
      // Wrong web key
      return PushAnswer(
        message: 'Can\'t accept this web key',
        updates: null,
        error: PushError(
          full: '',
          invalidJson: null,
        ),
      );
    } else {
      // It's a error by the server or symfony
      return PushAnswer(
        message: 'External error: ${response.statusCode}',
        updates: null,
        error: PushError(
          full: response.body,
          invalidJson: null,
        ),
      );
    }
  }
}

class PushAnswer {
  final String message;
  final List<PushedMeal> updates;
  final PushError error;

  PushAnswer({this.message, this.updates, this.error});

  get wasError => error != null;
}

class PushedMeal {
  // Saved in UTC
  final DateTime day;
  final bool vegetarian;
  final bool created;

  PushedMeal({this.day, this.vegetarian, this.created});
}

class PushError {
  final String full;
  final String invalidJson;

  PushError({this.full, this.invalidJson});

  get externalError => invalidJson == null;
}
