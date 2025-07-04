// Arquivo: lib/authors_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kardec_digital/author_books_screen.dart';

class AuthorsListScreen extends StatefulWidget {
  const AuthorsListScreen({Key? key}) : super(key: key);

  @override
  State<AuthorsListScreen> createState() => _AuthorsListScreenState();
}

class _AuthorsListScreenState extends State<AuthorsListScreen> {
  late final Future<List<String>> _authorsFuture;

  @override
  void initState() {
    super.initState();
    _authorsFuture = _getAllAuthors();
  }

  Future<List<String>> _getAllAuthors() async {
    final querySnapshot =
    await FirebaseFirestore.instance.collection('pdfs').get();
    final Set<String> authors = {};
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('autor')) {
        authors.add(data['autor'] as String);
      }
    }
    final sortedAuthors = authors.toList();
    sortedAuthors.sort();
    return sortedAuthors;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autores'),
      ),
      body: FutureBuilder<List<String>>(
        future: _authorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Erro ao carregar autores.'));
          }
          final authors = snapshot.data!;
          if (authors.isEmpty) {
            return const Center(child: Text('Nenhum autor encontrado.'));
          }

          return ListView.separated(
            itemCount: authors.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final author = authors[index];
              return ListTile(
                title: Text(author),
                leading: const Icon(Icons.person_outline),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuthorBooksScreen(author: author),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}