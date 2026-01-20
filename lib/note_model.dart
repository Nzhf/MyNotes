import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

//part 'note_model.g.dart'; // unused for manual adapter but keep for clarity (no codegen needed)

// We will implement a manual TypeAdapter below; the `part` is optional.

class Note {
  String id;
  String title;
  String content;
  int colorValue; // Color stored as int for Hive
  DateTime createdAt;
  DateTime updatedAt;
  bool isPinned;
  DateTime? reminder; // New field for reminder
  String? imagePath; // Local path to attached image
  String? audioPath; // Local path to attached voice recording or audio file
  String? aiSummary; // PERSISTENT AI summary of the note
  String? transcription; // PERSISTENT AI transcription of the audio
  String? audioSummary; // PERSISTENT AI summary of the audio transcription

  // =========================================================================
  // VIDEO ATTACHMENT FIELDS
  // =========================================================================
  String? videoPath; // Local path to attached video file
  String? videoTranscription; // PERSISTENT AI transcription of the video audio
  String? videoSummary; // PERSISTENT AI summary of the video transcription

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.reminder,
    this.imagePath,
    this.audioPath,
    this.aiSummary,
    this.transcription,
    this.audioSummary,
    this.videoPath,
    this.videoTranscription,
    this.videoSummary,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'colorValue': colorValue,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'isPinned': isPinned,
    'reminder': reminder?.millisecondsSinceEpoch,
    'imagePath': imagePath,
    'audioPath': audioPath,
    'aiSummary': aiSummary,
    'transcription': transcription,
    'audioSummary': audioSummary,
    'videoPath': videoPath,
    'videoTranscription': videoTranscription,
    'videoSummary': videoSummary,
  };

  factory Note.fromMap(Map m) {
    return Note(
      id: m['id'] as String,
      title: m['title'] as String,
      content: m['content'] as String,
      colorValue: m['colorValue'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updatedAt'] as int),
      isPinned: m['isPinned'] as bool,
      reminder: m['reminder'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['reminder'] as int)
          : null,
      imagePath: m['imagePath'] as String?,
      audioPath: m['audioPath'] as String?,
      aiSummary: m['aiSummary'] as String?,
      transcription: m['transcription'] as String?,
      audioSummary: m['audioSummary'] as String?,
      videoPath: m['videoPath'] as String?,
      videoTranscription: m['videoTranscription'] as String?,
      videoSummary: m['videoSummary'] as String?,
    );
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    DateTime? reminder,
    String? imagePath,
    String? audioPath,
    String? aiSummary,
    String? transcription,
    String? audioSummary,
    String? videoPath,
    String? videoTranscription,
    String? videoSummary,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      reminder: reminder ?? this.reminder,
      imagePath: imagePath ?? this.imagePath,
      audioPath: audioPath ?? this.audioPath,
      aiSummary: aiSummary ?? this.aiSummary,
      transcription: transcription ?? this.transcription,
      audioSummary: audioSummary ?? this.audioSummary,
      videoPath: videoPath ?? this.videoPath,
      videoTranscription: videoTranscription ?? this.videoTranscription,
      videoSummary: videoSummary ?? this.videoSummary,
    );
  }
}

// Manual Hive adapter (no build_runner)
class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    final map = reader.readMap();
    return Note.fromMap(Map<String, dynamic>.from(map));
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer.writeMap(obj.toMap());
  }
}
