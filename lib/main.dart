import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'servicos/firebase_options.dart';
import 'telas/tela_principal/tela_principal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- Lógica do Crashlytics ---
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // --- NOVO: Lógica de Autenticação Anônima ---
  // Faz login anonimamente se o usuário ainda não estiver logado.
  // Isso nos dá um ID único (auth.currentUser.uid) para cada instalação do app.
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(const KardecDigitalApp());
}

class KardecDigitalApp extends StatelessWidget {
  const KardecDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ColorScheme.fromSeed(seedColor: Colors.teal);
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
      home: const TelaPrincipal(),
    );
  }
}
