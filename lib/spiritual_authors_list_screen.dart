import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kardec_digital/spirit_books_screen.dart';

class SpiritualAuthorsListScreen extends StatefulWidget {
  const SpiritualAuthorsListScreen({Key? key}) : super(key: key);

  @override
  State<SpiritualAuthorsListScreen> createState() =>
      _SpiritualAuthorsListScreenState();
}

class _SpiritualAuthorsListScreenState
    extends State<SpiritualAuthorsListScreen> {
  late final Future<List<String>> _spiritsFuture;

  @override
  void initState() {
    super.initState();
    _spiritsFuture = _getAllSpirits();
  }

  Future<List<String>> _getAllSpirits() async {
    final querySnapshot =
    await FirebaseFirestore.instance.collection('pdfs').get();
    final Set<String> spirits = {};
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('espirito') &&
          data['espirito'] != null &&
          (data['espirito'] as String).trim().isNotEmpty) {
        spirits.add(data['espirito'] as String);
      }
    }
    final sortedSpirits = spirits.toList();
    sortedSpirits.sort();
    return sortedSpirits;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autores Espirituais'),
      ),
      body: FutureBuilder<List<String>>(
        future: _spiritsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Nenhum autor espiritual encontrado.'));
          }
          final spirits = snapshot.data!;
          return ListView.separated(
            itemCount: spirits.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final spiritName = spirits[index];
              return ListTile(
                title: Text('Série $spiritName'),
                leading: const Icon(Icons.auto_stories_outlined),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SpiritBooksScreen(spiritName: spiritName),
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