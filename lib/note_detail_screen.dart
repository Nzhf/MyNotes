import 'package:flutter/material.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';

class NoteDetailScreen extends StatefulWidget {
  final String title;
  final String content;
  final Color color;
  final String? imagePath;
  final String? audioPath;
  final String? aiSummary;
  final String? transcription;
  final String? videoPath;
  final String? audioSummary;
  final String? videoTranscription;
  final String? videoSummary;

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
    this.videoPath,
    this.videoTranscription,
    this.videoSummary,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late AudioPlayer _audioPlayer;
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Initialize video if available
    if (widget.videoPath != null) {
      _videoController = VideoPlayerController.file(File(widget.videoPath!))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }

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
    _videoController?.dispose();
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

            // --- Video Attachment Section ---
            if (widget.videoPath != null &&
                _videoController != null &&
                _videoController!.value.isInitialized)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.black87,
                            ),
                            onPressed: () {
                              setState(() {
                                _videoController!.value.isPlaying
                                    ? _videoController!.pause()
                                    : _videoController!.play();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // --- Text Content Section ---
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.content,
              style: TextStyle(
                fontSize: 18,
                color: textColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),

            // --- AI & Analysis Sections ---
            if (widget.aiSummary != null ||
                widget.transcription != null ||
                widget.videoSummary != null ||
                widget.videoTranscription != null) ...[
              const SizedBox(height: 40),
              Divider(color: textColor.withOpacity(0.1)),
              const SizedBox(height: 20),

              // Note Summary
              if (widget.aiSummary != null)
                _buildAnalysisSection(
                  title: 'AI Summary',
                  content: widget.aiSummary!,
                  icon: Icons.auto_awesome_rounded,
                  iconColor: Colors.indigo,
                  textColor: textColor,
                ),

              // Audio Summary
              if (widget.audioSummary != null)
                _buildAnalysisSection(
                  title: 'Audio Summary',
                  content: widget.audioSummary!,
                  icon: Icons.summarize_rounded,
                  iconColor: Colors.teal,
                  textColor: textColor,
                ),

              // Video Summary
              if (widget.videoSummary != null)
                _buildAnalysisSection(
                  title: 'Video Summary',
                  content: widget.videoSummary!,
                  icon: Icons.video_stable_rounded,
                  iconColor: Colors.deepPurple,
                  textColor: textColor,
                ),

              // Audio Transcription
              if (widget.transcription != null)
                _buildAnalysisSection(
                  title: 'Audio Transcription',
                  content: widget.transcription!,
                  icon: Icons.text_fields_rounded,
                  iconColor: Colors.green,
                  textColor: textColor,
                ),

              // Video Transcription
              if (widget.videoTranscription != null)
                _buildAnalysisSection(
                  title: 'Video Transcription',
                  content: widget.videoTranscription!,
                  icon: Icons.subtitles_rounded,
                  iconColor: Colors.orange,
                  textColor: textColor,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}