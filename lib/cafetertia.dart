class Meal {
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
}
