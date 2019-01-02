class Meal extends Comparable<Meal> {
  Meal({this.day, this.vegetarian, this.price, this.description});

  DateTime day;
  bool vegetarian;
  double price;
  String description;

  Meal copy() {
    return new Meal(
        day: day,
        vegetarian: vegetarian,
        price: price,
        description: description);
  }

  String formatDate() {
    return _fillZeros(day.day) +
        "." +
        _fillZeros(day.month) +
        "." +
        day.year.toString();
  }

  String _fillZeros(num date) {
    final string = date.toString();
    if (string.length < 2) {
      return "0" + string;
    }
    return string;
  }

  Map<String, dynamic> toJson() {
    final timeStart = DateTime.utc(1970);
    final duration = timeStart.difference(day.toUtc());
    return {
      'day': duration.inDays,
      'vegetarian': vegetarian,
      'price': price,
      'description': description
    };
  }

  @override
  int compareTo(Meal other) {
   final compareDay = day.compareTo(other.day);
   if (compareDay != 0) {
     return compareDay;
   }

   if (vegetarian && !other.vegetarian) {
     return 1;
   } else if (!vegetarian && other.vegetarian) {
     return -1;
   } else {
     return 0;
   }
  }


}
