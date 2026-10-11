import 'package:flutter_test/flutter_test.dart';
import 'package:ravapecont/shared/domain/bank_account.dart';

void main() {
  test('BankAccount round-trips through Firestore map', () {
    const account = BankAccount(
      id: 'account-1',
      iban: 'ES9221002526120210073652',
      alias: 'Cuenta principal',
      bankName: 'La Caixa',
      bic: 'CAIXESBBXXX',
      accountHolder: 'RAVAPE EUROPA S.L.',
      isDefault: true,
    );

    final restored = BankAccount.fromMap(account.toMap());

    expect(restored.id, account.id);
    expect(restored.iban, account.iban);
    expect(restored.alias, account.alias);
    expect(restored.bankName, account.bankName);
    expect(restored.bic, account.bic);
    expect(restored.accountHolder, account.accountHolder);
    expect(restored.isDefault, isTrue);
  });

  test('normalizes and masks a Spanish IBAN', () {
    const account = BankAccount(
      id: 'account-1',
      iban: 'es92 2100 2526 1202 1007 3652',
      isDefault: true,
    );

    expect(account.toMap()['iban'], 'ES9221002526120210073652');
    expect(account.maskedIban, 'ES92 •••• •••• •••• 3652');
    expect(BankAccount.validateIban(account.iban), isNull);
  });

  test('requires exactly 24 characters for a Spanish IBAN', () {
    expect(BankAccount.validateIban('ES92 2100'), 'Indica un IBAN válido.');
    expect(
      BankAccount.validateIban('ES922100252612021007365200'),
      'Un IBAN español debe tener 24 caracteres.',
    );
  });

  test('keeps exactly one default account', () {
    final normalized = normalizeBankAccounts(const [
      BankAccount(
        id: 'first',
        iban: 'ES9221002526120210073652',
        isDefault: true,
      ),
      BankAccount(
        id: 'second',
        iban: 'ES9121002526120210073653',
        isDefault: true,
      ),
    ]);

    expect(normalized.where((account) => account.isDefault).length, 1);
    expect(normalized.first.isDefault, isTrue);
  });
}
