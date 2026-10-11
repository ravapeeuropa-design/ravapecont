import 'package:flutter/material.dart';

import '../../../app/app_local_state.dart';
import '../../../features/customers/data/firestore_customer_repository.dart';
import '../../../features/customers/domain/customer_form_data.dart';
import '../../../shared/widgets/app_data_table.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/empty_state.dart';
import 'customer_form_dialog.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({
    super.key,
    required this.repository,
    required this.state,
  });

  final FirestoreCustomerRepository repository;
  final AppLocalState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'Clientes',
          subtitle: 'Destinatarios de facturas y proformas.',
          actions: [
            AppPrimaryButton(
              label: 'Añadir cliente',
              onPressed: () =>
                  showCustomerDialog(context, state, repository: repository),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder(
            stream: repository.watchCustomers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('No se han podido cargar los clientes.'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              final customers = snapshot.data!;
              if (customers.isEmpty) {
                return EmptyState(
                  title: 'No hay clientes creados',
                  message: 'Crea el primer cliente para empezar.',
                  action: AppPrimaryButton(
                    label: 'Añadir cliente',
                    onPressed: () => showCustomerDialog(
                      context,
                      state,
                      repository: repository,
                    ),
                  ),
                );
              }
              return _CustomersSearchTable(
                customers: customers,
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

class _CustomersSearchTable extends StatefulWidget {
  const _CustomersSearchTable({
    required this.customers,
    required this.state,
    required this.repository,
  });

  final List<CustomerFormData> customers;
  final AppLocalState state;
  final FirestoreCustomerRepository repository;

  @override
  State<_CustomersSearchTable> createState() => _CustomersSearchTableState();
}

class _CustomersSearchTableState extends State<_CustomersSearchTable> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final customers = widget.customers
        .where((customer) {
          return query.isEmpty ||
              customer.legalName.toLowerCase().contains(query) ||
              (customer.taxId?.toLowerCase().contains(query) ?? false) ||
              (customer.tradeName?.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false);

    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar clientes',
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
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Cuenta principal')),
              DataColumn(label: Text('Editar')),
            ],
            rows: [
              for (final customer in customers)
                DataRow(
                  onSelectChanged: (_) =>
                      widget.state.selectCustomer(customer.id),
                  cells: [
                    DataCell(Text(customer.legalName)),
                    DataCell(Text(customer.taxId ?? '')),
                    DataCell(
                      Text(
                        customer.emails.isEmpty ? '' : customer.emails.first,
                      ),
                    ),
                    DataCell(
                      Text(
                        customer.bankAccounts
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
                            onPressed: () => showCustomerDialog(
                              context,
                              widget.state,
                              repository: widget.repository,
                              customer: customer,
                            ),
                            child: const Text('Editar'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Eliminar cliente'),
                                  content: const Text(
                                    'Esta acción eliminará el cliente de la sesión actual. No se puede deshacer.',
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
                                await widget.repository.deleteCustomer(
                                  customer.id,
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
