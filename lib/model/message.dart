import 'package:hive/hive.dart';

part 'message.g.dart';

@HiveType(typeId: 2)
class Message {
  @HiveField(0)
  final String userId; // Идентификатор пользователя
  @HiveField(1)
  final String text;
  @HiveField(2)
  final String filePath;
  @HiveField(3)
  final String fileType;
  @HiveField(4)
  final DateTime timestamp;
  @HiveField(5)
  final bool isOutgoing; // true - исходящее, false - входящее
  @HiveField(6)
  bool isRead = false;

  Message(
    this.userId,
    this.text,
    this.filePath,
    this.fileType,
    this.timestamp,
    this.isOutgoing,
  );
}
