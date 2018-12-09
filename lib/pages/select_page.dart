import 'package:cafeteria_scanner/data/meal_scanner.dart';
import 'package:cafeteria_scanner/painters/text_box_painter.dart';
import 'package:flutter/material.dart';

class SelectSwipePage extends StatefulWidget {
  final MealScanner scanner;

  SelectSwipePage({@required this.scanner, Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new SelectSwipePageState(scanner);
}

class SelectSwipePageState extends State<SelectSwipePage> {
  final activeColor = Colors.green;
  final defaultColor = Colors.white;
  final disabledColor = Colors.grey;

  final MealScanner scanner;

  SelectSwipePageState(this.scanner);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scrollbar(
        child: new PageView.builder(
          itemBuilder: _buildPage,
          itemCount: scanner.getIdentifyCount() + 1,
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  // TODO: Improve default values
  Widget _buildPage(BuildContext context, int page) {
    if (page >= scanner.getIdentifyCount()) {
      return _buildFinishPage(context);
    }

    var identify = scanner.getIdentifyBlock(page);
    return new Column(
      children: <Widget>[
        _buildOverlayImage(page),
        _buildDayBar(identify),
        _buildVegetarianBar(identify),
        _buildCountBar(identify),
        _buildGreyText(identify),
      ],
    );
  }

  Widget _buildOverlayImage(int page) {
    return FittedBox(
      child: new Container(
        width: scanner.imageSize.width / 2,
        height: scanner.imageSize.height / 2,
        // constraints: BoxConstraints.expand(height: 300.0),
        decoration: new BoxDecoration(
          image: new DecorationImage(
            image: new FileImage(scanner.image),
            fit: BoxFit.fill,
          ),
        ),
        child: new CustomPaint(
          painter: new TextBoxPainter(scanner, page),
          willChange: false,
        ),
      ),
    );
  }

  Widget _buildDayBar(IdentifyBlock block) {
    final weekButtons = new List<Widget>();
    final weekNameMap = {
      1: "Mon",
      2: "The",
      3: "Wed",
      4: "Thu",
      5: "Fri",
      6: "Sat",
      7: "Sun"
    };
    for (var i = DateTime.monday; i <= DateTime.friday; i++) {
      var active = i == block.date.weekday && block.active;

      weekButtons.add(SizedBox(
        width: 40.0,
        child: new FlatButton(
          child: new Text(
            weekNameMap[i],
          ),
          onPressed: block.active ? () =>
              setState(() {
                block.weekday = i;
              }) : null,
          padding: EdgeInsets.zero,
          textColor: active ? activeColor : defaultColor,
          disabledTextColor: disabledColor,
        ),
      ));
    }

    return new ButtonBar(
      children: weekButtons,
      alignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
    );
  }

  Widget _buildVegetarianBar(IdentifyBlock block) {
    return new ButtonBar(
      children: <Widget>[
        new IconButton(
          icon: new Icon(Icons.restaurant),
          onPressed: block.active ? () =>
              setState(() {
                block.vegetarian = false;
              }) : null,
          color: !block.vegetarian ? activeColor : defaultColor,
          disabledColor: disabledColor,
        ),
        new IconButton(
          icon: new Icon(Icons.local_florist),
          onPressed: block.active ? () =>
              setState(() {
                block.vegetarian = true;
              }) : null,
          color: block.vegetarian ? activeColor : defaultColor,
          disabledColor: disabledColor,

        )
      ],
      alignment: MainAxisAlignment.center,
    );
  }

  Widget _buildCountBar(IdentifyBlock block) {
    final countButtons = new List<Widget>();
    final countMap = {
      // TODO: Add a merge button (call_merge)
      0: Icons.panorama_fish_eye,
      1: Icons.control_point,
      2: Icons.control_point_duplicate,
      // TODO: Maybe show a slider
    };

    for (var entry in countMap.entries) {
      final active = block.count == entry.key;

      countButtons.add(new IconButton(
        icon: new Icon(entry.value),
        onPressed: () =>
            setState(() {
              block.count = entry.key;
            }),
        color: active ? activeColor : defaultColor,
      ));
    }

    return ButtonBar(
      children: countButtons,
      alignment: MainAxisAlignment.center,
    );
  }

  _buildGreyText(IdentifyBlock identify) {
    return Expanded(
      child: Center(
        child: new Text(
          identify.text,
          style: new TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildFinishPage(BuildContext context) {
    return new Center(
      child: new FlatButton(
        child: new Text(
          "Finish",
          style: TextStyle(color: Colors.white),
        ),
        onPressed: _finishAction,
      ),
    );
  }

  void _finishAction() {
    Navigator.of(context).pop(scanner.toMeals());
  }
}
