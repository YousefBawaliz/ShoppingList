import 'package:flutter/material.dart';

enum Categories {
  vegetables,
  sweets,
  dairy,
  fruit,
  meat,
  carbs,
  spices,
  convenience,
  hygiene,
  other
}

class Category {
  const Category(this.name, this.color);

  final String name;
  final Color color;
}
