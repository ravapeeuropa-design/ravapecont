import 'customer_email.dart';

class Customer {
  Customer({
    required this.id,
    required this.legalName,
    required this.active,
    required List<CustomerEmail> emails,
    this.taxId,
  }) : emails = List.unmodifiable(emails);

  final String id;
  final String legalName;
  final String? taxId;
  final bool active;
  final List<CustomerEmail> emails;

  Customer copyWith({
    String? id,
    String? legalName,
    String? taxId,
    bool? active,
    List<CustomerEmail>? emails,
  }) {
    return Customer(
      id: id ?? this.id,
      legalName: legalName ?? this.legalName,
      taxId: taxId ?? this.taxId,
      active: active ?? this.active,
      emails: emails ?? this.emails,
    );
  }
}
