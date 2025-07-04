import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kardec_digital/local_storage_helper.dart';
import 'package:kardec_digital/storage_helper.dart';
import 'package:kardec_digital/pdf_viewer_screen.dart';

class SpiritBooksScreen extends StatefulWidget {
  final String spiritName;

  const SpiritBooksScreen({Key? key, required this.spiritName})
      : super(key: key);

  @override
  State<SpiritBooksScreen> createState() => _SpiritBooksScreenState();
}

class _SpiritBooksScreenState extends State<SpiritBooksScreen> {
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getDocumentsBySpirit();
  }

  Future<void> _getDocumentsBySpirit() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('pdfs')
        .where('espirito', isEqualTo: widget.spiritName)
        .get();

    final books = querySnapshot.docs;
    books.sort((a, b) {
      final aTitle = (a.data()['titulo'] as String?) ?? a.id;
      final bTitle = (b.data()['titulo'] as String?) ?? b.id;
      return aTitle.compareTo(bTitle);
    });

    setState(() {
      _books = books;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Série ${widget.spiritName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
          ? const Center(child: Text('Nenhum livro encontrado.'))
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final doc = _books[index];
          final data = doc.data();
          final title = (data['titulo'] as String?) ?? doc.id;
          final pdfPath = data['pdfPath'] as String;

          return GestureDetector(
            onTap: () async {
              await LocalStorageHelper.addToHistory(pdfPath);
              final url = await getDownloadUrl(pdfPath);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PDFViewerScreen(
                      url: url, title: title, pdfPath: pdfPath),
                ),
              );
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: buildCoverWithCache(
                        data['capaPath'] as String),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}