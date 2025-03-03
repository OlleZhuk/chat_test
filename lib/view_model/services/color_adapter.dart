import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ColorAdapter extends TypeAdapter<Color> {
  @override
  final int typeId = 3; // Уникальный идентификатор для типа Color

  @override
  Color read(BinaryReader reader) {
    final argb = reader.readInt();
    return Color(argb);
  }

  @override
  void write(BinaryWriter writer, Color obj) {
    writer.writeInt(obj.value); // Сохраняем ARGB-значение цвета
  }
}
