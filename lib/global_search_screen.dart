import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kardec_digital/pdf_viewer_screen.dart';
import 'package:kardec_digital/storage_helper.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({Key? key}) : super(key: key);

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allBooks = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _displayedBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllBooks();
    _searchController.addListener(_filterBooks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllBooks() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('pdfs').get();
    setState(() {
      _allBooks = querySnapshot.docs;
      _displayedBooks = _allBooks;
      _isLoading = false;
    });
  }

  void _filterBooks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _displayedBooks = _allBooks;
      } else {
        _displayedBooks = _allBooks.where((doc) {
          final data = doc.data();
          final title = (data['titulo'] as String? ?? doc.id).toLowerCase();
          final author = (data['autor'] as String? ?? '').toLowerCase();
          return title.contains(query) || author.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar na Biblioteca'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              autofocus: true, // Foca no campo de busca ao abrir a tela
              decoration: InputDecoration(
                hintText: 'Digite o título ou autor...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayedBooks.isEmpty
                ? const Center(child: Text('Nenhum resultado encontrado.'))
                : ListView.builder(
              itemCount: _displayedBooks.length,
              itemBuilder: (context, index) {
                final doc = _displayedBooks[index];
                final data = doc.data();
                final title = (data['titulo'] as String?) ?? doc.id;
                final author = (data['autor'] as String?) ?? 'Desconhecido';

                return ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 80,
                    child: buildCoverWithCache(data['capaPath'] as String),
                  ),
                  title: Text(title),
                  subtitle: Text(author),
                  onTap: () async {
                    final url = await getDownloadUrl(data['pdfPath'] as String);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PDFViewerScreen(url: url, title: title),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}