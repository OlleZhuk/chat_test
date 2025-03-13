import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../view_model/providers/chat_provider.dart';
import '../message.dart';
import '../user.dart';

final random = Random();

class DevUsers {
  /// Пользователь superUser - тот, от кого исходящие
  static User superUser =
      User('superuser', 'Super', 'User', Colors.transparent);

  /// Остальные пользователи - от которых входящие
  static List<User> users = [
    User('01', 'Иван', 'Зейдан',
        Colors.primaries[random.nextInt(Colors.primaries.length)]),
    User('02', 'Лиза', 'Синицина',
        Colors.primaries[random.nextInt(Colors.primaries.length)]),
    User('03', 'Павел', 'Стовольтовый',
        Colors.primaries[random.nextInt(Colors.primaries.length)]),
    User('04', 'Сергей', 'Стерх',
        Colors.primaries[random.nextInt(Colors.primaries.length)]),
    User('05', 'Катерина', 'Окочурина',
        Colors.primaries[random.nextInt(Colors.primaries.length)]),
    User('06', 'Женя', 'Страшилина',
        Colors.primaries[random.nextInt(Colors.primaries.length)]),
    User('07', 'Степан', 'Жатецкий',
        Colors.primaries[random.nextInt(Colors.primaries.length)]),
    User('08', 'Артём', 'Бардашов',
        Colors.primaries[random.nextInt(Colors.primaries.length)]),
    User('09', 'Гадя', 'Петрович',
        Colors.primaries[random.nextInt(Colors.primaries.length)]),
    User('10', 'Сандра', 'Буллочини',
        Colors.primaries[random.nextInt(Colors.primaries.length)]),
  ];

  static Widget refreshButton(void Function() refresh) => IconButton(
        onPressed: refresh,
        icon: const Icon(Icons.refresh),
      );

  static Widget clearButton(void Function() clear) => IconButton(
        onPressed: clear,
        icon: Image.asset('assets/icons/Cancel.png'),
      );
}

Message outgoingMessage(user) => Message(
      user.id,
      'Привет, как ты?',
      '',
      '',
      DateTime.now(),
      true,
    );

Message incomingMessage(user) => Message(
      user.id,
      'Привет, я норм. Как сам?',
      '',
      '',
      DateTime.now().add(const Duration(minutes: 2)),
      false,
    );
