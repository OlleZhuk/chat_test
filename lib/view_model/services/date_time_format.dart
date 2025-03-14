import 'package:intl/intl.dart';

//* Формат даты и времени
String formatMessageTime(DateTime timestamp, {bool isChatScreen = true}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final difference = now.difference(timestamp);

  if (difference.inMinutes <= 10) {
    //> Если прошло меньше 10 минут
    return isChatScreen
        ? '${_formatMinutes(difference.inMinutes)} назад'
        : ''; // не предусмотрено на экране сообщений
  } else if (timestamp.isAfter(today) || timestamp.isAtSameMomentAs(today)) {
    //> Если сегодня
    return isChatScreen
        //> Для экрана чатов
        ? DateFormat('HH:mm').format(timestamp)
        //> Для экрана сообщений
        : 'Сегодня';
  } else if (timestamp.isBefore(today)) {
    //> Если вчера
    return 'Вчера';
  } else {
    //> Если раньше, чем вчера
    return DateFormat('dd.MM.yy').format(timestamp);
  }
}

//* Падежи минуты
String _formatMinutes(int minutes) {
  if (minutes == 1) {
    return '$minutes минута';
  } else if (minutes >= 2 && minutes <= 4) {
    return '$minutes минуты';
  } else {
    return '$minutes минут';
  }
}
