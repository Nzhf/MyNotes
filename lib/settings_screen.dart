import 'package:flutter/material.dart';
import '../../data/settings_repository.dart';
import '../../services/auth_service.dart';
import '../../login_screen.dart';
import '../../profile_screen.dart';
import '../../data/note_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State variables to hold current settings values
  String _themeMode = 'system';
  double _fontSize = 1.0;
  String _noteLayout = 'grid';
  String _sortOrder = 'pinned_first';
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Load all settings from repository when screen initializes
  Future<void> _loadSettings() async {
    await SettingsRepository.init();
    if (mounted) {
      setState(() {
        final themeMode = SettingsRepository.getThemeMode();
        _themeMode = _themeModeToString(themeMode);
        _fontSize = SettingsRepository.getFontSize();
        _noteLayout = SettingsRepository.getNoteLayout();
        _sortOrder = SettingsRepository.getSortOrder();
      });
    }
  }

  /// Convert ThemeMode enum to string for UI display
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Update theme mode and save to repository
  Future<void> _updateTheme(String value) async {
    final themeMode = _stringToThemeMode(value);
    await SettingsRepository.setThemeMode(themeMode);
    if (mounted) {
      setState(() => _themeMode = value);
    }
  }

  /// Convert string to ThemeMode enum for repository storage
  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Update font size setting
  Future<void> _updateFontSize(double value) async {
    await SettingsRepository.setFontSize(value);
    if (mounted) {
      setState(() => _fontSize = value);
    }
  }

  /// Update note layout (grid or list)
  Future<void> _updateNoteLayout(String value) async {
    await SettingsRepository.setNoteLayout(value);
    if (mounted) {
      setState(() => _noteLayout = value);
    }
  }

  /// Update sort order setting
  Future<void> _updateSortOrder(String value) async {
    await SettingsRepository.setSortOrder(value);
    if (mounted) {
      setState(() => _sortOrder = value);
    }
  }

  /// Reset all settings to their default values
  Future<void> _resetToDefaults() async {
    await SettingsRepository.setThemeMode(ThemeMode.system);
    await SettingsRepository.setFontSize(1.0);
    await SettingsRepository.setNoteLayout('grid');
    await SettingsRepository.setSortOrder('pinned_first');
    await _loadSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings reset to defaults'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            bottom: 100, // Position above FAB
            left: 16,
            right: 16,
          ),
        ),
      );
    }
  }

  /// Sign out user with confirmation dialog
  Future<void> _signOut() async {
    // Show confirmation dialog before signing out
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // If user confirmed, proceed with sign out
    if (confirmed == true && mounted) {
      try {
        await _authService.signOut();

        if (mounted) {
          // Navigate to login and remove all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Delete all data (local + cloud)
  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete ALL your notes from both this device and the cloud.\n\nThis action cannot be undone.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await NoteRepository.deleteAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data deleted successfully'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Build section title widget with theme-aware color
  Widget _sectionTitle(String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? const Color(0xFFE0E0E0) : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme mode and colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? const Color(0xFFE0E0E0) : Colors.black;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    // Get user information
    final userName =
        _authService.currentUser?.displayName ??
        _authService.currentUser?.email ??
        'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========================================
            // USER INFO CARD (Clickable)
            // Display user's avatar and email
            // Tap to edit profile
            // ========================================
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // User avatar with first letter of name
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF2F80ED),
                        child: Text(
                          userName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // User name and email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _authService.currentUser?.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrow icon to indicate clickability
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: subtitleColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ========================================
            // THEME MODE SECTION
            // Let user choose light/dark/system theme
            // ========================================
            _sectionTitle('Appearance'),
            ListTile(
              title: Text('Theme mode', style: TextStyle(color: textColor)),
              subtitle: Text(
                'Light / Dark / System default',
                style: TextStyle(color: subtitleColor),
              ),
            ),
            // Radio option: System default
            RadioListTile<String>(
              title: Text('System default', style: TextStyle(color: textColor)),
              value: 'system',
              groupValue: _themeMode,
              onChanged: (v) => _updateTheme(v!),
            ),
            // Radio option: Light mode
            RadioListTile<String>(
              title: Text('Light', style: TextStyle(color: textColor)),
              value: 'light',
              groupValue: _themeMode,
              onChanged: (v) => _updateTheme(v!),
            ),
            // Radio option: Dark mode
            RadioListTile<String>(
              title: Text('Dark', style: TextStyle(color: textColor)),
              value: 'dark',
              groupValue: _themeMode,
              onChanged: (v) => _updateTheme(v!),
            ),

            const Divider(),

            // ========================================
            // FONT SIZE SECTION
            // Slider to adjust text size (80% - 150%)
            // ========================================
            _sectionTitle('Font Size'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(Icons.text_fields, color: textColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Slider for font size adjustment
                        Slider(
                          value: _fontSize,
                          min: 0.8,
                          max: 1.5,
                          divisions: 14,
                          label: '${(_fontSize * 100).round()}%',
                          onChanged: (v) => setState(() => _fontSize = v),
                          onChangeEnd: (v) => _updateFontSize(v),
                        ),
                        // Display current font scale percentage
                        Text(
                          'Scale: ${(_fontSize * 100).round()}%',
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // ========================================
            // NOTE LAYOUT SECTION
            // Toggle between grid and list view
            // ========================================
            _sectionTitle('Note layout'),
            ListTile(
              title: Text(
                'Choose layout for notes',
                style: TextStyle(color: textColor),
              ),
              subtitle: Text(
                'Grid shows cards; List shows full-width notes',
                style: TextStyle(color: subtitleColor),
              ),
            ),
            // Toggle buttons for grid/list layout
            ToggleButtons(
              isSelected: [_noteLayout == 'grid', _noteLayout == 'list'],
              onPressed: (i) {
                final newVal = (i == 0) ? 'grid' : 'list';
                _updateNoteLayout(newVal);
              },
              borderRadius: BorderRadius.circular(8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.grid_view, color: textColor),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.view_agenda, color: textColor),
                ),
              ],
            ),

            const Divider(),

            // ========================================
            // SORT ORDER SECTION
            // Choose how notes are sorted
            // ========================================
            _sectionTitle('Sort order'),
            ListTile(
              title: Text('Notes sorting', style: TextStyle(color: textColor)),
              subtitle: Text(
                'How notes are ordered on the home screen',
                style: TextStyle(color: subtitleColor),
              ),
            ),
            // Radio option: Pinned first
            RadioListTile(
              title: Text(
                'Pinned first, then recent',
                style: TextStyle(color: textColor),
              ),
              value: 'pinned_first',
              groupValue: _sortOrder,
              onChanged: (v) => _updateSortOrder(v!),
            ),
            // Radio option: Most recent first
            RadioListTile(
              title: Text(
                'Most recent first',
                style: TextStyle(color: textColor),
              ),
              value: 'recent',
              groupValue: _sortOrder,
              onChanged: (v) => _updateSortOrder(v!),
            ),
            // Radio option: Oldest first
            RadioListTile(
              title: Text('Oldest first', style: TextStyle(color: textColor)),
              value: 'oldest',
              groupValue: _sortOrder,
              onChanged: (v) => _updateSortOrder(v!),
            ),

            const SizedBox(height: 28),

            // ========================================
            // RESET TO DEFAULTS BUTTON
            // Reset all settings to initial values
            // ========================================
            ElevatedButton.icon(
              onPressed: _resetToDefaults,
              icon: const Icon(Icons.restore),
              label: const Text('Reset to defaults'),
            ),

            const SizedBox(height: 16),

            // ========================================
            // DELETE ALL DATA BUTTON (PRIVACY)
            // ========================================
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _deleteAllData,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete All My Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ========================================
            // SIGN OUT BUTTON
            // Log out and return to login screen
            // ========================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Extra bottom padding (no FAB/nav bar in settings)
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
