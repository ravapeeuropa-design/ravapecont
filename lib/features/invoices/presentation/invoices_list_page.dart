import 'package:flutter/material.dart';

import '../../../app/app_local_state.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../data/firestore_invoice_repository.dart';
import '../domain/invoice.dart';

class InvoicesListPage extends StatefulWidget {
  const InvoicesListPage({
    super.key,
    required this.state,
    required this.repository,
  });

  final AppLocalState state;
  final FirestoreInvoiceRepository repository;

  @override
  State<InvoicesListPage> createState() => _InvoicesListPageState();
}

class _InvoicesListPageState extends State<InvoicesListPage> {
  final TextEditingController _searchController = TextEditingController();
  late final Stream<List<Invoice>> _invoicesStream;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _invoicesStream = widget.repository.watchInvoices();
    _searchController.addListener(_updateQuery);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_updateQuery)
      ..dispose();
    super.dispose();
  }

  void _updateQuery() {
    final query = _searchController.text.trim().toLowerCase();
    if (query != _query) {
      setState(() {
        _query = query;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPageHeader(
          title: 'Facturas',
          subtitle: 'Borradores y facturas emitidas.',
          actions: [
            AppSecondaryButton(
              label: 'Desde proforma',
              onPressed: widget.state.openProformaSelectorForInvoice,
            ),
            AppPrimaryButton(
              label: 'Nueva factura',
              onPressed: widget.state.openNewInvoice,
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar facturas',
            hintText: 'Cliente, número, fecha o compañía',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<Invoice>>(
            stream: _invoicesStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'No se pudieron cargar las facturas: ${snapshot.error}',
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final invoices = snapshot.data!
                  .where(_matchesSearch)
                  .toList(growable: false);
              if (invoices.isEmpty) {
                return Center(
                  child: Text(
                    _query.isEmpty
                        ? 'Todavía no hay facturas guardadas.'
                        : 'No hay facturas que coincidan con la búsqueda.',
                  ),
                );
              }

              return ListView.separated(
                itemCount: invoices.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  return InkWell(
                    onTap: () => widget.state.openInvoiceForEdit(invoice),
                    borderRadius: BorderRadius.circular(12),
                    child: SectionCard(
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_outlined),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invoice.invoiceCode ?? 'Factura en borrador',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _partyNames(invoice),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatDate(_invoiceDate(invoice))} · '
                                  '${invoice.lines.length} línea${invoice.lines.length == 1 ? '' : 's'} · '
                                  'Serie ${invoice.series}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(invoice.isIssued ? 'Emitida' : 'Borrador'),
                          const SizedBox(width: 12),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  bool _matchesSearch(Invoice invoice) {
    if (_query.isEmpty) {
      return true;
    }
    final date = _invoiceDate(invoice);
    final searchableText = <String>[
      invoice.invoiceCode ?? '',
      invoice.invoiceNumber?.toString() ?? '',
      invoice.companyName ?? '',
      invoice.customerName ?? '',
      _formatDate(date),
      _formatIsoDate(date),
    ].join(' ').toLowerCase();
    return searchableText.contains(_query);
  }

  DateTime _invoiceDate(Invoice invoice) {
    return invoice.documentDate ??
        invoice.issuedAt ??
        invoice.updatedAt ??
        invoice.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _partyNames(Invoice invoice) {
    final names = <String>[
      if (invoice.customerName?.trim().isNotEmpty == true)
        invoice.customerName!.trim(),
      if (invoice.companyName?.trim().isNotEmpty == true)
        invoice.companyName!.trim(),
    ];
    return names.isEmpty
        ? 'Sin datos de cliente o compañía'
        : names.join(' · ');
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  String _formatIsoDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
