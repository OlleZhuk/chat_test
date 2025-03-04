import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../model/message.dart';
import '../../model/radius.dart';
import '../../model/user.dart';
import '../../view_model/providers/chat_provider.dart';
import '../../view_model/widgets/left_chat_bubble.dart';
import '../../view_model/widgets/right_chat_bubble.dart';

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
                // userMessages.sort((a, b) {
                //   print(a.timestamp);
                //   print(b.timestamp);
                //   return b.timestamp.compareTo(a.timestamp);
                // });

                return Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  children: [
                    ClipPath(
                      clipper: isMe
                          ? LeftChatBubble(
                              largeRadius: largeRadius,
                              smallRadius: smallRadius,
                            )
                          : RightChatBubble(
                              largeRadius: largeRadius,
                              smallRadius: smallRadius,
                            ),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        // width: 300,
                        height: 52,
                        color: isMe
                            ? theme.colorScheme.secondaryContainer
                            : user.color.withOpacity(.5),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: isMe
                            ? Row(
                                children: [
                                  const SizedBox(width: 24),
                                  Text(
                                    message.text,
                                    style: const TextStyle(height: 1.3),
                                    softWrap: true,
                                  ),
                                  const Spacer(),
                                  Text(formattedTime),
                                  const SizedBox(width: 6),
                                  if (isMe)
                                    Image.asset('assets/icons/Read.png'),
                                ],
                              )
                            : Row(
                                children: [
                                  Text(
                                    message.text,
                                    style: const TextStyle(height: 1.3),
                                    softWrap: true,
                                  ),
                                  const Spacer(),
                                  Text(formattedTime),
                                  const SizedBox(width: 6),
                                  if (isMe)
                                    Image.asset('assets/icons/Read.png'),
                                  const SizedBox(width: 20),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                );
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
