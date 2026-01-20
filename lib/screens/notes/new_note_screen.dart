import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../note_model.dart';
import '../../data/note_repository.dart';
import '../../services/notification_service.dart';
import '../../providers/ai_provider.dart';
import '../../utils/grammar_controller.dart';
import 'package:mynotes/services/media_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../../services/video_processor_service.dart';
import '../../services/ai_service.dart';
import 'package:path/path.dart' as p;

/// =============================================================================
/// NEW NOTE SCREEN - With AI Features
/// =============================================================================
///
/// This screen allows users to create and edit notes with AI-powered features:
///
/// **AI Features Included:**
/// 1. ✨ Summarize Button - Generates a concise summary using Google Gemini
/// 2. 🏷️ Smart Tags - Auto-suggests categories based on content
/// 3. ✍️ Grammar Check - Real-time grammar suggestions (coming soon)
///
/// **How it works (explained simply!):**
///
/// When you type a note, AI helpers are watching (in a good way!):
/// - After you stop typing for 1.5 seconds, the tag suggester thinks about
///   what labels would fit your note (like "Shopping" or "Work")
/// - When you click the sparkle button (✨), the summarizer reads your
///   whole note and gives you a short version
/// - The grammar checker looks for mistakes while you type
///
/// All of this uses "Riverpod" for state management, which means:
/// - Loading spinners appear while AI is thinking
/// - Results are cached so we don't ask the AI the same question twice
/// - Errors show as friendly messages at the bottom of the screen
/// =============================================================================
class NewNoteScreen extends ConsumerStatefulWidget {
  final Note? existingNote;
  const NewNoteScreen({super.key, this.existingNote});

  @override
  ConsumerState<NewNoteScreen> createState() => _NewNoteScreenState();
}

class _NewNoteScreenState extends ConsumerState<NewNoteScreen> {
  late final TextEditingController titleController;
  late final GrammarAwareTextEditingController contentController;
  final _uuid = const Uuid();
  Timer? _debounce;

  // Track if summary panels are expanded
  bool _showSummary = false;
  bool _showAudioSummary = false;

  // Local state tracking (do NOT mutate widget.existingNote)
  String? _noteId;
  int _selectedColor = 0xFFFFFFFF;
  DateTime? _reminderTime;
  String? _imagePath;
  String? _audioPath;
  String? _aiSummary;
  String? _transcription;
  String? _audioSummary; // Separate summary for the audio transcription

  // TO CONTROL IF THE TRANSCRIPTION TEXT BOX IS VISIBLE
  // We keep it hidden during "One-Tap" summaries to keep the UI clean.
  bool _showTranscriptionUI = false;

  // =========================================================================
  // VIDEO STATE VARIABLES
  // =========================================================================
  String? _videoPath;
  String? _videoTranscription;
  String? _videoSummary;
  bool _showVideoSummary = false;
  bool _showVideoTranscriptionUI = false;
  bool _isExtractingAudio = false; // Loading state for FFmpeg extraction
  VideoPlayerController? _videoController;
  final VideoProcessorService _videoProcessor = VideoProcessorService();

  final MediaService _mediaService = MediaService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Expanded pastel palette with more color options
  final List<int> _palette = [
    0xFFFFFFFF, // White
    0xFFFFF1C1, // Light Yellow
    0xFFFFD6E0, // Light Pink
    0xFFC6E5FF, // Light Blue
    0xFFD6F4D2, // Light Green
    0xFFE7D3FF, // Light Purple
    0xFFFFE8C7, // Light Orange/Peach
    0xFFE4F3FF, // Pale Blue
    0xFFFFE4EC, // Rose Pink
    0xFFD4F0F0, // Mint/Teal
    0xFFFCE4EC, // Blush Pink
    0xFFE8F5E9, // Mint Green
    0xFFFFF8E1, // Cream Yellow
    0xFFE1F5FE, // Sky Blue
    0xFFF3E5F5, // Lavender
  ];

  @override
  void initState() {
    super.initState();

    // pre-fill controllers if editing
    final existing = widget.existingNote;
    titleController = TextEditingController(text: existing?.title ?? '');

    // Initialize custom grammar-aware controller
    contentController = GrammarAwareTextEditingController();
    final initialContent = existing?.content;
    if (initialContent != null) {
      contentController.text = initialContent;
    }
    _selectedColor = (existing != null) ? (existing.colorValue) : 0xFFFFFFFF;
    _reminderTime = existing?.reminder;

    // note id tracked locally (null => new note not yet created)
    _noteId = existing?.id;
    _imagePath = existing?.imagePath;
    _audioPath = existing?.audioPath;
    _aiSummary = existing?.aiSummary;
    _transcription = existing?.transcription;
    _audioSummary = existing?.audioSummary;

    // --- VIDEO DATA ---
    _videoPath = existing?.videoPath;
    _videoTranscription = existing?.videoTranscription;
    _videoSummary = existing?.videoSummary;

    // Initialize Video Player if we have a path
    if (_videoPath != null) {
      _initVideoPlayer(_videoPath!);
    }

    // --- INITIALIZE VISIBILITY ---
    // If we already have a summary saved in the database,
    // we make sure the summary panel is visible right when you open the note!
    _showSummary = _aiSummary != null;
    _showAudioSummary = _audioSummary != null;

    // This toggle controls if the "Transcription Box" is visible.
    // We only show it if a transcription already exists or if the user taps "Transcribe".
    _showTranscriptionUI = _transcription != null;
    _showVideoTranscriptionUI = _videoTranscription != null;
    _showVideoSummary = _videoSummary != null;

    // Listen to audio player states
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    // --- RE-HYDRATE AI STATE ON ENTRY ---
    // If this note already has saved AI data, we "seed" the providers.
    // This makes sure the UI shows the saved results immediately, pinned to this Note ID!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final noteId = _noteId;
      if (noteId == null) {
        // New note: just reset everything
        ref.read(transcriptionProvider.notifier).reset();
        ref.read(summarizationProvider.notifier).reset();
        ref.read(audioSummarizationProvider.notifier).reset();
        ref.read(videoTranscriptionProvider.notifier).reset();
        ref.read(videoSummarizationProvider.notifier).reset();
        ref.read(tagSuggestionProvider.notifier).reset();
      } else {
        // Existing note: Load saved results into the "AI Brains"
        if (_transcription != null) {
          ref
              .read(transcriptionProvider.notifier)
              .setLoadedResult(_transcription!, noteId);
        } else {
          ref.read(transcriptionProvider.notifier).reset();
        }

        if (_aiSummary != null) {
          ref
              .read(summarizationProvider.notifier)
              .setLoadedResult(_aiSummary!, noteId);
        } else {
          ref.read(summarizationProvider.notifier).reset();
        }

        if (_audioSummary != null) {
          ref
              .read(audioSummarizationProvider.notifier)
              .setLoadedResult(_audioSummary!, "${noteId}_audio");
        } else {
          ref.read(audioSummarizationProvider.notifier).reset();
        }

        // --- VIDEO RE-HYDRATION ---
        if (_videoTranscription != null) {
          ref
              .read(videoTranscriptionProvider.notifier)
              .setLoadedResult(_videoTranscription!, "${noteId}_video");
        } else {
          ref.read(videoTranscriptionProvider.notifier).reset();
        }

        if (_videoSummary != null) {
          ref
              .read(videoSummarizationProvider.notifier)
              .setLoadedResult(_videoSummary!, "${noteId}_video_summary");
        } else {
          ref.read(videoSummarizationProvider.notifier).reset();
        }

        ref.read(tagSuggestionProvider.notifier).reset();
      }
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });

    // debounce autosave
    titleController.addListener(_onChanged);
    contentController.addListener(_onChanged);
  }

  // debounce helper - triggers autosave AND AI features
  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _autoSave();
      _triggerAISuggestions();
    });
  }

  /// Triggers AI features (tag suggestions and grammar check)
  /// Called after user stops typing to avoid spamming the API
  void _triggerAISuggestions() {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    // Only suggest tags if we have enough content
    if (content.length >= 30 && _noteId != null) {
      ref
          .read(tagSuggestionProvider.notifier)
          .suggestTags(
            title: title,
            content: content,
            noteId: _noteId!,
            debounce: false, // We already debounced above
          );
    }

    // Trigger grammar check (has its own internal debouncing)
    if (content.length >= 10) {
      ref
          .read(grammarCheckProvider.notifier)
          .checkGrammar(content, debounce: false);
    }
  }

  /// Summarizes the current note using AI
  /// Called when user taps the summarize button
  void _summarizeNote() {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (content.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note is too short to summarize. Add more content!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_noteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save the note first before summarizing.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show the summary panel
    setState(() => _showSummary = true);

    // Trigger summarization
    // We pass isAudioSummary: false to indicate this is the main note summary
    ref
        .read(summarizationProvider.notifier)
        .summarize(
          title: title,
          content: content,
          noteId: _noteId!,
          isAudioSummary: false,
        );
  }

  // autosave: create note if new, otherwise update existing
  Future<void> _autoSave() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    // nothing to do if nothing typed yet and no existing note
    if (_noteId == null && title.isEmpty && content.isEmpty) return;

    // If existing note: update with repository's update signature
    if (_noteId != null) {
      // updateNote(String id, String title, String content, { required int colorValue })
      await NoteRepository.updateNote(
        _noteId!,
        title,
        content,
        colorValue: _selectedColor,
        reminder: _reminderTime,
        imagePath: _imagePath,
        audioPath: _audioPath,
        aiSummary: _aiSummary,
        transcription: _transcription,
        audioSummary: _audioSummary,
        videoPath: _videoPath,
        videoTranscription: _videoTranscription,
        videoSummary: _videoSummary,
      );
      _manageNotification(_noteId!, title, content);
      return;
    }

    // Otherwise create a new Note and store it via addNote(note: Note)
    final id = _uuid.v4();
    final now = DateTime.now();

    final note = Note(
      id: id,
      title: title,
      content: content,
      colorValue: _selectedColor,
      createdAt: now,
      updatedAt: now,
      isPinned: false,
      reminder: _reminderTime,
      imagePath: _imagePath,
      audioPath: _audioPath,
      aiSummary: _aiSummary,
      transcription: _transcription,
      audioSummary: _audioSummary,
      videoPath: _videoPath,
      videoTranscription: _videoTranscription,
      videoSummary: _videoSummary,
    );

    await NoteRepository.addNote(note: note);

    // remember id locally so next edits will call updateNote
    setState(() {
      _noteId = id;
    });

    _manageNotification(id, title, content);
  }

  // ==========================================================================
  // MEDIA ACTIONS
  // ==========================================================================

  Future<void> _pickImage(ImageSource source) async {
    final path = await _mediaService.pickImage(source);
    if (path != null) {
      _handleImageSelected(path);
    }
  }

  void _handleImageSelected(String path) {
    setState(() => _imagePath = path);
    _autoSave();
  }

  Future<void> _handleGalleryPick() async {
    final path = await _mediaService.pickMedia();
    if (path != null) {
      final ext = p.extension(path).toLowerCase();
      if (ext == '.mp4' || ext == '.mov' || ext == '.avi') {
        await _handleVideoSelected(path);
      } else {
        _handleImageSelected(path);
      }
    }
  }

  Future<void> _recordVoice() async {
    if (_isRecording) {
      final path = await _mediaService.stopRecording();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
      if (!mounted) return;
      _autoSave();
      _showTranscriptionOffer();
    } else {
      try {
        await _mediaService.startRecording();
        setState(() => _isRecording = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _pickAudioFile() async {
    final path = await _mediaService.pickAudioFile();
    if (path != null) {
      setState(() => _audioPath = path);
      _autoSave();
      _showTranscriptionOffer();
    }
  }

  void _showTranscriptionOffer() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Audio added! Would you like to transcribe it?'),
        action: SnackBarAction(
          label: 'TRANSCRIBE',
          onPressed: _transcribeAudio,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _transcribeAudio() async {
    if (_audioPath == null) return;

    // Trigger transcription provider
    // Passing _noteId allows the provider to save the result permanently
    // even if the user leaves this screen before it finishes.
    ref
        .read(transcriptionProvider.notifier)
        .transcribe(_audioPath!, noteId: _noteId);
  }

  // ===========================================================================
  // VIDEO HANDLING LOGIC
  // ===========================================================================

  Future<void> _handleVideoSelected(String path) async {
    // Check file size
    final file = File(path);
    final size = await file.length();
    if (size > AIService.maxVideoSizeBytes) {
      if (mounted) {
        _showLimitError(
          'Video Too Large',
          'This video is over 500MB. To keep the app fast and stable, please choose a smaller video.',
        );
      }
      return;
    }

    setState(() {
      _videoPath = path;
    });

    // Initialize the player
    _initVideoPlayer(path);

    // Autosave so we don't lose the attachment
    _autoSave();

    // Offer to transcribe
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Video added! Would you like to transcribe it?'),
          action: SnackBarAction(
            label: 'TRANSCRIBE',
            onPressed: _transcribeVideo,
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// **Step 2: Extract audio and transcribe video**
  Future<void> _transcribeVideo() async {
    if (_videoPath == null) return;

    // Optimization: If we already have a transcription result, don't re-extract/re-transcribe
    if (_videoTranscription != null) {
      setState(() => _showVideoTranscriptionUI = true);
      return;
    }

    setState(() {
      _isExtractingAudio = true;
      _showVideoTranscriptionUI = true;
    });

    try {
      // 1. Extract audio from video using FFmpeg
      final extractedAudioPath = await _videoProcessor.extractAudio(
        _videoPath!,
      );

      // Check extracted audio file size (Groq Whisper limit is 25MB)
      final audioFile = File(extractedAudioPath);
      final audioSize = await audioFile.length();
      if (audioSize > AIService.maxAudioSizeBytes) {
        // Cleanup temp file
        await _videoProcessor.deleteExtractedAudio(extractedAudioPath);
        if (mounted) {
          _showLimitError(
            'Audio Too Large',
            'The extracted audio is larger than 25MB. AI processing currently supports up to 25MB per file.',
          );
        }
        return;
      }

      // 2. Send to AI for transcription
      // We pass noteId_video so the provider knows it's for the video field
      await ref
          .read(videoTranscriptionProvider.notifier)
          .transcribe(extractedAudioPath, noteId: "${_noteId}_video");

      // 3. Cleanup temp audio file
      await _videoProcessor.deleteExtractedAudio(extractedAudioPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transcription failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtractingAudio = false);
    }
  }

  /// **Step 3: Direct Summarization (One-Tap)**
  Future<void> _summarizeVideo() async {
    if (_videoPath == null) return;

    // Show the video summary panel
    setState(() => _showVideoSummary = true);

    // If we don't have a transcription yet, we MUST transcribe first
    if (_videoTranscription == null) {
      await _transcribeVideo();
    }

    // Now generate the summary using the transcription
    final currentTranscription = _videoTranscription;
    if (currentTranscription != null && _noteId != null) {
      ref
          .read(videoSummarizationProvider.notifier)
          .summarize(
            title: "Video Attachment", // Specific title to isolate context
            content: currentTranscription,
            noteId: "${_noteId}_video_summary",
          );
    }
  }

  void _removeImage() {
    setState(() => _imagePath = null);
    _autoSave();
  }

  void _removeAudio() {
    _audioPlayer.stop();
    setState(() {
      _audioPath = null;
      _transcription = null;
      _audioSummary = null;
      _showTranscriptionUI = false;
      _showAudioSummary = false;
      _isPlaying = false;
    });

    // Reset AI providers for audio
    ref.read(transcriptionProvider.notifier).reset();
    ref.read(audioSummarizationProvider.notifier).reset();

    _autoSave();
  }

  // ===========================================================================
  // VIDEO PLAYER LIFECYCLE
  // ===========================================================================
  /// Initializes the video player with the given file path.
  void _initVideoPlayer(String path) {
    if (_videoController != null) {
      _videoController!.dispose();
    }

    _videoController = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized.
        if (mounted) setState(() {});
      });
  }

  bool _isDisposed = false;
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save a reference to the ScaffoldMessengerState before the widget is disposed
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Hide any active snackbars to prevent them from "following" us to other screens
    _scaffoldMessenger?.hideCurrentSnackBar();

    _debounce?.cancel();
    titleController.removeListener(_onChanged);
    contentController.removeListener(_onChanged);
    titleController.dispose();
    contentController.dispose();
    _audioPlayer.dispose();
    _videoController?.dispose(); // Clean up the video memory
    _mediaService.dispose();
    super.dispose();
  }

  // Save button pressed
  Future<void> _saveAndExit() async {
    _debounce?.cancel();
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (_noteId != null) {
      await NoteRepository.updateNote(
        _noteId!,
        title,
        content,
        colorValue: _selectedColor,
        reminder: _reminderTime,
        imagePath: _imagePath,
        audioPath: _audioPath,
        aiSummary: _aiSummary,
        transcription: _transcription,
        audioSummary: _audioSummary,
        videoPath: _videoPath,
        videoTranscription: _videoTranscription,
        videoSummary: _videoSummary,
      );
      _manageNotification(_noteId!, title, content);
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    // if nothing typed, just close
    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // create a new note and exit
    final id = _uuid.v4();
    final now = DateTime.now();

    final note = Note(
      id: id,
      title: title,
      content: content,
      colorValue: _selectedColor,
      createdAt: now,
      updatedAt: now,
      isPinned: false,
      reminder: _reminderTime,
      imagePath: _imagePath,
      audioPath: _audioPath,
      aiSummary: _aiSummary,
      transcription: _transcription,
      audioSummary: _audioSummary,
      videoPath: _videoPath,
      videoTranscription: _videoTranscription,
      videoSummary: _videoSummary,
    );

    await NoteRepository.addNote(note: note);
    _manageNotification(id, title, content);
    if (!mounted) return;
    Navigator.pop(context);
  }

  // change color for existing note immediately
  Future<void> _onPickColor(int colorValue) async {
    setState(() => _selectedColor = colorValue);
    if (_noteId != null) {
      await NoteRepository.changeColor(_noteId!, colorValue);
      setState(() {});
    }
  }

  // Reminder Logic
  Future<void> _handleReminderClick() async {
    // Only show options if reminder is set AND in the future
    final isActive =
        _reminderTime != null && _reminderTime!.isAfter(DateTime.now());

    if (isActive) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reminder'),
          content: Text('Reminder set for: ${_formatDate(_reminderTime!)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel_reminder'),
              child: const Text(
                'Remove Reminder',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'edit'),
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );

      if (action == 'cancel_reminder') {
        setState(() => _reminderTime = null);
        if (_noteId != null) {
          // Cancel effective immediately
          await NotificationService().cancelReminder(_noteId.hashCode);
          // And update note
          await NoteRepository.updateNote(
            _noteId!,
            titleController.text.trim(),
            contentController.text.trim(),
            colorValue: _selectedColor,
            reminder: null,
            imagePath: _imagePath,
            audioPath: _audioPath,
            aiSummary: _aiSummary,
            transcription: _transcription,
            audioSummary: _audioSummary,
          );
          if (!mounted) return;
        }
      } else if (action == 'edit') {
        _pickReminder();
      }
    } else {
      // If null or expired, treat as fresh start
      _pickReminder();
    }
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 1))),
    );
    if (time == null || !mounted) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (dateTime.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot set reminder in the past')),
        );
      }
      return;
    }

    setState(() => _reminderTime = dateTime);

    // Trigger autosave/schedule immediately
    _autoSave();
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _manageNotification(String id, String title, String content) {
    final service = NotificationService();
    final noteIdHash = NotificationService.generateId(id);

    // Only schedule if reminder is set and in the future
    // Cancellation is handled explicitly in _handleReminderClick when user removes a reminder
    if (_reminderTime != null && _reminderTime!.isAfter(DateTime.now())) {
      service.scheduleReminder(
        id: noteIdHash,
        title: title.isEmpty ? 'Untitled Note' : title,
        body: content.isEmpty ? 'Reminder for your note' : content,
        scheduledTime: _reminderTime!,
        payload: id, // Pass Note ID for navigation
      );
    }
    // No else block needed:
    // - Expired notifications have already fired (system handles cleanup)
    // - Null reminders don't need cancellation (nothing was scheduled)
    // - Explicit removal is handled in _handleReminderClick (line 225)
  }

  // ===========================================================================
  // ERROR DIALOG HELPERS
  // ===========================================================================

  /// Shows a clean, modern dialog explaining why a file was rejected due to size.
  void _showLimitError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- SAFE AI LISTENERS ---
    // These listeners are tied to the widget lifecycle.
    // They will NOT leak when you navigate away!

    // 1. Listen for Transcription Results
    ref.listen(transcriptionProvider, (previous, next) {
      if (next is TranscriptionSuccess) {
        // --- ID CHECK ---
        // Only accept the result if it's meant for THIS specific note ID
        if (next.noteId == _noteId) {
          if (mounted) setState(() => _transcription = next.text);
        }
      }
    });

    // 2. Listen for Note Content Summary
    ref.listen(summarizationProvider, (previous, next) {
      if (next is SummarizationSuccess) {
        // Only accept the result if it's meant for THIS specific note ID
        if (next.noteId == _noteId) {
          if (mounted) setState(() => _aiSummary = next.summary);
        }
      }
    });

    // 3. Listen for Audio Transcription Summary
    ref.listen(audioSummarizationProvider, (previous, next) {
      if (next is SummarizationSuccess) {
        // Only accept the result if it matches our unique audio ID pattern: "noteId_audio"
        if (next.noteId == "${_noteId}_audio") {
          if (mounted) {
            setState(() {
              _audioSummary = next.summary;
              _showAudioSummary = true; // Auto-show when summary arrives
            });
          }
        }
      }
    });

    // 4. Listen for Video Transcription Results
    ref.listen(videoTranscriptionProvider, (previous, next) {
      if (next is TranscriptionSuccess) {
        // --- ID CHECK ---
        // Only accept the result if it matches our unique video ID pattern: "noteId_video"
        if (next.noteId == "${_noteId}_video") {
          if (mounted) {
            setState(() {
              _videoTranscription = next.text;
              _showVideoTranscriptionUI = true;
            });
          }
        }
      } else if (next is TranscriptionError || next is TranscriptionSuccess) {
        // Reset loading flag if it finishes or fails
        if (mounted) setState(() => _isExtractingAudio = false);
      }
    });

    // 5. Listen for Video Content Summary
    ref.listen(videoSummarizationProvider, (previous, next) {
      if (next is SummarizationSuccess) {
        // Only accept the result if it matches our unique video summary ID pattern: "noteId_video_summary"
        if (next.noteId == "${_noteId}_video_summary") {
          if (mounted) {
            setState(() {
              _videoSummary = next.summary;
              _showVideoSummary = true; // Auto-show when summary arrives
            });
          }
        }
      }
    });

    // Listen for grammar check results and update the controller
    ref.listen(grammarCheckProvider, (previous, next) {
      next.whenOrNull(
        success: (issues) {
          // Update the controller so it can draw red underlines
          contentController.updateIssues(issues);
        },
      );
    });

    final isEditing = _noteId != null;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? const Color(0xFFE0E0E0) : Colors.black;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow keyboard to push content up
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'New Note'),
        actions: [
          // Plus Button for adding media
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Media',
            onSelected: (value) {
              if (value == 'camera') _pickImage(ImageSource.camera);
              if (value == 'gallery') _handleGalleryPick();
              if (value == 'record') _recordVoice();
              if (value == 'file') _pickAudioFile();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'camera',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt),
                    SizedBox(width: 8),
                    Text('Camera'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'gallery',
                child: Row(
                  children: [
                    Icon(Icons.photo_library),
                    SizedBox(width: 8),
                    Text('Gallery'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'record',
                child: Row(
                  children: [
                    Icon(Icons.mic),
                    SizedBox(width: 8),
                    Text('Record Voice'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'file',
                child: Row(
                  children: [
                    Icon(Icons.audio_file),
                    SizedBox(width: 8),
                    Text('Pick Audio File'),
                  ],
                ),
              ),
            ],
          ),
          // AI Summarize button - Shows sparkle icon
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _summarizeNote,
            tooltip: 'AI Summarize',
          ),
          IconButton(
            icon: Builder(
              builder: (context) {
                final isActive =
                    _reminderTime != null &&
                    _reminderTime!.isAfter(DateTime.now());
                return Icon(
                  isActive
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: isActive ? Colors.blue : null,
                );
              },
            ),
            onPressed: _handleReminderClick,
            tooltip: 'Set Reminder',
          ),
          TextButton(
            onPressed: _saveAndExit,
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Text fields area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  ),

                  // ============= SMART TAGS SECTION =============
                  // Shows AI-suggested tags as chips
                  _buildSmartTagsSection(isDarkMode),

                  // ============= MEDIA SECTION =============
                  // Shows attached image and audio player
                  _buildMediaSection(isDarkMode),

                  // ============= TRANSCRIPTION SECTION =============
                  // Shows transcription result
                  _buildTranscriptionSection(isDarkMode),

                  // ============= VIDEO TRANSCRIPTION SECTION =============
                  if (_showVideoTranscriptionUI)
                    _buildVideoTranscriptionSection(isDarkMode),

                  // ============= AI SUMMARY SECTION =============
                  // Shows a short summary of YOUR note content
                  if (_showSummary) _buildSummarySection(isDarkMode),

                  // ============= AUDIO SUMMARY SECTION =============
                  // Shows a short summary of what was SAID in the audio
                  // This is the ONLY place this appears (the duplicate below has been removed!)
                  if (_showAudioSummary) _buildAudioSummarySection(isDarkMode),

                  // ============= VIDEO SUMMARY SECTION =============
                  if (_showVideoSummary) _buildVideoSummarySection(isDarkMode),

                  TextField(
                    controller: contentController,
                    style: TextStyle(fontSize: 16, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Start typing...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                ],
              ),
            ),
          ),

          // Color palette at bottom (above keyboard when it appears)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, i) {
                      final color = _palette[i];
                      final selected = color == _selectedColor;
                      return GestureDetector(
                        onTap: () => _onPickColor(color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: selected ? 60 : 52,
                          height: selected ? 60 : 52,
                          decoration: BoxDecoration(
                            color: Color(color),
                            borderRadius: BorderRadius.circular(10),
                            border: selected
                                ? Border.all(width: 3, color: Colors.blue)
                                : Border.all(
                                    width: 1,
                                    color: Colors.grey.shade300,
                                  ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(width: 4),
                    itemCount: _palette.length,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // AI FEATURE UI BUILDERS
  // ==========================================================================

  /// Builds the Smart Tags section showing AI-suggested tags as chips
  ///
  /// **States handled:**
  /// - Initial: Shows nothing (user hasn't typed enough)
  /// - Loading: Shows small loading indicator
  /// - Success: Shows tag chips that user can tap
  /// - Error: Shows nothing (fail silently for tags)
  Widget _buildSmartTagsSection(bool isDarkMode) {
    final tagState = ref.watch(tagSuggestionProvider);

    return tagState.when(
      initial: () => const SizedBox.shrink(),
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Suggesting tags...',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      success: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✨ Suggested Tags',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags
                    .map(
                      (tag) => ActionChip(
                        label: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        backgroundColor: isDarkMode
                            ? Colors.blueGrey[700]
                            : Colors.blue[50],
                        side: BorderSide(
                          color: isDarkMode
                              ? Colors.blueGrey[500]!
                              : Colors.blue[200]!,
                        ),
                        onPressed: () {
                          // TODO: Add tag to note (you can implement tag storage later)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tag "$tag" selected!'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
      error: (message) => const SizedBox.shrink(), // Fail silently
    );
  }

  /// Builds the AI Summary section showing generated summary
  ///
  /// **States handled:**
  /// - Initial: Shows empty (shouldn't happen when _showSummary is true)
  /// - Loading: Shows loading card with spinner
  /// - Success: Shows summary in a nice card
  /// - Error: Shows error message with retry button
  Widget _buildSummarySection(bool isDarkMode) {
    final summaryState = ref.watch(summarizationProvider);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.indigo.withValues(alpha: 0.2)
            : Colors.indigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.indigo[400]! : Colors.indigo[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: isDarkMode ? Colors.indigo[300] : Colors.indigo[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI Summary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? Colors.indigo[300]
                          : Colors.indigo[700],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                onPressed: () => setState(() => _showSummary = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Content area based on state
          summaryState.when(
            initial: () => Text(
              'Click the ✨ button to generate a summary',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            loading: () => Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDarkMode ? Colors.indigo[300] : Colors.indigo[600],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Generating summary...',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
            success: (summary, noteIdInState) {
              // --- ID CHECK ---
              // If the summary belongs to a DIFFERENT note, we hide it!
              if (noteIdInState != _noteId) {
                return Text(
                  'Click the ✨ button to generate a summary',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                );
              }

              return Text(
                summary,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
                ),
              );
            },
            error: (message) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error: $message',
                  style: TextStyle(color: Colors.red[400], fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _summarizeNote,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // MEDIA UI BUILDERS
  // ==========================================================================

  Widget _buildMediaSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_imagePath != null) _buildImagePreview(isDarkMode),
        if (_videoPath != null) _buildVideoPlayer(isDarkMode),
        if (_audioPath != null) _buildAudioPlayer(isDarkMode),
        if (_isRecording) _buildRecordingIndicator(isDarkMode),
      ],
    );
  }

  // ===========================================================================
  // VIDEO PLAYER WIDGET
  // ===========================================================================
  /// Builds a full in-note video player with controls.
  Widget _buildVideoPlayer(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // The Video Itself
          if (_videoController != null && _videoController!.value.isInitialized)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_videoController!),
                    // Play/Pause Overlay Button
                    Center(
                      child: IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: () {
                          setState(() {
                            _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                          });
                        },
                      ),
                    ),
                    // Progress Bar
                    VideoProgressIndicator(
                      _videoController!,
                      allowScrubbing: true,
                      padding: const EdgeInsets.only(top: 2),
                      colors: VideoProgressColors(
                        playedColor: Colors.purple,
                        bufferedColor: Colors.grey[700]!,
                        backgroundColor: Colors.grey[900]!,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: Colors.purple),
              ),
            ),

          // Bottom Bar with Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.video_file, size: 20, color: Colors.purple[400]),
                    const SizedBox(width: 8),
                    Text(
                      'Video Attached',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // AI Transcribe for Video
                    IconButton(
                      icon: const Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: Colors.purple,
                      ),
                      tooltip: 'Transcribe Video',
                      onPressed: _transcribeVideo,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    // AI Summarize for Video
                    IconButton(
                      icon: const Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: Colors.purple,
                      ),
                      tooltip: 'Video Summary',
                      onPressed: _summarizeVideo,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    // Remove Video
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: _removeVideo,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _removeVideo() {
    setState(() {
      _videoPath = null;
      _videoTranscription = null;
      _videoSummary = null;
      _showVideoTranscriptionUI = false;
      _showVideoSummary = false;
      _videoController?.dispose();
      _videoController = null;
    });

    // Reset AI providers for video so they don't show old data if we add a new video
    ref.read(videoTranscriptionProvider.notifier).reset();
    ref.read(videoSummarizationProvider.notifier).reset();

    _autoSave();
  }

  // ===========================================================================
  // VIDEO AI UI BUILDERS
  // ===========================================================================

  /// Builds the Video Transcription section.
  Widget _buildVideoTranscriptionSection(bool isDarkMode) {
    if (!_showVideoTranscriptionUI) return const SizedBox.shrink();

    final state = ref.watch(videoTranscriptionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Extraction Overlay (Loading)
        if (_isExtractingAudio)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Extracting audio from video...',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

        state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Transcribing video...',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          success: (text, noteIdInState) {
            // --- ID CHECK ---
            if (noteIdInState != "${_noteId}_video")
              return const SizedBox.shrink();

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.purple.withValues(alpha: 0.1)
                    : Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📝 Video Transcription',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.purple[300]
                              : Colors.purple[800],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () =>
                            setState(() => _showVideoTranscriptionUI = false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            );
          },
          error: (message) => Text(
            'Error: $message',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  /// Builds the Video Summary section.
  Widget _buildVideoSummarySection(bool isDarkMode) {
    if (!_showVideoSummary) return const SizedBox.shrink();

    final state = ref.watch(videoSummarizationProvider);

    return state.when(
      initial: () => const SizedBox.shrink(),
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Summarizing video content...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      success: (summary, noteIdInState) {
        // --- ID CHECK ---
        if (noteIdInState != "${_noteId}_video_summary")
          return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.purple.withValues(alpha: 0.2)
                : Colors.purple[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '✨ Video AI Summary',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? Colors.purple[300]
                          : Colors.purple[900],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _showVideoSummary = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDarkMode ? Colors.grey[200] : Colors.grey[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      error: (message) =>
          Text('Error: $message', style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildImagePreview(bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        // Open full screen image when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(imagePath: _imagePath!),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Hero(
                tag: 'note_image_${_noteId ?? "new"}',
                child: Image.file(
                  File(_imagePath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _removeImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(bool isDarkMode) {
    final textColor = isDarkMode ? Colors.white70 : Colors.black87;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                iconSize: 36,
                color: Colors.blue,
                onPressed: () async {
                  if (_isPlaying) {
                    await _audioPlayer.pause();
                  } else {
                    await _audioPlayer.play(DeviceFileSource(_audioPath!));
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(fontSize: 12, color: textColor),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(fontSize: 12, color: textColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.blue),
                onSelected: (value) {
                  if (value == 'transcribe') {
                    _transcribeAudio();
                  } else if (value == 'summarize') {
                    _summarizeAudio();
                  } else if (value == 'delete') {
                    _removeAudio();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'transcribe',
                    child: ListTile(
                      leading: Icon(Icons.text_fields),
                      title: Text('Transcribe'),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        // When user manually taps "Transcribe",
                        // we make the box visible and run the service.
                        setState(() => _showTranscriptionUI = true);
                        Navigator.pop(context); // Close the menu
                        _transcribeAudio();
                      },
                    ),
                  ),
                  PopupMenuItem(
                    value: 'summarize',
                    child: ListTile(
                      leading: Icon(Icons.summarize_outlined),
                      title: Text('Summarize'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.red),
          const SizedBox(width: 8),
          const Text(
            'Recording...',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _recordVoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('STOP'),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionSection(bool isDarkMode) {
    // We only build this section IF the user explicitly wanted to see it
    if (!_showTranscriptionUI) return const SizedBox.shrink();

    final state = ref.watch(transcriptionProvider);

    return state.when(
      initial: () => const SizedBox.shrink(),
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Transcribing audio...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      success: (text, noteIdInState) {
        // --- ID CHECK ---
        // We only show the text if the ID matches the current note.
        if (noteIdInState != _noteId) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.text_fields, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'Transcription',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      // Close the box and reset the AI state
                      setState(() => _showTranscriptionUI = false);
                      ref.read(transcriptionProvider.notifier).reset();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(text),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  contentController.text += '\n\nTranscription:\n$text';
                  ref.read(transcriptionProvider.notifier).reset();
                },
                child: const Text('Append to Note'),
              ),
            ],
          ),
        );
      },
      error: (msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Transcription error: $msg',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// **Summarize Audio**
  /// USES THE TRANSCRIPTION TO GENERATE A SUMMARY.
  /// IF THE AUDIO HASN'T BEEN TRANSCRIBED YET, IT RUNS THE TRANSCRIPTION FIRST AUTOMATICALLY!
  Future<void> _summarizeAudio() async {
    // 1. First, we check if we have a saved ID for this note.
    // We need the ID so we can save the transcription and summary results permanently.
    if (_noteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save the note first before summarizing.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 2. We check if we already have a transcription (the "script") ready to summarize.
    final transcriptionState = ref.read(transcriptionProvider);
    String? textToSummarize = _transcription;

    // If the transcription just finished in this session, we grab it from the smart provider
    if (transcriptionState is TranscriptionSuccess) {
      textToSummarize = transcriptionState.text;
    }

    // --- ONE-TAP AUTO-TRANSCRIBE ---
    // 3. If we DON'T have a transcription yet, we don't show an error anymore.
    // Instead, we automatically start the transcription for you! ⚡
    if (textToSummarize == null || textToSummarize.isEmpty) {
      if (_audioPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No audio file found to summarize!')),
        );
        return;
      }

      // --- IMPROVED FEEDBACK ---
      // We open the summary panel and manually tell it to show "Summarizing..."
      // even before the transcription starts. This makes the app feel faster!
      setState(() {
        _showAudioSummary = true;
        // This is the "Stealth" part: we DON'T set _showTranscriptionUI to true.
        // We want the summary to appear, but the raw text box to stay hidden.
      });

      // We explicitly set the Summarization Box to "Loading" state so the spinner appears
      // in the right place immediately.
      ref.read(audioSummarizationProvider.notifier).reset();
      // (The actual 'summarize' call later will handle the loading state properly,
      // but showing the container first is better UX.)

      // We ask the AI to transcribe the audio first.
      // We use 'await' so the app stays here until the transcription is done.
      await ref
          .read(transcriptionProvider.notifier)
          .transcribe(_audioPath!, noteId: _noteId);

      // --- ASYNC SAFETY ---
      // We check if the user is still looking at this screen!
      if (!mounted) return;

      // After it finishes, we check if it was successful.
      final nextState = ref.read(transcriptionProvider);
      if (nextState is TranscriptionSuccess) {
        textToSummarize = nextState.text;
      } else {
        // If the transcription failed (maybe no internet), we stop here.
        // The error message will show up automatically in the transcription box.
        return;
      }
    }

    // --- ASYNC SAFETY ---
    if (!mounted) return;

    // 4. Now that we definitely have the text, we show the summary panel
    // (in case it wasn't opened in step 3) and start the summarization!
    setState(() => _showAudioSummary = true);

    // --- CONTEXT PURITY ---
    // We use a neutral title like "Voice Recording" instead of the note's title.
    // This prevents the AI from "remembering" what was written in the note
    // and instead forces it to stick ONLY to what was said in the audio.
    await ref
        .read(audioSummarizationProvider.notifier)
        .summarize(
          title: "Voice Recording",
          content: textToSummarize,
          noteId:
              "${_noteId}_audio", // We use a special ID so we don't mix up note and audio summaries
          isAudioSummary: true,
        );

    // --- FINAL SAFETY CHECK ---
    if (!mounted) return;
  }

  /// Builds the Audio Transcription Summary section
  ///
  /// **Why separate?**
  /// This specifically summarizes what was SAID in the audio,
  /// keeping it distinct from what was WRITTEN in the note.
  Widget _buildAudioSummarySection(bool isDarkMode) {
    final summaryState = ref.watch(audioSummarizationProvider);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.teal.withValues(alpha: 0.2)
            : Colors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.teal[400]! : Colors.teal[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.summarize,
                    size: 18,
                    color: isDarkMode ? Colors.teal[300] : Colors.teal[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Audio Summary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.teal[300] : Colors.teal[700],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                onPressed: () => setState(() => _showAudioSummary = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          summaryState.when(
            initial: () => Text(
              'Select "Summarize" from audio menu',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            loading: () => Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDarkMode ? Colors.teal[300] : Colors.teal[600],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Summarizing recording...',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
            success: (summary, noteIdInState) {
              // --- ID CHECK ---
              // Each summary has a "mailing address" (noteId).
              // If the address doesn't match this note exactly, we keep the box empty!
              if (noteIdInState != "${_noteId}_audio") {
                return Text(
                  'Select "Summarize" from audio menu',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                );
              }

              return Text(
                summary,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
                ),
              );
            },
            error: (message) => Text(
              'Error: $message',
              style: TextStyle(color: Colors.red[400], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// **Full Screen Image Viewer**
/// Simple widget to view the image in full resolution with pinch-to-zoom.
class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const FullScreenImageViewer({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag:
                'note_image_full', // Hero animation tag needs to match or be consistent
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
        ),
      ),
    );
  }
}
