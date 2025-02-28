import 'package:hive/hive.dart';

import 'message.dart';

part 'chat.g.dart';

@HiveType(typeId: 3)
class Chat {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final List<String> participantIds;
  @HiveField(2)
  final List<Message> messages;

  Chat({
    required this.id,
    required this.participantIds,
    this.messages = const [],
  });
}
