class FirestorePaths {
  static const companiesCollection = 'companies';
  static const customersCollection = 'customers';
  static const documentDraftsCollection = 'documentDrafts';
  static const invoicesCollection = 'invoices';
  static const invoiceCountersCollection = 'invoiceCounters';

  static String companyDocument(String id) => '$companiesCollection/$id';
  static String customerDocument(String id) => '$customersCollection/$id';
}
