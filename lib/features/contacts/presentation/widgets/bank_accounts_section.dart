import 'package:flutter/material.dart';

import '../../../../shared/domain/bank_account.dart';

class EditableBankAccount {
  EditableBankAccount({
    required this.id,
    required this.ibanController,
    required this.aliasController,
    required this.bankNameController,
    required this.bicController,
    required this.holderController,
    this.isDefault = false,
  });

  factory EditableBankAccount.fromBankAccount(BankAccount account) {
    return EditableBankAccount(
      id: account.id,
      ibanController: TextEditingController(text: account.iban),
      aliasController: TextEditingController(text: account.alias ?? ''),
      bankNameController: TextEditingController(text: account.bankName ?? ''),
      bicController: TextEditingController(text: account.bic ?? ''),
      holderController: TextEditingController(
        text: account.accountHolder ?? '',
      ),
      isDefault: account.isDefault,
    );
  }

  final String id;
  final TextEditingController ibanController;
  final TextEditingController aliasController;
  final TextEditingController bankNameController;
  final TextEditingController bicController;
  final TextEditingController holderController;
  bool isDefault;

  BankAccount toBankAccount() {
    return BankAccount(
      id: id,
      iban: BankAccount.normalizeIban(ibanController.text),
      alias: _nullable(aliasController.text),
      bankName: _nullable(bankNameController.text),
      bic: _nullable(bicController.text)?.toUpperCase(),
      accountHolder: _nullable(holderController.text),
      isDefault: isDefault,
    );
  }

  void dispose() {
    ibanController.dispose();
    aliasController.dispose();
    bankNameController.dispose();
    bicController.dispose();
    holderController.dispose();
  }

  static String? _nullable(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

class BankAccountsSection extends StatelessWidget {
  const BankAccountsSection({
    super.key,
    required this.accounts,
    required this.onAdd,
    required this.onRemove,
    required this.onSetDefault,
    this.enabled = true,
  });

  final List<EditableBankAccount> accounts;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onSetDefault;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cuentas bancarias',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: enabled ? onAdd : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir cuenta'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (accounts.isEmpty)
              const Text('No hay cuentas bancarias añadidas.'),
            ...List.generate(accounts.length, (index) {
              final account = accounts[index];
              return Padding(
                key: ValueKey(account.id),
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Cuenta ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          tooltip: account.isDefault
                              ? 'Cuenta principal'
                              : 'Marcar como principal',
                          onPressed: enabled && !account.isDefault
                              ? () => onSetDefault(index)
                              : null,
                          icon: Icon(
                            account.isDefault ? Icons.star : Icons.star_border,
                          ),
                        ),
                        const Text('Principal'),
                        IconButton(
                          tooltip: 'Eliminar cuenta',
                          onPressed: enabled ? () => onRemove(index) : null,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _field(
                      account.aliasController,
                      'Alias',
                      enabled: enabled,
                      hintText: 'Ej.: Cuenta principal',
                    ),
                    _field(
                      account.ibanController,
                      'IBAN',
                      enabled: enabled,
                      hintText: 'ES00 0000 0000 0000 0000 0000',
                      validator: BankAccount.validateIban,
                      capitalize: true,
                    ),
                    _field(
                      account.bankNameController,
                      'Banco',
                      enabled: enabled,
                    ),
                    _field(
                      account.bicController,
                      'BIC/SWIFT (opcional)',
                      enabled: enabled,
                      capitalize: true,
                    ),
                    _field(
                      account.holderController,
                      'Titular de la cuenta',
                      enabled: enabled,
                    ),
                    const Divider(height: 32),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  static Widget _field(
    TextEditingController controller,
    String label, {
    required bool enabled,
    String? hintText,
    String? Function(String?)? validator,
    bool capitalize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        validator: validator,
        textCapitalization: capitalize
            ? TextCapitalization.characters
            : TextCapitalization.none,
        decoration: InputDecoration(labelText: label, hintText: hintText),
      ),
    );
  }
}
