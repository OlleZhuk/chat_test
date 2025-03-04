import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../view_model/providers/chat_provider.dart';
import 'messages_screen.dart';

class ChatListScreen extends ConsumerWidget {
  ChatListScreen({super.key});

  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        actions: [
          // Кнопка разработчика для очистки списка чатов
          IconButton(
            onPressed: () => ref.read(chatProvider.notifier).clearChat(),
            icon: const Icon(Icons.refresh),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Поиск",
                prefixIcon: Image.asset('assets/icons/Search_s.png'),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final user = chats[index];
          return Dismissible(
            key: Key(user.lastName),
            onDismissed: (direction) {
              ref.read(chatProvider.notifier).deleteChat(user.lastName);
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: user.color,
                child: Text('${user.firstName[0]}${user.lastName[0]}'),
              ),
              title: Text('${user.firstName} ${user.lastName}'),
              // subtitle: Text(user.key),
              subtitle: const Text('Последнее сообщение'),
              trailing: const Text('Время'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagesScreen(user: user),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _addContact(BuildContext context) {
    // Реализация добавления нового контакта
  }

  void _logout(BuildContext context) {
    // Реализация выхода из системы
  }
}
