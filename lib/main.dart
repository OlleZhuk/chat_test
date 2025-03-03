import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'model/chat.dart';
import 'model/message.dart';
import 'model/user.dart';
import 'view/screens/all_chats_screen.dart';

void main() async {
  var path = Directory.current.path;
  Hive
    ..init(path)
    ..registerAdapter(UserAdapter())
    ..registerAdapter(MessageAdapter())
    ..registerAdapter(ChatAdapter());
  await Hive.initFlutter();
  await Hive.openBox<User>('users_box');
  await Hive.openBox<Message>('message_box');
  await Hive.openBox<Chat>('chats_box');
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
      home: AllChatsScreen(),
    );
  }
}
