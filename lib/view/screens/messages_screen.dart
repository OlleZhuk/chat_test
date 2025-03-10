import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../model/message.dart';
import '../../model/chat_bubble_radius.dart';
import '../../model/user.dart';
import '../../view_model/providers/chat_provider.dart';
import '../../view_model/widgets/player_audio.dart';
import '../../view_model/widgets/chat_bubble_left.dart';
import '../../view_model/widgets/chat_bubble_right.dart';
import '../../view_model/widgets/player_video_.dart';

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
      //> с учетом реверса - minScrollExtent
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

  //* Метод открытия файлов
  void _openFile(String filePath) async {
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось открыть файл: ${result.message}'),
        ),
      );
    }
  }

  //* Метод построения текстовых сообщений
  Widget _buildTextMessage(
      Message message, String formattedTime, bool isOutgoing) {
    return Stack(
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
    );
  }

  //* Метод построения файловых сообщений
  Widget _buildFileMessage(
      Message message, String formattedTime, bool isOutgoing) {
    return Column(
      crossAxisAlignment:
          isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (message.fileType == 'image') Image.file(File(message.filePath)),
        if (message.fileType == 'video')
          VideoPlayerWidget(filePath: message.filePath),
        if (message.fileType == 'audio') buildAudioPlayer(message.filePath),
        if (message.fileType == 'file')
          GestureDetector(
            onTap: () => _openFile(message.filePath),
            child: Text('Файл: ${message.filePath.split('/').last}'),
          ),
        Row(
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
      ],
    );
  }

  //* Метод построения комби-сообщений
  Widget _buildFileWithTextMessage(
      Message message, String formattedTime, bool isOutgoing) {
    return Column(
      crossAxisAlignment:
          isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _buildFileMessage(message, '', false),
        _buildTextMessage(message, formattedTime, isOutgoing),
      ],
    );
  }

  //* Метод отрисовки сообщений
  Widget _buildMessageContainer(
      bool isLast, bool isOutgoing, Message message, String formattedTime) {
    final theme = Theme.of(context);
    const maxRadius = Radius.circular(largeRadius);
    const minRadius = Radius.circular(smallRadius);
    //
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
        child: Column(
          crossAxisAlignment:
              isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.filePath.isEmpty)
              _buildTextMessage(message, formattedTime, isOutgoing),
            if (message.filePath.isNotEmpty && message.text.isEmpty)
              _buildFileMessage(message, formattedTime, isOutgoing),
            if (message.filePath.isNotEmpty && message.text.isNotEmpty)
              _buildFileWithTextMessage(message, formattedTime, isOutgoing),
          ],
        ),
      ),
    );
  }

  //* Метод группировки сообщений по датам
  _groupMessagesByDate(List<Message> messages) {
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
  _buildDateDivider(DateTime date) {
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

  //* Метод отправки текстового сообщения:
  void _submitMessage() async {
    final enteredTextMessage = _textController.text;

    if (enteredTextMessage.trim().isEmpty) return;

    ref
        .read(messageProvider.notifier)
        .sendMessage(widget.user, enteredTextMessage);

    FocusScope.of(context).unfocus();
    _textController.clear();
  }

//* Метод выбора фото или видео с запросом разрешения
  Future<void> _pickPhotoOrVideo() async {
    //> Запрос разрешения на доступ к хранилищу
    final status = await Permission.storage.request();

    if (status.isGranted) {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? file = await picker.pickImage(source: ImageSource.gallery);

        if (file != null) {
          // Обработка выбранного фото/видео
          final File imageFile = File(file.path);
          if (mounted) {
            _showFileSendModal(context, imageFile, _textController.text.trim());
          }
        }
      } catch (e) {
        // Обработка исключения
        if (mounted) _showAlert(context, 'Галерея недоступна');
      }
    } else {
      // Разрешение отклонено
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Разрешение на доступ к хранилищу отклонено'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

//* Метод выбора документа или файла с запросом разрешения
  Future<void> _pickDocumentOrFile() async {
    // Запрашиваем разрешение на доступ к хранилищу
    final status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        final FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result != null) {
          // Обработка выбранного файла
          final File file = File(result.files.single.path!);
          if (mounted) {
            _showFileSendModal(context, file, _textController.text.trim());
          }
        }
      } catch (e) {
        // Обработка исключения
        if (mounted) _showAlert(context, 'Файлы недоступны');
      }
    } else {
      // Разрешение отклонено
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Разрешение на доступ к хранилищу отклонено'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  //* Показ алерта
  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  //* Метод выбора файлов
  void _showFileSendModal(
      BuildContext context, File file, String? initialText) {
    final TextEditingController textController =
        TextEditingController(text: initialText);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            10,
            0,
            10,
            MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  (file.path.endsWith('.jpg') || file.path.endsWith('.png'))
                      ? 'Отправить изображение'
                      : file.path.endsWith('.mp4')
                          ? 'Отправить видео'
                          : file.path.endsWith('.mp3')
                              ? 'Отправить аудио'
                              : 'Отправить файл',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              //> Отображение файла
              if (file.path.endsWith('.jpg') || file.path.endsWith('.png'))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.file(file,
                        height: 150, width: double.infinity, fit: BoxFit.cover),
                    const SizedBox(height: 6),
                    Text(file.path.split('/').last)
                  ],
                )
              else if (file.path.endsWith('.mp4'))
                Column(
                  children: [
                    const Icon(Icons.videocam, size: 100),
                    const SizedBox(height: 6),
                    Text(file.path.split('/').last)
                  ],
                )
              else
                Text(
                  file.path.split('/').last,
                  style: const TextStyle(fontSize: 16),
                ),
              //> Поле ввода текста
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: 'Добавьте текст...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              //> Кнопки "Отмена" и "Отправить"
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () {
                      final text = textController.text.trim();
                      _sendFileWithText(file, text); // Отправка файла и текста
                      Navigator.pop(context);
                    },
                    child: const Text('Отправить'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  //* Метод отправки файла и текста:
  void _sendFileWithText(File file, String text) async {
    try {
      //> Сохраняем файл локально
      final savedFile = await _saveFileLocally(file);

      //> Определяем тип файла
      String fileType;
      if (file.path.endsWith('.jpg') || file.path.endsWith('.png')) {
        fileType = 'image';
      } else if (file.path.endsWith('.mp4')) {
        fileType = 'video';
      } else if (file.path.endsWith('.mp3')) {
        fileType = 'audio';
      } else {
        fileType = 'file';
      }

      //> Создаем сообщение
      final message = Message(
        widget.user.id, // userId
        text, // text
        savedFile.path, // filePath
        fileType, // fileType
        DateTime.now(), // timestamp
        true, // isOutgoing
      );

      //> Сохраняем сообщение в Hive
      final messagesBox = Hive.box<Message>('messages');
      await messagesBox.add(message);

      //> Обновляем состояние провайдера
      ref.read(messageProvider.notifier).loadMessages();

      //> Очищаем поле ввода
      _textController.clear();
    } catch (e) {
      // Обработка ошибок
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при отправке файла: $e')),
        );
      }
    }
  }

  //* Метод локального сохранения файлов
  Future<File> _saveFileLocally(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final savedFile = File('${appDir.path}/${file.path.split('/').last}');
    return await file.copy(savedFile.path);
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
          //> "Скрепка" с выпадающим меню
          PopupMenuButton<String>(
            offset: const Offset(0, -120),
            icon: Image.asset('assets/icons/Attach.png'),
            onSelected: (value) {
              //> Обработка выбора пункта меню
              if (value == 'photo_or_video') {
                _pickPhotoOrVideo();
              } else if (value == 'document_or_file') {
                _pickDocumentOrFile();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'photo_or_video',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icons/Img.png'),
                    const SizedBox(width: 13),
                    const Text('Фото или видео'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'document_or_file',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icons/Attachment.png'),
                    const SizedBox(width: 13),
                    const Text('Документ или файл'),
                  ],
                ),
              ),
            ],
          ),
          //
          //> Поле ввода текстового сообщения
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
          //
          //> Либо микрофон, либо Отправить (меняются при наборе текста)
          _isButtonVisible
              ? IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _submitMessage,
                )
              : IconButton(
                  icon: Image.asset('assets/icons/Audio.png', scale: .8),
                  onPressed: () {},
                ),
        ],
      ),
    );
  }
}
