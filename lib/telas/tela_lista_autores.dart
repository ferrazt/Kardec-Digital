import 'package:flutter/material.dart';
// 1. Importa a nova classe de serviços que centraliza a lógica do Firebase.
import '../servicos/servicos_firebase.dart';
// 2. Importa a tela que mostrará os livros do autor, usando o novo caminho.
import 'tela_livros_autor.dart';

/// Tela que exibe uma lista de todos os autores (psicógrafos)
/// em ordem alfabética.
class TelaListaAutores extends StatefulWidget {
  const TelaListaAutores({super.key});

  @override
  State<TelaListaAutores> createState() => _TelaListaAutoresState();
}

class _TelaListaAutoresState extends State<TelaListaAutores> {
  final ServicosFirebase _servicosFirebase = ServicosFirebase();
  late final Future<List<String>> _autoresFuture;

  @override
  void initState() {
    super.initState();
    _autoresFuture = _servicosFirebase.getTodosAutores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Psicografado por:'),
      ),
      // 6. O FutureBuilder continua o mesmo, pois ele já estava
      // corretamente separado da lógica de busca de dados.
      body: FutureBuilder<List<String>>(
        future: _autoresFuture,
        builder: (context, snapshot) {
          // Enquanto os dados estão carregando, mostra um indicador de progresso.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Se ocorreu um erro, exibe uma mensagem.
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Erro ao carregar autores.'));
          }
          // Se a lista de autores estiver vazia, informa o usuário.
          final autores = snapshot.data!;
          if (autores.isEmpty) {
            return const Center(child: Text('Nenhum autor encontrado.'));
          }

          // Se tudo deu certo, constrói a lista de autores.
          return ListView.separated(
            itemCount: autores.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final autor = autores[index];
              return ListTile(
                title: Text(autor),
                leading: const Icon(Icons.person_outline),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Ao tocar, navega para a tela de livros do autor,
                  // que também foi movida e renomeada.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TelaLivrosAutor(autor: autor),
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
