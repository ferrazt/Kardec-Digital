import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kardec_digital/local_storage_helper.dart';
import 'package:kardec_digital/pdf_viewer_screen.dart';
import 'package:kardec_digital/storage_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _historyDetailsFuture;

  @override
  void initState() {
    super.initState();
    _historyDetailsFuture = _getHistoryDetails();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _getHistoryDetails() async {
    final historyPaths = await LocalStorageHelper.getHistory();
    if (historyPaths.isEmpty) {
      return [];
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('pdfs')
        .where('pdfPath', whereIn: historyPaths)
        .get();

    final docsMap = {
      for (var doc in querySnapshot.docs) doc.data()['pdfPath']: doc
    };

    final sortedDocs = historyPaths
        .map((path) => docsMap[path])
        .where((doc) => doc != null)
        .cast<QueryDocumentSnapshot<Map<String, dynamic>>>()
        .toList();

    return sortedDocs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Leitura'),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _historyDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Erro ao carregar histórico: ${snapshot.error}'));
          }
          final historyBooks = snapshot.data ?? [];
          if (historyBooks.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum livro no seu histórico ainda.\nComece a ler para registrar!',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: historyBooks.length,
            itemBuilder: (context, index) {
              final doc = historyBooks[index];
              final data = doc.data();
              final title = (data['titulo'] as String?) ?? doc.id;
              final author =
                  (data['autor'] as String?) ?? 'Autor desconhecido';
              final pdfPath = data['pdfPath'] as String;

              return ListTile(
                leading: SizedBox(
                  width: 50,
                  height: 80,
                  child: buildCoverWithCache(data['capaPath'] as String),
                ),
                title: Text(title),
                subtitle: Text(author),
                onTap: () async {
                  await LocalStorageHelper.addToHistory(pdfPath);
                  final url = await getDownloadUrl(pdfPath);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PDFViewerScreen(
                          url: url, title: title, pdfPath: pdfPath),
                    ),
                  ).then((_) => setState(() {
                    _historyDetailsFuture = _getHistoryDetails();
                  }));
                },
              );
            },
          );
        },
      ),
    );
  }
}