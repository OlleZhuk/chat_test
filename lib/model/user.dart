import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class User {
  @HiveField(0)
  final String id; // Уникальный идентификатор пользователя
  @HiveField(1)
  final String firstName;
  @HiveField(2)
  final String lastName;
  @HiveField(3)
  final Color
      color; // Цвет аватарки, тип Color задан отдельно в color_adapter.dart

  User(
    this.id,
    this.firstName,
    this.lastName,
    this.color,
  );
}
