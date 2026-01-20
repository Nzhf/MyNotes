import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';

/// =============================================================================
/// VIDEO PROCESSOR SERVICE - Audio Extraction from Video
/// =============================================================================
///
/// **What is this file?**
/// This service handles the "heavy lifting" of extracting audio tracks from
/// video files. We need audio to send it to the AI for transcription.
///
/// **Why do we extract audio first?**
/// The Groq Whisper API (our transcription brain) only understands audio files.
/// So before we can transcribe a video, we must pull out the audio track.
///
/// **How it works (The Audio Extractor):**
/// 1. It takes the video file path as input.
/// 2. It uses FFmpeg (a powerful media tool) to strip out just the audio.
/// 3. It saves the audio as a separate file and returns its path.
/// =============================================================================
class VideoProcessorService {
  // ===========================================================================
  // EXTRACT AUDIO FROM VIDEO
  // ===========================================================================
  /// Takes a video file path and returns the path to the extracted audio file.
  ///
  /// The output format is .m4a (AAC audio) which is compatible with Groq Whisper.
  Future<String> extractAudio(String videoPath) async {
    // --- PREPARE OUTPUT PATH ---
    // We create a unique filename in the app's documents directory.
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String outputFileName =
        'extracted_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final String outputPath = p.join(appDir.path, outputFileName);

    // --- BUILD THE FFMPEG COMMAND ---
    // -i : Input file
    // -vn : No video (discard the video stream)
    // -acodec copy : Copy the audio stream without re-encoding (fast!)
    // -y : Overwrite output file if it exists
    final String command = '-i "$videoPath" -vn -acodec copy -y "$outputPath"';

    // --- EXECUTE FFMPEG ---
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    // --- CHECK FOR SUCCESS ---
    if (ReturnCode.isSuccess(returnCode)) {
      // Verify the output file was actually created
      if (await File(outputPath).exists()) {
        return outputPath;
      } else {
        throw Exception(
          'Audio extraction succeeded but output file not found.',
        );
      }
    } else {
      // --- FALLBACK: TRY RE-ENCODING ---
      // Some video formats can't be "copied" directly. We try re-encoding.
      final String fallbackCommand =
          '-i "$videoPath" -vn -acodec aac -b:a 128k -y "$outputPath"';
      final fallbackSession = await FFmpegKit.execute(fallbackCommand);
      final fallbackReturnCode = await fallbackSession.getReturnCode();

      if (ReturnCode.isSuccess(fallbackReturnCode)) {
        if (await File(outputPath).exists()) {
          return outputPath;
        }
      }

      // If both attempts failed, throw an error
      final logs = await session.getAllLogsAsString();
      throw Exception('Failed to extract audio from video. FFmpeg logs: $logs');
    }
  }

  // ===========================================================================
  // CLEANUP HELPER
  // ===========================================================================
  /// Deletes a temporary extracted audio file to save storage.
  Future<void> deleteExtractedAudio(String audioPath) async {
    final file = File(audioPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
