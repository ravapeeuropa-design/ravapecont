import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Fallback para plataformas sin navegador (Android, escritorio, iOS).
///
/// La vista embebida del PDF solo está disponible en la versión web; aquí se
/// muestra un mensaje y se invita a usar el texto extraído para revisar.
class PdfInlineViewer extends StatelessWidget {
  const PdfInlineViewer({
    super.key,
    required this.bytes,
  });

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'La vista previa embebida del PDF solo está disponible en la '
          'versión web. Usa el texto extraído para revisar los conceptos.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
