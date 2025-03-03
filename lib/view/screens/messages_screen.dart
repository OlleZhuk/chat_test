import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/user.dart';
import '../../view_model/providers/chat_provider.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Row(
          children: [
            CircleAvatar(
              minRadius: 24,
              backgroundColor: user.color,
              child: Text('${user.firstName[0]}${user.lastName[0]}'),
            ),
            Column(
              children: [
                Text('${user.firstName} ${user.lastName}'),
                const Text('Не в сети'),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 0, // Заменим на количество сообщений
              itemBuilder: (context, index) {
                return const ListTile(
                  title: Text('Сообщение'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Введите сообщение...',
                    ),
                    onSubmitted: (text) {
                      ref.read(chatProvider.notifier).sendMessage(user, text);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
