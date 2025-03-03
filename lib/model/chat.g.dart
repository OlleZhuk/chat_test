// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatAdapter extends TypeAdapter<Chat> {
  @override
  final int typeId = 0;

  @override
  Chat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Chat(
      id: fields[0] as String,
      participantIds: (fields[1] as List).cast<String>(),
      messages: (fields[2] as List).cast<Message>(),
    );
  }

  @override
  void write(BinaryWriter writer, Chat obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.participantIds)
      ..writeByte(2)
      ..write(obj.messages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
