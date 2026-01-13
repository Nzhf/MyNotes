import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// =============================================================================
/// MEDIA SERVICE - Handling Photos and Voice Notes
/// =============================================================================
///
/// **What is this file?**
/// This is the app's "Media Assistant". It knows how to:
/// 1. 📸 Take or pick photos
/// 2. 🎙️ Record your voice
/// 3. 📂 Pick existing audio files from your phone
/// 4. 💾 Save all these files safely in the app's private folder
///
/// **How it works (The Digital Filing Cabinet):**
/// When you pick an image or record a voice note, we don't just "link" to it.
/// We make a copy and put it in our "Digital Filing Cabinet" (App Documents).
/// This way, even if you delete the original photo from your gallery,
/// your note still has its copy!
/// =============================================================================
class MediaService {
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();

  /// **Step 1: Pick an Image**
  /// [source] can be Camera or Gallery
  Future<String?> pickImage(ImageSource source) async {
    // Request permissions first
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) return null;
    }

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80, // Save space by slightly compressing
    );

    if (image == null) return null;

    // Save it to our local "Digital Filing Cabinet"
    return await _saveFileLocally(image.path, 'img');
  }

  /// **Step 2: Start Voice Recording**
  Future<void> startRecording() async {
    // 1. Ask for Microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception('Microphone permission not granted');
    }

    // 2. Prepare the "Tape Recorder"
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = p.join(dir.path, fileName);

    // 3. Start Recording!
    const config = RecordConfig();
    await _recorder.start(config, path: path);
  }

  /// **Step 3: Stop Voice Recording**
  /// Returns the path where the recording was saved
  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    return path;
  }

  /// **Step 4: Pick an Audio File from the device**
  Future<String?> pickAudioFile() async {
    // Open the system file picker
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      // Save it to our local folder so we don't lose access later
      return await _saveFileLocally(result.files.single.path!, 'audio');
    }
    return null;
  }

  /// **Helper: Save file to app's local directory**
  /// This ensures we keep the file even if the user deletes the original
  Future<String> _saveFileLocally(String originalPath, String prefix) async {
    final File originalFile = File(originalPath);
    final Directory appDir = await getApplicationDocumentsDirectory();

    // Create a unique name for the file
    final String extension = p.extension(originalPath);
    final String newName =
        '${prefix}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final String newPath = p.join(appDir.path, newName);

    // Copy the file to our local storage
    await originalFile.copy(newPath);

    return newPath;
  }

  /// Clean up
  void dispose() {
    _recorder.dispose();
  }
}
