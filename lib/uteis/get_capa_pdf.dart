import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';

final logger = Logger();

/// Retorna a URL pública para um arquivo no Storage (usada para PDFs e Capas)
Future<String> getDownloadUrl(String path) async {
  final sanitized = path.startsWith('/') ? path.substring(1) : path;
  logger.d('getDownloadUrl → $sanitized');
  final ref = FirebaseStorage.instance.ref().child(sanitized);
  return await ref.getDownloadURL();
}

Widget buildCoverWithCache(String coverPath) {
  if (coverPath.isEmpty) {
    return const Center(child: Icon(Icons.error, size: 50, color: Colors.red));
  }

  return FutureBuilder<String>(
    future: getDownloadUrl(coverPath),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(color: Colors.white),
        );
      }
      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
        logger.e('Erro ao obter URL da capa: ${snapshot.error}');
        return const Center(child: Icon(Icons.error, size: 50, color: Colors.red));
      }

      return CachedNetworkImage(
        imageUrl: snapshot.data!,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(color: Colors.white),
        ),
        errorWidget: (context, url, error) =>
        const Center(child: Icon(Icons.error)),
      );
    },
  );
}