import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kardec_digital/local_storage_helper.dart';
import 'package:kardec_digital/storage_helper.dart';
import 'package:kardec_digital/pdf_viewer_screen.dart';

class AuthorBooksScreen extends StatefulWidget {
  final String author;

  const AuthorBooksScreen({Key? key, required this.author}) : super(key: key);

  @override
  State<AuthorBooksScreen> createState() => _AuthorBooksScreenState();
}

class _AuthorBooksScreenState extends State<AuthorBooksScreen> {
  final _searchController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allBooks = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _displayedBooks = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterBooks);
    _getDocumentsByAuthor();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getDocumentsByAuthor() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('pdfs')
        .where('autor', isEqualTo: widget.author)
        .get();

    final books = querySnapshot.docs;
    books.sort((a, b) {
      final aTitle = (a.data()['titulo'] as String?) ?? a.id;
      final bTitle = (b.data()['titulo'] as String?) ?? b.id;
      return aTitle.compareTo(bTitle);
    });

    setState(() {
      _allBooks = books;
      _displayedBooks = books;
    });
  }

  void _filterBooks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _displayedBooks = _allBooks;
      } else {
        _displayedBooks = _allBooks.where((doc) {
          final title =
          ((doc.data())['titulo'] as String? ?? doc.id).toLowerCase();
          return title.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.author),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar por título',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _displayedBooks.isEmpty
                ? Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'Carregando livros...'
                    : 'Nenhum livro encontrado.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: _displayedBooks.length,
              itemBuilder: (context, index) {
                final doc = _displayedBooks[index];
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
                          url: url,
                          title: title,
                          pdfPath: pdfPath,
                        ),
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
          ),
        ],
      ),
    );
  }
}