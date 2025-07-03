import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'firebase_options.dart';

final logger = Logger(printer: PrettyPrinter(), level: Level.debug);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}): super(key: key);
  @override
  Widget build(BuildContext c) => MaterialApp(
    title: 'Catálogo de PDFs',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: const MyHomePage(title: 'Catálogo de PDFs'),
  );
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({Key? key, required this.title}): super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pdfs').snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snap.hasError)
            return const Center(child: Text('Erro ao carregar PDFs'));
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty)
            return const Center(child: Text('Nenhum PDF encontrado'));
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: .7,
              crossAxisSpacing: 10, mainAxisSpacing: 10,
            ),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final title   = docs[i].id;
              final cover   = (data['coverPath'] ?? '') as String;
              final pdfPath = (data['pdfPath']  ?? '') as String;
              return GestureDetector(
                onTap: () async {
                  final url = await _getDownloadUrl(pdfPath);
                  Navigator.push(c, MaterialPageRoute(
                    builder: (_) => PDFViewerScreen(url: url),
                  ));
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(children: [
                    Expanded(child: _buildCover(cover)),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<String> _getDownloadUrl(String path) async {
    final p = path.startsWith('/') ? path.substring(1) : path;
    logger.d('PDF URL path → $p');
    return await FirebaseStorage.instance.ref().child(p).getDownloadURL();
  }

  Future<Uint8List> _getCoverBytes(String path) async {
    final p = path.startsWith('/') ? path.substring(1) : path;
    logger.d('CAPA bytes path → $p');
    final ref = FirebaseStorage.instance.ref().child(p);
    const max = 2 * 1024 * 1024;
    final bytes = await ref.getData(max);
    if (bytes == null) throw Exception('Não baixou bytes de $p');
    return bytes;
  }

  Widget _buildCover(String path) {
    return FutureBuilder<Uint8List>(
      future: _getCoverBytes(path),
      builder: (_, s) {
        if (s.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (s.hasError || s.data == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book, size: 50, color: Colors.grey),
                Text('Capa não disponível',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return Image.memory(s.data!, fit: BoxFit.cover, width: double.infinity);
      },
    );
  }
}

/// Tela que baixa o PDF e exibe com flutter_pdfview
class PDFViewerScreen extends StatefulWidget {
  final String url;
  const PDFViewerScreen({Key? key, required this.url}): super(key: key);
  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? _localPath;
  @override
  void initState() {
    super.initState();
    _downloadPDF();
  }
  Future<void> _downloadPDF() async {
    final res = await http.get(Uri.parse(widget.url));
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/temp.pdf');
    await file.writeAsBytes(res.bodyBytes);
    setState(() => _localPath = file.path);
  }
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visualizar PDF')),
      body: _localPath == null
          ? const Center(child: CircularProgressIndicator())
          : PDFView(filePath: _localPath!),
    );
  }
}
