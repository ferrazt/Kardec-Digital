import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart'; // Importa o Performance
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../servicos/servicos_firebase.dart';
import '../uteis/armazenamento_local.dart';

class TelaLeitorPdf extends StatefulWidget {
  // ... (construtor e parâmetros existentes)
  final String pdfPath;
  final String title;
  final String? autor;
  final String? espirito;

  const TelaLeitorPdf({
    required this.pdfPath,
    required this.title,
    this.autor,
    this.espirito,
    super.key,
  });

  @override
  State<TelaLeitorPdf> createState() => _TelaLeitorPdfState();
}

class _TelaLeitorPdfState extends State<TelaLeitorPdf> {
  final _servicosFirebase = ServicosFirebase();
  final _crashlytics = FirebaseCrashlytics.instance;
  // NOVO: Instancia o Performance
  final _performance = FirebasePerformance.instance;
  String? _caminhoLocal;
  String? _mensagemErro;
  int _paginaInicial = 0;

  @override
  void initState() {
    super.initState();
    _servicosFirebase.logarAberturaLivro(
      titulo: widget.title,
      autor: widget.autor,
      espirito: widget.espirito, pdfPath: widget.pdfPath,
    );
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    _paginaInicial = await LocalStorageHelper.getReadingPosition(widget.pdfPath);
    await _baixarESalvarPDF();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _baixarESalvarPDF() async {
    // NOVO: Cria um rastreamento de requisição de rede personalizado.
    HttpMetric? metric;
    try {
      final urlString = await _servicosFirebase.getUrlDownload(widget.pdfPath);
      if (urlString.isEmpty) {
        throw Exception('URL do PDF não encontrada no Storage.');
      }

      final url = Uri.parse(urlString);
      metric = _performance.newHttpMetric(url.toString(), HttpMethod.Get);
      await metric.start(); // Inicia a medição

      final response = await http.get(url);

      // Registra os dados da resposta na métrica
      metric.httpResponseCode = response.statusCode;
      metric.responsePayloadSize = response.contentLength;

      if (response.statusCode != 200) {
        throw Exception('Erro de rede ao baixar PDF: ${response.statusCode}');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.pdfPath.hashCode}.pdf');
      await file.writeAsBytes(response.bodyBytes);
      if (mounted) {
        setState(() {
          _caminhoLocal = file.path;
          _mensagemErro = null;
        });
      }
    } catch (e, s) {
      _crashlytics.recordError(e, s,
          reason: 'Falha ao baixar e salvar PDF: ${widget.pdfPath}');
      if (mounted) {
        setState(() {
          _mensagemErro = 'Erro ao carregar PDF: $e';
        });
      }
    } finally {
      // Garante que a medição sempre seja parada, mesmo em caso de erro.
      await metric?.stop();
    }
  }

  // ... (resto do arquivo build e outros métodos)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Text(widget.title, maxLines: 2, textAlign: TextAlign.left),
      ),
      body: SafeArea(
        top: false,
        child: _mensagemErro != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_mensagemErro!, textAlign: TextAlign.center),
          ),
        )
            : _caminhoLocal != null
            ? PDFView(
          filePath: _caminhoLocal!,
          defaultPage: _paginaInicial,
          autoSpacing: true,
          enableSwipe: true,
          swipeHorizontal: false,
          fitPolicy: FitPolicy.WIDTH,
          pageFling: true,
          onRender: (pages) {},
          onError: (error) {
            _crashlytics.recordError(error, StackTrace.current,
                reason: "Erro no widget PDFView");
            setState(() {
              _mensagemErro = 'Erro ao exibir PDF: $error';
            });
          },
          onPageError: (page, error) {
            _crashlytics.recordError(error, StackTrace.current,
                reason:
                "Erro na página $page do PDF ${widget.pdfPath}");
          },
          onPageChanged: (page, total) {
            if (page != null) {
              LocalStorageHelper.saveReadingPosition(
                  widget.pdfPath, page);
            }
          },
        )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}