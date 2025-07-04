import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PDFViewerScreen extends StatefulWidget {
  final String url;
  final String title; // Novo parâmetro para o título do livro

  const PDFViewerScreen({required this.url, required this.title, super.key}); // Adicione o título como parâmetro requerido

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? localPath;
  String? errorMessage;
  int? pages;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePDF();
  }

  Future<void> _downloadAndSavePDF() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode != 200) {
        throw Exception('Erro ao baixar PDF: ${response.statusCode}');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp.pdf');
      await file.writeAsBytes(response.bodyBytes);
      setState(() {
        localPath = file.path;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao carregar PDF: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // Use o título do livro na AppBar
      ),
      body: SafeArea(
        child: errorMessage != null
            ? Center(child: Text(errorMessage!))
            : localPath != null
            ? PDFView(
          filePath: localPath!,
          autoSpacing: true,
          enableSwipe: true,
          swipeHorizontal: true,
          fitPolicy: FitPolicy.WIDTH,
          pageFling: true,
          onRender: (pages) {
            setState(() {
              pages = pages;
              isReady = true;
            });
          },
          onError: (error) {
            setState(() {
              errorMessage = 'Erro ao exibir PDF: $error';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage!)),
            );
          },
          onPageError: (page, error) {
            setState(() {
              errorMessage = 'Erro na página $page: $error';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage!)),
            );
          },
          onPageChanged: (page, total) {
            setState(() {
              // Atualiza a página atual
            });
          },
        )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}