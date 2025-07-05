import 'package:flutter/material.dart';
import '../servicos/servicos_firebase.dart';
import 'tela_livros_espirito.dart';

/// Tela que exibe uma lista de todos os autores espirituais.
class TelaListaAutoresEspirituais extends StatefulWidget {
  const TelaListaAutoresEspirituais({super.key});

  @override
  State<TelaListaAutoresEspirituais> createState() =>
      _TelaListaAutoresEspirituaisState();
}

class _TelaListaAutoresEspirituaisState
    extends State<TelaListaAutoresEspirituais> {
  final _servicosFirebase = ServicosFirebase();
  late final Future<List<String>> _espiritosFuture;

  @override
  void initState() {
    super.initState();
    _espiritosFuture = _servicosFirebase.getTodosAutoresEspirituais();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autores Espirituais'),
      ),
      body: FutureBuilder<List<String>>(
        future: _espiritosFuture,
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
                          TelaLivrosEspirito(spiritName: spiritName),
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
