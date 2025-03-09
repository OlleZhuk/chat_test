import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    //> Подписка на изменения в messageProvider
    //> (реактивное обновление экрана)
    ref.watch(messageProvider);

    //> Выборка сообщений для текущего диалога
    final dialogMessages =
        ref.read(messageProvider.notifier).getMessagesForDialog(widget.user.id);

    //> Сортировка сообщений по времени (новые снизу)
    dialogMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    //> Группировка сообщений по датам
    final groupedMessages = _groupMessagesByDate(dialogMessages);

    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        itemCount: groupedMessages.length,
        itemBuilder: (context, index) {
          final item = groupedMessages[index];
          //> Или разделитель с датой
          if (item is DateTime) {
            return _buildDateDivider(item);
          } else if (item is Message) {
            //> Или сообщение
            final Message message = item;
            final bool isOutgoing = message.isOutgoing;
            final List<Message> group = isOutgoing
                ? dialogMessages.where((m) => m.isOutgoing).toList()
                : dialogMessages.where((m) => !m.isOutgoing).toList();

            final bool isLastInGroup = message == group.last;
            final DateTime now = message.timestamp;
            String formattedTime = DateFormat.Hm().format(now);

            return Padding(
              //> наружные для сообщения
              padding: EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal:
                    //> для нижнего - малый, для остальных - с добавкой:
                    isLastInGroup ? smallRadius : smallRadius + largeRadius,
              ),
              child: Align(
                alignment:
                    isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
                child: isLastInGroup
                    //> для нижнего - чат-бабл,
                    //> для остальных - обычные закругления контейнера
                    ? ClipPath(
                        clipper: isOutgoing
                            ? RightChatBubble(
                                largeRadius: largeRadius,
                                smallRadius: smallRadius,
                              )
                            : LeftChatBubble(
                                largeRadius: largeRadius,
                                smallRadius: smallRadius,
                              ),
                        child: _buildMessageContainer(
                            isLastInGroup, isOutgoing, message, formattedTime),
                      )
                    : _buildMessageContainer(
                        isLastInGroup, isOutgoing, message, formattedTime),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  //* Метод отрисовки сообщений
  Container _buildMessageContainer(
    bool isLast,
    bool isOutgoing,
    Message message,
    String formattedTime,
  ) {
    final theme = Theme.of(context);
    const maxRadius = Radius.circular(largeRadius);
    const minRadius = Radius.circular(smallRadius);
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 330,
        minHeight: largeRadius * 2,
        maxHeight: double.infinity,
      ),
      decoration: BoxDecoration(
        color: isOutgoing
            ? theme.colorScheme.secondaryContainer
            : widget.user.color.withOpacity(.5),
        borderRadius: isLast
            ? null
            : BorderRadius.only(
                topLeft: maxRadius,
                topRight: maxRadius,
                bottomLeft: !isOutgoing ? minRadius : maxRadius,
                bottomRight: isOutgoing ? minRadius : maxRadius,
              ),
      ),
      child: Padding(
        //> отступы для текста нижнего сообщения и остальных
        padding: isOutgoing
            ? isLast
                ? const EdgeInsets.fromLTRB(13, 13, 36, 13)
                : const EdgeInsets.all(13)
            : const EdgeInsets.fromLTRB(36, 13, 13, 13),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: message.text),
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: SizedBox(width: 60, height: 8),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formattedTime),
                  if (isOutgoing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Image.asset('assets/icons/Read.png'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //* Метод группировки сообщений по датам
  List<dynamic> _groupMessagesByDate(List<Message> messages) {
    final groupedMessages = <dynamic>[];
    DateTime? currentDate;

    for (final message in messages) {
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );

      if (currentDate == null || currentDate != messageDate) {
        // Добавляем разделитель с датой
        groupedMessages.add(messageDate);
        currentDate = messageDate;
      }

      // Добавляем сообщение
      groupedMessages.add(message);
    }

    return groupedMessages.reversed.toList();
  }

  //* Метод построения разделителя с датой
  Widget _buildDateDivider(DateTime date) {
    final divColor = widget.user.color.withOpacity(.5);
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    String dateText;

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      dateText = 'Сегодня';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      dateText = 'Вчера';
    } else {
      dateText = DateFormat('dd.MM.yy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: divColor, indent: 13)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Text(dateText),
          ),
          Expanded(child: Divider(color: divColor, endIndent: 13)),
        ],
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

  //> Кнопка отправки появляется...
  void _updateButtonVisibility() {
    setState(
      () => _isButtonVisible = _textController.text.isNotEmpty,
    );
  }

  //* Метод отправки сообщения:
  void submitMessage() async {
    final enteredTextMessage = _textController.text;

    if (enteredTextMessage.trim().isEmpty) return;

    ref
        .read(messageProvider.notifier)
        .sendMessage(widget.user, enteredTextMessage);

    FocusScope.of(context).unfocus();
    _textController.clear();
  }

  //> Возможный метод отправки с клавиатуры:
  // void _onSubmitted(String value) {
  //   if (value.isNotEmpty) submitMessage();
  // }
  //> --------------------------------------

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

              //> Как возможный вариант - поменять Enter на Done
              //> для отправки сообщения с клавиатуры
              // textInputAction: TextInputAction.done,
              // onSubmitted: _onSubmitted, // Обработчик нажатия
              //> -----------------------------------------------
            ),
          ),

          //> При наборе текста вместо кн. микрофона появляется кн. Отправить
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
