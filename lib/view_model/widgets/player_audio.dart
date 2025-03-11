import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

Widget buildAudioPlayer(String filePath) {
  final AudioPlayer audioPlayer = AudioPlayer();

  return FutureBuilder(
    future: audioPlayer.setFilePath(filePath),
    builder: (context, snapshot) {
      const double iconSize = 40;
      if (snapshot.connectionState == ConnectionState.done) {
        return Row(
          children: [
            const Icon(Icons.audio_file_outlined, size: iconSize),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.play_arrow, size: iconSize),
              onPressed: () async => await audioPlayer.play(),
            ),
            IconButton(
              icon: const Icon(Icons.pause, size: iconSize),
              onPressed: () async => await audioPlayer.pause(),
            ),
            IconButton(
              icon: const Icon(Icons.stop, size: iconSize),
              onPressed: () async => await audioPlayer.stop(),
            ),
          ],
        );
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    },
  );
}
