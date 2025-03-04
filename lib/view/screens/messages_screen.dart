import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../model/message.dart';
import '../../model/user.dart';
import '../../view_model/providers/chat_provider.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final messagesBox = Hive.box<Message>('messages');
    // final messages = messagesBox.values.toList();

    // Фильтруем сообщения по userId
    final userMessages = messagesBox.values
        .where((message) => message.userId == user.id)
        .toList();

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
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.firstName} ${user.lastName}'),
                const Text(
                  'Не в сети',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: userMessages.length,
              itemBuilder: (context, index) {
                final message = userMessages[index];
                final isMe = message.isOutgoing;
                final now = message.timestamp;
                String formattedTime = DateFormat.Hm().format(now);

                return Container(
                  width: 200,
                  constraints: const BoxConstraints(maxWidth: 220),
                  decoration: BoxDecoration(
                    color: isMe
                        ? theme.colorScheme.secondaryContainer
                        : user.color.withOpacity(.5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft:
                          isMe ? Radius.zero : const Radius.circular(12),
                      bottomRight:
                          !isMe ? Radius.zero : const Radius.circular(12),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  // Граница вокруг окна сообщения.
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        message.text,
                        // Небольшой межстрочный интервал
                        style: const TextStyle(height: 1.3),
                        softWrap: true,
                      ),
                      Text(formattedTime),
                    ],
                  ),
                );
                // ListTile(
                //   title: Text(
                //     message.text,
                //     textAlign:
                //         message.isOutgoing ? TextAlign.left : TextAlign.right,
                //   ),
                //   trailing: Text(message.timestamp.toString()),
                // );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Image.asset('assets/icons/Attach.png'),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Сообщение...',
                    ),
                    onSubmitted: (text) {
                      ref.read(chatProvider.notifier).sendMessage(user, text);
                      Focus.of(context).unfocus();
                    },
                  ),
                ),
                IconButton(
                  icon: Image.asset('assets/icons/Audio.png'),
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
