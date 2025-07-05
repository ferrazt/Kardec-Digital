import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../servicos/servicos_firebase.dart';
import '../uteis/armazenamento_local.dart';
import 'tela_leitor_pdf.dart';

class TelaLivrosAutor extends StatefulWidget {
  final String autor;

  const TelaLivrosAutor({super.key, required this.autor});

  @override
  State<TelaLivrosAutor> createState() => _TelaLivrosAutorState();
}

class _TelaLivrosAutorState extends State<TelaLivrosAutor> {
  final _controladorBusca = TextEditingController();
  final _servicosFirebase = ServicosFirebase();

  List<QueryDocumentSnapshot> _todosOsLivros = [];
  List<QueryDocumentSnapshot> _livrosExibidos = [];

  @override
  void initState() {
    super.initState();
    _controladorBusca.addListener(_filtrarLivros);
    _servicosFirebase.getLivrosPorAutor(widget.autor).then((livros) {
      if (mounted) {
        setState(() {
          _todosOsLivros = livros;
          _livrosExibidos = livros;
        });
      }
    });
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    super.dispose();
  }

  void _filtrarLivros() {
    final consulta = _controladorBusca.text.toLowerCase();
    setState(() {
      if (consulta.isEmpty) {
        _livrosExibidos = _todosOsLivros;
      } else {
        _livrosExibidos = _todosOsLivros.where((doc) {
          final dados = doc.data() as Map<String, dynamic>;
          final titulo = (dados['titulo'] as String? ?? doc.id).toLowerCase();
          return titulo.contains(consulta);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.autor),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _controladorBusca,
              decoration: InputDecoration(
                labelText: 'Pesquisar por título',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _controladorBusca.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controladorBusca.clear();
                  },
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _livrosExibidos.isEmpty && _controladorBusca.text.isNotEmpty
                ? Center(
              child: Text(
                'Nenhum livro encontrado.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
                : _todosOsLivros.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: _livrosExibidos.length,
              itemBuilder: (context, index) {
                final doc = _livrosExibidos[index];
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
                          child: _servicosFirebase
                              .construirCapaLivro(caminhoCapa),
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
                                ?.copyWith(
                                fontWeight: FontWeight.bold),
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
