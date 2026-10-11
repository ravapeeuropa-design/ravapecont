import 'package:flutter/material.dart';

import '../features/auth/domain/app_user.dart';
import '../features/companies/data/firestore_company_repository.dart';
import '../features/companies/presentation/company_detail_page.dart';
import '../features/companies/presentation/companies_page.dart';
import '../features/companies/presentation/company_form_dialog.dart';
import '../features/customers/data/firestore_customer_repository.dart';
import '../features/customers/presentation/customers_page.dart';
import '../features/customers/presentation/customer_detail_page.dart';
import '../features/customers/presentation/customer_form_dialog.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/documents/data/firestore_document_draft_repository.dart';
import '../features/documents/presentation/add_document_page.dart';
import '../features/documents/presentation/document_review_page.dart';
import '../features/documents/presentation/documents_list_page.dart';
import '../features/invoices/presentation/invoices_list_page.dart';
import '../features/invoices/data/firestore_invoice_repository.dart';
import '../features/invoices/presentation/invoice_editor_page.dart';
import '../features/quotes/presentation/quotes_list_page.dart';
import '../features/settings/presentation/settings_page.dart';
import 'app_local_state.dart';
import 'app_navigation_item.dart';
import 'app_routes.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.currentUser,
    required this.onSignOutRequested,
    required this.companyRepository,
    required this.customerRepository,
    required this.onThemeModeChanged,
    required this.currentThemeMode,
  });

  final AppUser currentUser;
  final Future<void> Function() onSignOutRequested;
  final FirestoreCompanyRepository companyRepository;
  final FirestoreCustomerRepository customerRepository;
  final Future<void> Function(ThemeMode themeMode) onThemeModeChanged;
  final ThemeMode currentThemeMode;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AppLocalState _state = AppLocalState();
  final FirestoreDocumentDraftRepository _documentDraftRepository =
      FirestoreDocumentDraftRepository();
  final FirestoreInvoiceRepository _invoiceRepository =
      FirestoreInvoiceRepository();

  final List<AppNavigationItem> _navigationItems = const [
    AppNavigationItem(
      route: AppRoutes.dashboard,
      label: 'Inicio',
      icon: Icons.space_dashboard_outlined,
    ),
    AppNavigationItem(
      route: AppRoutes.companies,
      label: 'Compañías',
      icon: Icons.apartment_outlined,
    ),
    AppNavigationItem(
      route: AppRoutes.customers,
      label: 'Clientes',
      icon: Icons.people_outline,
    ),
    AppNavigationItem(
      route: AppRoutes.documentsList,
      label: 'Proformas',
      icon: Icons.description_outlined,
    ),
    AppNavigationItem(
      route: AppRoutes.invoicesList,
      label: 'Facturas',
      icon: Icons.receipt_long_outlined,
    ),
    AppNavigationItem(
      route: AppRoutes.settings,
      label: 'Ajustes',
      icon: Icons.settings_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1100) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Ravapecont requiere una pantalla de escritorio de al menos 1100 px.',
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Row(
              children: [
                _Sidebar(
                  state: _state,
                  items: _navigationItems,
                  userEmail: widget.currentUser.email.isEmpty
                      ? 'Usuario sin email'
                      : widget.currentUser.email,
                  onNavigate: (route) {
                    if (route == AppRoutes.invoicesList) {
                      _state.openInvoicesList();
                      return;
                    }
                    _state.navigateTo(route);
                  },
                  onSignOutRequested: widget.onSignOutRequested,
                  onThemeModeChanged: widget.onThemeModeChanged,
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _state,
                    builder: (context, child) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildPage(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage() {
    final route = _state.currentRoute;
    final companyId = _state.companyIdFromRoute(route);
    if (route == AppRoutes.dashboard) {
      return DashboardPage(
        state: _state,
        companyRepository: widget.companyRepository,
        customerRepository: widget.customerRepository,
        documentRepository: _documentDraftRepository,
        invoiceRepository: _invoiceRepository,
        onAddCompany: () => showCompanyDialog(
          context,
          _state,
          repository: widget.companyRepository,
        ),
        onAddCustomer: () => showCustomerDialog(
          context,
          _state,
          repository: widget.customerRepository,
        ),
        onAddInvoice: _state.openNewInvoice,
      );
    }
    if (route == AppRoutes.companies) {
      return CompaniesPage(repository: widget.companyRepository, state: _state);
    }
    if (route == AppRoutes.customers) {
      return CustomersPage(
        repository: widget.customerRepository,
        state: _state,
      );
    }
    if (route.startsWith('${AppRoutes.customers}/')) {
      final customerId = route.substring('${AppRoutes.customers}/'.length);
      if (customerId.isNotEmpty && !customerId.contains('/')) {
        return CustomerDetailPage(
          repository: widget.customerRepository,
          state: _state,
          customerId: customerId,
        );
      }
    }
    if (route == AppRoutes.documentsNew) {
      return AddDocumentPage(
        state: _state,
        companyRepository: widget.companyRepository,
        customerRepository: widget.customerRepository,
      );
    }
    if (route == AppRoutes.documentsReview) {
      return DocumentReviewPage(
        state: _state,
        companyRepository: widget.companyRepository,
        customerRepository: widget.customerRepository,
      );
    }
    if (route == AppRoutes.documentsList) {
      return DocumentsListPage(
        state: _state,
        repository: _documentDraftRepository,
      );
    }
    if (route == AppRoutes.invoicesList) {
      return InvoicesListPage(state: _state, repository: _invoiceRepository);
    }
    if (route == AppRoutes.selectProformaForInvoice) {
      return DocumentsListPage(
        state: _state,
        repository: _documentDraftRepository,
        mode: DocumentsListMode.selectProformaForInvoice,
      );
    }
    if (route == AppRoutes.invoiceEditor) {
      return InvoiceEditorPage(
        state: _state,
        repository: _invoiceRepository,
        companyRepository: widget.companyRepository,
        customerRepository: widget.customerRepository,
        invoiceId: _state.editingInvoiceId,
        initialInvoice: _state.initialInvoice,
        sourceProformaId: _state.sourceProformaId,
        sourceProformaNumber: _state.sourceProformaNumber,
      );
    }
    if (route == AppRoutes.settings) {
      return SettingsPage(
        currentUser: widget.currentUser,
        currentThemeMode: widget.currentThemeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        onSignOutRequested: widget.onSignOutRequested,
      );
    }
    if (route.endsWith('/invoices')) {
      if (companyId == null) {
        return CompaniesPage(
          repository: widget.companyRepository,
          state: _state,
        );
      }
      return InvoicesListPage(state: _state, repository: _invoiceRepository);
    }
    if (route.endsWith('/quotes')) {
      if (companyId == null) {
        return CompaniesPage(
          repository: widget.companyRepository,
          state: _state,
        );
      }
      return QuotesListPage(state: _state);
    }
    if (route.startsWith('/companies/')) {
      if (companyId == null) {
        return CompaniesPage(
          repository: widget.companyRepository,
          state: _state,
        );
      }
      return CompanyDetailPage(
        state: _state,
        companyId: companyId,
        repository: widget.companyRepository,
      );
    }
    return DashboardPage(
      state: _state,
      companyRepository: widget.companyRepository,
      customerRepository: widget.customerRepository,
      documentRepository: _documentDraftRepository,
      invoiceRepository: _invoiceRepository,
      onAddCompany: () => showCompanyDialog(
        context,
        _state,
        repository: widget.companyRepository,
      ),
      onAddCustomer: () => showCustomerDialog(
        context,
        _state,
        repository: widget.customerRepository,
      ),
      onAddInvoice: _state.openNewInvoice,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.state,
    required this.items,
    required this.userEmail,
    required this.onNavigate,
    required this.onSignOutRequested,
    required this.onThemeModeChanged,
  });

  final AppLocalState state;
  final List<AppNavigationItem> items;
  final String userEmail;
  final ValueChanged<String> onNavigate;
  final Future<void> Function() onSignOutRequested;
  final Future<void> Function(ThemeMode themeMode) onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(right: BorderSide(color: colorScheme.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ravapecont',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton<ThemeMode>(
                  icon: const Icon(Icons.palette_outlined),
                  tooltip: 'Cambiar tema',
                  onSelected: (themeMode) async {
                    await onThemeModeChanged(themeMode);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<ThemeMode>(
                      value: ThemeMode.light,
                      child: Row(
                        children: [
                          Icon(Icons.light_mode_outlined),
                          SizedBox(width: 12),
                          Text('Tema claro'),
                        ],
                      ),
                    ),
                    PopupMenuItem<ThemeMode>(
                      value: ThemeMode.dark,
                      child: Row(
                        children: [
                          Icon(Icons.dark_mode_outlined),
                          SizedBox(width: 12),
                          Text('Tema oscuro'),
                        ],
                      ),
                    ),
                    PopupMenuItem<ThemeMode>(
                      value: ThemeMode.system,
                      child: Row(
                        children: [
                          Icon(Icons.brightness_auto_outlined),
                          SizedBox(width: 12),
                          Text('Usar sistema'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = _isSelected(item.route);
                return InkWell(
                  onTap: () => onNavigate(item.route),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? colorScheme.surfaceContainer : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? colorScheme.outline
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          color: selected
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemCount: items.length,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uso privado',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(userEmail, style: TextStyle(color: colorScheme.onSurface)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onSignOutRequested,
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSelected(String route) {
    if (route == AppRoutes.dashboard) {
      return state.currentRoute == AppRoutes.dashboard;
    }
    if (route == AppRoutes.companies) {
      return state.currentRoute == AppRoutes.companies ||
          state.currentRoute.startsWith('/companies/');
    }
    if (route == AppRoutes.invoicesList) {
      return state.currentRoute == AppRoutes.invoicesList ||
          state.currentRoute == AppRoutes.invoiceEditor ||
          state.currentRoute == AppRoutes.selectProformaForInvoice;
    }
    return state.currentRoute == route;
  }
}
