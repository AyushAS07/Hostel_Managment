import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/backend_config.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'navigation_observer.dart';
import 'services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (BackendConfig.useFirebase) {
    if (!DefaultFirebaseOptions.isConfigured) {
      throw StateError(
        'Firebase is enabled but lib/firebase_options.dart is not configured. '
        'Run: dart pub global activate flutterfire_cli && flutterfire configure',
      );
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseService.restoreSessionIfNeeded();
  }
  runApp(const HostelApp());
}

class HostelApp extends StatelessWidget {
  const HostelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIT Hostel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.playfairDisplayTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const HomePage(),
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
    );
  }
}
