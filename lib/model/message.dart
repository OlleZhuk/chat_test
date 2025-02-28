import 'package:hive/hive.dart';

part 'message.g.dart';

@HiveType(typeId: 2)
class Message {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String senderId;
  @HiveField(2)
  final String? text;
  @HiveField(3)
  final DateTime timestamp;
  @HiveField(4)
  bool isRead;
  @HiveField(5)
  final String? filePath;
  @HiveField(6)
  final String? fileType;

  Message({
    required this.id,
    required this.senderId,
    this.text,
    required this.timestamp,
    this.isRead = false,
    this.filePath,
    this.fileType,
  });
}
