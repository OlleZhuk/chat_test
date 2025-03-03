import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'message.g.dart';

@HiveType(typeId: 2)
class Message {
  @HiveField(0)
  final UniqueKey id;
  @HiveField(1)
  final String senderId;
  @HiveField(2)
  final String text;
  @HiveField(3)
  final String filePath;
  @HiveField(4)
  final String fileType;
  @HiveField(5)
  final DateTime timestamp;
  @HiveField(6)
  final bool isOutgoing; // true - исходящее, false - входящее
  @HiveField(7)
  bool isRead = false;

  Message(
    this.id,
    this.senderId,
    this.text,
    this.filePath,
    this.fileType,
    this.timestamp,
    this.isOutgoing,
  );
}
