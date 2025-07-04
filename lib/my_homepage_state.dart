import 'package:flutter/material.dart';
import 'package:kardec_digital/authors_list_screen.dart';
import 'package:kardec_digital/global_search_screen.dart';
import 'package:kardec_digital/spiritual_authors_list_screen.dart';
import 'pdf_grid.dart';
import 'package:kardec_digital/history_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels > 200) {
      if (!_showFab) {
        setState(() {
          _showFab = true;
        });
      }
    } else {
      if (_showFab) {
        setState(() {
          _showFab = false;
        });
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar.large(
            leading: null,
            automaticallyImplyLeading: false,
            pinned: false,
            stretch: true,
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(
                'assets/images/banner.jpg',
                fit: BoxFit.cover,
              ),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverList(
            delegate: SliverChildListDelegate([
              const NetflixStylePDFList(),
              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),

      floatingActionButton: _showFab
          ? FloatingActionButton(
        onPressed: _scrollToTop,
        tooltip: 'Voltar ao Topo',
        child: const Icon(Icons.arrow_upward),
      )
          : null,

      // LOCALIZAÇÃO ALTERADA: Agora o botão ficará na lateral direita (end = final da tela).
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: BottomAppBar(
        child: Row(
          // MUDANÇA: De 'spaceBetween' para 'spaceAround' para distribuir 3 itens
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // Botão 1: Autores Mediúnicos
            IconButton(
              icon: const Icon(Icons.menu_book),
              tooltip: 'Ver autores mediúnicos',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthorsListScreen()),
                );
              },
            ),

            // NOVO BOTÃO: Autores Espirituais
            IconButton(
              icon: const Icon(Icons.groups_outlined),
              tooltip: 'Ver autores espirituais',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SpiritualAuthorsListScreen()),
                );
              },
            ),

            // Botão 3: Pesquisa
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Pesquisar na biblioteca',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
                );
              },
            ),

            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Histórico de Leitura',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}