import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cafeteria_scanner/data/cafetertia.dart';
import 'package:diff_match_patch/diff_match_patch.dart' as diffMatch;
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/rendering.dart';

class MealScanner {
  static const Map<int, String> _dayNames = {
    DateTime.monday: "Montag",
    DateTime.tuesday: "Dienstag",
    DateTime.wednesday: "Mittwoch",
    DateTime.thursday: "Donnerstag",
    DateTime.friday: "Freitag",
    DateTime.saturday: "Samstag",
    DateTime.sunday: "Sonntag",
  };

  static final _additivesRegex = RegExp(r" (?:[.,0-9a-z]+)$", multiLine: true);

  /*
      private final static Pattern TIME_PATTERN = Pattern.compile(
            "die Woche vom (\\d+).(\\d*).?\\s*-\\s*(?:\\d+).(\\d+).(\\d+)");
    private final static Pattern ADDITIVES_PATTERN = Pattern.compile(
            "(?:\\d| \\d|,\\d| ,\\d)([, 0-9a-i]+)");
    private static final Pattern PRICE_PATTERN = Pattern.compile(
            "(\\d+),(\\d+) *€");
   */

  final File file;

  List<TextBlock> _textBlocks;
  Rectangle<int> _imgBindings;
  Rectangle<int> _textBindings;
  Map<int, Rectangle<int>> _dayBindings;
  DateTime _monday;

  MealScanner(this.file);

  DateTime get monday => _monday;

  Future<List<Meal>> scan() async {
    _textBlocks = await _scanTextVision();

    final debugTextOut = _textBlocks
        .map((TextBlock block) => block.text + " (${block.boundingBox})")
        .join("\n");
    print("TextBlocks: $debugTextOut \n\n");

    _imgBindings = await _scanBindings();
    _textBindings = await _scanTextBindings();
    _dayBindings = await _searchDayBindings();
    _monday = _calcMonday();

    // Sorting meals before returning
    final meals = await _extractNearestBoxes();
    meals.sort();
    return meals;
  }

  Future<List<TextBlock>> _scanTextVision() async {
    final visionImage = FirebaseVisionImage.fromFile(file);
    final detector = FirebaseVision.instance.textDetector();
    return await detector.detectInImage(visionImage);
  }

  Future<Rectangle<int>> _scanBindings() async {
    // https://stackoverflow.com/a/44668879
    final completer = new Completer<Rectangle<int>>();
    FileImage(file)
        .resolve(ImageConfiguration())
        .addListener((ImageInfo info, bool _) {
      final image = info.image;
      completer.complete(new Rectangle(0, 0, image.width, image.height));
    });

    return completer.future;
  }

  Future<Rectangle<int>> _scanTextBindings() async {
    var upperBorder = _imgBindings.top;
    var lowerBorder = _imgBindings.bottom;

    for (var textBlock in _textBlocks) {
      final text = textBlock.text.toLowerCase();
      final bindings = textBlock.boundingBox;

      if (text.contains('speiseplan')) {
        upperBorder = bindings.bottom;
      } else if (text.contains('täglich') || text.contains('tomatensoße')) {
        lowerBorder = bindings.top;
      }
    }

    return new Rectangle(
        0, upperBorder, _imgBindings.width, lowerBorder - upperBorder);
  }

  Future<Map<int, Rectangle<int>>> _searchDayBindings() async {
    final map = Map<int, Rectangle<int>>();
    final halfWidth = _imgBindings.width / 2.0;

    for (var block in _textBlocks) {
      // Day names are never on the left part of the page
      if (block.boundingBox.right > halfWidth) {
        continue;
      }

      if (!_textBindings.containsRectangle(block.boundingBox)) {
        continue;
      }

      final blockText = block.text;

      // Day names can't be longer than 15 characters
      if (blockText.length > 15) {
        continue;
      }

      var levenshteinMin = 100;
      var bestMatchingDay = 0;

      for (var entry in _dayNames.entries) {
        final dayName = entry.value.trim().toLowerCase();

        // Trying to match the day name by using normal text operations
        if (dayName == blockText.trim().toLowerCase()) {
          map[entry.key] = block.boundingBox;
          print("Found using fast comp: $dayName");
          break;
        }

        // Trying to match the day name by using Levenshtein
        final textDiffs = diffMatch.diff(dayName, blockText);
        final levenshtein = diffMatch.levenshtein(textDiffs);

        if (levenshtein > 3) {
          // This difference is too big, so we skip it
          continue;
        }

        if (levenshtein < levenshteinMin) {
          levenshteinMin = levenshtein;
          bestMatchingDay = entry.key;
        }
      }

      if (levenshteinMin == 100 || bestMatchingDay == 0) {
        // We found nothing
        continue;
      }

      map[bestMatchingDay] = block.boundingBox;
      print("Found using normal comp: $bestMatchingDay");
    }

    return map;
  }

  DateTime _calcMonday() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final difference = weekday - DateTime.monday;

    final subtracted = DateTime.now().subtract(new Duration(days: difference));
    return DateTime.utc(subtracted.year, subtracted.month, subtracted.day)
        .toLocal();
  }

  Future<List<Meal>> _extractNearestBoxes() async {
    final meals = List<Meal>();
    final tenthDifference = _imgBindings.height * 0.1;

    for (var dayBinding in _dayBindings.entries) {
      print("DayBinding: " +
          dayBinding.key.toString() +
          " Rect: " +
          dayBinding.value.toString());

      final rightX = dayBinding.value.right;
      final topY = dayBinding.value.top;
      final minY = topY - tenthDifference;
      final maxY = topY + tenthDifference;

      int yDifference = -1;
      TextBlock bestMatch;

      for (var textBlock in _textBlocks) {
        final blockBox = textBlock.boundingBox;

        if (textBlock.text.length < 20) {
          continue;
        }

        // The box shouldn't be left of the box with the day name
        if (blockBox.left < rightX) {
          continue;
        }

        if (!_textBindings.containsRectangle(blockBox)) {
          continue;
        }

        // The box should not be over or under the deviation
        if (minY > blockBox.top || blockBox.top > maxY) {
          continue;
        }

        final difference = (topY - blockBox.top).abs();
        if (yDifference == -1 || difference < yDifference) {
          yDifference = difference;
          bestMatch = textBlock;
        }
      }

      if (bestMatch == null) {
        // Can't find a text block matching the criteria
        continue;
      }

      final additivesRegexMatch = _additivesRegex.firstMatch(bestMatch.text);
      // todo prevent money match
      if (additivesRegexMatch != null &&
          additivesRegexMatch.end + 15 < bestMatch.text.length) {
        // There's the second bloc included in this text
        meals.add(_generateMeal(
          day: dayBinding.key,
          text: bestMatch.text.substring(additivesRegexMatch.end + 1),
          price: 3.5,
          vegetarian: true,
        ));
      } else {
        final secondMeal = _findSecondMealBloc(bestMatch, dayBinding.key);
        if (secondMeal != null) {
          meals.add(secondMeal);
        }
      }

      // We found the correct box.
      meals.add(_generateMeal(
        day: dayBinding.key,
        text: bestMatch.text,
        price: 3.95,
        vegetarian: false,
      ));

      // TODO: Match additives descriptions and check if it's could be two lines
      // TODO: Also detect the box under this box => Not Veg & 3.50€
      // TODO: If there are more than two additives => Next day
    }

    return meals;
  }

  Meal _findSecondMealBloc(TextBlock nearBlock, int day) {
    final twentiethDifference = _imgBindings.height * 0.1;

    int matchScore = -1;
    TextBlock bestMatch;

    for (var textBlock in _textBlocks) {
      // We skip the nearest text block
      if (textBlock == nearBlock) {
        continue;
      }

      if (_isDayName(textBlock.text)) {
        continue;
      }

      // We don't want boxes which are over the nearest box
      if (nearBlock.boundingBox.bottom <
          textBlock.boundingBox.bottom - twentiethDifference) {
        continue;
      }

      if (!_textBindings.containsRectangle(textBlock.boundingBox)) {
        continue;
      }

      final nearY = textBlock.boundingBox.bottom - nearBlock.boundingBox.bottom;
      final nearX = textBlock.boundingBox.left - nearBlock.boundingBox.left;
      final blockScore = nearY.abs() * 5 + nearX.abs();

      if (blockScore < matchScore || matchScore < 0) {
        matchScore = blockScore;
        bestMatch = textBlock;
      }
    }

    if (bestMatch == null) {
      return null;
    }

    return _generateMeal(
      day: day,
      text: bestMatch.text,
      price: 3.5,
      vegetarian: true,
    );
  }

  bool _isDayName(String text) {
    for (var dayName in _dayNames.values) {
      if (text.toLowerCase().trim() == dayName.toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  bool _areAddtivies(String text) {
    // only small, number, .,
  }

  Meal _generateMeal({int day, String text, double price, bool vegetarian}) {
    return new Meal(
        day: _monday.add(new Duration(days: day - DateTime.monday)),
        description: text,
        price: price,
        vegetarian: vegetarian);
  }
}
