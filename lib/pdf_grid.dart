import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:shimmer/shimmer.dart';
import 'storage_helper.dart';
import 'pdf_viewer_screen.dart';

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

        // Para cada autor, um carrossel
        return Column(
          children: byAuthor.entries.map((e) {
            return _AuthorCarousel(
              author: e.key,
              books: e.value,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(author,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        cs.CarouselSlider.builder(
          itemCount: books.length,
          options: cs.CarouselOptions(
            height: 220,
            enlargeCenterPage: true,
            viewportFraction: 0.4,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
          ),
          itemBuilder: (ctx, i, realIdx) {
            final data = books[i].data()! as Map<String, dynamic>;
            return _BookCard(
              title: books[i].id,
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
              title: title, // Passe o título do livro
            ),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            Expanded(
              child: buildCoverFromBytes(coverPath), // Corrigido anteriormente
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
