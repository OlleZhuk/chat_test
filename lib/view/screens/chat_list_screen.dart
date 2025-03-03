import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

import '../../model/user.dart';
import 'one_chat_screen.dart';

class AllChatsScreen extends StatelessWidget {
  final _searchController = TextEditingController();

  AllChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Чаты"),
        actions: [
          IconButton(
              icon: Image.asset('assets/icons/Add_circle.png'),
              onPressed: () => _addContact(context)),
          IconButton(
              icon: Image.asset('assets/icons/Out_right.png'),
              onPressed: () => _logout(context)),
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
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<User>('users_box').listenable(),
              builder: (context, Box<User> box, _) {
                final users = box.values.toList();
                if (users.isEmpty) {
                  return const Center(
                      child: Text(
                          textAlign: TextAlign.center,
                          "Здесь пока никого нет.\nВы авторизованы как superuser.\nИспользуйте (+), чтобы добавить\nсебе собеседника."));
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
                            builder: (context) => OneChatScreen(user: user)),
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
