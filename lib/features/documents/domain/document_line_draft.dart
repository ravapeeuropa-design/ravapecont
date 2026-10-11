class DocumentLineDraft {
  const DocumentLineDraft({
    required this.id,
    required this.reference,
    required this.article,
    required this.quantity,
    required this.sourceUnitPrice,
    required this.taxRate,
    this.usesManualPrice = false,
  });

  final String id;
  final String reference;
  final String article;
  final double quantity;
  final double sourceUnitPrice;
  final int taxRate;
  final bool usesManualPrice;

  double unitPriceWithMargin(int marginPercent) {
    return _roundToCents(
      sourceUnitPrice * (1 + marginPercent / 100),
    );
  }

  double baseTotal(int marginPercent) {
    return _roundToCents(
      quantity * unitPriceWithMargin(marginPercent),
    );
  }

  double taxTotal(int marginPercent) {
    return _roundToCents(
      baseTotal(marginPercent) * taxRate / 100,
    );
  }

  double total(int marginPercent) {
    return _roundToCents(
      baseTotal(marginPercent) + taxTotal(marginPercent),
    );
  }

  bool get isValid {
    return article.trim().isNotEmpty &&
        quantity > 0 &&
        sourceUnitPrice >= 0 &&
        const <int>{0, 4, 10, 21}.contains(taxRate);
  }

  DocumentLineDraft copyWith({
    String? id,
    String? reference,
    String? article,
    double? quantity,
    double? sourceUnitPrice,
    int? taxRate,
    bool? usesManualPrice,
  }) {
    return DocumentLineDraft(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      article: article ?? this.article,
      quantity: quantity ?? this.quantity,
      sourceUnitPrice: sourceUnitPrice ?? this.sourceUnitPrice,
      taxRate: taxRate ?? this.taxRate,
      usesManualPrice: usesManualPrice ?? this.usesManualPrice,
    );
  }

  static double _roundToCents(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
