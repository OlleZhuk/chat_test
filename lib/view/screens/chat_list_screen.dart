import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/dev_data/dev_data.dart';
import '../../model/message.dart';
import '../../view_model/providers/chat_provider.dart';
import '../../view_model/services/date_time_format.dart';
import 'messages_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ChatListScreenState createState() => ChatListScreenState();
}

class ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _searchController = TextEditingController();
  late final ScrollController _scrollController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(chatProvider);
    ref.watch(messageProvider);

    //> Сортировка чатов по убыванию времени последнего сообщения
    chats.sort((a, b) {
      final lastMessageA =
          ref.read(messageProvider.notifier).getLastMessageForUser(a.id);
      final lastMessageB =
          ref.read(messageProvider.notifier).getLastMessageForUser(b.id);

      final timestampA = lastMessageA?.timestamp ?? DateTime(1970);
      final timestampB = lastMessageB?.timestamp ?? DateTime(1970);

      return timestampB.compareTo(timestampA);
    });

    //> Фильтрация чатов при поиске
    final filteredChats = chats.where((user) {
      final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();

      return fullName.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Чаты',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
        ),
        //! Кнопки разработчика
        actions: [
          //> Ручное обновление экрана
          DevUsers.refreshButton(
              () => ref.read(chatProvider.notifier).loadChats()),
          //> Очистка списка чатов
          DevUsers.clearButton(
              () => ref.read(chatProvider.notifier).clearChat()),
        ],
        //!====================
        //
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            //> Поиск
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Поиск",
                prefixIcon: Image.asset('assets/icons/Search_s.png'),
                suffixIcon: IconButton(
                  icon: Image.asset('assets/icons/Close.png'),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: filteredChats.length,
        itemBuilder: (context, index) {
          final user = filteredChats[index];
          final lastMessage =
              ref.read(messageProvider.notifier).getLastMessageForUser(user.id);

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
              subtitle: lastMessage != null
                  ? Row(
                      children: [
                        Text(
                          lastMessage.isOutgoing ? 'Вы: ' : '',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Expanded(
                            child: Text(
                          _getMessageType(lastMessage),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
                      ],
                    )
                  : null,
              //> Время/дата сообщения
              trailing: Text(
                lastMessage != null
                    ? formatMessageTime(lastMessage.timestamp,
                        isChatScreen: true)
                    : '',
              ),
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

  //* Проверка типов файлов в сообщениях
  String _getMessageType(Message message) {
    if (message.text.isNotEmpty) {
      return message.text; // Если есть текст, возвращаем его
    } else if (message.fileType.isNotEmpty) {
      switch (message.fileType) {
        case 'image':
          return 'изображение';
        case 'audio':
          return 'аудиофайл';
        case 'video':
          return 'видео';
        case 'voice':
          return 'голосовое сообщение';
        default:
          return 'файл';
      }
    }
    return 'Нет сообщений'; // На случай, если тип не определен
  }
}
