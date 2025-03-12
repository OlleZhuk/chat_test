import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waveform_recorder/waveform_recorder.dart';

import 'package:chat_test/view_model/widgets/player_audio.dart';

class VoiceRecord extends StatefulWidget {
  const VoiceRecord({super.key, required this.onSend});

  final Function(XFile?) onSend;

  @override
  State<VoiceRecord> createState() => _VoiceRecordState();
}

class _VoiceRecordState extends State<VoiceRecord> {
  final _waveController = WaveformRecorderController();

  @override
  void dispose() {
    _waveController.dispose();
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
            waveColor: Colors.grey,
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
                  ? const Icon(Icons.stop, size: 40)
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
                  if (recordedFile != null) buildAudioPlayer(recordedFile.path);
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
