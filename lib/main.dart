import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'my_homepage_state.dart'; // Your main content screen
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const KardecDigitalApp());
}

class KardecDigitalApp extends StatelessWidget {
  const KardecDigitalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final base = ColorScheme.fromSeed(seedColor: Colors.teal); // Your original theme setup
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kardec Digital',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: base,
        textTheme: GoogleFonts.openSansTextTheme(),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const MyHomePage(), // Your existing MyHomePage with the carousel
    );
  }
}