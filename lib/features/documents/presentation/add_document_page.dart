import 'package:flutter/material.dart';

import '../../../app/app_local_state.dart';
import '../../../app/app_routes.dart';
import '../../../core/utils/id_generator.dart';
import '../../../features/companies/data/firestore_company_repository.dart';
import '../../../features/customers/data/firestore_customer_repository.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../data/local_pdf_import_service.dart';
import '../data/pdf_line_parser.dart';
import '../domain/document_line_draft.dart';

class AddDocumentPage extends StatefulWidget {
  const AddDocumentPage({
    super.key,
    required this.state,
    required this.companyRepository,
    required this.customerRepository,
  });

  final AppLocalState state;
  final FirestoreCompanyRepository companyRepository;
  final FirestoreCustomerRepository customerRepository;

  @override
  State<AddDocumentPage> createState() => _AddDocumentPageState();
}

class _AddDocumentPageState extends State<AddDocumentPage> {
  final TextEditingController _marginController = TextEditingController();

  bool _importingPdf = false;

  @override
  void initState() {
    super.initState();
    _marginController.text = widget.state.documentDraft.marginPercent
        .toString();
  }

  @override
  void dispose() {
    _marginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.state.documentDraft;
    final margin = _marginValue;

    final hasValidSelection =
        (draft.sourcePdf != null || draft.persistedDraftId != null) &&
        draft.companyId != null &&
        draft.customerId != null &&
        margin != null &&
        margin >= 0 &&
        margin <= 1000;

    return ListView(
      children: [
        AppPageHeader(
          title: draft.persistedDraftId == null
              ? 'Añadir factura'
              : draft.documentType == 'invoice'
              ? 'Editar factura'
              : 'Editar proforma',
          subtitle:
              'Importa un PDF original y crea una factura o proforma revisable.',
        ),
        const SizedBox(height: 24),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Factura de origen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                draft.sourcePdf == null
                    ? 'Selecciona un PDF original para extraer su información.'
                    : 'Archivo seleccionado: ${draft.sourcePdf!.fileName}',
              ),
              const SizedBox(height: 8),
              if (draft.sourcePdf != null)
                Text(
                  draft.sourcePdf!.hasExtractableText
                      ? 'Texto extraído: ${draft.sourcePdf!.extractedText.length} caracteres.'
                      : 'No se detectó texto utilizable. Podrás añadir o corregir líneas manualmente.',
                  style: TextStyle(
                    color: draft.sourcePdf!.hasExtractableText
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              if (draft.sourcePdf?.extractionError != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Detalle técnico: ${draft.sourcePdf!.extractionError}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: _importingPdf
                    ? 'Importando PDF...'
                    : draft.sourcePdf == null
                    ? 'Seleccionar PDF'
                    : 'Sustituir PDF',
                onPressed: _importingPdf ? null : _pickPdf,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder(
          stream: widget.companyRepository.watchCompanies(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('No se han podido cargar las compañías.');
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final activeCompanies = snapshot.data!
                .where((item) => item.active)
                .toList(growable: false);

            final selected = draft.companyId;
            final selectedExists =
                selected != null &&
                activeCompanies.any((item) => item.id == selected);

            if (!selectedExists && selected != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.state.updateDocumentDraft(companyId: null);
              });
            }

            if (activeCompanies.isEmpty) {
              return Row(
                children: [
                  const Text('No hay compañías activas.'),
                  const SizedBox(width: 12),
                  AppPrimaryButton(
                    label: 'Añadir compañía',
                    onPressed: () {
                      widget.state.navigateTo(AppRoutes.companies);
                    },
                  ),
                ],
              );
            }

            return SectionCard(
              child: DropdownButtonFormField<String>(
                initialValue: selectedExists ? selected : null,
                decoration: const InputDecoration(
                  labelText: 'Compañía emisora',
                ),
                items: [
                  for (final company in activeCompanies)
                    DropdownMenuItem(
                      value: company.id,
                      child: Text(company.legalName),
                    ),
                ],
                onChanged: (value) {
                  widget.state.updateDocumentDraft(companyId: value);
                  setState(() {});
                },
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder(
          stream: widget.customerRepository.watchCustomers(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('No se han podido cargar los clientes.');
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final activeCustomers = snapshot.data!
                .where((item) => item.active)
                .toList(growable: false);

            final selected = draft.customerId;
            final selectedExists =
                selected != null &&
                activeCustomers.any((item) => item.id == selected);

            if (!selectedExists && selected != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.state.updateDocumentDraft(customerId: null);
              });
            }

            if (activeCustomers.isEmpty) {
              return Row(
                children: [
                  const Text('No hay clientes activos.'),
                  const SizedBox(width: 12),
                  AppPrimaryButton(
                    label: 'Añadir cliente',
                    onPressed: () {
                      widget.state.navigateTo(AppRoutes.customers);
                    },
                  ),
                ],
              );
            }

            return SectionCard(
              child: DropdownButtonFormField<String>(
                initialValue: selectedExists ? selected : null,
                decoration: const InputDecoration(
                  labelText: 'Cliente destinatario',
                ),
                items: [
                  for (final customer in activeCustomers)
                    DropdownMenuItem(
                      value: customer.id,
                      child: Text(customer.legalName),
                    ),
                ],
                onChanged: (value) {
                  widget.state.updateDocumentDraft(customerId: value);
                  setState(() {});
                },
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tipo de documento'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'invoice', label: Text('Factura')),
                  ButtonSegment(value: 'proforma', label: Text('Proforma')),
                ],
                selected: {draft.documentType},
                onSelectionChanged: (values) {
                  widget.state.updateDocumentDraft(documentType: values.first);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'La factura se guardará inicialmente como borrador, sin numeración fiscal definitiva.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: TextFormField(
            controller: _marginController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Margen sobre conceptos',
              suffixText: '%',
            ),
            onChanged: (value) {
              widget.state.updateDocumentDraft(
                marginPercent: int.tryParse(value),
              );
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 16),
        AppPrimaryButton(
          label: 'Generar vista previa',
          onPressed: hasValidSelection
              ? () {
                  final margin = _marginValue;

                  if (margin == null) {
                    return;
                  }

                  widget.state.updateDocumentDraft(marginPercent: margin);

                  widget.state.navigateTo(AppRoutes.documentsReview);
                }
              : null,
        ),
        const SizedBox(height: 12),
        if (!hasValidSelection)
          const Text(
            'Selecciona un PDF, una compañía, un cliente y un margen válido para continuar.',
          ),
      ],
    );
  }

  int? get _marginValue => int.tryParse(_marginController.text);

  Future<void> _pickPdf() async {
    setState(() {
      _importingPdf = true;
    });

    try {
      final source = await const LocalPdfImportService().pickAndExtract();

      if (!mounted || source == null) {
        return;
      }

      final lines = source.hasExtractableText
          ? const PdfLineParser().parse(
              source.extractedText,
              createId: IdGenerator.next,
            )
          : <DocumentLineDraft>[];

      widget.state.setSourcePdf(source);
      widget.state.setDocumentLines(lines);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source.hasExtractableText
                ? 'PDF importado. Se han detectado ${lines.length} líneas candidatas. Revísalas antes de continuar.'
                : 'PDF importado sin texto utilizable. Añade las líneas manualmente en la vista previa.',
          ),
        ),
      );
    } on PdfImportException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo importar el PDF: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _importingPdf = false;
        });
      }
    }
  }
}
