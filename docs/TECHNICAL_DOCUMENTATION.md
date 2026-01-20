# MyNotes - Technical Documentation (Senior Engineer Edition) 🏗️

This document provides a technical overview of the architecture, state management, and implementation patterns used in the MyNotes project.

## 1. Architecture Overview
The project follows a **Modified Layered Architecture** with a heavy emphasis on **Reactive Programming** via Riverpod.

- **UI Layer**: Flutter Widgets (mostly `ConsumerStatefulWidget`).
- **State Management Layer**: Riverpod Notifiers (using a "Smart Provider" pattern).
- **Service Layer**: Discrete services for specific tasks (AI, Media, Notifications).
- **Repository Layer**: The bridge between the app and data sources (Hive, Firestore).
- **Data Layer**: Hive for local-first persistence and Firebase for cloud synchronization.

## 2. Core Technologies
- **Flutter & Dart**: Primary framework and language.
- **Riverpod**: Used for dependency injection and state management.
- **Hive**: A lightweight NoSQL database for local persistence.
- **Firebase (Firestore)**: Used for cross-device cloud sync.
    - **Cerebras API**: Note and video summarization/tag suggestion (LLM).
    - **Groq Whisper API**: High-speed audio and video transcription.
- **FFmpeg**: Used for extracting high-quality audio from video files for transcription.

## 3. Implementation Patterns

### 3.1. Manual Sealed Classes for State
To ensure type safety and avoid the overhead of code generation (like Freezed), we use manually defined sealed classes for AI states:
```dart
sealed class SummarizationState {
  const SummarizationState();
}
class SummarizationInitial extends SummarizationState { const SummarizationInitial(); }
class SummarizationLoading extends SummarizationState { const SummarizationLoading(); }
class SummarizationSuccess extends SummarizationState { 
  final String summary;
  final String noteId;
  SummarizationSuccess(this.summary, {required this.noteId});
}
class SummarizationError extends SummarizationState { 
  final String message;
  SummarizationError(this.message);
}
```

### 3.2. Proactive Persistence
Summarization and transcription results are persisted immediately upon success. The `SummarizationNotifier` handles its own side effects:
- On success: Check if note exists in `NoteRepository`.
- If yes: Update note with new property (`aiSummary` or `audioSummary`).
- Trigger repository update (Hive + Firebase sync).

### 3.3. ID-Based State Isolation
To prevent data leakage across screens, every AI request is tagged with a `noteId`. 
- **The State Layer**: `SummarizationState` and `TranscriptionState` now include a `noteId` field in their `Success` variants.
- **The UI Layer**: UI builders (`_buildSummarySection`, etc.) perform a strict equality check: `if (noteIdInState != _noteId) return Placeholder()`. This ensures that even if a global provider holds stale data from a previous note, the current screen will ignore it.

### 3.4. State Re-hydration & Global Reset
Since Riverpod providers are global singletons, they persist state across navigation. We handle this with a "Double-Lock" strategy:
1.  **Strict Reset**: In `initState`, we trigger `notifier.reset()` for all AI providers. This ensures a "Clean Slate" when entering a new note.
2.  **Explicit Re-hydration**: For existing notes, we use the `setLoadedResult(data, id)` pattern. This manually "seeds" the provider with saved data from the database, ensuring the UI "paints" the saved summaries immediately upon entry without re-triggering the AI.

### 3.5. Separation of Concerns (Daily Quote Feature)
The Daily Quote feature demonstrates strict separation of concerns:
- **QuoteService**: Handles the API call (fetching from `zenquotes.io`) and caching logic.
- **QuoteProvider**: A simple `StateNotifier` that manages the `AsyncValue` state of the quote.
- **QuoteModel**: A plain Dart object (POJO) representing the data.
- **DailyQuoteCard**: A self-contained UI widget that consumes the provider. It is responsible for its own loading interactions and "Save as Note" logic, keeping the parent `NotesScreen` clean.

## 4. AI Integration Roadmap (Deep Dive)

The AI capability is delivered through a three-tier architecture:

### Tier 1: The Service Layer (`AIService.dart`)
This is a singleton-pattern service that manages raw communication with external LLM providers.
- **Provider Orchestration**: 
    - **Groq (Whisper-large-v3)**: Used for high-speed transcription (60x real-time).
    - **Cerebras (Llama-3.1-70b)**: Used for analytical tasks like summarization and tag extraction.
- **Multimedia Processing (`VideoProcessorService.dart`)**: 
    - Utilizes `ffmpeg_kit_flutter_new_audio` to extract AAC audio fragments from video containers.
    - Implemented a "One-Way Extraction" pattern: extract -> transcribe -> delete temp file.
- **Request Lifecycle**: 
    1.  `initialize()`: Fetches API keys from `flutter_dotenv`.
    2.  `POST` request: Formatted as `multipart/form-data` for audio or `application/json` for text.
    3.  Schema Validation: Responses are parsed and validated against expected JSON schemas before being returned to the provider.

### Tier 2: The Logic Layer (`ai_provider.dart`)
We use `StateNotifier` to bridge the gap between raw API results and the Flutter UI.
- **Differential State Management**: 
    - We don't just return a `String`. We return a `SummarizationState` object.
    - This allows the UI to reactively switch between `CircularProgressIndicator` (loading) and the `Text` widget (success) WITHOUT checking string empty statuses.
- **Proactive Persistence**:
    - Providers are "Repo-Aware." When `TranscriptionSuccess` is emitted, the notifier automatically triggers `NoteRepository.updateNote()`. 
    - This ensures transactional integrity—the state and the database are always in sync.
- **State Re-hydration (`setLoadedResult`)**:
    - To bridge the gap between "Local State" and "Database Persistence," we implemented `setLoadedResult`. 
    - This method allows the UI to manually inject a `Success` state into the provider if data is found in Hive/Firestore during `initState`, effectively pinning the result to the current session's `noteId`.

### Tier 3: The Interaction Layer (`NewNoteScreen.dart`)
AI features are orchestrated as "Asynchronous Commands."
- **The Chained Flow (`_summarizeAudio`)**:
    - **Guard**: Check if `textToSummarize` is null.
    - **Dispatch 1**: Call `transcriptionProvider.notifier.transcribe()`.
    - **Await**: Wait for completion using `await`.
    - **Guard**: Check `mounted` to prevent `setState` on unmounted widgets.
    - **Dispatch 2**: Call `audioSummarizationProvider.notifier.summarize()`.

## 5. Security & Environment
- **Dotenv**: All API keys are strictly stored in a `.env` file, excluded from git via `.gitignore`.
- **API Initialization**: Keys are only injected at runtime via `AIService`, preventing environment variable leakage in static build artifacts.

## 6. Persistence Strategy
3. On app start: Fetch from Firestore and merge into local Hive store.

## 7. Media Constraints & Size Validation
To ensure stability and prevent API timeouts/errors:
- **Audio Limit**: 25MB (Groq API constraint).
- **Video Limit**: 500MB (Resource preservation on mobile).
- **Consolidated Gallery**: Selection uses `ImagePicker().pickMedia()` with downstream type-detection and validation logic to provide a unified user experience.

---
*Documentation generated by Antigravity AI.*
