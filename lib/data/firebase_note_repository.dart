import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../note_model.dart';

class FirebaseNoteRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference: users/{userId}/notes
  static CollectionReference<Map<String, dynamic>> _getNotesCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('notes');
  }

  // ============================================================
  // SYNC: PULL FROM CLOUD (GET ALL)
  // ============================================================
  static Future<List<Note>> getAllNotes(String userId) async {
    try {
      final snapshot = await _getNotesCollection(userId).get();
      return snapshot.docs.map((doc) {
        // We use the data from Firestore, but ensure ID matches doc ID just in case
        final data = doc.data();
        data['id'] = doc.id;
        return Note.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching notes from Firebase: $e');
      return [];
    }
  }

  // ============================================================
  // SINGLE NOTE OPERATIONS (PUSH TO CLOUD)
  // ============================================================
  static Future<void> addNote(String userId, Note note) async {
    try {
      await _getNotesCollection(userId).doc(note.id).set(note.toMap());
    } catch (e) {
      debugPrint('Error adding note to Firebase: $e');
    }
  }

  static Future<void> updateNote(String userId, Note note) async {
    try {
      // Use set with merge: true to create if missing, or update if exists
      await _getNotesCollection(
        userId,
      ).doc(note.id).set(note.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating note in Firebase: $e');
    }
  }

  static Future<void> deleteNote(String userId, String noteId) async {
    try {
      await _getNotesCollection(userId).doc(noteId).delete();
    } catch (e) {
      debugPrint('Error deleting note from Firebase: $e');
    }
  }

  // ============================================================
  // BATCH OPERATIONS (SYNC)
  // ============================================================
  static Future<void> syncLocalNotesToCloud(
    String userId,
    List<Note> localNotes,
  ) async {
    final batch = _firestore.batch();
    final collection = _getNotesCollection(userId);

    for (final note in localNotes) {
      final docRef = collection.doc(note.id);
      batch.set(docRef, note.toMap());
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Error batch syncing to Firebase: $e');
    }
  }

  // ============================================================
  // DELETE ALL DATA (PRIVACY FEATURE)
  // ============================================================
  static Future<void> deleteAllData(String userId) async {
    try {
      final collection = _getNotesCollection(userId);
      final snapshot = await collection.get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all data from Firebase: $e');
      rethrow;
    }
  }
}
