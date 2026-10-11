import 'package:flutter/material.dart';

import '../../../app/app_local_state.dart';
import '../../../app/app_routes.dart';
import '../../../features/companies/data/firestore_company_repository.dart';
import '../../../features/companies/domain/company_form_data.dart';
import '../../../shared/widgets/app_data_table.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/empty_state.dart';
import 'company_form_dialog.dart';

class CompaniesPage extends StatelessWidget {
  const CompaniesPage({
    super.key,
    required this.repository,
    required this.state,
  });

  final FirestoreCompanyRepository repository;
  final AppLocalState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'Compañías',
          subtitle: 'Empresas emisoras de facturas y proformas.',
          actions: [
            AppPrimaryButton(
              label: 'Añadir compañía',
              onPressed: () =>
                  showCompanyDialog(context, state, repository: repository),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder(
            stream: repository.watchCompanies(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('No se han podido cargar las compañías.'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              final companies = snapshot.data!;
              if (companies.isEmpty) {
                return EmptyState(
                  title: 'No hay compañías creadas',
                  message: 'Crea la primera compañía para empezar a gestionar.',
                  action: AppPrimaryButton(
                    label: 'Añadir compañía',
                    onPressed: () => showCompanyDialog(
                      context,
                      state,
                      repository: repository,
                    ),
                  ),
                );
              }
              return _CompaniesSearchTable(
                companies: companies,
                state: state,
                repository: repository,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompaniesSearchTable extends StatefulWidget {
  const _CompaniesSearchTable({
    required this.companies,
    required this.state,
    required this.repository,
  });

  final List<CompanyFormData> companies;
  final AppLocalState state;
  final FirestoreCompanyRepository repository;

  @override
  State<_CompaniesSearchTable> createState() => _CompaniesSearchTableState();
}

class _CompaniesSearchTableState extends State<_CompaniesSearchTable> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final companies = widget.companies
        .where((company) {
          return query.isEmpty ||
              company.legalName.toLowerCase().contains(query) ||
              company.taxId.toLowerCase().contains(query) ||
              (company.tradeName?.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false);

    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar compañías',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: AppDataTable(
            columns: const [
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('NIF')),
              DataColumn(label: Text('Cuenta principal')),
              DataColumn(label: Text('Editar')),
            ],
            rows: [
              for (final company in companies)
                DataRow(
                  onSelectChanged: (_) => widget.state.navigateTo(
                    AppRoutes.companyDetail(company.id),
                  ),
                  cells: [
                    DataCell(Text(company.legalName)),
                    DataCell(Text(company.taxId)),
                    DataCell(
                      Text(
                        company.bankAccounts
                                .where((account) => account.isDefault)
                                .firstOrNull
                                ?.maskedIban ??
                            '',
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => showCompanyDialog(
                              context,
                              widget.state,
                              repository: widget.repository,
                              company: company,
                            ),
                            child: const Text('Editar'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Eliminar compañía'),
                                  content: const Text(
                                    'Esta acción eliminará la compañía de la sesión actual. No se puede deshacer.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await widget.repository.deleteCompany(
                                  company.id,
                                );
                              }
                            },
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
