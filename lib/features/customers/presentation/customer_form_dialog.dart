import 'package:flutter/material.dart';

import '../../../app/app_local_state.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/validators.dart';
import '../../../features/customers/data/firestore_customer_repository.dart';
import '../../../features/customers/domain/customer_form_data.dart';
import '../../../features/contacts/presentation/widgets/bank_accounts_section.dart';
import '../../../shared/domain/bank_account.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';

Future<void> showCustomerDialog(
  BuildContext context,
  AppLocalState state, {
  required FirestoreCustomerRepository repository,
  CustomerFormData? customer,
}) async {
  final result = await showDialog<CustomerFormData>(
    context: context,
    builder: (dialogContext) {
      return _CustomerFormDialog(state: state, customer: customer);
    },
  );

  if (result == null) {
    return;
  }

  try {
    if (customer == null) {
      await repository.createCustomer(result);
    } else {
      await repository.updateCustomer(result);
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          customer == null
              ? 'Cliente creado correctamente.'
              : 'Cliente actualizado correctamente.',
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No se pudo guardar el cliente: $error'),
        duration: const Duration(seconds: 8),
      ),
    );
  }
}

class _CustomerFormDialog extends StatefulWidget {
  const _CustomerFormDialog({required this.state, this.customer});

  final AppLocalState state;
  final CustomerFormData? customer;

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _legalNameController;
  late final TextEditingController _tradeNameController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _cityController;
  late final TextEditingController _provinceController;
  late final TextEditingController _countryController;
  late final TextEditingController _primaryEmailController;
  late final TextEditingController _extraEmailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _shippingAddressLine1Controller;
  late final TextEditingController _shippingAddressLine2Controller;
  late final TextEditingController _shippingPostalCodeController;
  late final TextEditingController _shippingCityController;
  late final TextEditingController _shippingProvinceController;
  late final TextEditingController _shippingCountryController;

  late bool _active;
  late final List<String> _extraEmails;
  final List<EditableBankAccount> _bankAccounts = <EditableBankAccount>[];

  @override
  void initState() {
    super.initState();

    final customer = widget.customer;

    _legalNameController = TextEditingController(
      text: customer?.legalName ?? '',
    );
    _tradeNameController = TextEditingController(
      text: customer?.tradeName ?? '',
    );
    _taxIdController = TextEditingController(text: customer?.taxId ?? '');
    _addressLine1Controller = TextEditingController(
      text: customer?.addressLine1 ?? '',
    );
    _addressLine2Controller = TextEditingController(
      text: customer?.addressLine2 ?? '',
    );
    _postalCodeController = TextEditingController(
      text: customer?.postalCode ?? '',
    );
    _cityController = TextEditingController(text: customer?.city ?? '');
    _provinceController = TextEditingController(text: customer?.province ?? '');
    _countryController = TextEditingController(
      text: customer?.country ?? 'España',
    );
    _primaryEmailController = TextEditingController(
      text: customer != null && customer.emails.isNotEmpty
          ? customer.emails.first
          : '',
    );
    _extraEmailController = TextEditingController();
    _phoneController = TextEditingController(text: customer?.phone ?? '');
    _shippingAddressLine1Controller = TextEditingController(
      text: customer?.shippingAddressLine1 ?? '',
    );
    _shippingAddressLine2Controller = TextEditingController(
      text: customer?.shippingAddressLine2 ?? '',
    );
    _shippingPostalCodeController = TextEditingController(
      text: customer?.shippingPostalCode ?? '',
    );
    _shippingCityController = TextEditingController(
      text: customer?.shippingCity ?? '',
    );
    _shippingProvinceController = TextEditingController(
      text: customer?.shippingProvince ?? '',
    );
    _shippingCountryController = TextEditingController(
      text: customer?.shippingCountry ?? 'España',
    );

    _active = customer?.active ?? true;
    _extraEmails = customer == null || customer.emails.length <= 1
        ? <String>[]
        : List<String>.from(customer.emails.skip(1));
    _loadBankAccounts(customer?.bankAccounts ?? const []);
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _tradeNameController.dispose();
    _taxIdController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _countryController.dispose();
    _primaryEmailController.dispose();
    _extraEmailController.dispose();
    _phoneController.dispose();
    _shippingAddressLine1Controller.dispose();
    _shippingAddressLine2Controller.dispose();
    _shippingPostalCodeController.dispose();
    _shippingCityController.dispose();
    _shippingProvinceController.dispose();
    _shippingCountryController.dispose();
    for (final account in _bankAccounts) {
      account.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.customer == null ? 'Añadir cliente' : 'Modificar cliente',
      ),
      content: SizedBox(
        width: 840,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Datos'),
                _field(
                  _legalNameController,
                  'Razón social',
                  validator: (value) {
                    return Validators.requiredText(value, 'La razón social');
                  },
                ),
                _field(_tradeNameController, 'Nombre comercial'),
                _field(_taxIdController, 'NIF/CIF'),
                const SizedBox(height: 12),
                const Text('Domicilio'),
                _field(
                  _addressLine1Controller,
                  'Dirección',
                  validator: (value) {
                    return Validators.requiredText(value, 'La dirección');
                  },
                ),
                _field(_addressLine2Controller, 'Complemento'),
                _field(
                  _postalCodeController,
                  'Código postal',
                  validator: Validators.postalCode,
                ),
                _field(
                  _cityController,
                  'Ciudad',
                  validator: (value) {
                    return Validators.requiredText(value, 'La ciudad');
                  },
                ),
                _field(_provinceController, 'Provincia'),
                _field(
                  _countryController,
                  'País',
                  validator: (value) {
                    return Validators.requiredText(value, 'El país');
                  },
                ),
                const SizedBox(height: 12),
                const Text('Dirección de envío'),
                _field(_shippingAddressLine1Controller, 'Dirección de envío'),
                _field(_shippingAddressLine2Controller, 'Complemento de envío'),
                _field(
                  _shippingPostalCodeController,
                  'Código postal de envío',
                  validator: _optionalPostalCode,
                ),
                _field(_shippingCityController, 'Ciudad de envío'),
                _field(_shippingProvinceController, 'Provincia de envío'),
                _field(_shippingCountryController, 'País de envío'),
                const SizedBox(height: 12),
                const Text('Contacto'),
                _field(
                  _primaryEmailController,
                  'Email principal',
                  validator: Validators.email,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _extraEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Añadir otro email',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppSecondaryButton(
                      label: 'Añadir',
                      onPressed: _addExtraEmail,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final email in _extraEmails)
                  ListTile(
                    dense: true,
                    title: Text(email),
                    trailing: IconButton(
                      onPressed: () {
                        setState(() {
                          _extraEmails.remove(email);
                        });
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                _field(_phoneController, 'Teléfono'),
                const SizedBox(height: 12),
                BankAccountsSection(
                  accounts: _bankAccounts,
                  onAdd: _addBankAccount,
                  onRemove: _removeBankAccount,
                  onSetDefault: _setDefaultBankAccount,
                ),
                SwitchListTile(
                  value: _active,
                  onChanged: (value) {
                    setState(() {
                      _active = value;
                    });
                  },
                  title: const Text('Activo'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        AppSecondaryButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppPrimaryButton(label: 'Guardar', onPressed: _save),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _addExtraEmail() {
    final value = _extraEmailController.text.trim();

    if (value.isEmpty || Validators.email(value) != null) {
      return;
    }

    final existingEmails = <String>[
      _primaryEmailController.text.trim().toLowerCase(),
      for (final email in _extraEmails) email.toLowerCase(),
    ];

    if (existingEmails.contains(value.toLowerCase())) {
      _extraEmailController.clear();
      return;
    }

    setState(() {
      _extraEmails.add(value);
      _extraEmailController.clear();
    });
  }

  void _save() {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    final now = DateTime.now().toUtc();
    final emails = <String>[
      _primaryEmailController.text.trim(),
      ..._extraEmails,
    ];

    final dedupedEmails = <String>[];

    for (final email in emails) {
      final exists = dedupedEmails.any(
        (item) => item.toLowerCase() == email.toLowerCase(),
      );

      if (!exists) {
        dedupedEmails.add(email);
      }
    }

    final customer = CustomerFormData(
      id: widget.customer?.id ?? IdGenerator.next(),
      legalName: _legalNameController.text.trim(),
      tradeName: _nullableText(_tradeNameController),
      taxId: _nullableText(_taxIdController),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _nullableText(_addressLine2Controller),
      postalCode: _postalCodeController.text.trim(),
      city: _cityController.text.trim(),
      province: _nullableText(_provinceController),
      country: _countryController.text.trim(),
      emails: dedupedEmails,
      phone: _nullableText(_phoneController),
      shippingAddressLine1: _nullableText(_shippingAddressLine1Controller),
      shippingAddressLine2: _nullableText(_shippingAddressLine2Controller),
      shippingPostalCode: _nullableText(_shippingPostalCodeController),
      shippingCity: _nullableText(_shippingCityController),
      shippingProvince: _nullableText(_shippingProvinceController),
      shippingCountry: _nullableText(_shippingCountryController),
      bankAccounts: normalizeBankAccounts(
        _bankAccounts.map((account) => account.toBankAccount()),
      ),
      active: _active,
      createdAt: widget.customer?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(customer);
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String? _optionalPostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return Validators.postalCode(value);
  }

  void _loadBankAccounts(Iterable<BankAccount> accounts) {
    for (final account in _bankAccounts) {
      account.dispose();
    }
    _bankAccounts
      ..clear()
      ..addAll(accounts.map(EditableBankAccount.fromBankAccount));
  }

  void _addBankAccount() {
    setState(() {
      _bankAccounts.add(
        EditableBankAccount(
          id: IdGenerator.next(),
          ibanController: TextEditingController(),
          aliasController: TextEditingController(),
          bankNameController: TextEditingController(),
          bicController: TextEditingController(),
          holderController: TextEditingController(),
          isDefault: _bankAccounts.isEmpty,
        ),
      );
    });
  }

  void _removeBankAccount(int index) {
    setState(() {
      final removed = _bankAccounts.removeAt(index);
      final removedWasDefault = removed.isDefault;
      removed.dispose();
      if (removedWasDefault && _bankAccounts.isNotEmpty) {
        _bankAccounts.first.isDefault = true;
      }
    });
  }

  void _setDefaultBankAccount(int index) {
    setState(() {
      for (var position = 0; position < _bankAccounts.length; position++) {
        _bankAccounts[position].isDefault = position == index;
      }
    });
  }
}
