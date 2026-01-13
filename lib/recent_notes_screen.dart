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
  @override
  Widget build(BuildContext context) {
    List<Note> notes = NoteRepository.getNotes();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: notes.isEmpty
            ? const Center(child: Text("No notes yet."))
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
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
                          ),
                        ),
                      );
                    },
                    child: NoteCard(
                      title: note.title,
                      content: note.content,
                      color: note.color,
                    ),
                  );
                },
              ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () async {
          // Wait for new note to be added
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewNoteScreen()),
          );
          setState(() {}); // Refresh grid
        },
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: const Icon(Icons.menu, color: Colors.black),
      centerTitle: true,
      title: const Text(
        'Recent Notes',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: Icon(Icons.search, color: Colors.black),
        ),
      ],
    );
  }
}
