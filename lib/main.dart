import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'model/chat.dart';
import 'model/message.dart';
import 'model/user.dart';
import 'view/screens/chat_list_screen.dart';
import 'view_model/services/color_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var path = Directory.current.path;
  Hive
    ..init(path)
    ..registerAdapter(UserAdapter())
    ..registerAdapter(MessageAdapter())
    ..registerAdapter(ChatAdapter())
    ..registerAdapter(ColorAdapter());
  await Hive.initFlutter();
  await Hive.openBox<User>('users');
  await Hive.openBox<Message>('messages');
  await Hive.openBox<Chat>('chats');

  // Добавляем статических пользователей
  final usersBox = Hive.box<User>('users');
  if (usersBox.isEmpty) {
    final random = Random();
    usersBox.addAll([
      User('Иван', 'Зейдан',
          Colors.primaries[random.nextInt(Colors.primaries.length)]),
      User('Лиза', 'Синицина',
          Colors.primaries[random.nextInt(Colors.primaries.length)]),
      User('Павел', 'Стовольтовый',
          Colors.primaries[random.nextInt(Colors.primaries.length)]),
      User('Сергей', 'Стерх',
          Colors.primaries[random.nextInt(Colors.primaries.length)]),
      User('Катерина', 'Окочурина',
          Colors.primaries[random.nextInt(Colors.primaries.length)]),
      User('Женя', 'Страшилина',
          Colors.primaries[random.nextInt(Colors.primaries.length)]),
      User('Степан', 'Жатецкий',
          Colors.primaries[random.nextInt(Colors.primaries.length)]),
      User('Артём', 'Бардашов',
          Colors.primaries[random.nextInt(Colors.primaries.length)]),
      User('Гадя', 'Петрович',
          Colors.primaries[random.nextInt(Colors.primaries.length)]),
      User('Сандра', 'Буллочини',
          Colors.primaries[random.nextInt(Colors.primaries.length)]),
    ]);
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.grey[900],
        fontFamily: 'Gilroy',
      ),
      home: ChatListScreen(),
    );
  }
}
