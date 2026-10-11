import 'package:flutter/material.dart';

import '../../../app/app_local_state.dart';
import '../../../app/app_routes.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';
import '../data/firestore_customer_repository.dart';
import 'customer_form_dialog.dart';

class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({
    super.key,
    required this.repository,
    required this.state,
    required this.customerId,
  });

  final FirestoreCustomerRepository repository;
  final AppLocalState state;
  final String customerId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: repository.watchCustomers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Cliente no encontrado'));
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final customer = snapshot.data!
            .where((item) => item.id == customerId)
            .firstOrNull;
        if (customer == null) {
          return EmptyState(
            title: 'Cliente no encontrado',
            message: 'El cliente solicitado ya no está disponible.',
            action: AppPrimaryButton(
              label: 'Volver a clientes',
              onPressed: () => state.navigateTo(AppRoutes.customers),
            ),
          );
        }

        return ListView(
          children: [
            AppPageHeader(
              title: customer.legalName,
              subtitle: customer.taxId ?? 'Sin NIF/CIF',
              actions: [
                AppSecondaryButton(
                  label: 'Volver',
                  onPressed: () => state.navigateTo(AppRoutes.customers),
                ),
                AppPrimaryButton(
                  label: 'Modificar cliente',
                  onPressed: () => showCustomerDialog(
                    context,
                    state,
                    repository: repository,
                    customer: customer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Datos fiscales y facturación'),
                        Text('Razón social: ${customer.legalName}'),
                        Text('NIF/CIF: ${customer.taxId ?? ''}'),
                        Text('Dirección: ${customer.addressLine1}'),
                        Text('${customer.postalCode} ${customer.city}'),
                        Text('País: ${customer.country}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Envío y contacto'),
                        Text(
                          'Envío: ${customer.shippingAddressLine1 ?? 'No especificado'}',
                        ),
                        Text('Ciudad: ${customer.shippingCity ?? ''}'),
                        Text('Emails: ${customer.emails.join(', ')}'),
                        Text('Teléfono: ${customer.phone ?? ''}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cuentas bancarias'),
                  const SizedBox(height: 8),
                  if (customer.bankAccounts.isEmpty)
                    const Text('No hay cuentas bancarias.')
                  else
                    for (final account in customer.bankAccounts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          account.isDefault
                              ? Icons.star
                              : Icons.account_balance_outlined,
                        ),
                        title: Text(account.alias ?? account.maskedIban),
                        subtitle: Text(account.maskedIban),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
