import 'package:firebase_auth/firebase_auth.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:mynotes/note_model.dart';
import 'firebase_note_repository.dart';

class NoteRepository {
  static Box<Note>? _box;
  static Note? _lastDeleted;

  static String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // ============================================================
  // INIT
  // ============================================================
  static Future<void> init() async {
    _box ??= await Hive.openBox<Note>('notesBox');
  }

  static Box<Note> get box => _box!;

  // ============================================================
  // GET NOTES
  // ============================================================
  static List<Note> getNotes() {
    if (_box == null) return [];
    final allNotes = _box!.values.toList();

    // Sort logic handled here or in UI - repo returns list
    // Usually sorted by createdAt or updatedAt.
    // Let's implement default sort: UpdatedAt desc
    allNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return allNotes;
  }

  static List<Note> getAllNotes() {
    if (_box == null) return [];
    return _box!.values.toList();
  }

  static Note? getNoteById(String id) {
    if (_box == null) return null;
    return _box!.get(id);
  }

  // ============================================================
  // SYNC
  // ============================================================
  /// Pulls notes from cloud, merges with local notes based on updatedAt
  static Future<void> syncFromCloud() async {
    final uid = _userId;
    if (uid == null) return;

    await init();

    // 1. Fetch Cloud Notes
    final cloudNotes = await FirebaseNoteRepository.getAllNotes(uid);
    if (cloudNotes.isEmpty) return;

    // 2. Merge Strategies
    for (final cNote in cloudNotes) {
      final localNote = _box!.get(cNote.id);

      if (localNote == null) {
        // New note from cloud -> save to local
        await _box!.put(cNote.id, cNote);
      } else {
        // Conflict: compare timestamps
        // If cloud note is newer, overwrite local
        if (cNote.updatedAt.isAfter(localNote.updatedAt)) {
          await _box!.put(cNote.id, cNote);
        }
        // If local is newer, we could push to cloud, but usually
        // that happens on save. We can implement bi-directional sync later.
      }
    }
  }

  // ============================================================
  // ADD
  // ============================================================
  static Future<void> addNote({required Note note}) async {
    await init();
    // 1. Save Local
    await _box!.put(note.id, note);

    // 2. Sync to Cloud
    final uid = _userId;
    if (uid != null) {
      // Fire and forget
      FirebaseNoteRepository.addNote(uid, note);
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================
  static Future<void> updateNote(
    String id,
    String title,
    String content, {
    required int colorValue,
    DateTime? reminder,
    String? imagePath,
    String? audioPath,
    String? aiSummary,
    String? transcription,
    String? audioSummary,
    // NEW: Video fields
    String? videoPath,
    String? videoTranscription,
    String? videoSummary,
  }) async {
    await init();

    final n = _box!.get(id);
    if (n == null) return;

    final updated = n.copyWith(
      title: title,
      content: content,
      colorValue: colorValue,
      updatedAt: DateTime.now(),
      reminder: reminder,
      imagePath: imagePath,
      audioPath: audioPath,
      aiSummary: aiSummary,
      transcription: transcription,
      audioSummary: audioSummary,
      videoPath: videoPath,
      videoTranscription: videoTranscription,
      videoSummary: videoSummary,
    );

    // 1. Save Local
    await _box!.put(id, updated);

    // 2. Sync to Cloud
    final uid = _userId;
    if (uid != null) {
      FirebaseNoteRepository.updateNote(uid, updated);
    }
  }

  // ============================================================
  // DELETE + UNDO
  // ============================================================
  static Future<void> deleteNote(String id) async {
    await init();
    _lastDeleted = _box!.get(id);

    // 1. Delete Local
    await _box!.delete(id);

    // 2. Delete from Cloud
    final uid = _userId;
    if (uid != null) {
      FirebaseNoteRepository.deleteNote(uid, id);
    }
  }

  static Future<void> undoDelete() async {
    if (_lastDeleted == null) return;
    await init();

    final noteToRestore = _lastDeleted!;

    // 1. Restore Local
    await _box!.put(noteToRestore.id, noteToRestore);

    // 2. Restore Cloud
    final uid = _userId;
    if (uid != null) {
      FirebaseNoteRepository.addNote(uid, noteToRestore);
    }

    _lastDeleted = null;
  }

  // Same as undoDelete but kept for compatibility if used elsewhere
  static Future<void> restoreLastDeleted() => undoDelete();

  // ============================================================
  // PIN
  // ============================================================
  static Future<void> togglePin(String id) async {
    await init();

    final n = _box!.get(id);
    if (n == null) return;

    final updated = n.copyWith(
      isPinned: !n.isPinned,
      updatedAt: DateTime.now(),
    );

    await _box!.put(id, updated);

    final uid = _userId;
    if (uid != null) {
      FirebaseNoteRepository.updateNote(uid, updated);
    }
  }

  // ============================================================
  // COLOR
  // ============================================================
  static Future<void> changeColor(String id, int colorValue) async {
    await init();

    final n = _box!.get(id);
    if (n == null) return;

    final updated = n.copyWith(
      colorValue: colorValue,
      updatedAt: DateTime.now(),
    );

    await _box!.put(id, updated);

    final uid = _userId;
    if (uid != null) {
      FirebaseNoteRepository.updateNote(uid, updated);
    }
  }

  // ============================================================
  // DELETE ALL DATA (SETTINGS)
  // ============================================================
  static Future<void> deleteAllData() async {
    await init();

    // 1. Delete all local
    await _box!.clear();

    // 2. Delete all cloud
    final uid = _userId;
    if (uid != null) {
      await FirebaseNoteRepository.deleteAllData(uid);
    }
  }
}
