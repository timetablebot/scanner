import 'dart:io';

import 'package:cafeteria_scanner/cafetertia.dart';
import 'package:cafeteria_scanner/edit_page.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

class ShowPage extends StatefulWidget {
  final File image;

  ShowPage({Key key, @required this.image}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new ShowPageState(image);
}

class ShowPageState extends State<ShowPage> {
  // TODO: Cleanup leftover images in storage
  final List<Meal> _meals = <Meal>[];
  final File _image;
  bool _finishedImg = false;

  ShowPageState(this._image) {
    _scanImage();
  }

  DateTime _calcMonday() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final difference = weekday - DateTime.monday;

    final subtracted = DateTime.now().subtract(new Duration(days: difference));
    return DateTime.utc(subtracted.year, subtracted.month, subtracted.day)
        .toLocal();
  }

  void _scanImage() async {
    final visionImage = FirebaseVisionImage.fromFile(_image);
    final detector = FirebaseVision.instance.textDetector();

    final textBlocks = await detector.detectInImage(visionImage);
    final meals = new List<Meal>();

    final monday = _calcMonday();

    var vegetarian = false;
    for (var textBlock in textBlocks) {
      // TODO: Parse block data for the document
      meals.add(new Meal(
          day: monday.add(new Duration(days: textBlock.lines.length - 1)),
          vegetarian: vegetarian,
          price: !vegetarian ? 3.95 : 3.5,
          description: textBlock.text));
      vegetarian = !vegetarian;
    }

    setState(() {
      _finishedImg = true;
      _meals.clear();
      _meals.addAll(meals);
    });
  }

  void _editMeal(Meal meal) async {
    final newMeal = await Navigator.of(context).push<Meal>(new MaterialPageRoute(
        builder: (context) => new EditPage(meal: meal)));

    if (newMeal == null) {
      return;
    }

    setState(() {
      // TODO: Sort meals
      meal.day = newMeal.day;
      meal.vegetarian = newMeal.vegetarian;
      meal.price = newMeal.price;
      meal.description = newMeal.description;
    });
  }

  void _upload() {}

  Widget _buildBody() {
    if (!_finishedImg) {
      return Center(child: new CircularProgressIndicator());
    }

    return new ListView.builder(
      itemCount: _meals.length,
      itemBuilder: (context, index) {
        final meal = _meals[index];
        return new ListTile(
          leading: new Icon(
              meal.vegetarian ? Icons.local_florist : Icons.restaurant),
          title: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Text(meal.formatDate()),
              new Text(meal.price.toStringAsFixed(2) + " €")
            ],
          ),
          subtitle: new Text(meal.description),
          onTap: () => _editMeal(meal),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: new Text("CafeteriaScanner"),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: "Discard changes",
          )
        ],
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _upload,
        tooltip: "Upload",
        child: new Icon(Icons.file_upload),
      ),
      body: _buildBody(),
    );
  }
}
