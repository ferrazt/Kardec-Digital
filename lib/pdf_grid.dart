import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kardec_digital/pdf_viewer_screen.dart';
import 'package:kardec_digital/storage_helper.dart';

/// Gera o grid de capas e abre a tela de PDF ao tocar
Widget buildPDFGrid(BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('pdfs').snapshots(),
    builder: (ctx, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return const Center(child: Text('Erro ao carregar PDFs'));
      }
      final docs = snapshot.data?.docs ?? [];
      if (docs.isEmpty) {
        return const Center(child: Text('Nenhum PDF encontrado'));
      }

      return GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: docs.length,
        itemBuilder: (ctx, i) {
          final data     = docs[i].data() as Map<String, dynamic>;
          final title    = docs[i].id;
          final coverPath = data['coverPath'] as String? ?? '';
          final pdfPath   = data['pdfPath']   as String? ?? '';

          return GestureDetector(
            onTap: () async {
              final pdfUrl = await getDownloadUrl(pdfPath);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PDFViewerScreen(url: pdfUrl)),
              );
            },
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Expanded(child: buildCoverFromBytes(coverPath)),
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
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
