import 'package:flutter/material.dart';
import 'note_card.dart';
import 'note_detail_screen.dart';
import 'screens/notes/new_note_screen.dart';
import 'package:mynotes/note_model.dart';
import 'package:mynotes/data/note_repository.dart';

class RecentNotesScreen extends StatefulWidget {
  const RecentNotesScreen({super.key});

  @override
  State<RecentNotesScreen> createState() => _RecentNotesScreenState();
}

class _RecentNotesScreenState extends State<RecentNotesScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  List<Note> _getFilteredNotes() {
    final allNotes = NoteRepository.getNotes();
    if (_searchQuery.isEmpty) return allNotes;

    return allNotes.where((note) {
      final titleMatch = note.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final contentMatch = note.content.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return titleMatch || contentMatch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _getFilteredNotes();
    final allNotes = NoteRepository.getNotes();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Subtle off-white background
      // We use a CustomScrollView to allow the header to scroll away or stay pinned if we wanted
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Custom Header Section ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "My Notes",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        "${allNotes.length} notes and counting...",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.black87,
                      ),
                      onPressed: () {
                        // Settings logic
                      },
                    ),
                  ),
                ],
              ),
            ),

            // --- Modern Search Bar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Search your thoughts...",
                    hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.black.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // --- Notes Content Area ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: filteredNotes.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          return NoteCard(
                            title: note.title,
                            content: note.content,
                            color: note.color,
                            date: note.updatedAt,
                            imagePath: note.imagePath,
                            audioPath: note.audioPath,
                            videoPath: note.videoPath,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NoteDetailScreen(
                                    title: note.title,
                                    content: note.content,
                                    color: note.color,
                                    imagePath: note.imagePath,
                                    audioPath: note.audioPath,
                                    aiSummary: note.aiSummary,
                                    transcription: note.transcription,
                                    audioSummary: note.audioSummary,
                                    videoPath: note.videoPath,
                                    videoTranscription: note.videoTranscription,
                                    videoSummary: note.videoSummary,
                                  ),
                                ),
                              );
                              if (mounted) setState(() {}); // Refresh if edited
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),

      // --- Custom Floating Action Button ---
      floatingActionButton: Container(
        height: 65,
        width: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Colors.black87, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewNoteScreen()),
              );
              setState(() {});
            },
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty
                ? Icons.note_add_outlined
                : Icons.search_off_rounded,
            size: 80,
            color: Colors.black.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? "Your digital canvas is empty"
                : "No notes match your search",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? "Tap the + button to start writing"
                : "Try a different keyword",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
