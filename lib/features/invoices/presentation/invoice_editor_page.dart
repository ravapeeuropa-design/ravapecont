import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../app/app_local_state.dart';
import '../../../core/utils/id_generator.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/domain/bank_account.dart';
import '../../companies/data/firestore_company_repository.dart';
import '../../companies/domain/company_form_data.dart';
import '../../customers/data/firestore_customer_repository.dart';
import '../../customers/domain/customer_form_data.dart';
import '../../documents/data/document_draft_firestore_mappers.dart';
import '../../documents/data/firestore_document_draft_repository.dart';
import '../../documents/domain/document_calculator.dart';
import '../../documents/domain/document_draft.dart';
import '../../documents/domain/document_line.dart';
import '../../documents/domain/document_totals.dart';
import '../data/firestore_invoice_repository.dart';
import '../domain/invoice.dart';

class InvoiceEditorPage extends StatefulWidget {
  const InvoiceEditorPage({
    super.key,
    required this.state,
    required this.repository,
    required this.companyRepository,
    required this.customerRepository,
    this.invoiceId,
    this.initialInvoice,
    this.sourceProformaId,
    this.sourceProformaNumber,
  });

  final AppLocalState state;
  final FirestoreInvoiceRepository repository;
  final FirestoreCompanyRepository companyRepository;
  final FirestoreCustomerRepository customerRepository;
  final String? invoiceId;
  final Invoice? initialInvoice;
  final String? sourceProformaId;
  final String? sourceProformaNumber;

  @override
  State<InvoiceEditorPage> createState() => _InvoiceEditorPageState();
}

class _InvoiceEditorPageState extends State<InvoiceEditorPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreDocumentDraftRepository _documentRepository =
      FirestoreDocumentDraftRepository();
  final List<_EditableInvoiceLine> _lines = <_EditableInvoiceLine>[];

  bool _isLoadingLookups = true;
  Object? _lookupsError;
  List<CompanyFormData> _companies = <CompanyFormData>[];
  List<CustomerFormData> _customers = <CustomerFormData>[];
  String? _selectedCompanyId;
  String? _selectedCustomerId;
  Invoice? _invoice;
  String? _invoiceId;
  String _selectedSeries = 'F';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _invoiceId = widget.invoiceId;
    _loadLookups();

    final initialInvoice = widget.initialInvoice;
    if (initialInvoice != null) {
      _loadInvoice(initialInvoice);
      return;
    }

    if (widget.sourceProformaId != null) {
      _loadFromProforma();
      return;
    }

    _createEmptyDraft();
  }

  @override
  void dispose() {
    _disposeLines();
    super.dispose();
  }

  void _loadInvoice(Invoice invoice) {
    _invoice = invoice;
    _invoiceId = invoice.id;
    _selectedCompanyId = _nonEmptyOrNull(invoice.companyId);
    _selectedCustomerId = _nonEmptyOrNull(invoice.customerId);
    _selectedSeries = invoice.series;
    _selectedDate = invoice.documentDate ?? invoice.createdAt ?? DateTime.now();
    _replaceLines(invoice.lines);
  }

  Future<void> _loadFromProforma() async {
    final proformaId = widget.sourceProformaId;
    if (proformaId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final proforma = await _documentRepository.fetchById(proformaId);
      if (!mounted) {
        return;
      }
      if (proforma == null) {
        setState(() {
          _loadError = 'No se ha encontrado la proforma seleccionada.';
        });
        return;
      }

      _loadProforma(proforma);
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = 'No se pudo cargar la proforma: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadProforma(DocumentDraft proforma) {
    setState(() {
      final companyId = _nonEmptyOrNull(proforma.companyId);
      final customerId = _nonEmptyOrNull(proforma.customerId);
      _selectedCompanyId = _isLoadingLookups
          ? companyId
          : _valueIfExists(companyId, _companies.map((company) => company.id));
      _selectedCustomerId = _isLoadingLookups
          ? customerId
          : _valueIfExists(
              customerId,
              _customers.map((customer) => customer.id),
            );
      _selectedDate = DateTime.now();
      _replaceLines(proforma.lines);
    });
  }

  void _createEmptyDraft() {
    _invoice = null;
    _invoiceId = null;
    _selectedCompanyId = null;
    _selectedCustomerId = null;
    _selectedSeries = 'F';
    _selectedDate = DateTime.now();
    _replaceLines(const <DocumentLine>[]);
  }

  Future<void> _loadLookups() async {
    setState(() {
      _isLoadingLookups = true;
      _lookupsError = null;
    });

    try {
      var companies = <CompanyFormData>[];
      var customers = <CustomerFormData>[];

      await Future.wait<void>([
        widget.companyRepository.watchCompanies().first.then((items) {
          companies = items;
        }),
        widget.customerRepository.watchCustomers().first.then((items) {
          customers = items;
        }),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _companies = companies;
        _customers = customers;
        _selectedCompanyId = _valueIfExists(
          _selectedCompanyId,
          _companies.map((company) => company.id),
        );
        _selectedCustomerId = _valueIfExists(
          _selectedCustomerId,
          _customers.map((customer) => customer.id),
        );
        _isLoadingLookups = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _lookupsError = error;
        _isLoadingLookups = false;
      });
    }
  }

  String? _valueIfExists(String? value, Iterable<String> validValues) {
    if (value == null) {
      return null;
    }

    return validValues.contains(value) ? value : null;
  }

  String? _nonEmptyOrNull(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void _replaceLines(Iterable<DocumentLine> lines) {
    _disposeLines();
    _lines
      ..clear()
      ..addAll(lines.map(_EditableInvoiceLine.fromDocumentLine));
  }

  void _disposeLines() {
    for (final line in _lines) {
      line.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIssued = _invoice?.isIssued ?? false;
    final issuedCode = _invoice?.invoiceCode;
    final invoiceLabel = isIssued && issuedCode != null
        ? issuedCode
        : 'Sin número — borrador';

    return Form(
      key: _formKey,
      child: ListView(
        children: [
          AppPageHeader(
            title: invoiceLabel,
            subtitle: isIssued
                ? 'Factura emitida. La numeración está protegida.'
                : 'La numeración se asignará únicamente al crear la factura.',
            actions: [
              AppSecondaryButton(
                label: 'Volver a facturas',
                onPressed: widget.state.openInvoicesList,
              ),
            ],
          ),
          if (widget.sourceProformaNumber != null) ...[
            const SizedBox(height: 8),
            Text('Referencia: Proforma ${widget.sourceProformaNumber}'),
          ],
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_loadError != null)
            SectionCard(
              child: Text(
                _loadError ?? 'No se pudo cargar la proforma.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          else ...[
            _buildHeaderFields(isIssued),
            const SizedBox(height: 16),
            _buildLinesEditor(),
            const SizedBox(height: 16),
            _buildTotals(),
            const SizedBox(height: 24),
            _buildActions(isIssued),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderFields(bool isIssued) {
    return SectionCard(
      child: Column(
        children: [
          _buildCompanyDropdown(),
          const SizedBox(height: 16),
          _buildCustomerDropdown(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSeries,
                  decoration: const InputDecoration(labelText: 'Serie'),
                  items: const [
                    DropdownMenuItem(value: 'F', child: Text('F')),
                    DropdownMenuItem(value: 'L', child: Text('L')),
                  ],
                  onChanged: isIssued
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedSeries = value);
                          }
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha del documento',
                    ),
                    child: Text(_formatDate(_selectedDate)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    if (_isLoadingLookups) {
      return const InputDecorator(
        decoration: InputDecoration(labelText: 'Compañía'),
        child: Text('Cargando compañías...'),
      );
    }

    if (_lookupsError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No se pudieron cargar las compañías.'),
          TextButton.icon(
            onPressed: _isSaving ? null : _loadLookups,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      key: const ValueKey('invoice-company-dropdown'),
      initialValue: _valueIfExists(
        _selectedCompanyId,
        _companies.map((company) => company.id),
      ),
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Compañía',
        hintText: 'Selecciona una compañía',
      ),
      items: _companies
          .map(
            (company) => DropdownMenuItem<String>(
              value: company.id,
              child: Text(company.legalName, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: _isSaving
          ? null
          : (companyId) {
              setState(() {
                _selectedCompanyId = companyId;
              });
            },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecciona una compañía.';
        }
        return null;
      },
    );
  }

  Widget _buildCustomerDropdown() {
    if (_isLoadingLookups) {
      return const InputDecorator(
        decoration: InputDecoration(labelText: 'Cliente'),
        child: Text('Cargando clientes...'),
      );
    }

    if (_lookupsError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No se pudieron cargar los clientes.'),
          TextButton.icon(
            onPressed: _isSaving ? null : _loadLookups,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      key: const ValueKey('invoice-customer-dropdown'),
      initialValue: _valueIfExists(
        _selectedCustomerId,
        _customers.map((customer) => customer.id),
      ),
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Cliente',
        hintText: 'Selecciona un cliente',
      ),
      items: _customers
          .map(
            (customer) => DropdownMenuItem<String>(
              value: customer.id,
              child: Text(customer.legalName, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: _isSaving
          ? null
          : (customerId) {
              setState(() {
                _selectedCustomerId = customerId;
              });
            },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecciona un cliente.';
        }
        return null;
      },
    );
  }

  Widget _buildLinesEditor() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Líneas (${_lines.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              AppSecondaryButton(label: 'Añadir línea', onPressed: _addLine),
            ],
          ),
          const SizedBox(height: 12),
          if (_lines.isEmpty)
            const Text('La factura todavía no contiene líneas.')
          else
            for (final line in _lines)
              Padding(
                key: ValueKey(line.id),
                padding: const EdgeInsets.only(bottom: 12),
                child: _InvoiceLineFields(
                  line: line,
                  onChanged: () => setState(() {}),
                  onRemove: () => _removeLine(line),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildTotals() {
    final totals = _calculateTotals();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Base: ${_formatMoney(totals.netCents)}'),
          const SizedBox(height: 4),
          Text('IVA: ${_formatMoney(totals.taxCents)}'),
          const Divider(),
          Text(
            'Total: ${_formatMoney(totals.totalCents)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isIssued) {
    if (isIssued) {
      return Align(
        alignment: Alignment.centerRight,
        child: AppPrimaryButton(
          label: _isSaving ? 'Guardando...' : 'Guardar cambios',
          onPressed: _isSaving ? null : _saveIssuedChanges,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IgnorePointer(
          ignoring: _isSaving,
          child: AppSecondaryButton(
            label: _isSaving ? 'Guardando...' : 'Guardar borrador',
            onPressed: _saveDraft,
          ),
        ),
        const SizedBox(width: 12),
        AppPrimaryButton(
          label: _isSaving ? 'Creando...' : 'Crear factura',
          onPressed: _isSaving || _lines.isEmpty ? null : _createInvoice,
        ),
      ],
    );
  }

  void _addLine() {
    setState(() {
      _lines.add(_EditableInvoiceLine.empty(IdGenerator.next()));
    });
  }

  void _removeLine(_EditableInvoiceLine line) {
    setState(() {
      _lines.remove(line);
      line.dispose();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) {
      setState(() => _selectedDate = selected);
    }
  }

  List<DocumentLine> _buildDocumentLines() {
    return _lines.map((line) => line.toDocumentLine()).toList(growable: false);
  }

  DocumentTotals _calculateTotals() {
    final validLines = <DocumentLine>[];
    for (final line in _lines) {
      final parsed = line.tryToDocumentLine();
      if (parsed != null) {
        validLines.add(parsed);
      }
    }
    return const DocumentCalculator().calculate(validLines);
  }

  Map<String, dynamic> _buildEditableDataFromForm() {
    final lines = _buildDocumentLines();
    final totals = const DocumentCalculator().calculate(lines);
    final companyId = _selectedCompanyId;
    final customerId = _selectedCustomerId;
    if (companyId == null || customerId == null) {
      throw StateError('Selecciona una compañía y un cliente.');
    }
    final company = _companies.firstWhere((item) => item.id == companyId);
    final customer = _customers.firstWhere((item) => item.id == customerId);
    final defaultBankAccount = company.bankAccounts
        .where((account) => account.isDefault)
        .firstOrNull;

    return <String, dynamic>{
      'companyId': companyId,
      'customerId': customerId,
      'companySnapshot': <String, Object?>{
        'id': company.id,
        'name': company.legalName,
        'taxId': company.taxId,
        'address': <String, Object?>{
          'line1': company.addressLine1,
          'line2': company.addressLine2,
          'postalCode': company.postalCode,
          'city': company.city,
          'province': company.province,
          'country': company.country,
        },
        'email': company.email,
        'phone': company.phone,
        'bankAccount': defaultBankAccount?.toMap(),
      },
      'customerSnapshot': <String, Object?>{
        'id': customer.id,
        'name': customer.legalName,
        'taxId': customer.taxId,
        'address': <String, Object?>{
          'line1': customer.addressLine1,
          'line2': customer.addressLine2,
          'postalCode': customer.postalCode,
          'city': customer.city,
          'province': customer.province,
          'country': customer.country,
        },
        'shippingAddress': <String, Object?>{
          'line1': customer.shippingAddressLine1,
          'line2': customer.shippingAddressLine2,
          'postalCode': customer.shippingPostalCode,
          'city': customer.shippingCity,
          'province': customer.shippingProvince,
          'country': customer.shippingCountry,
        },
      },
      'customer': <String, Object?>{
        'id': customer.id,
        'legalName': customer.legalName,
        'tradeName': customer.tradeName,
        'taxId': customer.taxId,
        'addressLine1': customer.addressLine1,
        'addressLine2': customer.addressLine2,
        'postalCode': customer.postalCode,
        'city': customer.city,
        'province': customer.province,
        'country': customer.country,
        'emails': customer.emails,
        'phone': customer.phone,
      },
      'documentDate': Timestamp.fromDate(_selectedDate),
      'lines': lines.map(documentLineToFirestoreMap).toList(growable: false),
      'totals': <String, dynamic>{
        'netCents': totals.netCents,
        'taxCents': totals.taxCents,
        'totalCents': totals.totalCents,
      },
    };
  }

  bool _validateForm() {
    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una línea.')),
      );
      return false;
    }
    return formIsValid;
  }

  Future<void> _saveDraft() async {
    if (!_validateForm()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final invoiceId = await widget.repository.saveDraft(
        invoiceId: _invoiceId,
        editableData: _buildEditableDataFromForm(),
        series: _selectedSeries,
        sourceProformaId: widget.sourceProformaId,
        sourceProformaNumber: widget.sourceProformaNumber,
      );

      if (!mounted) {
        return;
      }
      setState(() => _invoiceId = invoiceId);
      widget.state.setEditingInvoiceId(invoiceId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Borrador de factura guardado.')),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _createInvoice() async {
    if (!_validateForm()) {
      return;
    }
    final companyId = _selectedCompanyId;
    final company = companyId == null
        ? null
        : _companies.where((item) => item.id == companyId).firstOrNull;
    final primaryAccount = company?.bankAccounts
        .where((account) => account.isDefault)
        .firstOrNull;
    if (primaryAccount == null ||
        BankAccount.validateIban(primaryAccount.iban) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La compañía emisora necesita una cuenta bancaria principal válida.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear factura'),
          content: const Text(
            'Se asignará el siguiente número de factura y se marcará como '
            'emitida. La numeración asignada no se podrá reutilizar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Crear factura'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final invoiceId = await widget.repository.saveDraft(
        invoiceId: _invoiceId,
        editableData: _buildEditableDataFromForm(),
        series: _selectedSeries,
        sourceProformaId: widget.sourceProformaId,
        sourceProformaNumber: widget.sourceProformaNumber,
      );
      final result = await widget.repository.issueInvoice(
        invoiceId: invoiceId,
        year: DateTime.now().year,
        series: _selectedSeries,
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Factura ${result.code} creada correctamente.')),
      );
      widget.state.openInvoicesList();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveIssuedChanges() async {
    final invoiceId = _invoiceId;
    if (!_validateForm() || invoiceId == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.repository.saveIssuedChanges(
        invoiceId: invoiceId,
        editableData: _buildEditableDataFromForm(),
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambios guardados sin modificar la numeración.'),
        ),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo completar la operación: $error')),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _formatMoney(int cents) => '${(cents / 100).toStringAsFixed(2)} €';
}

class _InvoiceLineFields extends StatelessWidget {
  const _InvoiceLineFields({
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  final _EditableInvoiceLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: TextFormField(
            controller: line.descriptionController,
            decoration: const InputDecoration(labelText: 'Descripción'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obligatorio.';
              }
              return null;
            },
            onChanged: (value) => onChanged(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: line.quantityController,
            decoration: const InputDecoration(labelText: 'Cantidad'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final quantity = double.tryParse(
                (value ?? '').replaceAll(',', '.'),
              );
              return quantity == null || quantity <= 0
                  ? 'Cantidad inválida.'
                  : null;
            },
            onChanged: (value) => onChanged(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: line.unitPriceController,
            decoration: const InputDecoration(labelText: 'Precio'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final price = double.tryParse((value ?? '').replaceAll(',', '.'));
              return price == null || price < 0 ? 'Precio inválido.' : null;
            },
            onChanged: (value) => onChanged(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: DropdownButtonFormField<int>(
            initialValue: line.taxRate,
            decoration: const InputDecoration(labelText: 'IVA'),
            items: const [
              DropdownMenuItem(value: 0, child: Text('0 %')),
              DropdownMenuItem(value: 4, child: Text('4 %')),
              DropdownMenuItem(value: 10, child: Text('10 %')),
              DropdownMenuItem(value: 21, child: Text('21 %')),
            ],
            onChanged: (value) {
              if (value != null) {
                line.taxRate = value;
                onChanged();
              }
            },
          ),
        ),
        IconButton(
          tooltip: 'Eliminar línea',
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}

class _EditableInvoiceLine {
  _EditableInvoiceLine({
    required this.id,
    required this.descriptionController,
    required this.quantityController,
    required this.unitPriceController,
    required this.taxRate,
  });

  factory _EditableInvoiceLine.fromDocumentLine(DocumentLine line) {
    return _EditableInvoiceLine(
      id: line.id.isEmpty ? IdGenerator.next() : line.id,
      descriptionController: TextEditingController(text: line.description),
      quantityController: TextEditingController(
        text: (line.quantityMilliunits / 1000).toStringAsFixed(3),
      ),
      unitPriceController: TextEditingController(
        text: (line.unitPriceCents / 100).toStringAsFixed(2),
      ),
      taxRate: line.taxRateBasisPoints ~/ 100,
    );
  }

  factory _EditableInvoiceLine.empty(String id) {
    return _EditableInvoiceLine(
      id: id,
      descriptionController: TextEditingController(),
      quantityController: TextEditingController(text: '1'),
      unitPriceController: TextEditingController(text: '0'),
      taxRate: 21,
    );
  }

  final String id;
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  int taxRate;

  DocumentLine? tryToDocumentLine() {
    final description = descriptionController.text.trim();
    final quantity = double.tryParse(
      quantityController.text.replaceAll(',', '.'),
    );
    final unitPrice = double.tryParse(
      unitPriceController.text.replaceAll(',', '.'),
    );
    if (description.isEmpty ||
        quantity == null ||
        quantity <= 0 ||
        unitPrice == null ||
        unitPrice < 0) {
      return null;
    }

    return DocumentLine(
      id: id,
      description: description,
      quantityMilliunits: (quantity * 1000).round(),
      unitPriceCents: (unitPrice * 100).round(),
      taxRateBasisPoints: taxRate * 100,
    );
  }

  DocumentLine toDocumentLine() {
    final line = tryToDocumentLine();
    if (line == null) {
      throw StateError('Hay líneas de factura con datos inválidos.');
    }
    return line;
  }

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}
