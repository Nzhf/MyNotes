import '../models/quote_model.dart';
import '../services/quote_service.dart';

/// Repository pattern: intermediary between UI and data source
/// Handles business logic, caching, and data transformation
/// 
/// Benefits:
/// - UI doesn't know where data comes from (API, cache, database)
/// - Easy to add caching later
/// - Easy to switch between different APIs
/// - Business logic separate from API calls
class QuoteRepository {
  final QuoteService _quoteService;
  
  // Cache the last fetched quote to avoid unnecessary API calls
  Quote? _cachedQuote;
  
  // Track when the quote was last fetched
  DateTime? _lastFetchTime;
  
  // Cache duration: quotes older than this will be refreshed
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Constructor with dependency injection
  /// Allows passing mock service for testing
  QuoteRepository({QuoteService? quoteService})
      : _quoteService = quoteService ?? QuoteService();

  /// Fetches a random quote with smart caching
  /// 
  /// Caching logic:
  /// 1. If we have a cached quote AND it's less than 1 hour old, return cache
  /// 2. Otherwise, fetch fresh quote from API
  /// 
  /// Why cache?
  /// - Reduces API calls (some APIs have rate limits)
  /// - Faster response for users
  /// - Works offline (if cache exists)
  /// - Saves user's mobile data
  Future<Quote> getRandomQuote({bool forceRefresh = false}) async {
    try {
      // Check if we should use cached quote
      if (!forceRefresh && _shouldUseCachedQuote()) {
        return _cachedQuote!;
      }

      // Fetch fresh quote from API
      final quote = await _quoteService.getRandomQuote();
      
      // Update cache
      _cachedQuote = quote;
      _lastFetchTime = DateTime.now();
      
      return quote;
    } catch (e) {
      // If API fails but we have cached quote, return it as fallback
      if (_cachedQuote != null) {
        return _cachedQuote!;
      }
      
      // No cache available, rethrow error to be handled by provider
      rethrow;
    }
  }

  /// Get quote of the day
  /// This is a special quote that changes daily
  Future<Quote> getQuoteOfTheDay() async {
    return await _quoteService.getQuoteOfTheDay();
  }

  /// Helper method to determine if cached quote is still valid
  /// 
  /// Returns true if:
  /// - We have a cached quote AND
  /// - Last fetch time exists AND
  /// - Cache hasn't expired (< 1 hour old)
  bool _shouldUseCachedQuote() {
    if (_cachedQuote == null || _lastFetchTime == null) {
      return false;
    }

    final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
    return timeSinceLastFetch < _cacheDuration;
  }

  /// Clear the cache
  /// Useful when user explicitly wants fresh data
  void clearCache() {
    _cachedQuote = null;
    _lastFetchTime = null;
  }

  /// Get the currently cached quote if available
  /// Returns null if no quote is cached
  Quote? getCachedQuote() {
    return _cachedQuote;
  }

  /// Check if cache is available
  bool hasCachedQuote() {
    return _cachedQuote != null;
  }

  /// Dispose resources when repository is no longer needed
  void dispose() {
    _quoteService.dispose();
  }
}