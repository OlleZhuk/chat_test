import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

import '../../model/message.dart';
import '../../model/user.dart';
import '../../view_model/widgets/video_player.dart';

class OneChatScreen extends StatelessWidget {
  final User user;

  const OneChatScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    String currentUserId = 'superuser';
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.firstName),
            const Text("Не в сети", style: TextStyle(fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<Box<Message>>(
              valueListenable: Hive.box<Message>('message_box').listenable(),
              builder: (context, Box<Message> box, _) {
                final messages = box.values.toList();
                if (messages.isEmpty) {
                  return const Center(
                      child:
                          Text("Здесь пока никого нет.\nОтправьте сообщение."));
                }
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.text != null) Text(message.text!),
                            if (message.filePath != null)
                              message.fileType == 'image'
                                  ? Image.file(File(message.filePath!))
                                  : message.fileType == 'video'
                                      ? VideoPlayerWidget(
                                          filePath: message.filePath!)
                                      : Text("Файл: ${message.filePath}"),
                            Text(
                              DateFormat('HH:mm').format(message.timestamp),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            if (isMe)
                              Icon(
                                message.isRead ? Icons.done_all : Icons.done,
                                size: 16,
                                color: Colors.grey,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () => _showFilePicker(context),
                ),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(hintText: "Введите сообщение"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () => _startVoiceRecording(context),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilePicker(BuildContext context) {
    // Реализация выбора файла
  }

  void _startVoiceRecording(BuildContext context) {
    // Реализация записи голоса
  }

  void _sendMessage(BuildContext context) {
    // Реализация отправки сообщения
  }
}
