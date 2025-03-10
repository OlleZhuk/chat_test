import 'package:flutter/material.dart';

class RightChatBubble extends CustomClipper<Path> {
  RightChatBubble({required this.largeRadius, required this.smallRadius});

  final double largeRadius; // Большое закругление
  final double smallRadius; // Малое закругление

  @override
  Path getClip(Size size) {
    final path = Path();

    // Начало пути (левая верхняя точка после Б-закругления)
    path.moveTo(largeRadius, 0);
    // Верхняя граница вправо до М-закругления
    path.lineTo(size.width - largeRadius - smallRadius, 0);
    // М-закругление
    path.arcToPoint(
      Offset(size.width - largeRadius, smallRadius),
      radius: Radius.circular(smallRadius),
    );
    // Правая граница вниз (до начала хвоста)
    path.lineTo(size.width - largeRadius, size.height - largeRadius);
    // Б-закругление хвоста
    path.arcToPoint(
      Offset(size.width, size.height),
      radius: Radius.circular(largeRadius),
      clockwise: false,
    );
    // Нижняя граница влево до Б-закругления
    path.lineTo(largeRadius, size.height);
    // Б-закругление
    path.arcToPoint(
      Offset(0, size.height - largeRadius),
      radius: Radius.circular(largeRadius),
    );
    // Левая граница вверх до Б-закругления
    path.lineTo(0, largeRadius);
    // Б-закругление
    path.arcToPoint(
      Offset(largeRadius, 0),
      radius: Radius.circular(largeRadius),
    );
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true; // Перерисовываем, если параметры изменились
  }
}
