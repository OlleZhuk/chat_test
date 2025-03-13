import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../model/user.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({
    super.key,
    required this.filePath,
    required this.user,
  });

  final String filePath;
  final User user;

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayerListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getAudioDuration(widget.filePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final duration = snapshot.data!;
          final durationText = _formatDuration(duration);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: widget.user.color.withOpacity(.5),
              child: isPlaying
                  ? IconButton(
                      icon: const Icon(Icons.pause),
                      onPressed: () async {
                        _changeIcon();
                        await _audioPlayer.stop();
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () async {
                        _changeIcon();
                        await _audioPlayer.play();
                      },
                    ),
            ),
            //> возможно применение визуализации в title...
            title: Text(widget.filePath.split('/').last),
            subtitle: Text(durationText),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  //* Метод получения длительности
  Future<Duration> _getAudioDuration(String filePath) async {
    //> Определение источника
    await _audioPlayer.setFilePath(filePath);
    //> Определение длительности
    final duration = _audioPlayer.duration;
    //> Возвращает длительность или 0
    return duration ?? Duration.zero;
  }

  //* Форматирование длительности
  _formatDuration(Duration duration) {
    if (duration.inMinutes == 0) {
      //> Если меньше минуты, выводим только секунды
      return '${duration.inSeconds} сек.';
    } else {
      //> Если больше минуты, форматируем как "мм:сс"
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds.remainder(60);

      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  //* Слушатель сотояния для автосмены иконок
  void _setupAudioPlayerListeners() {
    _audioPlayer.playerStateStream.listen((PlayerState state) {
      if (state.processingState == ProcessingState.completed) {
        _audioPlayer.stop();
        //> Воспроизведение завершено
        setState(() => isPlaying = false);
      }
    });
  }

  void _changeIcon() => setState(() {
        isPlaying = !isPlaying;
      });
}
