import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../note_model.dart';
import '../../data/note_repository.dart';
import '../../data/settings_repository.dart';
import '../../services/auth_service.dart';
import '../../profile_screen.dart';
import '../../widgets/daily_quote_card.dart';
import 'new_note_screen.dart';
import '../../services/notification_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with AutomaticKeepAliveClientMixin {
  List<Note> _notes = [];
  String _searchQuery = '';
  bool _searching = false;

  // Expanded pastel palette with more color options
  final List<int> _palette = [
    0xFFFFFFFF, // White
    0xFFFFF1C1, // Light Yellow
    0xFFFFD6E0, // Light Pink
    0xFFC6E5FF, // Light Blue
    0xFFD6F4D2, // Light Green
    0xFFE7D3FF, // Light Purple
    0xFFFFE8C7, // Light Orange/Peach
    0xFFE4F3FF, // Pale Blue
    0xFFFFE4EC, // Rose Pink
    0xFFD4F0F0, // Mint/Teal
    0xFFFCE4EC, // Blush Pink
    0xFFE8F5E9, // Mint Green
    0xFFFFF8E1, // Cream Yellow
    0xFFE1F5FE, // Sky Blue
    0xFFF3E5F5, // Lavender
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  // Reload notes when screen becomes visible again
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reloadNotes();
  }

  // Pull to refresh action
  Future<void> _pullToRefresh() async {
    try {
      await NoteRepository.syncFromCloud();
      await _reloadNotes();
    } catch (e) {
      debugPrint('Pull-to-refresh sync failed: $e');
    }
  }

  Future<void> _initAndLoad() async {
    await NoteRepository.init();
    await SettingsRepository.init();
    await _reloadNotes();

    // Sync with cloud (non-blocking for initial UI but updates after)
    try {
      await NoteRepository.syncFromCloud();
      await _reloadNotes();
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  Future<void> _reloadNotes() async {
    var notes = NoteRepository.getAllNotes();

    // Check for and remove expired reminders from the database
    // Note: We don't need to call cancelReminder() here because:
    // 1. If the reminder time has passed, the notification has already fired
    // 2. Once a notification fires, the system automatically removes it
    // 3. Calling cancel on a non-existent notification is unnecessary
    final now = DateTime.now();
    bool changed = false;
    for (final note in notes) {
      if (note.reminder != null && note.reminder!.isBefore(now)) {
        // Just clear the reminder from the database - no need to cancel notification
        await NoteRepository.updateNote(
          note.id,
          note.title,
          note.content,
          colorValue: note.colorValue,
          reminder: null,
        );
        changed = true;
      }
    }

    // Refresh list if data changed
    if (changed) {
      notes = NoteRepository.getAllNotes();
    }

    final sortOrder = SettingsRepository.getSortOrder();
    _sortNotes(notes, sortOrder);
    if (mounted) {
      setState(() => _notes = notes);
    }
  }

  void _sortNotes(List<Note> notes, String sortOrder) {
    switch (sortOrder) {
      case 'pinned_first':
        notes.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
        break;
      case 'recent':
        notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case 'oldest':
        notes.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
    }
  }

  List<Note> _filter(List<Note> notes) {
    if (_searchQuery.trim().isEmpty) return notes;
    final q = _searchQuery.toLowerCase();
    return notes.where((n) {
      final title = n.title.toLowerCase();
      final content = n.content.toLowerCase();
      return title.contains(q) || content.contains(q);
    }).toList();
  }

  void _showUndoSnack(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Note deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await NoteRepository.undoDelete();
            await _reloadNotes();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showQuickActions(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(
                    note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  ),
                  title: Text(note.isPinned ? 'Unpin' : 'Pin'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await NoteRepository.togglePin(note.id);
                    await _reloadNotes();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Change color'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showColorPicker(note);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy to clipboard'),
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(text: '${note.title}\n\n${note.content}'),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showColorPicker(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            children: _palette.map((v) {
              return GestureDetector(
                onTap: () async {
                  await NoteRepository.changeColor(note.id, v);
                  Navigator.pop(ctx);
                  await _reloadNotes();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(v),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Reminder Logic
  Future<void> _handleReminderClick(Note note) async {
    // Only show options if reminder is set AND in the future
    final isActive =
        note.reminder != null && note.reminder!.isAfter(DateTime.now());

    if (isActive) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reminder'),
          content: Text('Reminder set for: ${_formatDate(note.reminder!)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel_reminder'),
              child: const Text(
                'Remove Reminder',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'edit'),
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );

      if (action == 'cancel_reminder') {
        // Cancel effective immediately
        await NotificationService().cancelReminder(note.id.hashCode);
        // And update note
        await NoteRepository.updateNote(
          note.id,
          note.title,
          note.content,
          colorValue: note.colorValue,
          reminder: null,
        );
        await _reloadNotes();
      } else if (action == 'edit') {
        _pickReminder(note);
      }
    } else {
      // If null or expired, treat as fresh start
      _pickReminder(note);
    }
  }

  Future<void> _pickReminder(Note note) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 1))),
    );
    if (time == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (dateTime.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot set reminder in the past')),
        );
      }
      return;
    }

    // Update note with new reminder
    await NoteRepository.updateNote(
      note.id,
      note.title,
      note.content,
      colorValue: note.colorValue,
      reminder: dateTime,
      imagePath: note.imagePath,
      audioPath: note.audioPath,
    );

    // Schedule notification
    final service = NotificationService();
    service.scheduleReminder(
      id: NotificationService.generateId(note.id),
      title: note.title.isEmpty ? 'Untitled Note' : note.title,
      body: note.content.isEmpty ? 'Reminder for your note' : note.content,
      scheduledTime: dateTime,
      payload: note.id, // Pass Note ID for navigation
    );

    await _reloadNotes();
  }

  Future<void> _deleteNoteAndShowUndo(String id) async {
    // Cancel any pending reminder first
    await NotificationService().cancelReminder(
      NotificationService.generateId(id),
    );
    await NoteRepository.deleteNote(id);
    await _reloadNotes();
    _showUndoSnack(context);
  }

  Widget _buildGridNoteCard(Note note) {
    return Slidable(
      key: ValueKey(note.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.48,
        children: [
          SlidableAction(
            flex: 1,
            onPressed: (_) async {
              await NoteRepository.togglePin(note.id);
              await _reloadNotes();
            },
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icons.push_pin,
            label: note.isPinned ? 'Unpin' : 'Pin',
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            flex: 1,
            onPressed: (_) async {
              await _deleteNoteAndShowUndo(note.id);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewNoteScreen(existingNote: note),
            ),
          );
          await _reloadNotes();
        },
        onLongPress: () => _showQuickActions(note),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Color(note.colorValue),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.isPinned)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Icon(
                    Icons.push_pin_outlined,
                    size: 18,
                    color: Colors.orange,
                  ),
                ),
              if (note.imagePath != null || note.audioPath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      if (note.imagePath != null)
                        const Icon(
                          Icons.image_outlined,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                      if (note.imagePath != null && note.audioPath != null)
                        const SizedBox(width: 4),
                      if (note.audioPath != null)
                        const Icon(
                          Icons.mic_none_outlined,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      (note.title.isNotEmpty ? note.title : 'Untitled'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                  _buildBellIcon(note),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      note.content.trim().isNotEmpty ? note.content : '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(note.updatedAt),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListNoteCard(Note note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(note.id),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.40,
          children: [
            SlidableAction(
              flex: 1,
              onPressed: (_) async {
                await NoteRepository.togglePin(note.id);
                await _reloadNotes();
              },
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              icon: Icons.push_pin,
              label: note.isPinned ? 'Unpin' : 'Pin',
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              flex: 1,
              onPressed: (_) async {
                await _deleteNoteAndShowUndo(note.id);
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewNoteScreen(existingNote: note),
              ),
            );
            await _reloadNotes();
          },
          onLongPress: () => _showQuickActions(note),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(note.colorValue),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP INDICATORS (Pin, Image, Mic)
                // We combine them into a single Row for a cleaner look
                if (note.isPinned ||
                    note.imagePath != null ||
                    note.audioPath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        if (note.isPinned) ...[
                          const Icon(
                            Icons.push_pin_outlined,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (note.imagePath != null) ...[
                          const Icon(
                            Icons.image_outlined,
                            size: 16,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (note.audioPath != null)
                          const Icon(
                            Icons.mic_none_outlined,
                            size: 16,
                            color: Colors.blueGrey,
                          ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        (note.title.isNotEmpty ? note.title : 'Untitled'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    _buildBellIcon(note),
                  ],
                ),
                if (note.content.trim().isNotEmpty) const SizedBox(height: 8),
                if (note.content.trim().isNotEmpty)
                  Text(
                    note.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(note.updatedAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBellIcon(Note note) {
    final isActive =
        note.reminder != null && note.reminder!.isAfter(DateTime.now());
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _handleReminderClick(note),
            child: Icon(
              isActive ? Icons.notifications_active : Icons.notifications_none,
              size: 20,
              color: isActive
                  ? Colors.blue
                  : (isDarkMode ? Colors.white : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: Hive.box('settingsBox').listenable(),
      builder: (context, box, _) {
        final noteLayout = SettingsRepository.getNoteLayout();
        final sortOrder = SettingsRepository.getSortOrder();

        // Re-sort notes when sort order changes
        final notes = List<Note>.from(_notes);
        _sortNotes(notes, sortOrder);
        final filtered = _filter(notes);

        return Scaffold(
          resizeToAvoidBottomInset: false,
          // Custom AppBar matching bank app design
          appBar: _searching
              ? AppBar(
                  automaticallyImplyLeading: false,
                  title: TextField(
                    autofocus: true,
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFE0E0E0)
                          : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _searching = false;
                          _searchQuery = '';
                        });
                      },
                    ),
                  ],
                  elevation: 0.5,
                )
              : PreferredSize(
                  preferredSize: const Size.fromHeight(80),
                  child: _buildCustomAppBar(context, isDarkMode),
                ),

          body: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // FIXED: Only show quote card when NOT searching
                      if (!_searching)
                        DailyQuoteCard(
                          onNoteSaved:
                              _reloadNotes, // Pass callback to refresh notes
                        ),
                      const SizedBox(height: 20),
                      Text(
                        _searching
                            ? 'No notes found'
                            : 'No notes yet — tap + to create one',
                        style: TextStyle(
                          color: isDarkMode
                              ? const Color(0xFFE0E0E0)
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )
              : noteLayout == 'grid'
              // FIXED: Add quote card to grid view
              ? RefreshIndicator(
                  onRefresh: _pullToRefresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // FIXED: Hide quote card when searching
                      if (!_searching)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 0),
                            child: DailyQuoteCard(
                              onNoteSaved:
                                  _reloadNotes, // Pass callback to refresh notes
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 0,
                          bottom: 100,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                          delegate: SliverChildBuilderDelegate((context, idx) {
                            return _buildGridNoteCard(filtered[idx]);
                          }, childCount: filtered.length),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _pullToRefresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 0,
                      bottom: 100,
                    ),
                    itemCount:
                        filtered.length +
                        (_searching
                            ? 0
                            : 1), // FIXED: Hide quote when searching
                    itemBuilder: (context, idx) {
                      // FIXED: Don't show quote card when searching
                      if (idx == 0 && !_searching) {
                        return DailyQuoteCard(
                          onNoteSaved:
                              _reloadNotes, // Pass callback to refresh notes
                        );
                      }
                      // Adjust index if quote card is shown
                      final noteIndex = _searching ? idx : idx - 1;
                      return _buildListNoteCard(filtered[noteIndex]);
                    },
                  ),
                ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    return "${d.day}/${d.month}/${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }

  /// Build custom app bar matching bank app design
  /// Shows user avatar, greeting, and search icon
  Widget _buildCustomAppBar(BuildContext context, bool isDarkMode) {
    // Import auth service to get user info
    final authService = AuthService();
    final user = authService.currentUser;
    final userName =
        user?.displayName?.split(' ').first ??
        user?.email?.split('@').first ??
        'User';
    final fullName = user?.displayName ?? user?.email ?? 'User';

    var appBar = AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 90,
      elevation: 0,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // User avatar and name - Combined clickable area to edit profile
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // User avatar (circular)
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF2F80ED),
                              child: Text(
                                userName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Greeting and user name
                            Flexible(
                              fit: FlexFit.loose,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Hello',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    fullName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? const Color(0xFFE0E0E0)
                                          : Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Dark mode toggle button
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: isDarkMode
                        ? const Color(0xFFE0E0E0)
                        : Colors.black87,
                  ),
                  onPressed: () async {
                    // Toggle between light and dark mode
                    final newMode = isDarkMode
                        ? ThemeMode.light
                        : ThemeMode.dark;
                    await SettingsRepository.setThemeMode(newMode);
                  },
                ),
              ),

              const SizedBox(width: 8),

              // Search icon button
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.search,
                    color: isDarkMode
                        ? const Color(0xFFE0E0E0)
                        : Colors.black87,
                  ),
                  onPressed: () {
                    setState(() => _searching = true);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return appBar;
  }
}
