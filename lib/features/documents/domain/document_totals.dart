class DocumentTotals {
  DocumentTotals({
    required this.netCents,
    required this.taxCents,
    required this.totalCents,
  }) {
    if (totalCents != netCents + taxCents) {
      throw ArgumentError(
        'totalCents must equal netCents + taxCents.',
      );
    }
  }

  final int netCents;
  final int taxCents;
  final int totalCents;

  DocumentTotals copyWith({
    int? netCents,
    int? taxCents,
    int? totalCents,
  }) {
    return DocumentTotals(
      netCents: netCents ?? this.netCents,
      taxCents: taxCents ?? this.taxCents,
      totalCents: totalCents ?? this.totalCents,
    );
  }
}
