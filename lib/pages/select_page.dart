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
    var canMerge = scanner.canMerge(page);
    return new Column(
      children: <Widget>[
        _buildOverlayImage(page),
        _buildDayBar(identify),
        _buildVegetarianBar(identify),
        _buildCountBar(identify, canMerge),
        _buildGreyText(identify),
      ],
    );
  }

  Widget _buildOverlayImage(int page) {
    return Expanded(
      child: FittedBox(
        fit: BoxFit.contain,
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
          onPressed: block.active
              ? () => setState(() {
                    block.weekday = i;
                  })
              : null,
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
          onPressed: block.active
              ? () => setState(() {
                    block.vegetarian = false;
                  })
              : null,
          color: !block.vegetarian ? activeColor : defaultColor,
          disabledColor: disabledColor,
        ),
        new IconButton(
          icon: new Icon(Icons.local_florist),
          onPressed: block.active
              ? () => setState(() {
                    block.vegetarian = true;
                  })
              : null,
          color: block.vegetarian ? activeColor : defaultColor,
          disabledColor: disabledColor,
        )
      ],
      alignment: MainAxisAlignment.center,
    );
  }

  Widget _buildCountBar(IdentifyBlock block, bool canMerge) {
    final countButtons = new List<Widget>();
    final countMap = {
      0: Icons.panorama_fish_eye,
      1: Icons.control_point,
    };

    countButtons.add(new IconButton(
      icon: new Icon(Icons.merge_type),
      onPressed: canMerge
          ? () {
        setState(() {
          block.merge = true;
        });
      }
          : null,
      color: block.merge ? activeColor : defaultColor,
      disabledColor: disabledColor,
    ));

    for (var entry in countMap.entries) {
      final active = block.count == entry.key;

      countButtons.add(new IconButton(
        icon: new Icon(entry.value),
        onPressed: () => setState(() {
              block.count = entry.key;
            }),
        color: active ? activeColor : defaultColor,
      ));
    }

    countButtons.add(new IconButton(
      icon: new Icon(Icons.control_point_duplicate),
      color: block.count >= 2 ? activeColor : defaultColor,
      onPressed: () {
        if (block.count < 2) {
          setState(() {
            block.count = 2;
          });
        }
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) => _buildMultipleModal(block),
        );
      },
      tooltip: block.count == 1 ? "1 copy" : block.count.toString() + " copies",
    ));

    return ButtonBar(
      children: countButtons,
      alignment: MainAxisAlignment.center,
    );
  }

  _buildMultipleModal(IdentifyBlock block) {
    final children = new List<Widget>();
    for (var i = 2; i <= 5; i++) {
      children.add(new FlatButton(
        onPressed: () {
          setState(() {
            block.count = i;
          });
          Navigator.pop(context);
        },
        child: Text(
          i.toString(),
          style: TextStyle(
            color: block.count == i ? activeColor : defaultColor,
          ),
          textScaleFactor: 1.25,
        ),
        padding: EdgeInsets.zero,
      ));
    }

    return Container(
      color: Colors.black,
      child: Row(
        children: children,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
    );
  }

  _buildGreyText(IdentifyBlock identify) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: new Text(
          identify.text,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildFinishPage(BuildContext context) {
    return new Center(
      child: new FlatButton(
        child: new Text(
          "Finish",
          style: const TextStyle(color: Colors.white),
        ),
        onPressed: _finishAction,
      ),
    );
  }

  void _finishAction() {
    Navigator.of(context).pop(scanner.toMeals());
  }
}
