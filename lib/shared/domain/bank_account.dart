class BankAccount {
  const BankAccount({
    required this.id,
    required this.iban,
    required this.isDefault,
    this.alias,
    this.bankName,
    this.bic,
    this.accountHolder,
  });

  final String id;
  final String iban;
  final bool isDefault;
  final String? alias;
  final String? bankName;
  final String? bic;
  final String? accountHolder;

  static String normalizeIban(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }

  static String? validateIban(String? value) {
    final iban = normalizeIban(value ?? '');
    if (iban.isEmpty) {
      return 'Indica el IBAN.';
    }
    if (!RegExp(r'^[A-Z]{2}[0-9A-Z]{13,32}$').hasMatch(iban)) {
      return 'Indica un IBAN válido.';
    }
    if (iban.startsWith('ES') && iban.length != 24) {
      return 'Un IBAN español debe tener 24 caracteres.';
    }
    return null;
  }

  String get maskedIban {
    final normalized = normalizeIban(iban);
    if (normalized.length <= 8) {
      return normalized;
    }
    return '${normalized.substring(0, 4)} •••• •••• •••• '
        '${normalized.substring(normalized.length - 4)}';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'iban': normalizeIban(iban),
      'alias': alias,
      'bankName': bankName,
      'bic': bic,
      'accountHolder': accountHolder,
      'isDefault': isDefault,
    };
  }

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      id: map['id'] as String? ?? '',
      iban: normalizeIban(map['iban'] as String? ?? ''),
      alias: map['alias'] as String?,
      bankName: map['bankName'] as String?,
      bic: map['bic'] as String?,
      accountHolder: map['accountHolder'] as String?,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  BankAccount copyWith({
    String? id,
    String? iban,
    String? alias,
    String? bankName,
    String? bic,
    String? accountHolder,
    bool? isDefault,
  }) {
    return BankAccount(
      id: id ?? this.id,
      iban: iban ?? this.iban,
      alias: alias ?? this.alias,
      bankName: bankName ?? this.bankName,
      bic: bic ?? this.bic,
      accountHolder: accountHolder ?? this.accountHolder,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

List<BankAccount> normalizeBankAccounts(Iterable<BankAccount> accounts) {
  final values = accounts
      .map(
        (account) =>
            account.copyWith(iban: BankAccount.normalizeIban(account.iban)),
      )
      .toList(growable: false);
  if (values.isEmpty) {
    return const <BankAccount>[];
  }

  final defaultIndex = values.indexWhere((account) => account.isDefault);
  final selectedIndex = defaultIndex < 0 ? 0 : defaultIndex;
  return List<BankAccount>.unmodifiable([
    for (var index = 0; index < values.length; index++)
      values[index].copyWith(isDefault: index == selectedIndex),
  ]);
}
