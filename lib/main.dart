import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'model/message.dart';
import 'model/user.dart';
import 'model/dev_data/dev_data.dart';
import 'view/screens/chat_list_screen.dart';
import 'view_model/services/color_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive
    ..registerAdapter(UserAdapter())
    ..registerAdapter(MessageAdapter())
    ..registerAdapter(ColorAdapter());
  await Hive.openBox<User>('users');
  await Hive.openBox<Message>('messages');

  //! (+) ввод данных разработчика
  // (список пользователей, сообщения)
  final usersBox = Hive.box<User>('users');
  final messagesBox = Hive.box<Message>('messages');

  if (usersBox.isEmpty && messagesBox.isEmpty) {
    ///> Cупер-пользователь
    usersBox.add(DevUsers.superUser);
    //> Список пользователей
    usersBox.addAll(DevUsers.users);
    //> Сообщения
    for (var user in DevUsers.users) {
      final outMess = outgoingMessage(user);
      final incMess = incomingMessage(user);
      messagesBox.add(outMess);
      messagesBox.add(incMess);
    }
  }
  //! -----------------------------------

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Обёртка от Riverpod
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blueGrey,
          scaffoldBackgroundColor: Colors.grey[900],
          fontFamily: 'Gilroy',
        ),
        home: const ChatListScreen(),
      ),
    );
  }
}
