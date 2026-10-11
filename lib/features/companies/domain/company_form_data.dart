import '../../../shared/domain/bank_account.dart';

class CompanyFormData {
  const CompanyFormData({
    required this.id,
    required this.legalName,
    required this.taxId,
    required this.addressLine1,
    required this.postalCode,
    required this.city,
    required this.country,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.tradeName,
    this.addressLine2,
    this.province,
    this.email,
    this.phone,
    this.website,
    this.bankAccounts = const <BankAccount>[],
  });

  final String id;
  final String legalName;
  final String? tradeName;
  final String taxId;
  final String addressLine1;
  final String? addressLine2;
  final String postalCode;
  final String city;
  final String? province;
  final String country;
  final String? email;
  final String? phone;
  final String? website;
  final List<BankAccount> bankAccounts;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompanyFormData copyWith({
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
    String? email,
    String? phone,
    String? website,
    List<BankAccount>? bankAccounts,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyFormData(
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
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
