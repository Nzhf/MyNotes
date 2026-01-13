import 'dart:convert';
import 'package:http/http.dart' as http;

/// =====================================================================
/// GRAMMAR SERVICE - LanguageTool Integration
/// =====================================================================
///
/// This service provides grammar and spelling checking using LanguageTool API.
///
/// **How it works (explained simply!):**
///
/// Imagine a helpful teacher looking over your shoulder while you write.
/// When you make a spelling mistake or grammar error, they gently tap
/// your shoulder and say "Hey, I think you meant 'their' instead of 'there'!"
///
/// That's what this service does! It sends your text to LanguageTool
/// (a free grammar checker) and gets back a list of issues with suggestions.
///
/// **Why LanguageTool?**
/// - Completely FREE - no API key required!
/// - Supports 20+ languages
/// - Checks grammar, spelling, and style
/// - Fast response times
///
/// **API Endpoint:** https://api.languagetool.org/v2/check
///
/// **Best Practices Used:**
/// - Debouncing: We don't check every keystroke, we wait for pauses
/// - Rate Limiting: LanguageTool has limits, we respect them
/// - Caching: Same text = same results (handled by provider)
/// =====================================================================

/// Represents a single grammar issue found in the text
///
/// **Fields explained:**
/// - [message]: What's wrong (e.g., "Possible spelling mistake")
/// - [shortMessage]: Brief version of the issue
/// - [offset]: Where in the text the error starts (character position)
/// - [length]: How many characters the error spans
/// - [replacements]: Suggested corrections
/// - [rule]: What grammar rule was broken
/// - [context]: The surrounding text for context
class GrammarIssue {
  final String message;
  final String? shortMessage;
  final int offset;
  final int length;
  final List<String> replacements;
  final String? ruleId;
  final String? ruleDescription;
  final String context;
  final int contextOffset;

  GrammarIssue({
    required this.message,
    this.shortMessage,
    required this.offset,
    required this.length,
    required this.replacements,
    this.ruleId,
    this.ruleDescription,
    required this.context,
    required this.contextOffset,
  });

  /// Creates a GrammarIssue from LanguageTool API response
  factory GrammarIssue.fromJson(Map<String, dynamic> json) {
    return GrammarIssue(
      message: json['message'] ?? 'Unknown issue',
      shortMessage: json['shortMessage'],
      offset: json['offset'] ?? 0,
      length: json['length'] ?? 0,
      replacements:
          (json['replacements'] as List<dynamic>?)
              ?.map((r) => r['value'] as String)
              .take(5) // Limit to 5 suggestions
              .toList() ??
          [],
      ruleId: json['rule']?['id'],
      ruleDescription: json['rule']?['description'],
      context: json['context']?['text'] ?? '',
      contextOffset: json['context']?['offset'] ?? 0,
    );
  }

  /// Returns the problematic text that was flagged
  String get problematicText {
    if (context.isEmpty || contextOffset < 0) return '';
    final start = contextOffset;
    final end = contextOffset + length;
    if (end <= context.length) {
      return context.substring(start, end);
    }
    return '';
  }

  @override
  String toString() {
    return 'GrammarIssue(message: $message, offset: $offset, replacements: $replacements)';
  }
}

/// Result of a grammar check operation
class GrammarCheckResult {
  final List<GrammarIssue> issues;
  final String checkedText;
  final String language;
  final DateTime timestamp;

  GrammarCheckResult({
    required this.issues,
    required this.checkedText,
    required this.language,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Returns true if no grammar issues were found
  bool get isClean => issues.isEmpty;

  /// Returns the number of issues found
  int get issueCount => issues.length;

  /// Create an empty result (no issues)
  factory GrammarCheckResult.empty(String text) {
    return GrammarCheckResult(issues: [], checkedText: text, language: 'en-US');
  }
}

/// Service class for grammar checking
class GrammarService {
  // LanguageTool API endpoint (free, no API key required!)
  static const String _baseUrl = 'https://api.languagetool.org/v2/check';

  // HTTP client for making requests
  final http.Client _client;

  // Default language for grammar checking
  final String _defaultLanguage;

  /// Constructor with optional HTTP client for testing
  ///
  /// [defaultLanguage] defaults to 'en-US' (American English)
  /// Other options: 'en-GB', 'de-DE', 'fr', 'es', etc.
  GrammarService({http.Client? client, String defaultLanguage = 'en-US'})
    : _client = client ?? http.Client(),
      _defaultLanguage = defaultLanguage;

  /// Checks text for grammar, spelling, and style issues
  ///
  /// **Parameters:**
  /// - [text]: The text to check
  /// - [language]: Optional language override (defaults to 'en-US')
  ///
  /// **Returns:** [GrammarCheckResult] with list of issues
  ///
  /// **Example:**
  /// ```dart
  /// final result = await grammarService.checkGrammar('I has a cat.');
  /// print(result.issues.first.message); // "The verb 'has' doesn't agree..."
  /// print(result.issues.first.replacements); // ['have']
  /// ```
  Future<GrammarCheckResult> checkGrammar(
    String text, {
    String? language,
  }) async {
    // Skip checking for very short text
    if (text.trim().length < 5) {
      return GrammarCheckResult.empty(text);
    }

    try {
      // Build request body
      // LanguageTool expects form data, not JSON
      final response = await _client
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {
              'text': text,
              'language': language ?? _defaultLanguage,
              // Disable certain rules that might be too strict for notes
              'disabledRules': 'WHITESPACE_RULE,COMMA_PARENTHESIS_WHITESPACE',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Grammar check timed out');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse matches (issues) from response
        final matches = data['matches'] as List<dynamic>? ?? [];

        final issues = matches
            .map(
              (match) => GrammarIssue.fromJson(match as Map<String, dynamic>),
            )
            .toList();

        return GrammarCheckResult(
          issues: issues,
          checkedText: text,
          language: data['language']?['name'] ?? language ?? _defaultLanguage,
        );
      } else if (response.statusCode == 429) {
        // Rate limited - LanguageTool has request limits
        throw Exception('Too many requests. Please wait a moment.');
      } else {
        throw Exception('Grammar check failed: ${response.statusCode}');
      }
    } on http.ClientException {
      throw Exception('Network error. Check your internet connection.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Grammar check error: ${e.toString()}');
    }
  }

  /// Checks only for spelling errors (faster, fewer false positives)
  ///
  /// Uses LanguageTool's spelling check category only
  Future<GrammarCheckResult> checkSpelling(String text) async {
    if (text.trim().length < 3) {
      return GrammarCheckResult.empty(text);
    }

    try {
      final response = await _client
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {
              'text': text,
              'language': _defaultLanguage,
              // Only check for typos and spelling
              'enabledCategories': 'TYPOS',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matches = data['matches'] as List<dynamic>? ?? [];

        final issues = matches
            .map(
              (match) => GrammarIssue.fromJson(match as Map<String, dynamic>),
            )
            .toList();

        return GrammarCheckResult(
          issues: issues,
          checkedText: text,
          language: _defaultLanguage,
        );
      } else {
        throw Exception('Spelling check failed');
      }
    } catch (e) {
      throw Exception('Spelling check error: ${e.toString()}');
    }
  }

  /// Clean up resources
  void dispose() {
    _client.close();
  }
}
