import 'package:freezed_annotation/freezed_annotation.dart';

// This tells the code generator to create a file named quote_model.freezed.dart
part 'quote_model.freezed.dart';
// This tells the code generator to create JSON serialization code
part 'quote_model.g.dart';

/// Quote model representing a single inspirational quote
/// Uses Freezed for immutability and JSON serialization
@freezed
class Quote with _$Quote {
  const factory Quote({
    /// Unique identifier from API
    required String id,
    
    /// The actual quote text
    required String content,
    
    /// Author of the quote
    required String author,
    
    /// Array of tags (e.g., "inspirational", "wisdom")
    @Default([]) List<String> tags,
    
    /// Length of the quote in characters
    required int length,
  }) = _Quote;

  /// Factory constructor to create Quote from JSON response
  /// API returns: {"_id": "...", "content": "...", "author": "..."}
  factory Quote.fromJson(Map<String, dynamic> json) => _$QuoteFromJson(json);
}

/// State wrapper for handling different UI states
/// This pattern is called "sealed unions" - only one state can be active
@freezed
class QuoteState with _$QuoteState {
  /// Initial state when no data is loaded yet
  const factory QuoteState.initial() = QuoteStateInitial;
  
  /// Loading state while fetching from API
  /// Shows loading indicator in UI
  const factory QuoteState.loading() = QuoteStateLoading;
  
  /// Success state with quote data
  /// [quote] contains the fetched quote
  const factory QuoteState.success(Quote quote) = QuoteStateSuccess;
  
  /// Error state when API call fails
  /// [message] contains error description for user
  const factory QuoteState.error(String message) = QuoteStateError;
}