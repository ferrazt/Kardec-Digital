import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; // Importa o Analytics
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ServicosFirebase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  // NOVO: Instancia o Firebase Analytics
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// NOVO: Método centralizado que incrementa o contador e registra o evento no Analytics.
  Future<void> logarAberturaLivro({
    required String pdfPath,
    required String titulo,
    String? autor,
    String? espirito,
  }) async {
    // 1. Incrementa o contador de aberturas no Firestore
    try {
      final querySnapshot = await _db
          .collection('pdfs')
          .where('pdfPath', isEqualTo: pdfPath)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await _db
            .collection('pdfs')
            .doc(docId)
            .update({'open_count': FieldValue.increment(1)});
      }
    } catch (e, s) {
      _crashlytics.recordError(e, s,
          reason: 'Falha ao incrementar contador para: $pdfPath');
    }

    // 2. Registra o evento no Google Analytics
    try {
      // O Analytics tem um limite de 100 caracteres para valores de parâmetros.
      // Garantimos que o título não exceda isso.
      final tituloSeguro = titulo.length > 100 ? titulo.substring(0, 100) : titulo;

      await _analytics.logEvent(
        name: 'abrir_livro',
        parameters: {
          'titulo_livro': tituloSeguro,
          'nome_autor': ?autor,
          'nome_espirito': ?espirito,
        },
      );
      _crashlytics.log('Evento Analytics "abrir_livro" registrado para: $titulo');
    } catch (e, s) {
      _crashlytics.recordError(e, s, reason: 'Falha ao registrar evento no Analytics');
    }
  }

  // --- O restante dos seus métodos continua aqui ---

  Stream<QuerySnapshot> getLivrosStream() {
    return _db.collection('pdfs').snapshots();
  }

  Future<List<String>> getTodosAutores() async {
    try {
      final querySnapshot = await _db.collection('pdfs').get();
      final Set<String> autores = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('autor')) {
          autores.add(data['autor'] as String);
        }
      }
      return autores.toList()..sort();
    } catch (e, s) {
      _crashlytics.recordError(e, s, reason: 'Falha ao buscar lista de autores');
      return [];
    }
  }

  Future<List<String>> getTodosAutoresEspirituais() async {
    try {
      final querySnapshot = await _db.collection('pdfs').get();
      final Set<String> espiritos = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('espirito') &&
            data['espirito'] != null &&
            (data['espirito'] as String).trim().isNotEmpty) {
          espiritos.add(data['espirito'] as String);
        }
      }
      return espiritos.toList()..sort();
    } catch (e, s) {
      _crashlytics.recordError(e, s,
          reason: 'Falha ao buscar lista de autores espirituais');
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot>> getLivrosPorAutor(String autor) async {
    try {
      final querySnapshot =
      await _db.collection('pdfs').where('autor', isEqualTo: autor).get();
      final livros = querySnapshot.docs;
      livros.sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        return (aData['titulo'] ?? a.id).compareTo(bData['titulo'] ?? b.id);
      });
      return livros;
    } catch (e, s) {
      _crashlytics.recordError(e, s,
          reason: 'Falha ao buscar livros do autor: $autor');
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot>> getLivrosPorEspirito(
      String nomeEspirito) async {
    try {
      final querySnapshot = await _db
          .collection('pdfs')
          .where('espirito', isEqualTo: nomeEspirito)
          .get();
      final livros = querySnapshot.docs;
      livros.sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        return (aData['titulo'] ?? a.id).compareTo(bData['titulo'] ?? b.id);
      });
      return livros;
    } catch (e, s) {
      _crashlytics.recordError(e, s,
          reason: 'Falha ao buscar livros do espírito: $nomeEspirito');
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot>> getTodosOsLivros() async {
    try {
      final querySnapshot = await _db.collection('pdfs').get();
      return querySnapshot.docs;
    } catch (e, s) {
      _crashlytics.recordError(e, s,
          reason: 'Falha ao buscar todos os livros para a busca global');
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot>> getDetalhesDoHistorico(
      List<String> caminhos) async {
    try {
      if (caminhos.isEmpty) return [];
      final querySnapshot =
      await _db.collection('pdfs').where('pdfPath', whereIn: caminhos).get();
      final docsMap = {
        for (var doc in querySnapshot.docs) doc.data()['pdfPath']: doc
      };
      return caminhos
          .map((path) => docsMap[path])
          .where((doc) => doc != null)
          .cast<QueryDocumentSnapshot<Map<String, dynamic>>>()
          .toList();
    } catch (e, s) {
      _crashlytics.recordError(e, s,
          reason: 'Falha ao buscar detalhes do histórico');
      return [];
    }
  }

  Future<String> getUrlDownload(String caminhoNoStorage) async {
    try {
      if (caminhoNoStorage.isEmpty) return '';
      return await _storage.ref(caminhoNoStorage).getDownloadURL();
    } catch (e, s) {
      _crashlytics.recordError(e, s,
          reason: 'Falha ao obter URL de download para: $caminhoNoStorage');
      return '';
    }
  }

  Future<List<String>> getBannerUrls() async {
    try {
      final ListResult result = await _storage.ref('banner').listAll();
      final List<String> urls = [];
      for (final Reference ref in result.items) {
        final String url = await ref.getDownloadURL();
        urls.add(url);
      }
      return urls;
    } catch (e, s) {
      _crashlytics.recordError(e, s, reason: "Falha ao buscar banners");
      return [];
    }
  }

  Widget construirCapaLivro(String? caminhoCapa) {
    if (caminhoCapa == null || caminhoCapa.isEmpty) {
      return const Icon(Icons.book, size: 50, color: Colors.grey);
    }
    return FutureBuilder<String>(
      future: getUrlDownload(caminhoCapa),
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
          fit: BoxFit.contain,
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
