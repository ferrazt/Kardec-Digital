import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:kardec_digital/pdf_viewer_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'storage_helper.dart';

class NetflixStylePDFList extends StatelessWidget {
  const NetflixStylePDFList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pdfs').snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: SizedBox(height: 220, child: Container(color: Colors.white)),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Nenhum PDF'));

        // Agrupa por autor
        final Map<String, List<QueryDocumentSnapshot>> byAuthor = {};
        for (var d in docs) {
          final data = d.data()! as Map<String, dynamic>;
          final a = data['autor'] as String? ?? 'Desconhecido';
          byAuthor.putIfAbsent(a, () => []).add(d);
        }

        // === INÍCIO DA CORREÇÃO ===
        // 1. Pega as entradas do mapa (autor e sua lista de livros) e converte para uma lista.
        final sortedEntries = byAuthor.entries.toList();

        // 2. Ordena essa lista em ordem alfabética usando a chave (o nome do autor).
        sortedEntries.sort((a, b) => a.key.compareTo(b.key));
        // === FIM DA CORREÇÃO ===

        // Para cada autor, um carrossel, agora usando a lista ordenada.
        return Column(
          children: sortedEntries.map((entry) { // Modificado de byAuthor.entries para sortedEntries
            return _AuthorCarousel(
              author: entry.key,
              books: entry.value,
            );
          }).toList(),
        );
      },
    );
  }
}

class _AuthorCarousel extends StatelessWidget {
  final String author;
  final List<QueryDocumentSnapshot> books;
  const _AuthorCarousel({required this.author, required this.books});

  @override
  Widget build(BuildContext context) {
    // Ordena os livros dentro do carrossel por título
    books.sort((a, b) {
      final aData = a.data()! as Map<String, dynamic>;
      final bData = b.data()! as Map<String, dynamic>;
      final aTitle = aData['titulo'] as String? ?? a.id;
      final bTitle = bData['titulo'] as String? ?? b.id;
      return aTitle.compareTo(bTitle);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            author,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        cs.CarouselSlider.builder(
          itemCount: books.length,
          options: cs.CarouselOptions(
            height: 220,
            enlargeCenterPage: true,
            viewportFraction: 0.4,
            autoPlay: books.length > 2, // Desativa o autoPlay se tiver poucos livros
            autoPlayInterval: const Duration(seconds: 5),
          ),
          itemBuilder: (ctx, i, realIdx) {
            final doc = books[i];
            final data = doc.data()! as Map<String, dynamic>;
            final title = (data['titulo'] as String?) ?? doc.id;

            return _BookCard(
              title: title,
              coverPath: data['capaPath'] as String? ?? '',
              pdfPath: data['pdfPath'] as String? ?? '',
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _BookCard extends StatelessWidget {
  final String title, coverPath, pdfPath;
  const _BookCard({
    required this.title,
    required this.coverPath,
    required this.pdfPath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final url = await getDownloadUrl(pdfPath);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PDFViewerScreen(
              url: url,
              title: title,
            ),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(
              child: buildCoverWithCache(coverPath),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}