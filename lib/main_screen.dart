import 'package:flutter/material.dart';
import 'package:mynotes/screens/notes/notes_screen.dart';
import '../../settings_screen.dart';
import 'package:mynotes/screens/notes/new_note_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // Use a stateful builder to hide FAB conditionally
      body: NotesScreen(key: ValueKey('notes_screen')),

      // Center FAB (rounded square)
      // No need to hide - we'll use resizeToAvoidBottomInset in notes screen
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: Material(
          color: Colors.blue,
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewNoteScreen()),
              );
            },
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Floating rounded bottom navigation
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0, left: 100, right: 100),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavIcon(
                icon: Icons.home,
                active: true,
                onTap: () {}, // Already on home
              ),

              // space for FAB
              const SizedBox(width: 48),

              _NavIcon(
                icon: Icons.settings,
                active: false,
                onTap: () {
                  // Navigate to settings as a new screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavIcon({
    super.key,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.blue : Colors.grey.shade600;
    return IconButton(
      icon: Icon(icon, color: color, size: 26),
      onPressed: onTap,
      tooltip: '',
    );
  }
}
