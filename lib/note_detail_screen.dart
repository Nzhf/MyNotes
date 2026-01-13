import 'package:flutter/material.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

class NoteDetailScreen extends StatefulWidget {
  final String title;
  final String content;
  final Color color;
  final String? imagePath;
  final String? audioPath;
  final String? aiSummary;
  final String? transcription;
  final String? audioSummary;

  const NoteDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.color,
    this.imagePath,
    this.audioPath,
    this.aiSummary,
    this.transcription,
    this.audioSummary,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? const Color(0xFFE0E0E0) : Colors.black;

    return Scaffold(
      backgroundColor: widget.color,
      appBar: AppBar(
        backgroundColor: widget.color,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          widget.title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.imagePath != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(widget.imagePath!),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            if (widget.audioPath != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle : Icons.play_circle,
                      ),
                      iconSize: 40,
                      onPressed: () async {
                        if (_isPlaying) {
                          await _audioPlayer.pause();
                        } else {
                          await _audioPlayer.play(
                            DeviceFileSource(widget.audioPath!),
                          );
                        }
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Slider(
                            value: _position.inSeconds.toDouble(),
                            max: _duration.inSeconds.toDouble() > 0
                                ? _duration.inSeconds.toDouble()
                                : 1.0,
                            onChanged: (value) async {
                              await _audioPlayer.seek(
                                Duration(seconds: value.toInt()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Text(
              widget.title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.content,
              style: TextStyle(fontSize: 18, color: textColor),
            ),

            if (widget.aiSummary != null || widget.transcription != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              if (widget.aiSummary != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.aiSummary!,
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (widget.audioSummary != null) ...[
                Row(
                  children: [
                    const Icon(Icons.summarize, size: 20, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(
                      'Audio Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.audioSummary!,
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (widget.transcription != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.text_fields,
                      size: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Transcription',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.transcription!,
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
