import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class User {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String firstName;
  @HiveField(2)
  final String? lastName;
  @HiveField(3)
  final int pinCode;

  User({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.pinCode,
  });
}
