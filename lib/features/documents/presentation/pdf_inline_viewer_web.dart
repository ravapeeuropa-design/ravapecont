// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Visor embebido del PDF para web: convierte los bytes en una URL
/// `data:application/pdf;base64,...` y la muestra dentro de un `<iframe>`.
///
/// Se usa una URL base64 (y no una `blob:` temporal) para que editar, añadir o
/// eliminar líneas no invalide el documento: no hay ningún object URL que
/// revocar mientras el visor está montado.
class PdfInlineViewer extends StatefulWidget {
  const PdfInlineViewer({
    super.key,
    required this.bytes,
  });

  final Uint8List bytes;

  @override
  State<PdfInlineViewer> createState() => _PdfInlineViewerState();
}

class _PdfInlineViewerState extends State<PdfInlineViewer> {
  static final Set<String> _registeredViewTypes = <String>{};

  late String _viewType;
  late String _pdfDataUrl;

  @override
  void initState() {
    super.initState();
    _prepareViewer();
  }

  @override
  void didUpdateWidget(covariant PdfInlineViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.bytes != widget.bytes) {
      _prepareViewer();
    }
  }

  void _prepareViewer() {
    final bytes = widget.bytes;

    if (bytes.isEmpty) {
      _viewType = '';
      _pdfDataUrl = '';
      return;
    }

    _pdfDataUrl = 'data:application/pdf;base64,${base64Encode(bytes)}';
    _viewType = 'original-pdf-${bytes.length}-${_contentHash(bytes)}';

    _registerPdfView();
  }

  void _registerPdfView() {
    if (_pdfDataUrl.isEmpty || !_registeredViewTypes.add(_viewType)) {
      return;
    }

    final dataUrl = _pdfDataUrl;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        return html.IFrameElement()
          ..src = dataUrl
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..setAttribute('title', 'Factura original');
      },
    );
  }

  int _contentHash(Uint8List bytes) {
    // Muestreo estable del contenido para diferenciar PDFs sin recorrerlos
    // enteros: primeros y últimos bytes más la longitud.
    const sampleSize = 64;
    var hash = bytes.length;

    final head = bytes.length < sampleSize ? bytes.length : sampleSize;
    for (var i = 0; i < head; i++) {
      hash = 0x1fffffff & (hash * 31 + bytes[i]);
    }

    for (var i = bytes.length - head; i < bytes.length; i++) {
      if (i < 0) {
        continue;
      }
      hash = 0x1fffffff & (hash * 31 + bytes[i]);
    }

    return hash;
  }

  @override
  Widget build(BuildContext context) {
    if (_viewType.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    return HtmlElementView(
      key: ValueKey<String>(_viewType),
      viewType: _viewType,
    );
  }
}
