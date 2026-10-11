import 'package:flutter/material.dart';

import '../../../app/app_local_state.dart';
import '../../../app/app_routes.dart';
import '../../../features/companies/data/firestore_company_repository.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_secondary_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';
import 'company_form_dialog.dart';

class CompanyDetailPage extends StatelessWidget {
  const CompanyDetailPage({
    super.key,
    required this.repository,
    required this.state,
    required this.companyId,
  });

  final FirestoreCompanyRepository repository;
  final AppLocalState state;
  final String companyId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: repository.watchCompanies(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Compañía no encontrada'));
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        final company = snapshot.data!
            .where((item) => item.id == companyId)
            .firstOrNull;
        if (company == null) {
          return EmptyState(
            title: 'Compañía no encontrada',
            message: 'La compañía solicitada ya no está disponible.',
            action: AppPrimaryButton(
              label: 'Volver a compañías',
              onPressed: () => state.navigateTo(AppRoutes.companies),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPageHeader(
              title: company.legalName,
              subtitle: company.taxId,
              actions: [
                AppSecondaryButton(
                  label: 'Volver',
                  onPressed: () => state.navigateTo(AppRoutes.companies),
                ),
                AppSecondaryButton(
                  label: company.active ? 'Activa' : 'Inactiva',
                  onPressed: () {},
                ),
                AppPrimaryButton(
                  label: 'Modificar compañía',
                  onPressed: () => showCompanyDialog(
                    context,
                    state,
                    repository: repository,
                    company: company,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cuentas bancarias'),
                  const SizedBox(height: 8),
                  if (company.bankAccounts.isEmpty)
                    const Text('No hay cuentas bancarias.')
                  else
                    for (final account in company.bankAccounts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          account.isDefault
                              ? Icons.star
                              : Icons.account_balance_outlined,
                        ),
                        title: Text(account.alias ?? account.maskedIban),
                        subtitle: Text(
                          '${account.maskedIban}${account.bankName == null ? '' : ' · ${account.bankName}'}',
                        ),
                      ),
                ],
              ),
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
                        const Text('Datos fiscales'),
                        Text('Razón social: ${company.legalName}'),
                        Text('NIF/CIF: ${company.taxId}'),
                        Text('Dirección: ${company.addressLine1}'),
                        Text('Ciudad: ${company.city}'),
                        Text('País: ${company.country}'),
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
                        const Text('Contacto'),
                        Text('Email: ${company.email ?? ''}'),
                        Text('Teléfono: ${company.phone ?? ''}'),
                        Text('Web: ${company.website ?? ''}'),
                        Text(
                          'Estado: ${company.active ? 'Activa' : 'Inactiva'}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        state.navigateTo(AppRoutes.companyInvoices(company.id)),
                    child: const SectionCard(
                      child: SizedBox(
                        height: 140,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Facturas'),
                            SizedBox(height: 8),
                            Text(
                              'Consultar facturas emitidas por esta compañía',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        state.navigateTo(AppRoutes.companyQuotes(company.id)),
                    child: const SectionCard(
                      child: SizedBox(
                        height: 140,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Proformas'),
                            SizedBox(height: 8),
                            Text(
                              'Consultar proformas creadas por esta compañía',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

extension FirstOrNullCompany<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
