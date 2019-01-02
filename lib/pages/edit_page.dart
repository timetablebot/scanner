import 'dart:async';

import 'package:cafeteria_scanner/data/cafetertia.dart';
import 'package:cafeteria_scanner/modals/input_dialog.dart';
import 'package:flutter/material.dart';

class EditPage extends StatefulWidget {
  final Meal meal;

  EditPage({this.meal});

  @override
  State createState() => new EditPageState(meal: meal);
}

class EditPageState extends State<EditPage> {
  final Meal _meal;

  EditPageState({@required Meal meal}) : _meal = meal.copy();

  // TODO: Add a remove button

  void _chooseDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _meal.day,
        firstDate: _meal.day.subtract(new Duration(days: 365)),
        lastDate: _meal.day.add(new Duration(days: 365)));

    if (date == null) {
      return;
    }

    setState(() {
      _meal.day = date;
    });
  }

  Future<String> _chooseDialog(
      {String title, String initialText, TextInputType input}) async {
    return await showDialog<String>(
        context: context,
        builder: (context) => new InputDialog(
            title: title, initialText: initialText, inputType: input));
  }

  void _choosePrice() async {
    final text = await _chooseDialog(
        title: 'Price',
        initialText: _meal.price.toStringAsFixed(2),
        input: TextInputType.numberWithOptions(decimal: true));

    if (text == null) {
      // Nothing changed
      return;
    }
    try {
      double price;
      try {
        price = double.parse(text);
      } on FormatException {
        _showSnackbar('Please enter a valid double as the price');
        return;
      }

      if (price < 0) {
        _showSnackbar('The price may not be smaller than zero');
        return;
      }

      if (price > 100) {
        _showSnackbar('The price may not be greater than 100');
        return;
      }

      setState(() {
        _meal.price = price;
      });
    } catch (ex) {
      print(ex);
    }
  }

  void _chooseDescription() async {
    final text = await _chooseDialog(
      title: 'Description',
      initialText: _meal.description,
      input: TextInputType.multiline,
    );

    if (text == null) {
      return;
    }

    if (text.isEmpty) {
      _showSnackbar('Warning: The description is empty');
    }

    setState(() {
      _meal.description = text;
    });
  }

  void _showSnackbar(String text) {
    Scaffold.of(context).showSnackBar(new SnackBar(content: new Text(text)));
  }

  Widget _buildBody() {
    return new ListView(
      children: <Widget>[
        new ListTile(
          title: new Text("Date"),
          trailing: new Text(_meal.formatDate()),
          onTap: _chooseDate,
        ),
        new SwitchListTile(
          title: new Text("Vegetarian"),
          onChanged: (value) => setState(() => _meal.vegetarian = value),
          value: _meal.vegetarian,
        ),
        new ListTile(
          title: new Text("Price"),
          trailing: new Text(_meal.price.toStringAsFixed(2) + " €"),
          onTap: _choosePrice,
        ),
        new ListTile(
          title: new Text("Description"),
          subtitle: new Text(_meal.description),
          onTap: _chooseDescription,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: new Text("Edit meal"),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(null),
            tooltip: "Discard changes",
          )
        ],
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: () => Navigator.of(context).pop(_meal),
        tooltip: "Save meal",
        child: new Icon(Icons.save),
      ),
      body: _buildBody(),
    );
  }
}
