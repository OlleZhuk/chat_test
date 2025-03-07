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

// Провайдер для управления состоянием сообщений
final messageProvider =
    StateNotifierProvider<MessageNotifier, List<Message>>((ref) {
  final hiveBoxes = ref.watch(hiveProvider);
  return MessageNotifier(hiveBoxes);
});

class MessageNotifier extends StateNotifier<List<Message>> {
  final Map<String, Box> hiveBoxes;

  MessageNotifier(this.hiveBoxes) : super([]) {
    loadMessages();
  }

  void loadMessages() {
    final messagesBox = hiveBoxes['messages'] as Box<Message>;
    state = messagesBox.values.toList();
  }

  Future<void> sendMessage(User user, String text) async {
    if (text.trim().isEmpty) return;

    final messagesBox = hiveBoxes['messages'] as Box<Message>;

    // Создаем новое сообщение
    final message = Message(
      user.id, // userId
      text, // text
      '', // imageUrl (если нужно)
      '', // audioUrl (если нужно)
      DateTime.now(), // timestamp
      true, // isOutgoing
    );

    // Сохраняем сообщение в Hive
    await messagesBox.add(message);

    // Обновляем состояние сообщений
    loadMessages();
  }
}

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

  // void sendMessage(User user, String text) async {
  //   final messagesBox = hiveBoxes['messages'] as Box<Message>;
  //   final message = Message(
  //     user.id,
  //     text,
  //     '',
  //     '',
  //     DateTime.now(),
  //     true, // исходящее
  //   ); // Исходящее сообщение
  //   await messagesBox.add(message);
  //   // Можно добавить логику для обновления UI
  //   loadChats();
  // }
}
