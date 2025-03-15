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
import '../../view_model/providers/main_provider.dart';
import '../../view_model/services/date_time_format.dart';
import '../../view_model/widgets/divider.dart';
import '../../view_model/services/player_audio.dart';
import '../../view_model/widgets/chat_bubble_left.dart';
import '../../view_model/widgets/chat_bubble_right.dart';
import '../../view_model/services/player_video_.dart';
import '../../view_model/services/record_audio.dart';
import 'gallery_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final firstName = user.firstName;
    final lastName = user.lastName;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              minRadius: 24,
              backgroundColor: user.color,
              child: FittedBox(child: Text('${firstName[0]}${lastName[0]}')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$firstName $lastName'),
                  const Text('Не в сети', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _OutputTextMessages(user: user), // #63
          _InputTextMessage(user: user), // #390
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
      //> с учетом реверса -> minScrollExtent
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                vertical: 2.0,
                horizontal:
                    //> для нижнего/первого - малый,
                    //> для остальных - с добавкой:
                    isLastInGroup ? smallRadius : smallRadius + largeRadius,
              ),
              child: Align(
                alignment:
                    isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
                child: isLastInGroup
                    //> для нижнего/первого - чат-бабл,
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

  //* Метод сборки текстового сообщения
  Widget _buildTextMessage(
      Message message, String formattedTime, bool isOutgoing) {
    return Stack(
      children: [
        //> Основной текст и отступ, исключающий
        //> "наползание" на время
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: message.text),
                const WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  //> отступ
                  child: SizedBox(width: 60),
                ),
              ],
            ),
          ),
        ),
        //> Время и отметка
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

  //* Метод сборки файлового сообщения
  Widget _buildFileMessage(
    Message message,
    String formattedTime,
    bool isOutgoing,
  ) {
    //
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //>1< Картинка файла
        if (message.fileType == 'image')
          GestureDetector(
            child: Image.file(File(message.filePath)),
            onTap: () => _openFile(message.filePath),
          ),
        if (message.fileType == 'video')
          VideoPlayerWidget(filePath: message.filePath),
        if (message.fileType == 'audio')
          AudioPlayerWidget(filePath: message.filePath, user: widget.user),
        if (message.fileType == 'voice')
          AudioPlayerWidget(filePath: message.filePath, user: widget.user),
        if (message.fileType == 'file')
          GestureDetector(
            onTap: () => _openFile(message.filePath),
            child: const Text('Файл: ', style: TextStyle(color: Colors.grey)),
          ),
        //>2<
        const SizedBox(height: 8),
        //>3< Имя файла
        Text(
          message.filePath.split('/').last,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, height: .8),
        ),
        const Divider(thickness: 1, color: Colors.grey),
        //> не показывать строку со временем при таких условиях:
        (message.fileType == 'image' ||
                    message.fileType == 'video' ||
                    message.fileType == 'audio' ||
                    message.fileType == 'file') &&
                message.text.isNotEmpty
            ? Container()
            //> Строка со временем и отметкой
            : Row(
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

  //* Метод сборки комби-сообщения
  Widget _buildFileWithTextMessage(
      Message message, String formattedTime, bool isOutgoing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildFileMessage(message, formattedTime, isOutgoing), // без времени
        _buildTextMessage(message, formattedTime, isOutgoing),
      ],
    );
  }

  //* Метод сборки разделителя с датой
  _buildDateDivider(DateTime date) {
    final divColor = widget.user.color.withOpacity(.5);
    String dateText = formatMessageTime(date, isChatScreen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: dividerBuilder(divColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Text(dateText),
          ),
          Expanded(child: dividerBuilder(divColor)),
        ],
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

  //* Метод отрисовки непоследнего сообщения
  Widget _buildMessageContainer(
      bool isLast, bool isOutgoing, Message message, String formattedTime) {
    final theme = Theme.of(context);
    const maxRadius = Radius.circular(largeRadius);
    const minRadius = Radius.circular(smallRadius);
    //
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 300,
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
                ? const EdgeInsets.fromLTRB(13, 13, 36, 6)
                : const EdgeInsets.all(13)
            : const EdgeInsets.fromLTRB(36, 4, 13, 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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

  //* Метод открытия/просмотра файлов
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
  bool isSubmitButtonVisible = false;
  String? audioFilePath;

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //> "Скрепка" с экраном меню
          IconButton(
            icon: Image.asset('assets/icons/Attach.png'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GalleryScreen(),
              ),
            ),
          ),
          //> Поле ввода текстового сообщения
          _textMessage(),
          isSubmitButtonVisible
              //> Отправить (появляется при наборе текста)
              ? IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _submitMessage,
                )
              //> Микрофон
              : IconButton(
                  icon: Image.asset('assets/icons/Audio.png', scale: .8),
                  onPressed: () {
                    _showFileSendModal(context, null, null);
                  },
                ),
        ],
      ),
    );
  }

  //> Кнопка отправки появляется...
  void _updateButtonVisibility() {
    setState(() => isSubmitButtonVisible = _textController.text.isNotEmpty);
  }

  //* Метод выбора "изображение" с запросом разрешения
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

  //* Метод выбора "другие файлы" с запросом разрешения
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

  //* Модальный лист для отправки файлов
  void _showFileSendModal(
      BuildContext context, File? file, String? initialText) {
    final textController = TextEditingController(text: initialText);
    XFile? recordedFile;

    Widget fileName = file != null
        ? Text(
            file.path.split('/').last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          )
        : Container();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                10,
                0,
                10,
                MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //>1< Заголовок
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          dividerBuilder(widget.user.color),
                          Text(
                            file != null
                                ? (file.path.endsWith('.jpg') ||
                                        file.path.endsWith('.png'))
                                    ? 'Отправить изображение'
                                    : file.path.endsWith('.mp4')
                                        ? 'Отправить видео'
                                        : file.path.endsWith('.mp3')
                                            ? 'Отправить аудио'
                                            : 'Отправить файл'
                                : 'Голосовое сообщение',
                            style: TextStyle(
                                color: widget.user.color,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          dividerBuilder(widget.user.color),
                        ],
                      ),
                    ),
                    //>2< Отображение файла или виджета записи
                    if (file != null)
                      if (file.path.endsWith('.jpg') ||
                          file.path.endsWith('.png'))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.file(file, fit: BoxFit.contain),
                            const SizedBox(height: 6),
                            fileName,
                          ],
                        )
                      else if (file.path.endsWith('.mp4'))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VideoPlayerWidget(filePath: file.path),
                            const SizedBox(height: 6),
                            fileName,
                          ],
                        )
                      else if (file.path.endsWith('.mp3'))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AudioPlayerWidget(
                                user: widget.user, filePath: file.path),
                          ],
                        )
                      else
                        //> Файл без определенного типа
                        fileName
                    //>2< if (file = null)
                    else
                      VoiceRecord(
                        onSend: (file) => setState(() {
                          recordedFile = file;
                        }),
                        user: widget.user,
                      ),
                    //
                    //>3< Отступ
                    const SizedBox(height: 6),
                    //>4< Сообщение
                    if (file != null)
                      TextField(
                        controller: textController,
                        maxLines: null,
                        decoration: InputDecoration(
                          constraints: const BoxConstraints(maxHeight: 80),
                          hintText: 'Сообщение...',
                          suffixIcon: IconButton(
                            icon: Image.asset('assets/icons/Close.png',
                                scale: 1.2),
                            onPressed: () {
                              textController.clear();
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                      ),
                    //
                    //>5< Кнопки "Отмена" и "Отправить"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _textController.clear();
                            FocusScope.of(context).unfocus();
                            Navigator.pop(context);
                          },
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () {
                            final text = textController.text.trim();
                            if (file != null) {
                              //> Отправка файла и текста
                              _sendFileWithText(file, text);
                            } else if (recordedFile != null) {
                              //> Отправка голосового сообщения
                              _sendVoiceMessage(recordedFile!);
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('Отправить'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //* Метод ввода сообщения
  Expanded _textMessage() {
    return Expanded(
      child: TextField(
        controller: _textController,
        keyboardType: TextInputType.multiline,
        maxLines: null, // Многострочный режим
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          constraints: const BoxConstraints(maxHeight: 180),
          hintText: 'Сообщение...',
          filled: false,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(26)),
          ),
          suffixIcon: IconButton(
            icon: Image.asset('assets/icons/Close.png', scale: 1.2),
            onPressed: () {
              _textController.clear();
              FocusScope.of(context).unfocus();
            },
          ),
        ),

        //> Как возможный вариант - поменять Enter на Done
        //> для отправки сообщения с клавиатуры
        // textInputAction: TextInputAction.done,
        // onSubmitted: _onSubmitted, // Обработчик нажатия
        //> -----------------------------------------------
      ),
    );
  }

  //* Метод отправки текстового сообщения:
  void _submitMessage() async {
    final enteredTextMessage = _textController.text;
    FocusScope.of(context).unfocus();
    _textController.clear();

    if (enteredTextMessage.trim().isEmpty) return;

    ref
        .read(messageProvider.notifier)
        .sendMessage(widget.user, enteredTextMessage);
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
      if (mounted) FocusScope.of(context).unfocus();
      _textController.clear();
    } catch (e) {
      // Некоторая обработка ошибок
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при отправке файла: $e')),
        );
      }
    }
  }

  //* Метод отправки голосового сообщения
  void _sendVoiceMessage(XFile file) async {
    try {
      final message = Message(
        widget.user.id, // userId
        '', // text
        file.path, // filePath
        'voice', // fileType
        DateTime.now(), // timestamp
        true, // isOutgoing
      );
      //> Сохранение сообщения в Hive
      final messagesBox = Hive.box<Message>('messages');
      await messagesBox.add(message);
      //> Обновление состояния провайдера
      ref.read(messageProvider.notifier).loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка при отправке голосового сообщения: $e')),
        );
      }
    }
  }

  //* Метод локального сохранения файла из сообщения
  Future<File> _saveFileLocally(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final savedFile = File('${appDir.path}/${file.path.split('/').last}');

    return await file.copy(savedFile.path);
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

  //> Возможный метод отправки с клавиатуры:
  // void _onSubmitted(String value) {
  //   if (value.isNotEmpty) submitMessage();
  // }
  //> --------------------------------------
}
