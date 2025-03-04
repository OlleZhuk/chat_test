import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'model/message.dart';
import 'model/user.dart';
import 'view/screens/chat_list_screen.dart';
import 'view_model/services/color_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // var path = Directory.current.path;
  await Hive.initFlutter();
  Hive
    // ..init(path)
    ..registerAdapter(UserAdapter())
    ..registerAdapter(MessageAdapter())
    ..registerAdapter(ColorAdapter());
  await Hive.openBox<User>('users');
  await Hive.openBox<Message>('messages');

  /// + статические данные для разработчика (список пользователей и диалоги)
  final usersBox = Hive.box<User>('users');
  final messagesBox = Hive.box<Message>('messages');

  if (usersBox.isEmpty && messagesBox.isEmpty) {
    final random = Random();
    final users = [
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

    /// Сохраняем список пользователей
    usersBox.addAll(users);

    /// + Сообщения для каждого пользователя
    for (var user in users) {
      final outgoingMessage = Message(
        user.id,
        'Привет, как ты?',
        '',
        '',
        DateTime.now(),
        true,
      );
      final incomingMessage = Message(
        user.id,
        'Привет, я норм. Как сам?',
        '',
        '',
        DateTime.now().add(const Duration(minutes: 2)),
        false,
      );

      /// Сохраняем сообщения в Hive
      messagesBox.add(outgoingMessage);
      messagesBox.add(incomingMessage);
    }
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blueGrey,
          scaffoldBackgroundColor: Colors.grey[900],
          fontFamily: 'Gilroy',
        ),
        home: ChatListScreen(),
      ),
    );
  }
}
