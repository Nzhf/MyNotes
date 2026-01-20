import 'dart:convert'; // Helps us translate "Computer Language" (JSON) to "App Language" (Dart Objects)
import 'package:http/http.dart'
    as http; // Like a web browser for our code - sends requests to the internet
import 'package:flutter_dotenv/flutter_dotenv.dart'; // keeps our secrets (API Keys) safe

/// =====================================================================
/// AI SERVICE - Cerebras AI Integration (Llama 3.1)
/// =====================================================================
///
/// **What is this file?**
/// This is the "Brain" of our AI features. It talks to Cerebras (the current
/// speed champion of AI) to summarize notes and suggest tags.
///
/// **Why did we switch to Cerebras?**
/// Because they are super generous! They give us 1,000,000 tokens for FREE
/// every single day. That's enough to summarize thousands of notes!
///
/// **How it works (The Restaurant Analogy):**
/// 1. **The Order (Request):** We write down what we want (the note content) on a piece of paper.
/// 2. **The Waiter (HTTP):** This service takes the order to the kitchen (Cerebras' API).
/// 3. **The Kitchen (AI Model):** The Llama 3.1 model cooks up a summary.
/// 4. **The Dish (Response):** The waiter brings back the result, and we serve it to the user.
///
class AIService {
  bool _isInitialized = false;
  String? _apiKey;

  // URL: The address of the "Cerebras Kitchen"
  static const String _baseUrl = 'https://api.cerebras.ai/v1/chat/completions';

  // Model: The specific Chef we want (Llama 3.1 8B is lightning fast)
  static const String _model = 'llama3.1-8b';

  // ===========================================================================
  // FILE SIZE LIMITS (SAFETY GUARDS)
  // ===========================================================================
  // Groq Whisper has a hard limit of 25MB for audio files.
  static const int maxAudioSizeBytes = 25 * 1024 * 1024; // 25 MB

  // We set a 500MB limit for video files to prevent the app from freezing
  // or running out of memory during the audio extraction process.
  static const int maxVideoSizeBytes = 500 * 1024 * 1024; // 500 MB

  /// **Step 1: Get the Keys**
  /// We need to show our Cerebras ID (API Key) to use their service.
  /// This method loads it from your hidden .env file.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await dotenv.load(fileName: '.env');
    _apiKey = dotenv.env['CEREBRAS_API_KEY'];

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception(
        'Cerebras API key not found! Please add CEREBRAS_API_KEY to your .env file.\n'
        'Get a free key at: https://inference.cerebras.ai',
      );
    }

    _isInitialized = true;
  }

  /// **Step 2: Summarize a Note**
  /// Uses AI to turn a long note into a short, 1-3 sentence summary.
  Future<String> summarizeNote({
    required String title,
    required String content,
  }) async {
    if (!_isInitialized) await initialize();

    // If note is too short, we don't need AI to summarize it
    if (content.trim().length < 50) {
      return content.trim();
    }

    try {
      // PROMPT ENGINEERING:
      // We give the AI clear rules so it knows exactly how to summarize.
      final prompt =
          '''
You are a helpful assistant that summarizes notes concisely.
Note Title: $title
Note Content:
$content

Instructions:
- Provide a brief summary in 1-3 sentences.
- Focus on the most important points.
- Keep it under 100 words.
- Don't say "This note is about..." - just start summarizing.
''';

      // Send the request to Cerebras!
      final response = await _makeRequest(prompt);
      return response.trim();
    } catch (e) {
      throw Exception('Failed to summarize: $e');
    }
  }

  /// **Step 3: Suggest Tags**
  /// Reads your note and picks 3-5 labels to help you organize.
  Future<List<String>> suggestTags({
    required String title,
    required String content,
  }) async {
    if (!_isInitialized) await initialize();

    if (content.trim().length < 20) {
      return ['Note', 'Quick'];
    }

    try {
      // Tags are returned in JSON format (a list like ["Work", "Personal"])
      final prompt =
          '''
You are a helpful assistant that suggests tags for notes.
Note Title: $title
Note Content:
$content

Instructions:
- Suggest 3-5 relevant tags.
- Use single words or short phrases.
- Return ONLY a JSON array of strings: ["Tag1", "Tag2"].
- Do not include any extra text or markdown.
''';

      final responseText = await _makeRequest(prompt);

      // We clean up the AI's response to make sure it's valid JSON
      String cleaned = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      try {
        final List<dynamic> parsed = json.decode(cleaned);
        return parsed.map((e) => e.toString()).toList();
      } catch (e) {
        // Fallback: If the AI's format is messy, we try to fix it manually
        return cleaned
            .replaceAll(RegExp(r'[\[\]"{}]'), '')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .take(5)
            .toList();
      }
    } catch (e) {
      return ['Note']; // Default tag if something goes wrong
    }
  }

  /// **Step 4: Transcribe Audio**
  /// Uses Groq's Whisper model to turn audio into text.
  Future<String> transcribeAudio(String path) async {
    if (!_isInitialized) await initialize();

    final groqKey = dotenv.env['GROQ_API_KEY'];
    if (groqKey == null || groqKey.isEmpty) {
      throw Exception(
        'Groq API key not found! Please add GROQ_API_KEY to your .env file.',
      );
    }

    try {
      // 1. Prepare the request
      final uri = Uri.parse(
        'https://api.groq.com/openai/v1/audio/transcriptions',
      );
      final request = http.MultipartRequest('POST', uri);

      // 2. Add headers and fields
      request.headers['Authorization'] = 'Bearer $groqKey';
      request.fields['model'] = 'whisper-large-v3';

      // 3. Add the audio file
      final file = await http.MultipartFile.fromPath('file', path);
      request.files.add(file);

      // 4. Send and wait for answer
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] as String;
      } else {
        throw Exception(
          'Groq Transcription Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to transcribe: $e');
    }
  }

  /// **The Engine Room (_makeRequest)**
  /// This private method handles the actual internet talk with Cerebras.
  Future<String> _makeRequest(String content) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey', // Our secret key
        'Content-Type': 'application/json', // We are sending JSON
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': content},
        ],
        'temperature': 0.7, // Balanced creativity
      }),
    );

    // If the server says "OK" (Status 200)
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // We look deep inside the response to find the AI's actual words
      return data['choices'][0]['message']['content'];
    } else {
      // If there's an error (like an invalid key)
      throw Exception(
        'Cerebras API Error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  void dispose() {
    _isInitialized = false;
  }
}
