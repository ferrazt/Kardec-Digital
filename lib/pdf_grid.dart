import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:kardec_digital/local_storage_helper.dart';
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

        final Map<String, List<QueryDocumentSnapshot>> byAuthor = {};
        for (var d in docs) {
          final data = d.data()! as Map<String, dynamic>;
          final a = data['autor'] as String? ?? 'Desconhecido';
          byAuthor.putIfAbsent(a, () => []).add(d);
        }

        final sortedEntries = byAuthor.entries.toList();
        sortedEntries.sort((a, b) => a.key.compareTo(b.key));

        return Column(
          children: sortedEntries.map((entry) {
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
            autoPlay: books.length > 2,
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