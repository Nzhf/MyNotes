import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
export '../models/ai_state.dart';
import '../models/ai_state.dart';
import '../services/ai_service.dart';
import '../services/grammar_service.dart';
import '../data/note_repository.dart';

/// =====================================================================
/// AI PROVIDERS - Riverpod State Management
/// =====================================================================
///
/// This file contains all the Riverpod providers for AI features.
///
/// **Explained simply:**
///
/// Think of providers like "smart boxes" that:
/// 1. Hold some data (the state)
/// 2. Know how to update that data
/// 3. Tell everyone who's watching when something changes
///
/// **Provider Types Used:**
///
/// 1. `Provider` - Creates a single shared instance (like a singleton)
///    Example: One AIService for the whole app
///
/// 2. `StateNotifierProvider` - Holds state that can change
///    Example: SummarizationState (loading → success → error)
///
/// **Data Flow:**
/// ```
/// User clicks "Summarize"
///     ↓
/// provider.notifier.summarize(note)
///     ↓
/// State → Loading (UI shows spinner)
///     ↓
/// AIService.summarizeNote(...)
///     ↓
/// State → Success (UI shows summary)
///     or
/// State → Error (UI shows snackbar)
/// ```
///
/// **Caching Strategy:**
/// - Summaries are cached by note ID
/// - Cache clears when note content changes
/// - Prevents unnecessary API calls
/// =====================================================================

// =============================================================================
// SERVICE PROVIDERS
// =============================================================================

/// Provider for shared AIService instance
///
/// **Why Provider instead of StateNotifierProvider?**
/// AIService doesn't have state that changes - it's just a service
/// that makes API calls. We only need one instance shared across the app.
final aiServiceProvider = Provider<AIService>((ref) {
  final service = AIService();

  // Clean up when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for shared GrammarService instance
final grammarServiceProvider = Provider<GrammarService>((ref) {
  final service = GrammarService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// =============================================================================
// SUMMARIZATION PROVIDER
// =============================================================================

/// StateNotifier for managing summarization state
///
/// **Methods:**
/// - `summarize(title, content, noteId)`: Generates summary for a note
/// - `clearSummary(noteId)`: Clears cached summary for a note
/// - `clearAll()`: Clears all cached summaries
class SummarizationNotifier extends StateNotifier<SummarizationState> {
  final AIService _aiService;

  // Cache to store summaries by note ID
  // This prevents re-calling the API for the same note
  final Map<String, String> _cache = {};

  // Track which content was used for each cached summary
  // If content changes, we invalidate the cache
  final Map<String, int> _contentHashes = {};

  SummarizationNotifier(this._aiService)
    : super(const SummarizationState.initial());

  /// Generates a summary for the given note
  ///
  /// Uses caching to avoid redundant API calls:
  /// - If note ID exists in cache AND content hasn't changed → return cached
  /// - Otherwise → call API and cache result
  Future<void> summarize({
    required String title,
    required String content,
    required String noteId,
    bool isAudioSummary = false,
  }) async {
    // Check cache first
    final contentHash = content.hashCode;
    if (_cache.containsKey(noteId) && _contentHashes[noteId] == contentHash) {
      // Return cached summary
      state = SummarizationState.success(_cache[noteId]!, noteId: noteId);
      return;
    }

    // Show loading state
    state = const SummarizationLoading();

    try {
      // Initialize service if needed and get summary
      await _aiService.initialize();
      final summary = await _aiService.summarizeNote(
        title: title,
        content: content,
      );

      // Cache the result
      _cache[noteId] = summary;
      _contentHashes[noteId] = contentHash;

      // Update state to success (this updates the UI immediately if the user is still on the screen)
      state = SummarizationSuccess(summary, noteId: noteId);

      // --- BACKGROUND PERSISTENCE LOGIC ---
      // This is the "magic" that keeps your summaries even if you exit the note!
      //
      // 1. We find the real note ID by removing any suffixes like '_audio'
      final realNoteId = noteId.split('_').first;

      // 2. We look up the existing note from the database
      final existingNote = NoteRepository.getNoteById(realNoteId);
      if (existingNote != null) {
        // 3. We update the database directly with the new summary.
        // If 'isAudioSummary' is true, we update the 'audioSummary' field.
        // Otherwise, we update the main 'aiSummary' field.
        await NoteRepository.updateNote(
          realNoteId,
          existingNote.title,
          existingNote.content,
          colorValue: existingNote.colorValue,
          reminder: existingNote.reminder,
          imagePath: existingNote.imagePath,
          audioPath: existingNote.audioPath,
          aiSummary: isAudioSummary ? existingNote.aiSummary : summary,
          transcription: existingNote.transcription,
          audioSummary: isAudioSummary ? summary : existingNote.audioSummary,
        );
      }
      // ------------------------------------
    } catch (e) {
      // Update state to error
      state = SummarizationError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Clears the cached summary for a specific note
  void clearSummary(String noteId) {
    _cache.remove(noteId);
    _contentHashes.remove(noteId);
    state = const SummarizationInitial();
  }

  /// Clears all cached summaries
  void clearAll() {
    _cache.clear();
    _contentHashes.clear();
    state = const SummarizationInitial();
  }

  /// Check if a summary is cached for this note
  bool hasCachedSummary(String noteId) {
    return _cache.containsKey(noteId);
  }

  /// Resets the state to initial
  void reset() {
    state = const SummarizationInitial();
  }

  /// Manually sets a successful result (used when loading from DB)
  void setLoadedResult(String summary, String noteId) {
    state = SummarizationSuccess(summary, noteId: noteId);
    // Also cache it so we don't re-summarize if content hasn't changed
    _cache[noteId] = summary;
  }
}

/// Provider for summarization state management
///
/// **Usage in widgets:**
/// ```dart
/// // Watch state
/// final state = ref.watch(summarizationProvider);
///
/// // Call methods
/// ref.read(summarizationProvider.notifier).summarize(
///   title: note.title,
///   content: note.content,
///   noteId: note.id,
/// );
/// ```
final summarizationProvider =
    StateNotifierProvider<SummarizationNotifier, SummarizationState>((ref) {
      final aiService = ref.watch(aiServiceProvider);
      return SummarizationNotifier(aiService);
    });

// =============================================================================
// TAG SUGGESTION PROVIDER
// =============================================================================

/// StateNotifier for managing tag suggestions state
class TagSuggestionNotifier extends StateNotifier<TagSuggestionState> {
  final AIService _aiService;

  // Cache tags by note ID
  final Map<String, List<String>> _cache = {};
  final Map<String, int> _contentHashes = {};

  // Debounce timer - prevents calling API on every keystroke
  Timer? _debounceTimer;

  TagSuggestionNotifier(this._aiService) : super(const TagSuggestionInitial());

  /// Suggests tags for the given note content
  ///
  /// **Parameters:**
  /// - [title]: Note title (helps AI understand context)
  /// - [content]: Note content to analyze
  /// - [noteId]: Unique note identifier for caching
  /// - [debounce]: If true, waits 1.5 seconds before calling API
  ///   This prevents calling API while user is still typing
  Future<void> suggestTags({
    required String title,
    required String content,
    required String noteId,
    bool debounce = true,
  }) async {
    // Cancel any pending debounced call
    _debounceTimer?.cancel();

    // Skip if content is too short
    if (content.trim().length < 30) {
      state = const TagSuggestionInitial();
      return;
    }

    // Check cache first
    final contentHash = content.hashCode;
    if (_cache.containsKey(noteId) && _contentHashes[noteId] == contentHash) {
      state = TagSuggestionSuccess(_cache[noteId]!);
      return;
    }

    if (debounce) {
      // Debounce: wait before calling API
      _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
        _fetchTags(title, content, noteId, contentHash);
      });
    } else {
      // Call immediately
      await _fetchTags(title, content, noteId, contentHash);
    }
  }

  /// Internal method to fetch tags from API
  Future<void> _fetchTags(
    String title,
    String content,
    String noteId,
    int contentHash,
  ) async {
    state = const TagSuggestionLoading();

    try {
      await _aiService.initialize();
      final tags = await _aiService.suggestTags(title: title, content: content);

      // Cache results
      _cache[noteId] = tags;
      _contentHashes[noteId] = contentHash;

      state = TagSuggestionSuccess(tags);
    } catch (e) {
      state = TagSuggestionError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Clears suggestions for a specific note
  void clearSuggestions(String noteId) {
    _cache.remove(noteId);
    _contentHashes.remove(noteId);
    state = const TagSuggestionInitial();
  }

  /// Clears all cached suggestions
  void clearAll() {
    _debounceTimer?.cancel();
    _cache.clear();
    _contentHashes.clear();
    state = const TagSuggestionInitial();
  }

  /// Resets the state to initial
  void reset() {
    _debounceTimer?.cancel();
    state = const TagSuggestionInitial();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Provider for tag suggestion state management
final tagSuggestionProvider =
    StateNotifierProvider<TagSuggestionNotifier, TagSuggestionState>((ref) {
      final aiService = ref.watch(aiServiceProvider);
      return TagSuggestionNotifier(aiService);
    });

// =============================================================================
// GRAMMAR CHECK PROVIDER
// =============================================================================

/// StateNotifier for managing grammar check state
class GrammarCheckNotifier extends StateNotifier<GrammarCheckState> {
  final GrammarService _grammarService;

  // Cache grammar results by text hash
  final Map<int, List<GrammarIssueData>> _cache = {};

  // Debounce timer for real-time checking
  Timer? _debounceTimer;

  GrammarCheckNotifier(this._grammarService)
    : super(const GrammarCheckInitial());

  /// Checks grammar for the given text
  ///
  /// **Parameters:**
  /// - [text]: The text to check
  /// - [debounce]: If true, waits 800ms after typing stops before checking
  Future<void> checkGrammar(String text, {bool debounce = true}) async {
    // Cancel any pending check
    _debounceTimer?.cancel();

    // Skip if text is too short
    if (text.trim().length < 10) {
      state = const GrammarCheckSuccess([]);
      return;
    }

    // Check cache first
    final textHash = text.hashCode;
    if (_cache.containsKey(textHash)) {
      state = GrammarCheckSuccess(_cache[textHash]!);
      return;
    }

    if (debounce) {
      // Wait for user to stop typing
      _debounceTimer = Timer(const Duration(milliseconds: 800), () {
        _performCheck(text, textHash);
      });
    } else {
      await _performCheck(text, textHash);
    }
  }

  /// Internal method to perform the actual grammar check
  Future<void> _performCheck(String text, int textHash) async {
    // Show subtle loading (we don't want to distract user while typing)
    state = const GrammarCheckLoading();

    try {
      final result = await _grammarService.checkGrammar(text);

      // Convert to GrammarIssueData
      final issues = result.issues
          .map(
            (issue) => GrammarIssueData(
              message: issue.message,
              offset: issue.offset,
              length: issue.length,
              suggestions: issue.replacements,
              problematicText: issue.problematicText,
            ),
          )
          .toList();

      // Cache results
      _cache[textHash] = issues;

      // Limit cache size to prevent memory issues
      if (_cache.length > 50) {
        _cache.remove(_cache.keys.first);
      }

      state = GrammarCheckSuccess(issues);
    } catch (e) {
      // Fail silently for grammar check - it's not critical
      state = const GrammarCheckSuccess([]);
    }
  }

  /// Clears all cached results
  void clearAll() {
    _debounceTimer?.cancel();
    _cache.clear();
    state = const GrammarCheckInitial();
  }

  /// Resets the state to initial
  void reset() {
    _debounceTimer?.cancel();
    state = const GrammarCheckInitial();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Provider for grammar check state management
final grammarCheckProvider =
    StateNotifierProvider<GrammarCheckNotifier, GrammarCheckState>((ref) {
      final grammarService = ref.watch(grammarServiceProvider);
      return GrammarCheckNotifier(grammarService);
    });

// =============================================================================
// TRANSCRIPTION PROVIDER
// =============================================================================

/// StateNotifier for managing audio transcription
class TranscriptionNotifier extends StateNotifier<TranscriptionState> {
  final AIService _aiService;

  TranscriptionNotifier(this._aiService)
    : super(const TranscriptionState.initial());

  /// Transcribes the audio file at the given path
  Future<void> transcribe(String path, {String? noteId}) async {
    state = const TranscriptionLoading();

    try {
      await _aiService.initialize();
      final text = await _aiService.transcribeAudio(path);
      // Update state to success
      state = TranscriptionSuccess(text, noteId: noteId);

      // --- BACKGROUND PERSISTENCE LOGIC ---
      // If a noteId was passed, we save the transcription results to the database
      // right now, so it's not lost if the user leaves the screen.
      if (noteId != null) {
        final existingNote = NoteRepository.getNoteById(noteId);
        if (existingNote != null) {
          await NoteRepository.updateNote(
            noteId,
            existingNote.title,
            existingNote.content,
            colorValue: existingNote.colorValue,
            reminder: existingNote.reminder,
            imagePath: existingNote.imagePath,
            audioPath: existingNote.audioPath,
            aiSummary: existingNote.aiSummary,
            transcription: text,
            audioSummary: existingNote.audioSummary,
          );
        }
      }
      // ------------------------------------
    } catch (e) {
      state = TranscriptionError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Resets the state to initial
  void reset() {
    state = const TranscriptionInitial();
  }

  /// Manually sets a successful result (used when loading from DB)
  void setLoadedResult(String text, String noteId) {
    state = TranscriptionSuccess(text, noteId: noteId);
  }
}

/// Provider for transcription state management
final transcriptionProvider =
    StateNotifierProvider<TranscriptionNotifier, TranscriptionState>((ref) {
      final aiService = ref.watch(aiServiceProvider);
      return TranscriptionNotifier(aiService);
    });

/// Provider for audio-specific summarization state management
///
/// **Why a separate provider?**
/// This allows the user to have a note summary AND an audio summary
/// existing at the same time without their loading states or results
/// conflicting in the UI.
final audioSummarizationProvider =
    StateNotifierProvider<SummarizationNotifier, SummarizationState>((ref) {
      final aiService = ref.watch(aiServiceProvider);
      return SummarizationNotifier(aiService);
    });
