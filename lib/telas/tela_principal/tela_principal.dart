import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../../servicos/servicos_firebase.dart';
import '../tela_busca_global.dart';
import '../tela_historico.dart';
import '../tela_lista_autores.dart';
import '../tela_lista_autores_espirtuais.dart';
import 'widgets/carrossel_livros.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  final ScrollController _scrollController = ScrollController();
  final ServicosFirebase _servicosFirebase = ServicosFirebase();
  final _crashlytics = FirebaseCrashlytics.instance;
  bool _showFab = false;
  Future<List<String>>? _bannersFuture;

  @override
  void initState() {
    super.initState();
    _crashlytics.setCustomKey("tela_atual", "TelaPrincipal");
    _scrollController.addListener(_scrollListener);
    _bannersFuture = _servicosFirebase.getBannerUrls();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels > 200) {
      if (!_showFab) setState(() => _showFab = true);
    } else {
      if (_showFab) setState(() => _showFab = false);
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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: false,
              stretch: true,
              expandedHeight: 180,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: _construirCarrosselDeBanners(),
                titlePadding: EdgeInsets.zero,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverList(
              delegate: SliverChildListDelegate([
                const CarrosselLivros(),
                const SizedBox(height: 20),
              ]),
            ),
          ],
        ),
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
        onPressed: _scrollToTop,
        tooltip: 'Voltar ao Topo',
        child: const Icon(Icons.arrow_upward),
      )
          : null,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Pesquisar',
              onPressed: () {
                _crashlytics.log("Navegando para TelaBuscaGlobal");
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TelaBuscaGlobal()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.menu_book),
              tooltip: 'Autores Mediúnicos',
              onPressed: () {
                _crashlytics.log("Navegando para TelaListaAutores");
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TelaListaAutores()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.groups_outlined),
              tooltip: 'Autores Espirituais',
              onPressed: () {
                _crashlytics.log("Navegando para TelaListaAutoresEspirituais");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TelaListaAutoresEspirituais()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Histórico',
              onPressed: () {
                _crashlytics.log("Navegando para TelaHistorico");
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TelaHistorico()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCarrosselDeBanners() {
    return FutureBuilder<List<String>>(
      future: _bannersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(color: Colors.white),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Icon(Icons.image_not_supported,
                color: Colors.grey, size: 50),
          );
        }

        final bannerUrls = snapshot.data!;

        return CarouselSlider.builder(
          itemCount: bannerUrls.length,
          itemBuilder: (context, index, realIndex) {
            final url = bannerUrls[index];
            return CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            );
          },
          options: CarouselOptions(
            height: 180,
            autoPlay: bannerUrls.length > 1,
            autoPlayInterval: const Duration(seconds: 4),
            viewportFraction: 1.0,
            enlargeCenterPage: false,
          ),
        );
      },
    );
  }
}
