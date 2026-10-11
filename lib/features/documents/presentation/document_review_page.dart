import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_local_state.dart';
import '../../../app/app_routes.dart';
import '../../../core/utils/id_generator.dart';
import '../../../features/companies/data/firestore_company_repository.dart';
import '../../../features/companies/domain/company_form_data.dart';
import '../../../features/customers/data/firestore_customer_repository.dart';
import '../../../features/customers/domain/customer_form_data.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';
import '../data/firestore_document_draft_repository.dart';
import '../domain/document_draft_mapper.dart';
import '../domain/document_line_draft.dart';
import '../domain/imported_pdf_source.dart';

class DocumentReviewPage extends StatelessWidget {
  const DocumentReviewPage({
    super.key,
    required this.state,
    required this.companyRepository,
    required this.customerRepository,
  });

  final AppLocalState state;
  final FirestoreCompanyRepository companyRepository;
  final FirestoreCustomerRepository customerRepository;

  @override
  Widget build(BuildContext context) {
    final draft = state.documentDraft;

    if (draft.companyId == null || draft.customerId == null) {
      return EmptyState(
        title: 'No hay documento para revisar',
        message: 'Selecciona una compañía y un cliente antes de continuar.',
        action: AppPrimaryButton(
          label: 'Volver a editar',
          onPressed: () => state.navigateTo(AppRoutes.documentsNew),
        ),
      );
    }

    return FutureBuilder<_DocumentParties>(
      future: _loadParties(
        companyId: draft.companyId!,
        customerId: draft.customerId!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          return _ErrorState(
            message:
                'No se han podido cargar los datos del documento: '
                '${snapshot.error}',
            onBack: () => state.navigateTo(AppRoutes.documentsNew),
          );
        }

        final parties = snapshot.data;

        if (parties == null) {
          return _ErrorState(
            message: 'No se han recibido los datos de empresa y cliente.',
            onBack: () => state.navigateTo(AppRoutes.documentsNew),
          );
        }

        return _DocumentReviewWorkspace(
          state: state,
          company: parties.company,
          customer: parties.customer,
        );
      },
    );
  }

  Future<_DocumentParties> _loadParties({
    required String companyId,
    required String customerId,
  }) async {
    final companies = await companyRepository.watchCompanies().first;
    final customers = await customerRepository.watchCustomers().first;

    final company = companies.firstWhereOrNull((item) => item.id == companyId);

    final customer = customers.firstWhereOrNull(
      (item) => item.id == customerId,
    );

    if (company == null) {
      throw StateError('No se encontró la compañía seleccionada.');
    }

    if (customer == null) {
      throw StateError('No se encontró el cliente seleccionado.');
    }

    return _DocumentParties(company: company, customer: customer);
  }
}

class _DocumentParties {
  const _DocumentParties({required this.company, required this.customer});

  final CompanyFormData company;
  final CustomerFormData customer;
}

class _DocumentReviewWorkspace extends StatelessWidget {
  const _DocumentReviewWorkspace({
    required this.state,
    required this.company,
    required this.customer,
  });

  final AppLocalState state;
  final CompanyFormData company;
  final CustomerFormData customer;

  @override
  Widget build(BuildContext context) {
    final draft = state.documentDraft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: draft.documentType == 'invoice'
              ? 'Revisar factura'
              : 'Revisar proforma',
          subtitle: 'Corrige los conceptos antes de guardar el borrador.',
          actions: [
            AppSecondaryButton(
              label: 'Volver y modificar',
              onPressed: () {
                state.navigateTo(AppRoutes.documentsNew);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _DocumentReviewEditor(
            state: state,
            company: company,
            customer: customer,
          ),
        ),
      ],
    );
  }
}

class _DocumentReviewEditor extends StatelessWidget {
  const _DocumentReviewEditor({
    required this.state,
    required this.company,
    required this.customer,
  });

  final AppLocalState state;
  final CompanyFormData company;
  final CustomerFormData customer;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final draft = state.documentDraft;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SourcePdfDisabledPanel(
                sourcePdf: draft.sourcePdf,
                onBack: () => state.navigateTo(AppRoutes.documentsNew),
              ),
              const SizedBox(height: 16),
              _GeneratedDocumentPanel(
                state: state,
                company: company,
                customer: customer,
                isInvoice: draft.documentType == 'invoice',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SourcePdfDisabledPanel extends StatelessWidget {
  const _SourcePdfDisabledPanel({
    required this.sourcePdf,
    required this.onBack,
  });

  final ImportedPdfSource? sourcePdf;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final sourcePdf = this.sourcePdf;

    if (sourcePdf == null) {
      return SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Factura original',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('No hay un PDF seleccionado para esta sesión.'),
            const SizedBox(height: 16),
            AppPrimaryButton(label: 'Seleccionar PDF', onPressed: onBack),
          ],
        ),
      );
    }

    final textPreview = sourcePdf.extractedText.trim();
    final extractionIsIncomplete = _isExtractionIncomplete(textPreview);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Factura original',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            sourcePdf.fileName,
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatFileSize(sourcePdf.sizeInBytes)} · '
            '${sourcePdf.hasExtractableText ? 'Texto detectado' : 'Sin texto detectable'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!sourcePdf.hasExtractableText || extractionIsIncomplete) ...[
            const SizedBox(height: 12),
            const _WarningBox(
              message:
                  'El texto extraído no parece contener todos los artículos. Revisa y añade manualmente las líneas necesarias.',
            ),
          ],
          const SizedBox(height: 4),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Diagnóstico: texto extraído'),
            children: [
              SizedBox(
                height: 180,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        textPreview.isEmpty
                            ? 'No se ha podido obtener texto del PDF.'
                            : textPreview,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppSecondaryButton(
                label: 'Copiar texto extraído',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: textPreview));

                  if (!context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Texto extraído copiado al portapapeles.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ],
      ),
    );
  }

  static bool _isExtractionIncomplete(String text) {
    if (text.length < 300) {
      return true;
    }

    return !RegExp(
      r'\b(?:artículo|articulo|descripción|descripcion|cantidad|precio|importe|subtotal)\b',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    final kilobytes = bytes / 1024;

    if (kilobytes < 1024) {
      return '${kilobytes.toStringAsFixed(1)} KB';
    }

    return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
  }
}

class _GeneratedDocumentPanel extends StatelessWidget {
  const _GeneratedDocumentPanel({
    required this.state,
    required this.company,
    required this.customer,
    required this.isInvoice,
  });

  final AppLocalState state;
  final CompanyFormData company;
  final CustomerFormData customer;
  final bool isInvoice;

  @override
  Widget build(BuildContext context) {
    final draft = state.documentDraft;
    final totals = _DocumentTotals.fromLines(draft.lines, draft.marginPercent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          child: _InvoiceHeader(
            company: company,
            customer: customer,
            isInvoice: isInvoice,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: _LinesEditor(state: state, marginPercent: draft.marginPercent),
        ),
        const SizedBox(height: 16),
        SectionCard(child: _TotalsPanel(totals: totals)),
        const SizedBox(height: 16),
        SectionCard(child: _PaymentPanel(company: company)),
        const SizedBox(height: 24),
        AppPrimaryButton(
          label: 'Guardar borrador',
          onPressed:
              draft.lines.isNotEmpty &&
                  draft.lines.every((line) => line.isValid)
              ? () async {
                  final draftId = draft.persistedDraftId ?? IdGenerator.next();

                  try {
                    final persistentDraft = DocumentDraftMapper.fromLocalState(
                      draft,
                      draftId: draftId,
                      createdAt: draft.persistedCreatedAt,
                    );

                    await FirestoreDocumentDraftRepository().saveDraft(
                      persistentDraft,
                    );

                    state.setPersistedDraft(
                      draftId: draftId,
                      createdAt: persistentDraft.createdAt,
                    );

                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Borrador guardado correctamente.'),
                      ),
                    );
                  } catch (error) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('No se pudo guardar el borrador: $error'),
                      ),
                    );
                  }
                }
              : null,
        ),
        if (draft.lines.isEmpty) ...[
          const SizedBox(height: 12),
          const Text('Añade al menos una línea de producto antes de guardar.'),
        ] else if (!draft.lines.every((line) => line.isValid)) ...[
          const SizedBox(height: 12),
          const Text(
            'Revisa las líneas: artículo, cantidad, precio e IVA deben ser válidos.',
          ),
        ],
      ],
    );
  }
}

class _InvoiceHeader extends StatelessWidget {
  const _InvoiceHeader({
    required this.company,
    required this.customer,
    required this.isInvoice,
  });

  final CompanyFormData company;
  final CustomerFormData customer;
  final bool isInvoice;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _EntityDetails(
            heading: 'EMISOR',
            legalName: company.legalName,
            taxId: company.taxId,
            address: _address(
              company.addressLine1,
              company.postalCode,
              company.city,
              company.province,
              company.country,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: _EntityDetails(
            heading: 'CLIENTE',
            legalName: customer.legalName,
            taxId: customer.taxId ?? '',
            address: _address(
              customer.addressLine1,
              customer.postalCode,
              customer.city,
              customer.province,
              customer.country,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Fecha de emisión: ${_formatDate(now)}'),
              const SizedBox(height: 4),
              Text(
                isInvoice ? 'FACTURA Nº: BORRADOR' : 'PROFORMA Nº: BORRADOR',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _address(
    String addressLine1,
    String postalCode,
    String city,
    String? province,
    String country,
  ) {
    final location = <String>[
      postalCode,
      city,
    ].where((item) => item.trim().isNotEmpty).join(' ');

    return <String>[
      addressLine1,
      location,
      if (province != null && province.trim().isNotEmpty) province,
      country,
    ].where((item) => item.trim().isNotEmpty).join('\n');
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _EntityDetails extends StatelessWidget {
  const _EntityDetails({
    required this.heading,
    required this.legalName,
    required this.taxId,
    required this.address,
  });

  final String heading;
  final String legalName;
  final String taxId;
  final String address;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(legalName, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (taxId.trim().isNotEmpty) Text('NIF/CIF: $taxId'),
          if (address.trim().isNotEmpty) Text(address),
        ],
      ),
    );
  }
}

class _LinesEditor extends StatelessWidget {
  const _LinesEditor({required this.state, required this.marginPercent});

  final AppLocalState state;
  final int marginPercent;

  @override
  Widget build(BuildContext context) {
    final lines = state.documentDraft.lines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Productos y conceptos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            AppSecondaryButton(
              label: 'Añadir línea',
              onPressed: () {
                state.addDocumentLine(
                  DocumentLineDraft(
                    id: IdGenerator.next(),
                    reference: '',
                    article: '',
                    quantity: 1,
                    sourceUnitPrice: 0,
                    taxRate: 21,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'El precio unitario se calcula aplicando el margen seleccionado al precio de origen. '
          'Las columnas no reconocidas del PDF se ignoran.',
        ),
        const SizedBox(height: 16),
        if (lines.isEmpty)
          const _WarningBox(
            message:
                'No se han detectado líneas válidas. Añade los productos manualmente y compáralos con el PDF original.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;

              if (!wide) {
                return Column(
                  children: [
                    for (final line in lines) ...[
                      _CompactLineCard(
                        key: ValueKey<String>(line.id),
                        state: state,
                        line: line,
                        marginPercent: marginPercent,
                        showLabels: true,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  const _DocumentLinesHeader(),
                  const SizedBox(height: 8),
                  for (final line in lines) ...[
                    _CompactLineCard(
                      key: ValueKey<String>(line.id),
                      state: state,
                      line: line,
                      marginPercent: marginPercent,
                      showLabels: false,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }

  static String formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  static String formatCurrency(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  static double? parseNumber(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }
}

class _CompactLineCard extends StatefulWidget {
  const _CompactLineCard({
    super.key,
    required this.state,
    required this.line,
    required this.marginPercent,
    required this.showLabels,
  });

  final AppLocalState state;
  final DocumentLineDraft line;
  final int marginPercent;
  final bool showLabels;

  @override
  State<_CompactLineCard> createState() => _CompactLineCardState();
}

class _CompactLineCardState extends State<_CompactLineCard> {
  late final TextEditingController _referenceController;
  late final TextEditingController _articleController;
  late final TextEditingController _quantityController;
  late final TextEditingController _sourcePriceController;

  late final FocusNode _referenceFocusNode;
  late final FocusNode _articleFocusNode;
  late final FocusNode _quantityFocusNode;
  late final FocusNode _sourcePriceFocusNode;

  double _previewSourcePrice = 0;

  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();

    _referenceController = TextEditingController(text: widget.line.reference);

    _articleController = TextEditingController(text: widget.line.article);

    _quantityController = TextEditingController(
      text: _LinesEditor.formatNumber(widget.line.quantity),
    );

    _sourcePriceController = TextEditingController(
      text: _LinesEditor.formatNumber(widget.line.sourceUnitPrice),
    );

    _previewSourcePrice = widget.line.sourceUnitPrice;

    _referenceFocusNode = FocusNode()
      ..addListener(() {
        if (!_referenceFocusNode.hasFocus) {
          _handleFieldFocusChange();
        }
      });

    _articleFocusNode = FocusNode()
      ..addListener(() {
        if (!_articleFocusNode.hasFocus) {
          _handleFieldFocusChange();
        }
      });

    _quantityFocusNode = FocusNode()
      ..addListener(() {
        if (!_quantityFocusNode.hasFocus) {
          _handleFieldFocusChange();
        }
      });

    _sourcePriceFocusNode = FocusNode()
      ..addListener(() {
        if (!_sourcePriceFocusNode.hasFocus) {
          _handleFieldFocusChange();
        }
      });

    _referenceController.addListener(_markDirty);
    _articleController.addListener(_markDirty);
    _quantityController.addListener(_markDirty);
    _sourcePriceController.addListener(_markDirty);
  }

  @override
  void didUpdateWidget(covariant _CompactLineCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.line.id != widget.line.id) {
      _setValuesFromLine();
      return;
    }

    if (!_hasUnsavedChanges && oldWidget.line != widget.line) {
      _setValuesFromLine();
    }
  }

  void _setValuesFromLine() {
    _referenceController.text = widget.line.reference;
    _articleController.text = widget.line.article;
    _quantityController.text = _LinesEditor.formatNumber(widget.line.quantity);
    _sourcePriceController.text = _LinesEditor.formatNumber(
      widget.line.sourceUnitPrice,
    );
  }

  void _markDirty() {
    if (_hasUnsavedChanges) {
      return;
    }

    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  void _commitLine() {
    final quantity = _LinesEditor.parseNumber(_quantityController.text);

    final sourceUnitPrice = _LinesEditor.parseNumber(
      _sourcePriceController.text,
    );

    if (quantity == null ||
        quantity <= 0 ||
        sourceUnitPrice == null ||
        sourceUnitPrice < 0) {
      return;
    }

    final updatedLine = widget.line.copyWith(
      reference: _referenceController.text.trim(),
      article: _articleController.text.trim(),
      quantity: quantity,
      sourceUnitPrice: sourceUnitPrice,
    );

    if (_matchesCurrentLine(updatedLine)) {
      return;
    }

    widget.state.updateDocumentLine(updatedLine);

    if (mounted) {
      setState(() {
        _hasUnsavedChanges = false;
        _previewSourcePrice = sourceUnitPrice;
      });
    }
  }

  bool _matchesCurrentLine(DocumentLineDraft updatedLine) {
    final current = widget.line;

    return updatedLine.id == current.id &&
        updatedLine.reference == current.reference &&
        updatedLine.article == current.article &&
        updatedLine.quantity == current.quantity &&
        updatedLine.sourceUnitPrice == current.sourceUnitPrice &&
        updatedLine.taxRate == current.taxRate;
  }

  void _updatePricePreview() {
    final value = _LinesEditor.parseNumber(_sourcePriceController.text);

    if (value == null || value < 0) {
      return;
    }

    setState(() {
      _previewSourcePrice = value;
    });
  }

  void _handleFieldFocusChange() {
    _updatePricePreview();
    _commitLine();
  }

  @override
  void dispose() {
    _referenceController
      ..removeListener(_markDirty)
      ..dispose();

    _articleController
      ..removeListener(_markDirty)
      ..dispose();

    _quantityController
      ..removeListener(_markDirty)
      ..dispose();

    _sourcePriceController
      ..removeListener(_markDirty)
      ..dispose();

    _referenceFocusNode.dispose();
    _articleFocusNode.dispose();
    _quantityFocusNode.dispose();
    _sourcePriceFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final wide = MediaQuery.sizeOf(context).width >= 980;

    final finalUnitPrice =
        _previewSourcePrice * (1 + widget.marginPercent / 100);

    final referenceField = _CompactField(
      label: 'Referencia',
      width: wide ? 150 : null,
      showLabel: widget.showLabels,
      child: TextField(
        controller: _referenceController,
        focusNode: _referenceFocusNode,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
        ),
      ),
    );

    final articleField = _CompactField(
      label: 'Artículo',
      showLabel: widget.showLabels,
      child: TextField(
        controller: _articleController,
        focusNode: _articleFocusNode,
        minLines: 1,
        maxLines: wide ? 2 : 3,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
        ),
      ),
    );

    final quantityField = _CompactField(
      label: 'Cantidad',
      width: wide ? 110 : null,
      showLabel: widget.showLabels,
      child: TextField(
        controller: _quantityController,
        focusNode: _quantityFocusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
        ),
      ),
    );

    final sourcePriceField = _CompactField(
      label: 'Precio original S/M',
      width: wide ? 165 : null,
      showLabel: widget.showLabels,
      child: TextField(
        controller: _sourcePriceController,
        focusNode: _sourcePriceFocusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
        ),
        onEditingComplete: _updatePricePreview,
        onTapOutside: (_) => _updatePricePreview(),
      ),
    );

    final finalPriceField = _CompactField(
      label: 'Precio con margen',
      width: wide ? 165 : null,
      showLabel: widget.showLabels,
      child: _ReadOnlyPriceField(
        value: _LinesEditor.formatCurrency(finalUnitPrice),
      ),
    );

    final taxField = _CompactField(
      label: 'IVA',
      width: wide ? 190 : null,
      showLabel: widget.showLabels,
      child: DropdownButtonFormField<int>(
        initialValue: line.taxRate,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: 21, child: Text('General · 21 %')),
          DropdownMenuItem(value: 10, child: Text('Reducido · 10 %')),
          DropdownMenuItem(value: 4, child: Text('Superreducido · 4 %')),
          DropdownMenuItem(value: 0, child: Text('Exento · 0 %')),
        ],
        onChanged: (value) {
          if (value == null) {
            return;
          }

          widget.state.updateDocumentLine(line.copyWith(taxRate: value));
        },
      ),
    );

    final deleteButton = IconButton(
      tooltip: 'Eliminar línea',
      onPressed: () {
        widget.state.removeDocumentLine(line.id);
      },
      icon: const Icon(Icons.delete_outline),
    );

    if (wide) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              referenceField,
              const SizedBox(width: 12),
              Expanded(child: articleField),
              const SizedBox(width: 12),
              quantityField,
              const SizedBox(width: 12),
              sourcePriceField,
              const SizedBox(width: 12),
              finalPriceField,
              const SizedBox(width: 12),
              taxField,
              const SizedBox(width: 4),
              deleteButton,
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            articleField,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: referenceField),
                const SizedBox(width: 12),
                Expanded(child: quantityField),
              ],
            ),
            const SizedBox(height: 12),
            sourcePriceField,
            const SizedBox(height: 12),
            finalPriceField,
            const SizedBox(height: 12),
            taxField,
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [deleteButton],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  const _CompactField({
    required this.label,
    required this.child,
    this.width,
    this.showLabel = true,
  });

  final String label;
  final Widget child;
  final double? width;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final content = showLabel
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              child,
            ],
          )
        : child;

    if (width == null) {
      return content;
    }

    return SizedBox(width: width, child: content);
  }
}

class _DocumentLinesHeader extends StatelessWidget {
  const _DocumentLinesHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text('Referencia', style: style)),
          const SizedBox(width: 12),
          Expanded(child: Text('Artículo', style: style)),
          const SizedBox(width: 12),
          SizedBox(width: 110, child: Text('Cantidad', style: style)),
          const SizedBox(width: 12),
          SizedBox(
            width: 165,
            child: Text('Precio original S/M', style: style),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 165, child: Text('Precio con margen', style: style)),
          const SizedBox(width: 12),
          SizedBox(width: 190, child: Text('IVA', style: style)),
          const SizedBox(width: 104),
        ],
      ),
    );
  }
}

class _ReadOnlyPriceField extends StatelessWidget {
  const _ReadOnlyPriceField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      enableInteractiveSelection: false,
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
      ),
      style: const TextStyle(fontWeight: FontWeight.w700),
    );
  }
}

class _TotalsPanel extends StatelessWidget {
  const _TotalsPanel({required this.totals});

  final _DocumentTotals totals;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Resumen de la operación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _TotalRow(
              label: 'Base imponible',
              value: _formatCurrency(totals.baseTotal),
            ),
            for (final entry in totals.taxByRate.entries)
              _TotalRow(
                label: 'IVA ${entry.key} %',
                value: _formatCurrency(entry.value),
              ),
            const Divider(height: 24),
            _TotalRow(
              label: 'TOTAL OPERACIÓN',
              value: _formatCurrency(totals.grandTotal),
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w400,
      fontSize: emphasize ? 18 : 14,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({required this.company});

  final CompanyFormData company;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Forma de pago',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text('Transferencia bancaria'),
        const SizedBox(height: 4),
        Text(
          'Cuenta corriente / IBAN: '
          '${_paymentAccount(company)}',
        ),
      ],
    );
  }

  String _paymentAccount(CompanyFormData company) {
    for (final account in company.bankAccounts) {
      if (account.isDefault) {
        return account.iban;
      }
    }
    return 'Pendiente de configurar en los datos de la compañía';
  }
}

class _DocumentTotals {
  const _DocumentTotals({
    required this.baseTotal,
    required this.taxByRate,
    required this.grandTotal,
  });

  final double baseTotal;
  final Map<int, double> taxByRate;
  final double grandTotal;

  factory _DocumentTotals.fromLines(
    List<DocumentLineDraft> lines,
    int marginPercent,
  ) {
    var baseTotal = 0.0;
    final taxByRate = <int, double>{};

    for (final line in lines) {
      baseTotal += line.baseTotal(marginPercent);

      taxByRate.update(
        line.taxRate,
        (value) => value + line.taxTotal(marginPercent),
        ifAbsent: () => line.taxTotal(marginPercent),
      );
    }

    baseTotal = _roundToCents(baseTotal);

    final normalizedTaxes = <int, double>{
      for (final entry in taxByRate.entries)
        entry.key: _roundToCents(entry.value),
    };

    final taxTotal = normalizedTaxes.values.fold(
      0.0,
      (value, item) => value + item,
    );

    return _DocumentTotals(
      baseTotal: baseTotal,
      taxByRate: normalizedTaxes,
      grandTotal: _roundToCents(baseTotal + taxTotal),
    );
  }

  static double _roundToCents(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'No se puede mostrar la vista previa',
      message: message,
      action: AppPrimaryButton(label: 'Volver y modificar', onPressed: onBack),
    );
  }
}

extension _FirstWhereOrNullExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T value) test) {
    for (final value in this) {
      if (test(value)) {
        return value;
      }
    }

    return null;
  }
}
