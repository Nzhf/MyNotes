import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NoteCard extends StatelessWidget {
  final String title;
  final String content;
  final Color color;
  final DateTime date;
  final String? imagePath;
  final String? audioPath;
  final String? videoPath;
  final VoidCallback? onTap;

  const NoteCard({
    super.key,
    required this.title,
    required this.content,
    required this.color,
    required this.date,
    this.imagePath,
    this.audioPath,
    this.videoPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Format the date for a cleaner look
    final String formattedDate = DateFormat('MMM d, y').format(date);

    return Card(
      elevation: 0, // Flat design for a more premium, modern feel
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Section: Title & Date ---
              Text(
                title.isEmpty ? 'Untitled' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // --- Body Section: Content Preview ---
              Expanded(
                child: Text(
                  content,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 4,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ),

              // --- Footer Section: Media Indicators ---
              if (imagePath != null || audioPath != null || videoPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      if (imagePath != null)
                        _buildIndicator(Icons.image_outlined),
                      if (audioPath != null)
                        _buildIndicator(Icons.mic_none_rounded),
                      if (videoPath != null)
                        _buildIndicator(Icons.videocam_outlined),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 14, color: Colors.black.withOpacity(0.6)),
    );
  }
}
