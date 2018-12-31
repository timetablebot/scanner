import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cafeteria_scanner/data/cafetertia.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

class MealScanner {
  final File _image;
  Size _imageSize;
  DateTime _baseDate;
  List<IdentifyBlock> _identifyBlocks;

  MealScanner(File file) : _image = file;

  Future<void> scan() async {
    final textBlocks = await _scanTextVision();
    _imageSize = await _scanSize();
    _identifyBlocks = await _findIdentifyBlocks(textBlocks);
    _baseDate = await _findBaseDate(_identifyBlocks);
    _populateDefaultDates(_identifyBlocks, _baseDate);
  }

  Future<Size> _scanSize() async {
    // https://stackoverflow.com/a/44668879
    final completer = new Completer<Size>();

    final imageStream = new FileImage(_image).resolve(ImageConfiguration());
    imageStream.addListener((ImageInfo info, bool _) {
      final image = info.image;
      final size = new Size(image.width.toDouble(), image.height.toDouble());
      completer.complete(size);
    });

    return completer.future;
  }

  Future<List<TextBlock>> _scanTextVision() async {
    final visionImage = FirebaseVisionImage.fromFile(_image);
    final recognizer = FirebaseVision.instance.textRecognizer();
    var visionText = await recognizer.processImage(visionImage);
    return visionText.blocks;
  }

  Future<List<IdentifyBlock>> _findIdentifyBlocks(
      List<TextBlock> blocks) async {
    final list = new List<IdentifyBlock>();

    for (TextBlock block in blocks) {
      final text = block.text;

      // We ignore names of days, prices and additives
      if (text.length < 11) {
        continue;
      }

      list.add(IdentifyBlock(box: block.boundingBox, text: block.text));
    }

    return list;
  }

  Future<DateTime> _findBaseDate(List<IdentifyBlock> blocks) async {
    String search = "die woche vom";
    IdentifyBlock foundBlock;
    DateTime date;

    // Search for the 'search' pattern in all blocks
    for (IdentifyBlock block in blocks) {
      final text = block.text;

      if (text.toLowerCase().contains(search)) {
        foundBlock = block;
      }
    }

    blocks.remove(foundBlock);
    var found = foundBlock.text;

    if (found != null) {
      // Trying to convert the found text into a date
      var numbers = found.split("vom ").last;
      numbers = numbers.replaceAll(new RegExp(r"\D"), "");

      var year = numbers.substring(numbers.length - 4);
      var month = numbers.substring(numbers.length - 6, numbers.length - 4);
      var day = numbers.substring(numbers.length - 8, numbers.length - 6);

      try {
        var yearNr = int.parse(year);
        var monthNr = int.parse(month);
        var dayNr = int.parse(day);

        date = DateTime(yearNr, monthNr, dayNr);
      } on FormatException {
        print('Could not convert text to ints: "$year" "$month" "$day"');
      }
    }

    if (date == null) {
      // We could not find anything int the text, so we'll use this week
      date = DateTime.now();
    }

    // Get the monday of the week
    final weekday = date.weekday;
    final difference = weekday - DateTime.monday;

    final subtracted = date.subtract(new Duration(days: difference));
    return DateTime.utc(subtracted.year, subtracted.month, subtracted.day)
        .toLocal();
  }

  void _populateDefaultDates(List<IdentifyBlock> blocks, DateTime baseDate) {
    blocks.sort((blockOne, blockTwo) => blockOne.box.top - blockTwo.box.top);

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final vegetarian = i % 2 == 1;
      var day = (i ~/ 2) + DateTime.monday;

      if (day >= DateTime.friday) {
        day = DateTime.friday;
      }

      block.date = baseDate.add(new Duration(days: day - 1));
      block._baseDate = baseDate;
      block.vegetarian = vegetarian;
      block.count = 1;
    }
  }

  File get image => _image;

  Size get imageSize => _imageSize;

  DateTime get baseDate => _baseDate;

  int get identifyCount => _identifyBlocks.length;

  DateTime getBaseDate() {
    return _baseDate;
  }

  int getIdentifyCount() {
    return _identifyBlocks.length;
  }

  IdentifyBlock getIdentifyBlock(int element) {
    if (element >= getIdentifyCount()) {
      throw RangeError.range(element, 0, getIdentifyCount() - 1);
    }

    return _identifyBlocks[element];
  }

  bool canMerge(int element) {
    if (element >= getIdentifyCount()) {
      throw RangeError.range(element, 0, getIdentifyCount() - 1);
    }

    for (var i = element - 1; i >= 0; i--) {
      if (getIdentifyBlock(i).count > 0) {
        return true;
      }
    }

    return false;
  }

  List<Meal> toMeals() {
    final list = new List<Meal>();

    for (var i = 0; i < _identifyBlocks.length; ++i) {
      var block = _identifyBlocks[i];

      if (block.merge) {
        // Merging with the meal before, if there's a meal before
        if (list.length == 0) {
          print("Warning: Can't merge with empty element");
          list.addAll(block.toMeals());
        } else {
          list.last.description += "\n" + block.text;
        }
      } else {
        // Just adding the meals to the list
        list.addAll(block.toMeals());
      }

    }

    return list;
  }
}

class IdentifyBlock {
  final Rectangle<int> box; // for showing the preview
  final String text;
  DateTime _baseDate;
  DateTime date; // the day of the week is only important
  bool vegetarian;
  int _count;

  // double price; // enter if it differs

  IdentifyBlock({this.box, this.text});

  int get count => this._count;

  bool get active => this._count > 0;

  bool get merge => this._count < 0;

  // 0 -> nothing
  // 1.. -> elements
  set count(int count) {
    if (count < 0 || count > 10) {
      throw RangeError.range(count, 0, 10);
    }

    _count = count;
  }

  set weekday(int weekday) {
    final addition = weekday - _baseDate.weekday;
    this.date = _baseDate.add(new Duration(days: addition));
  }

  set merge(bool merge) {
    if (merge) {
      this._count = -1;
    } else if (this._count == -1) {
      this._count = 0;
    }
  }

  List<Meal> toMeals() {
    final list = new List<Meal>();

    if (_count >= 1 || merge) {
      list.add(new Meal(
          day: date,
          vegetarian: vegetarian,
          description: text,
          price: vegetarian ? 3.5 : 3.95));
    }

    if (_count >= 2) {
      for (var i = 1; i < _count; i++) {
        // Going to the next entry
        final oldMeal = list.last;

        list.add(new Meal(
          day: oldMeal.vegetarian
              ? oldMeal.day.add(Duration(days: 1))
              : oldMeal.day,
          vegetarian: !oldMeal.vegetarian,
          description: text,
          price: !oldMeal.vegetarian ? 3.5 : 3.95,
        ));
      }
    }

    return list;
  }
}
