import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

Widget buildAudioPlayer(String filePath) {
  final AudioPlayer audioPlayer = AudioPlayer();

  return FutureBuilder(
    future: audioPlayer.setFilePath(filePath),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        return Row(
          children: [
            const Icon(Icons.audio_file_outlined, size: 40),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () async => await audioPlayer.play(),
            ),
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () async => await audioPlayer.pause(),
            ),
            IconButton(
              icon: const Icon(Icons.stop),
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
