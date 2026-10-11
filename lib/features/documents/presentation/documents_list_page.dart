import 'package:flutter/material.dart';

import '../../../app/app_local_state.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../data/firestore_document_draft_repository.dart';
import '../domain/document_draft.dart';

enum DocumentsListMode { manageProformas, selectProformaForInvoice }

class DocumentsListPage extends StatelessWidget {
  const DocumentsListPage({
    super.key,
    required this.state,
    required this.repository,
    this.mode = DocumentsListMode.manageProformas,
  });

  final AppLocalState state;
  final FirestoreDocumentDraftRepository repository;
  final DocumentsListMode mode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPageHeader(
          title: mode == DocumentsListMode.selectProformaForInvoice
              ? 'Seleccionar proforma'
              : 'Proformas',
          subtitle: mode == DocumentsListMode.selectProformaForInvoice
              ? 'Elige una proforma para preparar una factura.'
              : 'Borradores guardados y pendientes de emisión.',
          actions: mode == DocumentsListMode.manageProformas
              ? [
                  AppPrimaryButton(
                    label: 'Añadir proforma',
                    onPressed: state.createDraft,
                  ),
                ]
              : const [],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<List<DocumentDraft>>(
            stream: repository.watchDrafts(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'No se pudieron cargar las proformas: ${snapshot.error}',
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final drafts = mode == DocumentsListMode.selectProformaForInvoice
                  ? snapshot.data!
                        .where((draft) => draft.documentType == 'proforma')
                        .toList(growable: false)
                  : snapshot.data!;

              if (drafts.isEmpty) {
                return const Center(
                  child: Text('Todavía no hay proformas guardadas.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: drafts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _DraftListItem(
                    draft: drafts[index],
                    selectingForInvoice:
                        mode == DocumentsListMode.selectProformaForInvoice,
                    onTap: () {
                      if (mode == DocumentsListMode.selectProformaForInvoice) {
                        state.openInvoiceFromProforma(drafts[index]);
                        return;
                      }
                      state.editDraft(drafts[index]);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DraftListItem extends StatelessWidget {
  const _DraftListItem({
    required this.draft,
    required this.selectingForInvoice,
    required this.onTap,
  });

  final DocumentDraft draft;
  final bool selectingForInvoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SectionCard(
        child: Row(
          children: [
            const Icon(Icons.description_outlined),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.documentType == 'invoice'
                        ? 'Factura · Borrador'
                        : 'Proforma · Borrador',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Actualizado: ${_formatDate(draft.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${draft.lines.length} línea${draft.lines.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (selectingForInvoice)
              TextButton(
                onPressed: onTap,
                child: const Text('Usar para factura'),
              )
            else
              const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }
}
