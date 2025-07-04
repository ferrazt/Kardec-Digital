import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:kardec_digital/local_storage_helper.dart';
import 'package:path_provider/path_provider.dart';

class PDFViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  final String pdfPath;

  const PDFViewerScreen(
      {required this.url,
        required this.title,
        required this.pdfPath,
        super.key});

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? localPath;
  String? errorMessage;
  int? pages;
  bool isReady = false;
  int initialPage = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialPage();
    _downloadAndSavePDF();
  }

  Future<void> _loadInitialPage() async {
    final page = await LocalStorageHelper.getReadingPosition(widget.pdfPath);
    if (mounted) {
      setState(() {
        initialPage = page;
      });
    }
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
        toolbarHeight: 80,
        title: Text(
          widget.title,
          maxLines: 2,
          textAlign: TextAlign.center,
          softWrap: true,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: errorMessage != null
            ? Center(child: Text(errorMessage!))
            : localPath != null
            ? PDFView(
          filePath: localPath!,
          defaultPage: initialPage,
          autoSpacing: true,
          enableSwipe: true,
          swipeHorizontal: true,
          fitPolicy: FitPolicy.WIDTH,
          pageFling: true,
          onRender: (_pages) {
            setState(() {
              pages = _pages;
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