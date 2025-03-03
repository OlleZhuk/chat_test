import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class User {
  @HiveField(0)
  final String firstName;
  @HiveField(1)
  final String lastName;
  @HiveField(2)
  final Color
      color; // Цвет аватарки, тип Color задан отдельно в color_adapter.dart

  User(
    this.firstName,
    this.lastName,
    this.color,
  );
}
