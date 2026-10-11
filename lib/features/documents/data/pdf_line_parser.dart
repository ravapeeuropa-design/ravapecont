import '../domain/document_line_draft.dart';

class PdfLineParser {
  const PdfLineParser();

  List<DocumentLineDraft> parse(
    String text, {
    required String Function() createId,
  }) {
    final lines = <DocumentLineDraft>[];

    for (final rawLine in text.split(RegExp(r'\r?\n'))) {
      final line = _normalizeWhitespace(rawLine);

      if (!_looksLikeCandidateLine(line)) {
        continue;
      }

      final parsed = _tryParseLine(
        line,
        createId: createId,
      );

      if (parsed != null) {
        lines.add(parsed);
      }
    }

    return lines;
  }

  bool _looksLikeCandidateLine(String line) {
    if (line.length < 8) {
      return false;
    }

    final normalized = line.toLowerCase();

    const ignoredFragments = <String>[
      'factura',
      'proforma',
      'albarán',
      'albaran',
      'fecha',
      'cliente',
      'proveedor',
      'emisor',
      'destinatario',
      'nif',
      'cif',
      'vat',
      'subtotal',
      'base imponible',
      'importe total',
      'total factura',
      'total iva',
      'total operación',
      'total operacion',
      'forma de pago',
      'iban',
      'cuenta',
      'banco',
      'descuento',
      'observaciones',
      'vencimiento',
      'dirección',
      'direccion',
      'teléfono',
      'telefono',
      'email',
      'www.',
      '@',
      'euros',
      'importe neto',
      'recargo',
    ];

    if (ignoredFragments.any(normalized.contains)) {
      return false;
    }

    final moneyValues = _extractMoneyValues(line);

    // Exigimos al menos dos importes monetarios: precio unitario e importe.
    if (moneyValues.length < 2) {
      return false;
    }

    // Evita tratar líneas formadas sólo por códigos, fechas o importes.
    final textWithoutNumbers = line
        .replaceAll(_numberPattern, ' ')
        .replaceAll(_currencyPattern, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return textWithoutNumbers.length >= 3 &&
        RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(textWithoutNumbers);
  }

  DocumentLineDraft? _tryParseLine(
    String line, {
    required String Function() createId,
  }) {
    final tokens = _extractNumericTokens(line);

    if (tokens.length < 3) {
      return null;
    }

    final moneyTokens = tokens.where((token) => token.isMoney).toList();

    if (moneyTokens.length < 2) {
      return null;
    }

    final possibleUnitPrice = moneyTokens[moneyTokens.length - 2].value;
    final possibleLineTotal = moneyTokens.last.value;

    if (!_isReasonablePrice(possibleUnitPrice) ||
        !_isReasonablePrice(possibleLineTotal)) {
      return null;
    }

    final quantity = _findVerifiedQuantity(
      tokens: tokens,
      unitPrice: possibleUnitPrice,
      lineTotal: possibleLineTotal,
    );

    if (quantity == null) {
      return null;
    }

    final article = _extractArticle(line);

    if (article.length < 3) {
      return null;
    }

    final reference = _extractReference(line);

    return DocumentLineDraft(
      id: createId(),
      reference: reference,
      article: article,
      quantity: quantity,
      sourceUnitPrice: possibleUnitPrice,
      taxRate: _detectTaxRate(line) ?? 21,
    );
  }

  double? _findVerifiedQuantity({
    required List<_NumericToken> tokens,
    required double unitPrice,
    required double lineTotal,
  }) {
    final expectedQuantity = lineTotal / unitPrice;

    if (!_isReasonableQuantity(expectedQuantity)) {
      return null;
    }

    for (final token in tokens) {
      final candidate = token.value;

      if (!_isReasonableQuantity(candidate)) {
        continue;
      }

      if (_approximatelyEquals(
        candidate * unitPrice,
        lineTotal,
      )) {
        return candidate;
      }
    }

    // Algunos extractores no separan la cantidad correctamente. Sólo se acepta
    // la cantidad calculada si está muy cerca de un entero o de 0,5 / 0,25.
    if (_isSimpleQuantity(expectedQuantity) &&
        _approximatelyEquals(
          expectedQuantity * unitPrice,
          lineTotal,
        )) {
      return _roundQuantity(expectedQuantity);
    }

    return null;
  }

  bool _isReasonableQuantity(double value) {
    return value > 0 && value <= 9999;
  }

  bool _isReasonablePrice(double value) {
    return value >= 0 && value <= 100000;
  }

  bool _approximatelyEquals(double actual, double expected) {
    final difference = (actual - expected).abs();

    // Tolera redondeos de céntimos y una desviación relativa pequeña.
    final tolerance = expected.abs() * 0.015 + 0.03;

    return difference <= tolerance;
  }

  bool _isSimpleQuantity(double value) {
    final rounded = _roundQuantity(value);
    return (value - rounded).abs() <= 0.01;
  }

  double _roundQuantity(double value) {
    return (value * 1000).roundToDouble() / 1000;
  }

  String _extractArticle(String line) {
    var article = line;

    article = article.replaceAll(_currencyPattern, ' ');
    article = article.replaceAll(_numberPattern, ' ');
    article = article.replaceAll(
      RegExp(
        r'\b(?:ud|uds|unidad|unidades|kg|kgs|g|gr|l|lt|lts|m|mt|mts|caja|cajas|pack|packs)\b',
        caseSensitive: false,
      ),
      ' ',
    );

    article = article.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Elimina signos de puntuación sueltos que queden tras retirar números.
    article = article
        .replaceAll(RegExp(r'^[,;:./\-–—]+'), '')
        .replaceAll(RegExp(r'[,;:./\-–—]+$'), '')
        .trim();

    return article;
  }

  String _extractReference(String line) {
    final match = RegExp(
      r'\b(?:ref(?:erencia)?\.?\s*[:\-]?\s*)?([A-Za-z]{1,5}[-/]?\d{3,12})\b',
      caseSensitive: false,
    ).firstMatch(line);

    if (match == null) {
      return '';
    }

    return match.group(1) ?? '';
  }

  int? _detectTaxRate(String line) {
    final match = RegExp(
      r'(?:^|[\s|;])(?:iva\s*)?(21|10|4|0)\s*%',
      caseSensitive: false,
    ).firstMatch(line);

    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1)!);
  }

  List<double> _extractMoneyValues(String line) {
    return _extractNumericTokens(line)
        .where((token) => token.isMoney)
        .map((token) => token.value)
        .toList(growable: false);
  }

  List<_NumericToken> _extractNumericTokens(String line) {
    final matches = _numericTokenPattern.allMatches(line);

    return matches
        .map((match) {
          final rawValue = match.group(1)!;
          final hasCurrency = match.group(2) != null;
          final value = _parseLocalizedNumber(rawValue);

          if (value == null) {
            return null;
          }

          final hasDecimals = RegExp(r'[.,]\d{1,2}$').hasMatch(rawValue);

          return _NumericToken(
            rawValue: rawValue,
            value: value,
            isMoney: hasCurrency || hasDecimals,
          );
        })
        .whereType<_NumericToken>()
        .toList(growable: false);
  }

  double? _parseLocalizedNumber(String rawValue) {
    var value = rawValue.trim();

    if (value.isEmpty) {
      return null;
    }

    final lastComma = value.lastIndexOf(',');
    final lastDot = value.lastIndexOf('.');

    if (lastComma >= 0 && lastDot >= 0) {
      if (lastComma > lastDot) {
        value = value.replaceAll('.', '').replaceAll(',', '.');
      } else {
        value = value.replaceAll(',', '');
      }

      return double.tryParse(value);
    }

    if (lastComma >= 0) {
      final decimals = value.length - lastComma - 1;

      if (decimals == 1 || decimals == 2) {
        value = value.replaceAll('.', '').replaceAll(',', '.');
      } else {
        value = value.replaceAll(',', '');
      }

      return double.tryParse(value);
    }

    if (lastDot >= 0) {
      final decimals = value.length - lastDot - 1;

      if (decimals == 1 || decimals == 2) {
        value = value.replaceAll(',', '');
      } else {
        value = value.replaceAll('.', '');
      }

      return double.tryParse(value);
    }

    return double.tryParse(value);
  }

  String _normalizeWhitespace(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static final RegExp _numberPattern = RegExp(
    r'\b\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?\b',
  );

  static final RegExp _currencyPattern = RegExp(
    r'(?:€|EUR|EUROS|Ôé¼)',
    caseSensitive: false,
  );

  static final RegExp _numericTokenPattern = RegExp(
    r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?)(?:\s*(€|EUR|EUROS|Ôé¼))?',
    caseSensitive: false,
  );
}

class _NumericToken {
  const _NumericToken({
    required this.rawValue,
    required this.value,
    required this.isMoney,
  });

  final String rawValue;
  final double value;
  final bool isMoney;
}
