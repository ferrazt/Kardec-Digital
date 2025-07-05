import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../servicos/servicos_firebase.dart';
import '../uteis/armazenamento_local.dart';
import 'tela_leitor_pdf.dart';

class TelaHistorico extends StatefulWidget {
  const TelaHistorico({super.key});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  final _servicosFirebase = ServicosFirebase();
  late Future<List<QueryDocumentSnapshot>> _detalhesHistoricoFuture;

  @override
  void initState() {
    super.initState();
    _carregarDetalhesDoHistorico();
  }

  Future<void> _carregarDetalhesDoHistorico() async {
    final caminhos = await LocalStorageHelper.getHistory();
    if (mounted) {
      setState(() {
        _detalhesHistoricoFuture =
            _servicosFirebase.getDetalhesDoHistorico(caminhos);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Leitura'),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _detalhesHistoricoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Erro ao carregar histórico: ${snapshot.error}'));
          }
          final livrosHistorico = snapshot.data ?? [];
          if (livrosHistorico.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum livro no seu histórico ainda.\nComece a ler para registrar!',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: livrosHistorico.length,
            itemBuilder: (context, index) {
              final doc = livrosHistorico[index];
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
                  child: _servicosFirebase.construirCapaLivro(caminhoCapa),
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
                  ).then((_) {
                    _carregarDetalhesDoHistorico();
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
