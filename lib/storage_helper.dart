// storage_helper.dart
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'main.dart'; // para usar o mesmo `logger`

/// Retorna a URL pública para PDF (usada no onTap)
Future<String> getDownloadUrl(String path) async {
  final sanitized = path.startsWith('/') ? path.substring(1) : path;
  logger.d('getDownloadUrl → $sanitized');
  final ref = FirebaseStorage.instance.ref().child(sanitized);
  return await ref.getDownloadURL();
}

/// Baixa até [maxSize] bytes e retorna o conteúdo da imagem
Future<Uint8List> getCoverBytes(String path) async {
  final sanitized = path.startsWith('/') ? path.substring(1) : path;
  logger.d('getCoverBytes → $sanitized');
  final ref = FirebaseStorage.instance.ref().child(sanitized);
  const maxSize = 2 * 1024 * 1024; // 2MB
  final data = await ref.getData(maxSize);
  if (data == null) {
    throw FirebaseException(
      plugin: 'firebase_storage',
      message: 'Não foi possível baixar bytes de $path',
    );
  }
  return data;
}

/// Widget que exibe a capa pegando os bytes (escapa do CORS no Web)
Widget buildCoverFromBytes(String coverPath) {
  return FutureBuilder<Uint8List>(
    future: getCoverBytes(coverPath),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snap.hasError || snap.data == null) {
        logger.e('Erro buildCoverFromBytes: ${snap.error}');
        return const Center(child: Icon(Icons.error, size: 50, color: Colors.red));
      }
      return Image.memory(
        snap.data!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    },
  );
}
