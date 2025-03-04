import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../model/message.dart';
import '../../model/user.dart';

// Провайдер для работы с Hive
final hiveProvider = Provider((ref) {
  return {
    'users': Hive.box<User>('users'),
    'messages': Hive.box<Message>('messages'),
  };
});

// Провайдер для управления состоянием чатов
final chatProvider = StateNotifierProvider<ChatNotifier, List<User>>((ref) {
  final hiveBoxes = ref.watch(hiveProvider);
  return ChatNotifier(hiveBoxes);
});

class ChatNotifier extends StateNotifier<List<User>> {
  final Map<String, Box> hiveBoxes;

  ChatNotifier(this.hiveBoxes) : super([]) {
    loadChats();
  }

  void loadChats() {
    final usersBox = hiveBoxes['users'] as Box<User>;
    state = usersBox.values.toList();
  }

  Future<void> deleteChat(key) async {
    final usersBox = hiveBoxes['users'] as Box<User>;
    await usersBox.delete(key);
    // print('==> $key');
    // loadChats(); // Обновляем состояние
  }

  void clearChat() {
    final usersBox = hiveBoxes['users'] as Box<User>;
    final messagesBox = hiveBoxes['messages'] as Box<Message>;
    usersBox.clear();
    messagesBox.clear();
    loadChats(); // Обновляем состояние
  }

  void sendMessage(User user, String text) {
    final messagesBox = hiveBoxes['messages'] as Box<Message>;
    // final id = UniqueKey();
    final message = Message(
      user.id,
      text,
      '',
      '',
      DateTime.now(),
      true, // исходящее
    ); // Исходящее сообщение
    messagesBox.add(message);
    // Можно добавить логику для обновления UI
  }
}
