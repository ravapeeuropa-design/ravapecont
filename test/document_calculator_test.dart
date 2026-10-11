import 'package:flutter_test/flutter_test.dart';
import 'package:ravapecont/features/documents/domain/document_calculator.dart';
import 'package:ravapecont/features/documents/domain/document_line.dart';

void main() {
  const calculator = DocumentCalculator();

  test('calcula base, IVA y total con redondeo determinista', () {
    final lines = [
      DocumentLine(
        id: '1',
        description: 'Línea 1',
        quantityMilliunits: 1500,
        unitPriceCents: 2000,
        taxRateBasisPoints: 2100,
      ),
      DocumentLine(
        id: '2',
        description: 'Línea 2',
        quantityMilliunits: 333,
        unitPriceCents: 1999,
        taxRateBasisPoints: 1000,
      ),
    ];

    final totals = calculator.calculate(lines);

    expect(totals.netCents, 3665);
    expect(totals.taxCents, 697);
    expect(totals.totalCents, 4362);
  });

  test('aplica margen porcentual en puntos básicos antes de calcular', () {
    final line = DocumentLine(
      id: '1',
      description: 'Línea',
      quantityMilliunits: 1000,
      unitPriceCents: 1000,
      taxRateBasisPoints: 2100,
      sourceUnitPriceCents: 800,
      marginBasisPoints: 2500,
    );

    final normalized = calculator.normalizeLine(line);
    final totals = calculator.calculate([line]);

    expect(normalized.unitPriceCents, 1000);
    expect(totals.netCents, 1000);
    expect(totals.taxCents, 210);
    expect(totals.totalCents, 1210);
  });
}
