import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:shimmer/shimmer.dart';
import '../../../servicos/servicos_firebase.dart';
import '../../../uteis/armazenamento_local.dart';
import '../../tela_leitor_pdf.dart';

/// Widget que exibe carrosséis de livros, agrupados por autor.
class CarrosselLivros extends StatelessWidget {
  const CarrosselLivros({super.key});

  @override
  Widget build(BuildContext context) {
    // A instância do serviço é criada apenas uma vez aqui.
    final servicosFirebase = ServicosFirebase();
    return StreamBuilder<QuerySnapshot>(
      stream: servicosFirebase.getLivrosStream(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
              child: Text('Nenhum livro encontrado na biblioteca.'));
        }

        final Map<String, List<QueryDocumentSnapshot>> porAutor = {};
        for (var d in docs) {
          final data = d.data()! as Map<String, dynamic>;
          final autor = data['autor'] as String? ?? 'Desconhecido';
          porAutor.putIfAbsent(autor, () => []).add(d);
        }

        final autoresOrdenados = porAutor.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        return Column(
          children: autoresOrdenados.map((entry) {
            return _CarrosselPorAutor(
              autor: entry.key,
              livros: entry.value,
              // A instância do serviço é passada para os widgets filhos.
              servicosFirebase: servicosFirebase,
            );
          }).toList(),
        );
      },
    );
  }
}

class _CarrosselPorAutor extends StatelessWidget {
  final String autor;
  final List<QueryDocumentSnapshot> livros;
  // Recebe a instância do serviço.
  final ServicosFirebase servicosFirebase;

  const _CarrosselPorAutor(
      {required this.autor,
        required this.livros,
        required this.servicosFirebase});

  @override
  Widget build(BuildContext context) {
    livros.sort((a, b) {
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
          child: Text(autor, style: Theme.of(context).textTheme.titleLarge),
        ),
        cs.CarouselSlider.builder(
          itemCount: livros.length,
          options: cs.CarouselOptions(
            height: 220,
            enlargeCenterPage: true,
            viewportFraction: 0.4,
            autoPlay: livros.length > 2,
            autoPlayInterval: const Duration(seconds: 5),
          ),
          itemBuilder: (ctx, i, realIdx) {
            final doc = livros[i];
            final data = doc.data()! as Map<String, dynamic>;
            final titulo = (data['titulo'] as String?) ?? doc.id;
            final autor = data['autor'] as String?;
            final espirito = data['espirito'] as String?;

            return _CardLivro(
              titulo: titulo,
              caminhoCapa: data['capaPath'] as String? ?? '',
              caminhoPdf: data['pdfPath'] as String? ?? '',
              autor: autor,
              espirito: espirito,
              // Passa a instância do serviço para o card.
              servicosFirebase: servicosFirebase,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CardLivro extends StatelessWidget {
  final String titulo, caminhoCapa, caminhoPdf;
  final String? autor;
  final String? espirito;
  // Recebe a instância do serviço.
  final ServicosFirebase servicosFirebase;

  const _CardLivro({
    required this.titulo,
    required this.caminhoCapa,
    required this.caminhoPdf,
    this.autor,
    this.espirito,
    required this.servicosFirebase,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await LocalStorageHelper.addToHistory(caminhoPdf);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TelaLeitorPdf(
              title: titulo,
              pdfPath: caminhoPdf,
              autor: autor,
              espirito: espirito,
            ),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              // A lógica de construção da capa agora está aqui dentro,
              // garantindo que temos controle total sobre ela.
              child: _construirCapa(caminhoCapa),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                titulo,
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

  /// Este método agora vive dentro do Card, nos dando controle sobre o `fit`.
  Widget _construirCapa(String? caminhoCapa) {
    if (caminhoCapa == null || caminhoCapa.isEmpty) {
      return const Icon(Icons.book, size: 50, color: Colors.grey);
    }

    return FutureBuilder<String>(
      future: servicosFirebase.getUrlDownload(caminhoCapa),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(color: Colors.white),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Icon(Icons.error_outline, color: Colors.red);
        }

        return CachedNetworkImage(
          imageUrl: snapshot.data!,
          // CORREÇÃO: BoxFit.cover preenche o espaço mantendo a proporção.
          // É o melhor equilíbrio entre preenchimento e fidelidade da imagem.
          fit: BoxFit.cover,
          placeholder: (context, url) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(color: Colors.white),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        );
      },
    );
  }
}
