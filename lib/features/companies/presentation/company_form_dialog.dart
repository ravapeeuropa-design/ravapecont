import 'package:flutter/material.dart';

import '../../../app/app_local_state.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/validators.dart';
import '../../../features/companies/data/firestore_company_repository.dart';
import '../../../features/companies/domain/company_form_data.dart';
import '../../../features/contacts/presentation/widgets/bank_accounts_section.dart';
import '../../../shared/domain/bank_account.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/section_card.dart';

Future<CompanyFormData?> showCompanyDialog(
  BuildContext context,
  AppLocalState state, {
  required FirestoreCompanyRepository repository,
  CompanyFormData? company,
}) async {
  final result = await showDialog<CompanyFormData>(
    context: context,
    builder: (context) => _CompanyFormDialog(
      state: state,
      repository: repository,
      company: company,
    ),
  );
  if (result != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          company == null
              ? 'Compañía creada correctamente.'
              : 'Compañía actualizada correctamente.',
        ),
      ),
    );
  }
  return result;
}

class _CompanyFormDialog extends StatefulWidget {
  const _CompanyFormDialog({
    required this.state,
    required this.repository,
    this.company,
  });

  final AppLocalState state;
  final FirestoreCompanyRepository repository;
  final CompanyFormData? company;

  @override
  State<_CompanyFormDialog> createState() => _CompanyFormDialogState();
}

class _CompanyFormDialogState extends State<_CompanyFormDialog> {
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
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;
  late bool _active;
  final List<EditableBankAccount> _bankAccounts = <EditableBankAccount>[];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final company = widget.company;
    _legalNameController = TextEditingController(
      text: company?.legalName ?? '',
    );
    _tradeNameController = TextEditingController(
      text: company?.tradeName ?? '',
    );
    _taxIdController = TextEditingController(text: company?.taxId ?? '');
    _addressLine1Controller = TextEditingController(
      text: company?.addressLine1 ?? '',
    );
    _addressLine2Controller = TextEditingController(
      text: company?.addressLine2 ?? '',
    );
    _postalCodeController = TextEditingController(
      text: company?.postalCode ?? '',
    );
    _cityController = TextEditingController(text: company?.city ?? '');
    _provinceController = TextEditingController(text: company?.province ?? '');
    _countryController = TextEditingController(
      text: company?.country ?? 'España',
    );
    _emailController = TextEditingController(text: company?.email ?? '');
    _phoneController = TextEditingController(text: company?.phone ?? '');
    _websiteController = TextEditingController(text: company?.website ?? '');
    _active = company?.active ?? true;
    _loadBankAccounts(company?.bankAccounts ?? const []);
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
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    for (final account in _bankAccounts) {
      account.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.company == null ? 'Añadir compañía' : 'Modificar compañía',
      ),
      content: SizedBox(
        width: 840,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionCard(child: Text('Datos fiscales')),
                const SizedBox(height: 16),
                _field(
                  _legalNameController,
                  'Razón social',
                  validator: (value) =>
                      Validators.requiredText(value, 'La razón social'),
                ),
                _field(_tradeNameController, 'Nombre comercial'),
                _field(
                  _taxIdController,
                  'NIF/CIF',
                  validator: (value) =>
                      Validators.requiredText(value, 'El NIF/CIF'),
                ),
                const SizedBox(height: 16),
                const Text('Domicilio fiscal'),
                _field(
                  _addressLine1Controller,
                  'Dirección',
                  validator: (value) =>
                      Validators.requiredText(value, 'La dirección'),
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
                  validator: (value) =>
                      Validators.requiredText(value, 'La ciudad'),
                ),
                _field(_provinceController, 'Provincia'),
                _field(
                  _countryController,
                  'País',
                  validator: (value) =>
                      Validators.requiredText(value, 'El país'),
                ),
                const SizedBox(height: 16),
                const Text('Contacto'),
                _field(_emailController, 'Email', validator: Validators.email),
                _field(_phoneController, 'Teléfono'),
                _field(_websiteController, 'Web'),
                const SizedBox(height: 16),
                BankAccountsSection(
                  accounts: _bankAccounts,
                  onAdd: _addBankAccount,
                  onRemove: _removeBankAccount,
                  onSetDefault: _setDefaultBankAccount,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text('Activa'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        AppSecondaryButton(
          label: 'Cancelar',
          onPressed: _isSaving ? () {} : () => Navigator.of(context).pop(),
        ),
        AppPrimaryButton(
          label: _isSaving ? 'Guardando...' : 'Guardar',
          onPressed: _save,
        ),
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

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now().toUtc();
    final company = CompanyFormData(
      id: widget.company?.id ?? IdGenerator.next(),
      legalName: _legalNameController.text.trim(),
      tradeName: _tradeNameController.text.trim().isEmpty
          ? null
          : _tradeNameController.text.trim(),
      taxId: _taxIdController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim().isEmpty
          ? null
          : _addressLine2Controller.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      city: _cityController.text.trim(),
      province: _provinceController.text.trim().isEmpty
          ? null
          : _provinceController.text.trim(),
      country: _countryController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      bankAccounts: normalizeBankAccounts(
        _bankAccounts.map((account) => account.toBankAccount()),
      ),
      active: _active,
      createdAt: widget.company?.createdAt ?? now,
      updatedAt: now,
    );
    setState(() => _isSaving = true);
    try {
      if (widget.company == null) {
        await widget.repository.createCompany(company);
      } else {
        await widget.repository.updateCompany(company);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(company);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la compañía: $error')),
      );
    }
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
