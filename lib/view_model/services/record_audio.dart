import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:waveform_recorder/waveform_recorder.dart';

import '../../model/user.dart';

class VoiceRecord extends StatefulWidget {
  const VoiceRecord({
    super.key,
    required this.onSend,
    required this.user,
  });

  final Function(XFile?) onSend;
  final User user;

  @override
  State<VoiceRecord> createState() => _VoiceRecordState();
}

class _VoiceRecordState extends State<VoiceRecord> {
  final _waveController = WaveformRecorderController();
  final _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _waveController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_waveController.isRecording)
          WaveformRecorder(
            controller: _waveController,
            height: 48,
            waveColor: widget.user.color,
            durationTextStyle: const TextStyle(color: Colors.grey),
            onRecordingStopped: () async {
              final recordedFile = _waveController.file;
              if (recordedFile != null) {
                widget.onSend(recordedFile); // файл уходит в callback
                setState(() {});
              }
            },
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: _waveController.isRecording
                  // Стоп
                  ? const Icon(Icons.stop, size: 40)
                  // Микрофон
                  : Image.asset('assets/icons/Audio.png', scale: .7),
              onPressed: () async {
                if (_waveController.isRecording) {
                  await _waveController.stopRecording();
                } else {
                  await _waveController.startRecording();
                }
                if (mounted) setState(() {});
              },
            ),
            if (_waveController.file != null)
              IconButton(
                icon: const Icon(Icons.play_arrow, size: 40),
                onPressed: () async {
                  final recordedFile = _waveController.file;
                  await _audioPlayer.setFilePath(recordedFile!.path);
                  await _audioPlayer.play();
                },
              ),
            if (_waveController.isRecording)
              IconButton(
                icon: const Icon(Icons.delete, size: 30),
                onPressed: () async {
                  await _waveController.cancelRecording();
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ],
    );
  }
}
