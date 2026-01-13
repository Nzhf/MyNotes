import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mynotes/main_screen.dart';
import 'package:mynotes/login_screen.dart';
import 'package:mynotes/services/auth_service.dart';
import 'package:mynotes/services/notification_service.dart';
import 'package:mynotes/utils/app_globals.dart';
import 'note_model.dart';
import 'data/note_repository.dart';
import 'data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Load environment variables from .env file
  // This is where we store the Gemini API key securely
  await dotenv.load(fileName: '.env');

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());

  await NoteRepository.init();
  await SettingsRepository.init();
  await NotificationService().init();

  // Wrap app with ProviderScope for Riverpod state management
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    // Listen to theme settings from Hive
    return ValueListenableBuilder(
      valueListenable: Hive.box('settingsBox').listenable(),
      builder: (context, box, _) {
        final mode = SettingsRepository.getThemeMode();
        final fontSize = SettingsRepository.getFontSize();

        return MaterialApp(
          navigatorKey:
              navigatorKey, // Enables navigation from NotificationService
          debugShowCheckedModeBanner: false,

          // Apply font scaling globally using MediaQuery
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(fontSize)),
              child: child!,
            );
          },

          // Light theme (normal mode)
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFDFDFD),
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black),
              bodyLarge: TextStyle(color: Colors.black),
              titleMedium: TextStyle(color: Colors.black),
              titleLarge: TextStyle(color: Colors.black),
            ),
          ),

          // Pastel Dark Mode
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF2A2A2A),
            cardColor: const Color(0xFF3A3A3A),
            canvasColor: const Color(0xFF2A2A2A),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF2A2A2A),
              foregroundColor: Color(0xFFE0E0E0),
              elevation: 0,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
              bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
              titleMedium: TextStyle(color: Color(0xFFE0E0E0)),
              titleLarge: TextStyle(color: Color(0xFFE0E0E0)),
              labelLarge: TextStyle(color: Color(0xFFE0E0E0)),
            ),
            dividerColor: const Color(0xFFBDBDBD),
          ),

          themeMode: mode,

          // Check if user is logged in
          home: StreamBuilder(
            stream: authService.authStateChanges,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasData) {
                // User is logged in
                return const MainScreen();
              } else {
                // User is not logged in
                return const LoginScreen();
              }
            },
          ),
        );
      },
    );
  }
}
