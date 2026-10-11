import '../../../shared/domain/bank_account.dart';

class CustomerFormData {
  CustomerFormData({
    required this.id,
    required this.legalName,
    required this.addressLine1,
    required this.postalCode,
    required this.city,
    required this.country,
    required List<String> emails,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.tradeName,
    this.taxId,
    this.addressLine2,
    this.province,
    this.phone,
    this.shippingAddressLine1,
    this.shippingAddressLine2,
    this.shippingPostalCode,
    this.shippingCity,
    this.shippingProvince,
    this.shippingCountry,
    this.bankAccounts = const <BankAccount>[],
  }) : emails = List.unmodifiable(emails);

  final String id;
  final String legalName;
  final String? tradeName;
  final String? taxId;
  final String addressLine1;
  final String? addressLine2;
  final String postalCode;
  final String city;
  final String? province;
  final String country;
  final List<String> emails;
  final String? phone;
  final String? shippingAddressLine1;
  final String? shippingAddressLine2;
  final String? shippingPostalCode;
  final String? shippingCity;
  final String? shippingProvince;
  final String? shippingCountry;
  final List<BankAccount> bankAccounts;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerFormData copyWith({
    String? id,
    String? legalName,
    String? tradeName,
    String? taxId,
    String? addressLine1,
    String? addressLine2,
    String? postalCode,
    String? city,
    String? province,
    String? country,
    List<String>? emails,
    String? phone,
    String? shippingAddressLine1,
    String? shippingAddressLine2,
    String? shippingPostalCode,
    String? shippingCity,
    String? shippingProvince,
    String? shippingCountry,
    List<BankAccount>? bankAccounts,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerFormData(
      id: id ?? this.id,
      legalName: legalName ?? this.legalName,
      tradeName: tradeName ?? this.tradeName,
      taxId: taxId ?? this.taxId,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      province: province ?? this.province,
      country: country ?? this.country,
      emails: emails ?? this.emails,
      phone: phone ?? this.phone,
      shippingAddressLine1: shippingAddressLine1 ?? this.shippingAddressLine1,
      shippingAddressLine2: shippingAddressLine2 ?? this.shippingAddressLine2,
      shippingPostalCode: shippingPostalCode ?? this.shippingPostalCode,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingProvince: shippingProvince ?? this.shippingProvince,
      shippingCountry: shippingCountry ?? this.shippingCountry,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
