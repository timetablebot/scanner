import 'package:flutter/material.dart';

class MealAmount extends StatelessWidget {
  ListTile _generateTile(IconData icon, String text, MealAmountAction action,
      BuildContext context) {
    return new ListTile(
      title: new Text(text),
      leading: new Icon(icon),
      onTap: () => Navigator.of(context).pop<MealAmountAction>(action),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _generateTile(
            Icons.call_merge,
            "Merge",
            MealAmountAction.MERGE,
            context,
          ),
          _generateTile(
            Icons.content_copy,
            "Duplicate",
            MealAmountAction.DUPLICATE,
            context,
          ),
          _generateTile(
            Icons.delete,
            "Delete",
            MealAmountAction.DELETE,
            context,
          ),
        ],
      ),
    );
  }
}

enum MealAmountAction {
  DELETE,
  MERGE,
  DUPLICATE,
}
