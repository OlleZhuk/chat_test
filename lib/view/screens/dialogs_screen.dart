import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

import '../../model/user.dart';
import 'chat_screen.dart';

class DialogsScreen extends StatelessWidget {
  final _searchController = TextEditingController();

  DialogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Чаты"),
        actions: [
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addContact(context)),
          IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => _logout(context)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Поиск контакта",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<User>('users_box').listenable(),
              builder: (context, Box<User> box, _) {
                final users = box.values.toList();
                if (users.isEmpty) {
                  return const Center(
                      child: Text(
                          "Здесь пока никого нет.\nВы авторизованы как superuser.\nИспользуйте (+), чтобы добавить себе собеседника."));
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Colors.primaries[index % Colors.primaries.length],
                        child: Text(user.firstName[0]),
                      ),
                      title: Text(user.firstName),
                      subtitle: Text(user.lastName ?? ""),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChatScreen(user: user)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
