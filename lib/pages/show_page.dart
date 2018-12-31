import 'package:cafeteria_scanner/data/cafetertia.dart';
import 'package:cafeteria_scanner/modals/meal_amount.dart';
import 'package:cafeteria_scanner/pages/edit_page.dart';
import 'package:cafeteria_scanner/data/meal_scanner.dart';
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

  ShowPageState(this.scanner) : _meals = scanner.toMeals() {
    _meals.sort();
  }

  // TODO: Allow to mark two and merge them
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

    _meals.add(newMeal);
    _meals.sort();

    setState(() {});
  }

  void _editMeal(Meal meal) async {
    final newMeal =
        await Navigator.of(context).push<Meal>(new MaterialPageRoute(
      builder: (context) => new EditPage(meal: meal),
    ));

    if (newMeal == null) {
      return;
    }

    meal.day = newMeal.day;
    meal.vegetarian = newMeal.vegetarian;
    meal.price = newMeal.price;
    meal.description = newMeal.description;

    _meals.sort();

    setState(() {});
  }

  void _editMealAmount(Meal meal, BuildContext context) async {
    final action = await showModalBottomSheet<MealAmountAction>(
        context: context, builder: (context) => MealAmount());

    if (action == null) {
      return;
    }

    switch (action) {
      case MealAmountAction.MERGE:
        final index = _meals.indexOf(meal);
        if (index == 0) {
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text('Can\'t merge the first element'),
          ));
          return;
        }
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

    setState(() {});
  }

  void _upload() {}

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
        onPressed: _upload,
        tooltip: "Upload",
        child: new Icon(Icons.file_upload),
      ),
      body: _buildBody(),
    );
  }
}
