import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote_model.dart';
import '../repositories/quote_repository.dart';

/// Provider for QuoteRepository instance
/// This creates a single shared instance of QuoteRepository
/// 
/// Why Provider?
/// - Single instance shared across entire app (singleton pattern)
/// - Automatic disposal when no longer needed
/// - Easy to inject mock repository for testing
final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  // Create repository instance
  final repository = QuoteRepository();
  
  // Clean up when provider is disposed
  // This is called when app closes or provider is no longer used
  ref.onDispose(() {
    repository.dispose();
  });
  
  return repository;
});

/// StateNotifier manages QuoteState and handles business logic
/// Think of it as a "controller" that holds and updates state
/// 
/// Why StateNotifier?
/// - Separates state from UI
/// - Immutable state updates (creates new state, doesn't mutate)
/// - Easy to test business logic
class QuoteNotifier extends StateNotifier<QuoteState> {
  final QuoteRepository _repository;

  /// Constructor initializes with 'initial' state
  /// [_repository] is injected for making API calls
  QuoteNotifier(this._repository) : super(const QuoteState.initial());

  /// Fetches a random quote and updates state accordingly
  /// 
  /// State flow:
  /// 1. Set state to loading (shows loading indicator)
  /// 2. Call repository to get quote
  /// 3a. Success: Set state to success with quote data
  /// 3b. Error: Set state to error with message
  /// 
  /// [forceRefresh] bypasses cache and fetches fresh quote
  Future<void> fetchRandomQuote({bool forceRefresh = false}) async {
    // Update state to loading
    // This triggers UI to show loading indicator
    state = const QuoteState.loading();

    try {
      // Fetch quote from repository (handles caching internally)
      final quote = await _repository.getRandomQuote(
        forceRefresh: forceRefresh,
      );

      // Update state to success with quote data
      // This triggers UI to display the quote
      state = QuoteState.success(quote);
    } catch (e) {
      // Update state to error with user-friendly message
      // This triggers UI to show error message
      state = QuoteState.error(
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Fetches quote of the day
  Future<void> fetchQuoteOfTheDay() async {
    state = const QuoteState.loading();

    try {
      final quote = await _repository.getQuoteOfTheDay();
      state = QuoteState.success(quote);
    } catch (e) {
      state = QuoteState.error(
        'Could not fetch quote of the day. ${e.toString()}',
      );
    }
  }

  /// Refresh quote (force bypass cache)
  /// User clicked refresh button, so we want fresh data
  Future<void> refresh() async {
    await fetchRandomQuote(forceRefresh: true);
  }

  /// Clear cache and reset to initial state
  void clearQuote() {
    _repository.clearCache();
    state = const QuoteState.initial();
  }
}

/// StateNotifierProvider connects QuoteNotifier to the widget tree
/// This is what widgets will use to access quote state and methods
/// 
/// How it works:
/// 1. Creates QuoteNotifier instance
/// 2. Injects QuoteRepository dependency
/// 3. Exposes state and methods to widgets
/// 4. Automatically disposes when not needed
/// 
/// Usage in widgets:
/// ```dart
/// // Read current state
/// final quoteState = ref.watch(quoteProvider);
/// 
/// // Call methods
/// ref.read(quoteProvider.notifier).fetchRandomQuote();
/// ```
final quoteProvider = StateNotifierProvider<QuoteNotifier, QuoteState>((ref) {
  // Get repository instance from provider
  final repository = ref.watch(quoteRepositoryProvider);
  
  // Create and return notifier with injected repository
  return QuoteNotifier(repository);
});