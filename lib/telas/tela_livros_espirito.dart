import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../servicos/servicos_firebase.dart';
import '../uteis/armazenamento_local.dart';
import 'tela_leitor_pdf.dart';

class TelaLivrosEspirito extends StatefulWidget {
  final String spiritName;

  const TelaLivrosEspirito({super.key, required this.spiritName});

  @override
  State<TelaLivrosEspirito> createState() => _TelaLivrosEspiritoState();
}

class _TelaLivrosEspiritoState extends State<TelaLivrosEspirito> {
  final _servicosFirebase = ServicosFirebase();
  late Future<List<QueryDocumentSnapshot>> _livrosFuture;

  @override
  void initState() {
    super.initState();
    _livrosFuture = _servicosFirebase.getLivrosPorEspirito(widget.spiritName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Série ${widget.spiritName}'),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _livrosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Erro ao carregar os livros.'));
          }
          final livros = snapshot.data!;
          if (livros.isEmpty) {
            return const Center(child: Text('Nenhum livro encontrado.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: livros.length,
            itemBuilder: (context, index) {
              final doc = livros[index];
              final data = doc.data() as Map<String, dynamic>;
              final titulo = (data['titulo'] as String?) ?? doc.id;
              final caminhoPdf = data['pdfPath'] as String;
              final caminhoCapa = data['capaPath'] as String?;
              // Extrai os dados para o Analytics
              final autor = data['autor'] as String?;
              final espirito = data['espirito'] as String?;

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
                  clipBehavior: Clip.antiAlias,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child:
                        _servicosFirebase.construirCapaLivro(caminhoCapa),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          titulo,
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
          );
        },
      ),
    );
  }
}
