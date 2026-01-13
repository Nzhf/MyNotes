import 'package:flutter/foundation.dart';

/// =====================================================================
/// AI STATE MODELS
/// =====================================================================
///
/// Refactored to manual sealed classes to avoid code generation issues.
/// This file no longer requires 'build_runner' or 'freezed'.
/// =====================================================================

// =============================================================================
// SUMMARIZATION STATE
// =============================================================================

sealed class SummarizationState {
  const SummarizationState();
  const factory SummarizationState.initial() = SummarizationInitial;
  const factory SummarizationState.loading() = SummarizationLoading;
  const factory SummarizationState.success(String summary, {String? noteId}) =
      SummarizationSuccess;
  const factory SummarizationState.error(String message) = SummarizationError;

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(String summary, String? noteId) success,
    required T Function(String message) error,
  }) {
    final state = this;
    if (state is SummarizationInitial) return initial();
    if (state is SummarizationLoading) return loading();
    if (state is SummarizationSuccess)
      return success(state.summary, state.noteId);
    if (state is SummarizationError) return error(state.message);
    throw Exception('Unknown state: $state');
  }

  T? whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(String summary, String? noteId)? success,
    T Function(String message)? error,
  }) {
    final state = this;
    if (state is SummarizationInitial && initial != null) return initial();
    if (state is SummarizationLoading && loading != null) return loading();
    if (state is SummarizationSuccess && success != null) {
      return success(state.summary, state.noteId);
    }
    if (state is SummarizationError && error != null) {
      return error(state.message);
    }
    return null;
  }

  T? mapOrNull<T>({T Function(SummarizationSuccess state)? success}) {
    if (this is SummarizationSuccess && success != null) {
      return success(this as SummarizationSuccess);
    }
    return null;
  }
}

class SummarizationInitial extends SummarizationState {
  const SummarizationInitial();
}

class SummarizationLoading extends SummarizationState {
  const SummarizationLoading();
}

class SummarizationSuccess extends SummarizationState {
  final String summary;
  final String? noteId;
  const SummarizationSuccess(this.summary, {this.noteId});
}

class SummarizationError extends SummarizationState {
  final String message;
  const SummarizationError(this.message);
}

// =============================================================================
// TAG SUGGESTION STATE
// =============================================================================

sealed class TagSuggestionState {
  const TagSuggestionState();
  const factory TagSuggestionState.initial() = TagSuggestionInitial;
  const factory TagSuggestionState.loading() = TagSuggestionLoading;
  const factory TagSuggestionState.success(List<String> tags) =
      TagSuggestionSuccess;
  const factory TagSuggestionState.error(String message) = TagSuggestionError;

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(List<String> tags) success,
    required T Function(String message) error,
  }) {
    final state = this;
    if (state is TagSuggestionInitial) return initial();
    if (state is TagSuggestionLoading) return loading();
    if (state is TagSuggestionSuccess) return success(state.tags);
    if (state is TagSuggestionError) return error(state.message);
    throw Exception('Unknown state: $state');
  }
}

class TagSuggestionInitial extends TagSuggestionState {
  const TagSuggestionInitial();
}

class TagSuggestionLoading extends TagSuggestionState {
  const TagSuggestionLoading();
}

class TagSuggestionSuccess extends TagSuggestionState {
  final List<String> tags;
  const TagSuggestionSuccess(this.tags);
}

class TagSuggestionError extends TagSuggestionState {
  final String message;
  const TagSuggestionError(this.message);
}

// =============================================================================
// GRAMMAR CHECK STATE
// =============================================================================

sealed class GrammarCheckState {
  const GrammarCheckState();
  const factory GrammarCheckState.initial() = GrammarCheckInitial;
  const factory GrammarCheckState.loading() = GrammarCheckLoading;
  const factory GrammarCheckState.success(List<GrammarIssueData> issues) =
      GrammarCheckSuccess;
  const factory GrammarCheckState.error(String message) = GrammarCheckError;

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(List<GrammarIssueData> issues) success,
    required T Function(String message) error,
  }) {
    final state = this;
    if (state is GrammarCheckInitial) return initial();
    if (state is GrammarCheckLoading) return loading();
    if (state is GrammarCheckSuccess) return success(state.issues);
    if (state is GrammarCheckError) return error(state.message);
    throw Exception('Unknown state: $state');
  }

  T? whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(List<GrammarIssueData> issues)? success,
    T Function(String message)? error,
  }) {
    final state = this;
    if (state is GrammarCheckInitial && initial != null) return initial();
    if (state is GrammarCheckLoading && loading != null) return loading();
    if (state is GrammarCheckSuccess && success != null) {
      return success(state.issues);
    }
    if (state is GrammarCheckError && error != null) {
      return error(state.message);
    }
    return null;
  }
}

class GrammarCheckInitial extends GrammarCheckState {
  const GrammarCheckInitial();
}

class GrammarCheckLoading extends GrammarCheckState {
  const GrammarCheckLoading();
}

class GrammarCheckSuccess extends GrammarCheckState {
  final List<GrammarIssueData> issues;
  const GrammarCheckSuccess(this.issues);
}

class GrammarCheckError extends GrammarCheckState {
  final String message;
  const GrammarCheckError(this.message);
}

// =============================================================================
// TRANSCRIPTION STATE
// =============================================================================

sealed class TranscriptionState {
  const TranscriptionState();
  const factory TranscriptionState.initial() = TranscriptionInitial;
  const factory TranscriptionState.loading() = TranscriptionLoading;
  const factory TranscriptionState.success(String text, {String? noteId}) =
      TranscriptionSuccess;
  const factory TranscriptionState.error(String message) = TranscriptionError;

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(String text, String? noteId) success,
    required T Function(String message) error,
  }) {
    final state = this;
    if (state is TranscriptionInitial) return initial();
    if (state is TranscriptionLoading) return loading();
    if (state is TranscriptionSuccess) return success(state.text, state.noteId);
    if (state is TranscriptionError) return error(state.message);
    throw Exception('Unknown state: $state');
  }

  T? whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(String text, String? noteId)? success,
    T Function(String message)? error,
  }) {
    final state = this;
    if (state is TranscriptionInitial && initial != null) return initial();
    if (state is TranscriptionLoading && loading != null) return loading();
    if (state is TranscriptionSuccess && success != null) {
      return success(state.text, state.noteId);
    }
    if (state is TranscriptionError && error != null) {
      return error(state.message);
    }
    return null;
  }

  T? mapOrNull<T>({T Function(TranscriptionSuccess state)? success}) {
    if (this is TranscriptionSuccess && success != null) {
      return success(this as TranscriptionSuccess);
    }
    return null;
  }
}

class TranscriptionInitial extends TranscriptionState {
  const TranscriptionInitial();
}

class TranscriptionLoading extends TranscriptionState {
  const TranscriptionLoading();
}

class TranscriptionSuccess extends TranscriptionState {
  final String text;
  final String? noteId;
  const TranscriptionSuccess(this.text, {this.noteId});
}

class TranscriptionError extends TranscriptionState {
  final String message;
  const TranscriptionError(this.message);
}

// =============================================================================
// GRAMMAR ISSUE DATA
// =============================================================================

@immutable
class GrammarIssueData {
  final String message;
  final int offset;
  final int length;
  final List<String> suggestions;
  final String problematicText;

  const GrammarIssueData({
    required this.message,
    required this.offset,
    required this.length,
    required this.suggestions,
    required this.problematicText,
  });
}
