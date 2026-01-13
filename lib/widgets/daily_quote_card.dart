import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/quote_provider.dart';
import '../models/quote_model.dart';
import '../data/note_repository.dart';
import '../utils/pastel_colors.dart';
import '../note_model.dart';
import 'package:uuid/uuid.dart';

/// Widget that displays daily inspirational quote
/// Uses Riverpod to manage state and handle API calls
///
/// Features:
/// - Shows quote with author
/// - Refresh button to get new quote
/// - Save quote as note button
/// - Loading and error states
class DailyQuoteCard extends ConsumerStatefulWidget {
  // Add callback function to notify parent when note is saved
  final VoidCallback? onNoteSaved;

  const DailyQuoteCard({super.key, this.onNoteSaved});

  @override
  ConsumerState<DailyQuoteCard> createState() => _DailyQuoteCardState();
}

/// ConsumerState gives us access to 'ref' for Riverpod
class _DailyQuoteCardState extends ConsumerState<DailyQuoteCard> {
  @override
  void initState() {
    super.initState();
    // Fetch quote when widget is first created
    // WidgetsBinding ensures this runs after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quoteProvider.notifier).fetchRandomQuote();
    });
  }

  /// Save current quote as a note in the database
  Future<void> _saveQuoteAsNote(Quote quote) async {
    try {
      final uuid = const Uuid();
      final now = DateTime.now();

      // Create note with quote content
      final note = Note(
        id: uuid.v4(),
        title: 'Quote by ${quote.author}',
        content: '"${quote.content}"\n\n— ${quote.author}',
        colorValue: PastelColors.getRandom()
            .toARGB32(), // Random pastel color from palette
        createdAt: now,
        updatedAt: now,
        isPinned: false,
      );

      // Save to database
      await NoteRepository.addNote(note: note);

      // Show success toast message (above FAB and bottom nav)
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Quote saved as note ✓",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.lightGreen,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // FIXED: Call the callback to notify parent to refresh
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && widget.onNoteSaved != null) {
          widget.onNoteSaved!();
        }
      }
    } catch (e) {
      // Show error toast if save fails
      if (mounted) {
        Fluttertoast.showToast(
          msg: "✗ Failed to save quote: ${e.toString()}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the quote provider - rebuilds when state changes
    final quoteState = ref.watch(quoteProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0xFF2A2A2A), const Color(0xFF3A3A3A)]
                : [const Color(0xFFF5F7FA), const Color(0xFFE8EEF5)],
          ),
        ),
        child: quoteState.when(
          // Initial state: Show prompt to load quote
          initial: () => _buildInitialState(isDarkMode),

          // Loading state: Show loading indicator
          loading: () => _buildLoadingState(),

          // Success state: Show quote content
          success: (quote) => _buildSuccessState(quote, isDarkMode),

          // Error state: Show error message
          error: (message) => _buildErrorState(message, isDarkMode),
        ),
      ),
    );
  }

  /// Build UI for initial state
  Widget _buildInitialState(bool isDarkMode) {
    return Column(
      children: [
        Icon(
          Icons.format_quote,
          size: 48,
          color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
        ),
        const SizedBox(height: 12),
        Text(
          'Get Your Daily Inspiration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildRefreshButton(isDarkMode),
      ],
    );
  }

  /// Build UI for loading state
  Widget _buildLoadingState() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text(
          'Loading inspiration...',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  /// Build UI for success state with quote
  Widget _buildSuccessState(Quote quote, bool isDarkMode) {
    final textColor = isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quote icon and title
        Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber[600], size: 24),
            const SizedBox(width: 8),
            Text(
              'Daily Inspiration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Quote text with quotation marks
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"',
              style: TextStyle(
                fontSize: 32,
                height: 0.8,
                color: Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                quote.content,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Author name
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '— ${quote.author}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Action buttons
        Row(
          children: [
            // Refresh button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(quoteProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('New Quote'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Save as note button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _saveQuoteAsNote(quote),
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save as Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build UI for error state
  Widget _buildErrorState(String message, bool isDarkMode) {
    return Column(
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
        const SizedBox(height: 12),
        Text(
          'Oops!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? const Color(0xFFE0E0E0) : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        _buildRefreshButton(isDarkMode),
      ],
    );
  }

  /// Reusable refresh button
  Widget _buildRefreshButton(bool isDarkMode) {
    return ElevatedButton.icon(
      onPressed: () {
        ref.read(quoteProvider.notifier).fetchRandomQuote();
      },
      icon: const Icon(Icons.refresh),
      label: const Text('Try Again'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
