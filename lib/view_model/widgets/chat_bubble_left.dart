import 'package:flutter/material.dart';

class LeftChatBubble extends CustomClipper<Path> {
  LeftChatBubble({required this.largeRadius, required this.smallRadius});

  final double largeRadius; // Большое закругление (Б)
  final double smallRadius; // Малое закругление (М)

  @override
  Path getClip(Size size) {
    final path = Path();

    // Начало пути (левая верхняя точка с отступом = Б-закругление хвоста + М-закругление)
    path.moveTo(largeRadius + smallRadius, 0);
    // Верхняя граница вправо до Б-закругления
    path.lineTo(size.width - largeRadius, 0);
    // Б-закругление
    path.arcToPoint(
      Offset(size.width, largeRadius),
      radius: Radius.circular(largeRadius),
    );
    // Правая граница вниз до Б-закругления
    path.lineTo(size.width, size.height - largeRadius);
    // Б-закругление
    path.arcToPoint(
      Offset(size.width - largeRadius, size.height),
      radius: Radius.circular(largeRadius),
    );
    // Нижняя граница влево до кончика хвоста
    path.lineTo(0, size.height);
    // Б-закругление хвоста
    path.arcToPoint(
      Offset(largeRadius, size.height - largeRadius),
      radius: Radius.circular(largeRadius),
      clockwise: false,
    );
    // Левая граница вверх до М-закругления
    path.lineTo(largeRadius, smallRadius);
    // М-закругление
    path.arcToPoint(
      Offset(largeRadius + smallRadius, 0),
      radius: Radius.circular(smallRadius),
    );
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true; // Перерисовываем, если параметры изменились
  }
}
