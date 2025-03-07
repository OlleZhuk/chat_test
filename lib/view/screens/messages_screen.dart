import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../model/message.dart';
import '../../model/chat_bubble_radius.dart';
import '../../model/user.dart';
import '../../view_model/providers/chat_provider.dart';
import '../../view_model/widgets/left_chat_bubble.dart';
import '../../view_model/widgets/right_chat_bubble.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final firstName = user.firstName;
    final lastName = user.lastName;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Row(
          children: [
            CircleAvatar(
              minRadius: 24,
              backgroundColor: user.color,
              child: Text('${firstName[0]}${lastName[0]}'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$firstName $lastName'),
                const Text('Не в сети', style: TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _OutputTextMessages(user: user),
          _InputTextMessage(user: user),
        ],
      ),
    );
  }

  /// Метод для определения форм чат-баблов
  BorderRadius _getBorderRadius(
    bool isFirstInGroup,
    bool isLastInGroup,
    // bool isSingleInGroup,
  ) {
    const radius = Radius.circular(26);

    if (isLastInGroup) {
      // Последнее сообщение в группе
      return BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: isFirstInGroup ? radius : Radius.zero,
        bottomRight: radius,
      );
    } else if (isFirstInGroup) {
      // Первое сообщение в группе
      return const BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: radius,
      );
    } else {
      // Сообщение в середине группы
      return const BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: Radius.zero,
      );
    }
  }
}

/// ВЫВОД СООБЩЕНИЙ ===>
class _OutputTextMessages extends ConsumerStatefulWidget {
  const _OutputTextMessages({required this.user});

  final User user;

  @override
  _OutputTextMessagesState createState() => _OutputTextMessagesState();
}

class _OutputTextMessagesState extends ConsumerState<_OutputTextMessages> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // с учетом реверса - minScrollExtent
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = ref.watch(messageProvider);
    // final messagesBox = Hive.box<Message>('messages');

    // Фильтр сообщений по userId
    final userMessages =
        messages.where((message) => message.userId == widget.user.id).toList();

    // Сортировка сообщений по времени (новые снизу)
    userMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Группировка сообщений по пользователям, чтобы выявлять цепочки
    // сообщений, в которых будут отличаться формы чат-баблов
    final Map<String, List<Message>> groupedMessages = {};
    for (var message in userMessages) {
      final userId = message.userId;
      if (!groupedMessages.containsKey(userId)) {
        groupedMessages[userId] = [];
      }
      groupedMessages[userId]!.add(message);
    }

    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        itemCount: userMessages.length,
        itemBuilder: (context, index) {
          final message = userMessages[index];
          final isMe = message.isOutgoing;
          final userId = message.userId;

          final messageGroup = groupedMessages[userId]!;
          final isFirstInGroup = message == messageGroup.first;
          final isLastInGroup = message == messageGroup.last;
          // final isSingleInGroup = message == messageGroup.single;

          final now = message.timestamp;
          String formattedTime = DateFormat.Hm().format(now);

          return Column(
            // mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                !isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              ClipPath(
                clipper: !isMe
                    ? LeftChatBubble(
                        largeRadius: largeRadius,
                        smallRadius: smallRadius,
                      )
                    : RightChatBubble(
                        largeRadius: largeRadius,
                        smallRadius: smallRadius,
                      ),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 330,
                    minHeight: 52,
                    maxHeight: double.infinity,
                  ),
                  color: isMe
                      ? theme.colorScheme.secondaryContainer
                      : widget.user.color.withOpacity(.5),
                  child: Padding(
                    padding: !isMe
                        ? const EdgeInsets.fromLTRB(40, 13, 13, 13)
                        : const EdgeInsets.fromLTRB(13, 13, 40, 13),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: message.text),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: Container(
                                    width: 60,
                                    height: 8,
                                    color: Colors.blue[200],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Row(
                            // mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formattedTime),
                              if (isMe)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 4, left: 4),
                                  child: Image.asset('assets/icons/Read.png'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // child: Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Text(message.text),
                    //     Padding(
                    //       padding: isMe
                    //           ? const EdgeInsets.only(left: 190)
                    //           : const EdgeInsets.only(left: 190),
                    //       child: Row(
                    //         mainAxisSize: MainAxisSize.min,
                    //         mainAxisAlignment: MainAxisAlignment.end,
                    //         crossAxisAlignment: CrossAxisAlignment.end,
                    //         children: [
                    //           Text(formattedTime),
                    //           if (isMe)
                    //             Padding(
                    //               padding:
                    //                   const EdgeInsets.only(bottom: 4, left: 4),
                    //               child: Image.asset('assets/icons/Read.png'),
                    //             ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ),
                ),
              ),
              const SizedBox(height: 6)
            ],
          );
        },
      ),
    );
  }
}

/// ВВОД СООБЩЕНИЙ <===
/// (нижний ряд)

class _InputTextMessage extends ConsumerStatefulWidget {
  const _InputTextMessage({required this.user});

  final User user;

  @override
  InputTextMessageState createState() => InputTextMessageState();
}

class InputTextMessageState extends ConsumerState<_InputTextMessage> {
  final _textController = TextEditingController();
  bool _isButtonVisible = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateButtonVisibility);
  }

  @override
  void dispose() {
    _textController.removeListener(_updateButtonVisibility);
    _textController.dispose();
    super.dispose();
  }

  /// Кнопка отправки появляется...
  void _updateButtonVisibility() {
    setState(
      () => _isButtonVisible = _textController.text.isNotEmpty,
    );
  }

  /// Метод отправки сообщения:
  void submitMessage() async {
    final enteredTextMessage = _textController.text;

    if (enteredTextMessage.trim().isEmpty) return;

    ref
        .read(messageProvider.notifier)
        .sendMessage(widget.user, enteredTextMessage);

    FocusScope.of(context).unfocus();
    _textController.clear();
  }

  /// Метод отправки сообщения с клавиатуры:
  // void _onSubmitted(String value) {
  //   if (value.isNotEmpty) submitMessage();
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Image.asset('assets/icons/Attach.png'),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              keyboardType: TextInputType.multiline,
              maxLines: null, // Многострочный режим
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                constraints: BoxConstraints(maxHeight: 180),
                hintText: 'Сообщение...',
                filled: false,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(26)),
                ),
              ),

              /// Как возможный вариант - поменять Enter на Done
              /// для отправки сообщения с клавиатуры
              // textInputAction: TextInputAction.done,
              // onSubmitted: _onSubmitted, // Обработчик нажатия
              /// ------------------------------------
            ),
          ),

          // При наборе текста вместо кн. микрофона появляется кн. Отправить
          _isButtonVisible
              ? IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: submitMessage,
                )
              : IconButton(
                  icon: Image.asset(
                    'assets/icons/Audio.png',
                    scale: .8,
                  ),
                  onPressed: () {},
                ),
        ],
      ),
    );
  }
}
