import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quote_model.dart';

/// Service class responsible for fetching quotes from external API
/// Handles all HTTP communication with ZenQuotes API
class QuoteService {
  // Base URL for the ZenQuotes API (free, no API key required)
  static const String _baseUrl = 'https://zenquotes.io/api';
  
  // HTTP client for making requests
  // Using dependency injection pattern for easier testing
  final http.Client _client;
  
  /// Constructor with optional client parameter
  /// Allows injecting mock client for testing
  QuoteService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches a random quote from the API
  /// 
  /// API Endpoint: GET https://zenquotes.io/api/random
  /// 
  /// Returns [Quote] object on success
  /// Throws [Exception] on failure with descriptive message
  /// 
  /// Example API Response:
  /// ```json
  /// [
  ///   {
  ///     "q": "Be yourself; everyone else is already taken.",
  ///     "a": "Oscar Wilde",
  ///     "h": "<blockquote>...</blockquote>"
  ///   }
  /// ]
  /// ```
  Future<Quote> getRandomQuote() async {
    try {
      // Make HTTP GET request to the API
      final response = await _client.get(
        Uri.parse('$_baseUrl/random'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10), // Timeout after 10 seconds
        onTimeout: () {
          throw Exception('Request timed out. Please check your connection.');
        },
      );

      // Check if request was successful (status code 200-299)
      if (response.statusCode == 200) {
        // Parse JSON response body - API returns array with one quote
        final List<dynamic> jsonData = json.decode(response.body);
        
        if (jsonData.isEmpty) {
          throw Exception('No quote received from server.');
        }
        
        // Get first quote from array
        final quoteData = jsonData[0];
        
        // ZenQuotes uses different field names:
        // "q" for quote content, "a" for author
        // Convert to our model's format
        final convertedData = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(), // Generate unique ID
          'content': quoteData['q'] ?? 'No quote available',
          'author': quoteData['a'] ?? 'Unknown',
          'tags': <String>[], // ZenQuotes doesn't provide tags
          'length': (quoteData['q'] ?? '').toString().length,
        };
        
        // Convert JSON to Quote object using generated fromJson method
        return Quote.fromJson(convertedData);
      } else if (response.statusCode == 404) {
        // API endpoint not found
        throw Exception('Quote service unavailable. Please try again later.');
      } else if (response.statusCode >= 500) {
        // Server error
        throw Exception('Server error. Please try again later.');
      } else {
        // Other HTTP errors
        throw Exception('Failed to fetch quote. Status: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      // Network-related errors (no internet, DNS failure, etc.)
      throw Exception('Network error: Please check your internet connection.');
    } on FormatException catch (e) {
      // JSON parsing errors
      throw Exception('Invalid data received from server.');
    } catch (e) {
      // Catch any other unexpected errors
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  /// Fetches quote of the day
  /// API Endpoint: GET https://zenquotes.io/api/today
  Future<Quote> getQuoteOfTheDay() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/today'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        if (jsonData.isEmpty) {
          throw Exception('No quote received.');
        }
        
        final quoteData = jsonData[0];
        final convertedData = {
          'id': 'today-${DateTime.now().day}',
          'content': quoteData['q'] ?? 'No quote available',
          'author': quoteData['a'] ?? 'Unknown',
          'tags': <String>[],
          'length': (quoteData['q'] ?? '').toString().length,
        };
        
        return Quote.fromJson(convertedData);
      } else {
        throw Exception('Failed to fetch quote of the day');
      }
    } catch (e) {
      throw Exception('Error fetching quote: ${e.toString()}');
    }
  }

  /// Clean up resources when service is no longer needed
  void dispose() {
    _client.close();
  }
}