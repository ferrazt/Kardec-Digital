import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_performance/firebase_performance.dart'; // Importa o Performance
import 'package:flutter/material.dart';
import '../servicos/servicos_firebase.dart';
import '../uteis/armazenamento_local.dart';
import 'tela_leitor_pdf.dart';

class TelaBuscaGlobal extends StatefulWidget {
  const TelaBuscaGlobal({super.key});

  @override
  State<TelaBuscaGlobal> createState() => _TelaBuscaGlobalState();
}

class _TelaBuscaGlobalState extends State<TelaBuscaGlobal> {
  final _controladorBusca = TextEditingController();
  final _servicosFirebase = ServicosFirebase();

  List<QueryDocumentSnapshot> _todosOsLivros = [];
  List<QueryDocumentSnapshot> _livrosExibidos = [];
  bool _estaCarregando = true;

  @override
  void initState() {
    super.initState();
    _carregarTodosOsLivros();
    _controladorBusca.addListener(_filtrarLivros);
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    super.dispose();
  }

  Future<void> _carregarTodosOsLivros() async {
    // NOVO: Cria um rastreamento personalizado para esta operação.
    final trace = FirebasePerformance.instance.newTrace("busca_global_livros");
    await trace.start(); // Inicia a medição

    try {
      final livros = await _servicosFirebase.getTodosOsLivros();

      // Adiciona uma métrica personalizada ao rastreamento
      trace.setMetric("livros_encontrados", livros.length);

      if (mounted) {
        setState(() {
          _todosOsLivros = livros;
          _livrosExibidos = livros;
          _estaCarregando = false;
        });
      }
    } finally {
      // Garante que a medição sempre seja parada.
      await trace.stop();
    }
  }

  // ... (resto do arquivo build e outros métodos)
  void _filtrarLivros() {
    final consulta = _controladorBusca.text.toLowerCase();
    setState(() {
      if (consulta.isEmpty) {
        _livrosExibidos = _todosOsLivros;
      } else {
        _livrosExibidos = _todosOsLivros.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final titulo = (data['titulo'] as String? ?? doc.id).toLowerCase();
          final autor = (data['autor'] as String? ?? '').toLowerCase();
          return titulo.contains(consulta) || autor.contains(consulta);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar na Biblioteca'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _controladorBusca,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Digite o título ou autor...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _controladorBusca.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _controladorBusca.clear(),
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _estaCarregando
                ? const Center(child: CircularProgressIndicator())
                : _livrosExibidos.isEmpty
                ? const Center(child: Text('Nenhum resultado encontrado.'))
                : ListView.builder(
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

                return ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 80,
                    child: _servicosFirebase
                        .construirCapaLivro(caminhoCapa),
                  ),
                  title: Text(titulo),
                  subtitle: Text(autor ?? 'Autor desconhecido'),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}