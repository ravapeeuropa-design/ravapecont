import 'package:flutter/material.dart';

import '../../../app/app_local_state.dart';
import '../../../app/app_routes.dart';
import '../../../features/companies/data/firestore_company_repository.dart';
import '../../../features/companies/domain/company_form_data.dart';
import '../../../features/customers/data/firestore_customer_repository.dart';
import '../../../features/customers/domain/customer_form_data.dart';
import '../../../features/documents/data/firestore_document_draft_repository.dart';
import '../../../features/documents/domain/document_draft.dart';
import '../../../features/invoices/data/firestore_invoice_repository.dart';
import '../../../features/invoices/domain/invoice.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/section_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.state,
    required this.companyRepository,
    required this.customerRepository,
    required this.documentRepository,
    required this.invoiceRepository,
    required this.onAddCompany,
    required this.onAddCustomer,
    required this.onAddInvoice,
  });

  final AppLocalState state;
  final FirestoreCompanyRepository companyRepository;
  final FirestoreCustomerRepository customerRepository;
  final FirestoreDocumentDraftRepository documentRepository;
  final FirestoreInvoiceRepository invoiceRepository;
  final Future<void> Function() onAddCompany;
  final Future<void> Function() onAddCustomer;
  final VoidCallback onAddInvoice;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final Stream<List<CompanyFormData>> _companiesStream;
  late final Stream<List<CustomerFormData>> _customersStream;
  late final Stream<List<DocumentDraft>> _proformasStream;
  late final Stream<List<Invoice>> _invoicesStream;

  AppLocalState get state => widget.state;
  FirestoreCompanyRepository get companyRepository => widget.companyRepository;
  FirestoreCustomerRepository get customerRepository =>
      widget.customerRepository;
  Future<void> Function() get onAddCompany => widget.onAddCompany;
  Future<void> Function() get onAddCustomer => widget.onAddCustomer;
  VoidCallback get onAddInvoice => widget.onAddInvoice;

  @override
  void initState() {
    super.initState();
    _companiesStream = widget.companyRepository.watchCompanies();
    _customersStream = widget.customerRepository.watchCustomers();
    _proformasStream = widget.documentRepository.watchDrafts().map(
      (drafts) => drafts
          .where((draft) => draft.documentType == 'proforma')
          .toList(growable: false),
    );
    _invoicesStream = widget.invoiceRepository.watchInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1280
            ? 4
            : (width >= 960 ? 3 : (width >= 680 ? 2 : 1));
        final horizontalPadding = width >= 1280 ? 32.0 : 16.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPageHeader(
              title: 'Inicio',
              subtitle: 'Gestión privada de facturas y proformas.',
              actions: [
                AppSecondaryButton(
                  label: 'Añadir compañía',
                  onPressed: () async => onAddCompany(),
                ),
                AppSecondaryButton(
                  label: 'Añadir cliente',
                  onPressed: () async => onAddCustomer(),
                ),
                AppPrimaryButton(
                  label: 'Añadir factura',
                  onPressed: onAddInvoice,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _DashboardMetricCard(
                    onTap: () => state.navigateTo(AppRoutes.companies),
                    child: StreamBuilder(
                      stream: _companiesStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const _MetricCard(
                            title: 'Compañías',
                            value: 'No disponible',
                          );
                        }

                        if (!snapshot.hasData) {
                          return const _MetricCard(
                            title: 'Compañías',
                            value: 'Cargando',
                          );
                        }

                        return _MetricCard(
                          title: 'Compañías',
                          value: snapshot.data!.length.toString(),
                        );
                      },
                    ),
                  ),
                  _DashboardMetricCard(
                    onTap: () => state.navigateTo(AppRoutes.customers),
                    child: StreamBuilder(
                      stream: _customersStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const _MetricCard(
                            title: 'Clientes',
                            value: 'No disponible',
                          );
                        }

                        if (!snapshot.hasData) {
                          return const _MetricCard(
                            title: 'Clientes',
                            value: 'Cargando',
                          );
                        }

                        return _MetricCard(
                          title: 'Clientes',
                          value: snapshot.data!.length.toString(),
                        );
                      },
                    ),
                  ),
                  _DashboardDocumentsCard<Invoice>(
                    title: 'Facturas',
                    stream: _invoicesStream,
                    emptyMessage: 'No hay facturas.',
                    onOpenList: state.openInvoicesList,
                    onOpenItem: state.openInvoiceForEdit,
                    itemBuilder: (invoice) => _DashboardDocumentItem(
                      title: invoice.invoiceCode ?? 'Factura en borrador',
                      subtitle: _partyNames(
                        invoice.companyName,
                        invoice.customerName,
                      ),
                      date: invoice.documentDate ?? invoice.updatedAt,
                    ),
                  ),
                  StreamBuilder(
                    stream: _companiesStream,
                    builder: (context, companiesSnapshot) {
                      return StreamBuilder(
                        stream: _customersStream,
                        builder: (context, customersSnapshot) {
                          final companyNames = {
                            for (final company
                                in companiesSnapshot.data ??
                                    const <CompanyFormData>[])
                              company.id: company.legalName,
                          };
                          final customerNames = {
                            for (final customer
                                in customersSnapshot.data ??
                                    const <CustomerFormData>[])
                              customer.id: customer.legalName,
                          };
                          return _DashboardDocumentsCard<DocumentDraft>(
                            title: 'Proformas',
                            stream: _proformasStream,
                            emptyMessage: 'No hay proformas.',
                            onOpenList: () =>
                                state.navigateTo(AppRoutes.documentsList),
                            onOpenItem: state.editDraft,
                            itemBuilder: (draft) => _DashboardDocumentItem(
                              title:
                                  draft.documentNumber ??
                                  'Proforma en borrador',
                              subtitle: _partyNames(
                                companyNames[draft.companyId],
                                customerNames[draft.customerId],
                              ),
                              date: draft.updatedAt,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _partyNames(String? companyName, String? customerName) {
    final names = [
      companyName?.trim(),
      customerName?.trim(),
    ].whereType<String>().where((name) => name.isNotEmpty).toList();
    return names.isEmpty
        ? 'Sin datos de compañía o cliente'
        : names.join(' · ');
  }
}

class _DashboardDocumentsCard<T> extends StatelessWidget {
  const _DashboardDocumentsCard({
    required this.title,
    required this.stream,
    required this.emptyMessage,
    required this.onOpenList,
    required this.onOpenItem,
    required this.itemBuilder,
  });

  final String title;
  final Stream<List<T>> stream;
  final String emptyMessage;
  final VoidCallback onOpenList;
  final ValueChanged<T> onOpenItem;
  final _DashboardDocumentItem Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onOpenList,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<T>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('No disponible'));
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  );
                }
                final items = snapshot.data!;
                if (items.isEmpty) {
                  return Center(child: Text(emptyMessage));
                }
                return Scrollbar(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final presentation = itemBuilder(item);
                      return InkWell(
                        onTap: () => onOpenItem(item),
                        child: presentation,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardDocumentItem extends StatelessWidget {
  const _DashboardDocumentItem({
    required this.title,
    required this.subtitle,
    required this.date,
  });

  final String title;
  final String subtitle;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (date != null)
            Text(
              _formatDate(date!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(padding: const EdgeInsets.all(4), child: child),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
