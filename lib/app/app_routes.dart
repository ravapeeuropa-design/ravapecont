class AppRoutes {
  static const dashboard = '/dashboard';
  static const companies = '/companies';
  static const customers = '/customers';
  static const documentsNew = '/documents/new';
  static const documentsReview = '/documents/review';
  static const String documentsList = '/documents';
  static const invoicesList = '/invoices';
  static const invoiceEditor = '/invoice-editor';
  static const selectProformaForInvoice = '/select-proforma-for-invoice';
  static const settings = '/settings';

  static String companyDetail(String companyId) => '/companies/$companyId';
  static String customerDetail(String customerId) => '/customers/$customerId';
  static String companyInvoices(String companyId) =>
      '/companies/$companyId/invoices';
  static String companyQuotes(String companyId) =>
      '/companies/$companyId/quotes';
}
