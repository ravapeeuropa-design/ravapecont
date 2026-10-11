class DocumentLine {
  DocumentLine({
    required this.id,
    required this.description,
    required this.quantityMilliunits,
    required this.unitPriceCents,
    required this.taxRateBasisPoints,
    this.sourceUnitPriceCents,
    this.marginBasisPoints,
  }) {
    if (quantityMilliunits <= 0) {
      throw ArgumentError.value(
        quantityMilliunits,
        'quantityMilliunits',
        'Must be greater than zero.',
      );
    }
    if (unitPriceCents < 0) {
      throw ArgumentError.value(
        unitPriceCents,
        'unitPriceCents',
        'Must not be negative.',
      );
    }
    if (taxRateBasisPoints < 0) {
      throw ArgumentError.value(
        taxRateBasisPoints,
        'taxRateBasisPoints',
        'Must not be negative.',
      );
    }
    if (sourceUnitPriceCents != null && sourceUnitPriceCents! < 0) {
      throw ArgumentError.value(
        sourceUnitPriceCents,
        'sourceUnitPriceCents',
        'Must not be negative.',
      );
    }
    if (marginBasisPoints != null && marginBasisPoints! < 0) {
      throw ArgumentError.value(
        marginBasisPoints,
        'marginBasisPoints',
        'Must not be negative.',
      );
    }
  }

  final String id;
  final String description;
  final int quantityMilliunits;
  final int unitPriceCents;
  final int taxRateBasisPoints;
  final int? sourceUnitPriceCents;
  final int? marginBasisPoints;

  int get lineNetCents => (quantityMilliunits * unitPriceCents) ~/ 1000;

  DocumentLine copyWith({
    String? id,
    String? description,
    int? quantityMilliunits,
    int? unitPriceCents,
    int? taxRateBasisPoints,
    int? sourceUnitPriceCents,
    int? marginBasisPoints,
  }) {
    return DocumentLine(
      id: id ?? this.id,
      description: description ?? this.description,
      quantityMilliunits: quantityMilliunits ?? this.quantityMilliunits,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      taxRateBasisPoints: taxRateBasisPoints ?? this.taxRateBasisPoints,
      sourceUnitPriceCents: sourceUnitPriceCents ?? this.sourceUnitPriceCents,
      marginBasisPoints: marginBasisPoints ?? this.marginBasisPoints,
    );
  }
}
