import 'package:cafeteria_scanner/data/cafetertia.dart';
import 'package:cafeteria_scanner/modals/meal_amount.dart';
import 'package:cafeteria_scanner/modals/text_dialog.dart';
import 'package:cafeteria_scanner/pages/edit_page.dart';
import 'package:cafeteria_scanner/data/meal_scanner.dart';
import 'package:cafeteria_scanner/web/web_api.dart';
import 'package:flutter/material.dart';

class ShowPage extends StatefulWidget {
  final scanner;

  ShowPage({Key key, @required this.scanner}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new ShowPageState(scanner);
}

class ShowPageState extends State<ShowPage> {
  final List<Meal> _meals;
  final MealScanner scanner;
  bool _uploading;

  ShowPageState(this.scanner) : _meals = scanner.toMeals() {
    _uploading = false;
    _meals.sort();
  }

  void _addMeal() async {
    final baseMeal = Meal(
      day: scanner.getBaseDate(),
      vegetarian: false,
      price: 3.95,
      description: "",
    );

    final newMeal = await Navigator.of(context).push<Meal>(
        new MaterialPageRoute(
            builder: (context) => new EditPage(meal: baseMeal)));

    if (newMeal == null) {
      return;
    }

    setState(() {
      _meals.add(newMeal);
      _meals.sort();
    });
  }

  void _removePushIcons() {
    setState(() {
      for (var meal in _meals) {
        if (meal.pushType != PushType.NONE) {
          meal.pushType = PushType.NONE;
        }
      }
    });
  }

  void _editMeal(Meal meal) async {
    final newMeal =
        await Navigator.of(context).push<Meal>(new MaterialPageRoute(
      builder: (context) => new EditPage(meal: meal),
    ));

    // Removing the labels if it was uploaded
    _removePushIcons();

    if (newMeal == null) {
      return;
    }

    setState(() {
      meal.day = newMeal.day;
      meal.vegetarian = newMeal.vegetarian;
      meal.price = newMeal.price;
      meal.description = newMeal.description;

      _meals.sort();
    });
  }

  void _editMealAmount(Meal meal, BuildContext context) async {
    final action = await showModalBottomSheet<MealAmountAction>(
        context: context, builder: (context) => MealAmount());

    if (action == null) {
      return;
    }

    if (action == MealAmountAction.MERGE && _meals.indexOf(meal) == 0) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text('Can\'t merge the first element'),
      ));
      return;
    }

    setState(() {
      switch (action) {
        case MealAmountAction.MERGE:
          final index = _meals.indexOf(meal);
          final mergeMeal = _meals[index - 1];
          mergeMeal.description += "\n" + meal.description;
          _meals.removeAt(index);
          break;
        case MealAmountAction.DUPLICATE:
          _meals.add(meal);
          _meals.sort();
          break;
        case MealAmountAction.DELETE:
          _meals.remove(meal);
          break;
      }
    });
  }

  Future<void> _upload() async {
    if (_uploading) {
      return;
    }
    setState(() {
      _uploading = true;
    });

    PushAnswer answer;
    try {
      answer = await TimetableApi.uploadChanges(_meals);
    } catch (err) {
      return;
    }

    setState(() {
      _uploading = false;
    });
    if (!answer.wasError) {
      final pushTypeMap = Map<Meal, PushType>();

      for (var update in answer.updates) {
        for (var meal in _meals) {
          if (meal.vegetarian != update.vegetarian) continue;
          if (meal.day.toUtc() != update.day) continue;
          pushTypeMap[meal] =
              update.created ? PushType.ADDED : PushType.UPDATED;
        }
      }

      setState(() {
        for (var entry in pushTypeMap.entries) {
          entry.key.pushType = entry.value;
        }
      });
    } else {
      var text = 'Message: ${answer.message}\n';
      if (answer.error.externalError) {
        text += 'Text: ${answer.error.full}';
      } else {
        text += 'Invalid JSON: ${answer.error.invalidJson}';
      }

      showDialog(
        context: context,
        builder: (context) => TextDialog(title: 'Error', text: text),
      );
    }
  }

  Widget _buildBody() {
    return new ListView.builder(
      itemCount: _meals.length + 1,
      itemBuilder: (context, index) {
        // Add a field to a new meal
        if (index == _meals.length) {
          return new ListTile(
            leading: new Icon(Icons.add),
            title: new Text("Add a meal"),
            onTap: () => _addMeal(),
          );
        }

        final meal = _meals[index];

        IconData icon;
        if (meal.pushType == PushType.ADDED) {
          icon = Icons.label_important;
        } else if (meal.pushType == PushType.UPDATED) {
          icon = Icons.label;
        } else if (meal.vegetarian) {
          icon = Icons.local_florist;
        } else {
          icon = Icons.restaurant;
        }

        return new ListTile(
          leading: new Icon(icon),
          title: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Text(meal.formatDate()),
              new Text(meal.price.toStringAsFixed(2) + " €")
            ],
          ),
          subtitle: new Text(meal.description),
          onTap: () => _editMeal(meal),
          onLongPress: () => _editMealAmount(meal, context),
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
        onPressed: _uploading ? null : _upload,
        tooltip: "Upload",
        child: _uploading
            ? FractionallySizedBox(
                heightFactor: 0.3,
                widthFactor: 0.3,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3.0,
                ),
              )
            : Icon(Icons.file_upload),
      ),
      body: _buildBody(),
    );
  }
}
