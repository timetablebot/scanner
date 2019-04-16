// https://flutter.io/cookbook/networking/fetch-data/
// https://pub.dartlang.org/packages/http
// https://flutter.io/cookbook/networking/background-parsing/

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cafeteria_scanner/data/cafetertia.dart';
import 'package:cafeteria_scanner/web/web_connection.dart';
import 'package:connectivity/connectivity.dart';

class TimetableApi {
  static const _webKeyError = "Invalid web key";

  static Future<TestResult> testKeyConn(WebConnection conn) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      return TestResult.no_connection;
    }

    try {
      final response =
      await conn.post('push/test').timeout(const Duration(seconds: 5));

      switch (response.statusCode) {
        case 200:
          return TestResult.success;
        case 302:
          return TestResult.redirect;
        case 401:
          return TestResult.unauthorized;
        case 501:
          return TestResult.push_key_config;
        default:
          return TestResult.not_found;
      }
    } on TimeoutException catch (_) {
      return TestResult.timeout;
    } on SocketException catch (e) {
      print(e);

      if (e.message.toLowerCase().contains('failed host lookup')) {
        return TestResult.not_found;
      }

      return TestResult.error;
    } catch (e) {
      print(e);
      return TestResult.error;
    }
  }

  static Future<PushAnswer> uploadChanges(WebConnection conn,
      List<Meal> meals) async {
    final response = await conn.post('push', body: json.encode(meals));
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
        message: 'Invalid Push Key',
        updates: null,
        error: PushError(
          full: _webKeyError,
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

enum TestResult {
  success,
  unauthorized,
  push_key_config,
  redirect,
  not_found,
  error,
  no_connection,
  timeout,
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

  get invalidWebKey => full == TimetableApi._webKeyError;
}
