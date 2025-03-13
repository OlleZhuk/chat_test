import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../model/message.dart';
import '../../model/user.dart';

/// Провайдер для работы с Hive
final hiveProvider = Provider((ref) {
  return {
    'users': Hive.box<User>('users'),
    'messages': Hive.box<Message>('messages'),
  };
});

/// Провайдер для управления состоянием чатов
class ChatNotifier extends StateNotifier<List<User>> {
  final Map<String, Box> hiveBoxes;

  ChatNotifier(this.hiveBoxes) : super([]) {
    loadChats();
  }

  void loadChats() {
    final usersBox = hiveBoxes['users'] as Box<User>;
    final allUsers = usersBox.values.toList();
    //> superuser, который вне списка чатов
    state = allUsers.where((user) => user.id != 'superuser').toList();
  }

  Future<void> deleteChat(key) async {
    final usersBox = hiveBoxes['users'] as Box<User>;
    await usersBox.delete(key);
  }

  void clearChat() {
    final usersBox = hiveBoxes['users'] as Box<User>;
    final messagesBox = hiveBoxes['messages'] as Box<Message>;
    usersBox.clear();
    messagesBox.clear();
    loadChats(); // Обновляем состояние
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<User>>((ref) {
  final hiveBoxes = ref.watch(hiveProvider);
  return ChatNotifier(hiveBoxes);
});

/// Провайдер для управления состоянием сообщений
class MessageNotifier extends StateNotifier<List<Message>> {
  final Map<String, Box> hiveBoxes;

  MessageNotifier(this.hiveBoxes) : super([]) {
    loadMessages();
  }

  void loadMessages() {
    final messagesBox = hiveBoxes['messages'] as Box<Message>;
    state = messagesBox.values.toList();
  }

  //* Метод определения последнего сообщения пользователя
  Message? getLastMessageForUser(String userId) {
    final userMessages =
        state.where((message) => message.userId == userId).toList();
    if (userMessages.isEmpty) return null;
    //> Сортировка по времени
    userMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return userMessages.first;
  }

  //* Метод получения сообщений для диалога
  List<Message> getMessagesForDialog(String userId) {
    return state
        .where((message) =>
            message.userId == userId || message.userId == 'superuser')
        .toList();
  }

  Future<void> sendMessage(User user, String text) async {
    if (text.trim().isEmpty) return;

    final messagesBox = hiveBoxes['messages'] as Box<Message>;

    //> Новое сообщение
    final message = Message(
      user.id, // userId
      text, // text
      '', // filePath (если нужно)
      '', // fileType (если нужно)
      DateTime.now(), // timestamp
      true, // исходящее
    );

    //> Сохранение сообщения в Hive
    await messagesBox.add(message);
    //> Обновление состояния сообщений
    loadMessages();
  }
}

final messageProvider =
    StateNotifierProvider<MessageNotifier, List<Message>>((ref) {
  final hiveBoxes = ref.watch(hiveProvider);
  return MessageNotifier(hiveBoxes);
});
