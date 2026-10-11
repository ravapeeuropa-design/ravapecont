import 'document_line.dart';
import 'document_totals.dart';

class DocumentCalculator {
  const DocumentCalculator();

  DocumentLine normalizeLine(DocumentLine line) {
    return line.copyWith(
      unitPriceCents: _roundedProduct(
        line.sourceUnitPriceCents ?? line.unitPriceCents,
        10000 + (line.marginBasisPoints ?? 0),
        10000,
      ),
    );
  }

  DocumentTotals calculate(Iterable<DocumentLine> lines) {
    var netCents = 0;
    var taxCents = 0;

    for (final line in lines) {
      final normalizedLine = normalizeLine(line);
      netCents += normalizedLine.lineNetCents;
      taxCents += _roundedProduct(
        normalizedLine.lineNetCents,
        normalizedLine.taxRateBasisPoints,
        10000,
      );
    }

    return DocumentTotals(
      netCents: netCents,
      taxCents: taxCents,
      totalCents: netCents + taxCents,
    );
  }

  int _roundedProduct(int value, int numerator, int denominator) {
    final product = value * numerator;
    if (product >= 0) {
      return (product + (denominator ~/ 2)) ~/ denominator;
    }
    return -(((-product) + (denominator ~/ 2)) ~/ denominator);
  }
}
