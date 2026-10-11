import 'package:cloud_firestore/cloud_firestore.dart';

import '../../companies/domain/company_form_data.dart';
import '../../../shared/domain/bank_account.dart';

Map<String, Object?> companyToFirestoreMap(CompanyFormData company) {
  final map = <String, Object?>{
    'legalName': company.legalName,
    'taxId': company.taxId,
    'addressLine1': company.addressLine1,
    'postalCode': company.postalCode,
    'city': company.city,
    'country': company.country,
    'billingAddress': <String, Object?>{
      'line1': company.addressLine1,
      'line2': company.addressLine2,
      'postalCode': company.postalCode,
      'city': company.city,
      'province': company.province,
      'country': company.country,
    },
    'active': company.active,
    'bankAccounts': normalizeBankAccounts(
      company.bankAccounts,
    ).map((account) => account.toMap()).toList(growable: false),
    'createdAt': Timestamp.fromDate(company.createdAt.toUtc()),
    'updatedAt': Timestamp.fromDate(company.updatedAt.toUtc()),
  };
  if (company.tradeName != null) map['tradeName'] = company.tradeName;
  if (company.addressLine2 != null) map['addressLine2'] = company.addressLine2;
  if (company.province != null) map['province'] = company.province;
  if (company.email != null) map['email'] = company.email;
  if (company.phone != null) map['phone'] = company.phone;
  if (company.website != null) map['website'] = company.website;
  return map;
}

CompanyFormData companyFromFirestoreMap(String id, Map<String, dynamic> data) {
  final billing =
      data['billingAddress'] as Map<String, dynamic>? ?? <String, dynamic>{};
  return CompanyFormData(
    id: id,
    legalName: data['legalName'] as String,
    tradeName: data['tradeName'] as String?,
    taxId: data['taxId'] as String,
    addressLine1:
        data['addressLine1'] as String? ?? billing['line1'] as String? ?? '',
    addressLine2:
        data['addressLine2'] as String? ?? billing['line2'] as String?,
    postalCode:
        data['postalCode'] as String? ?? billing['postalCode'] as String? ?? '',
    city: data['city'] as String? ?? billing['city'] as String? ?? '',
    province: data['province'] as String? ?? billing['province'] as String?,
    country:
        data['country'] as String? ?? billing['country'] as String? ?? 'España',
    email: data['email'] as String?,
    phone: data['phone'] as String?,
    website: data['website'] as String?,
    active: data['active'] as bool,
    bankAccounts: normalizeBankAccounts(
      (data['bankAccounts'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(BankAccount.fromMap),
    ),
    createdAt: _dateTimeFromFirestore(data['createdAt']),
    updatedAt: _dateTimeFromFirestore(data['updatedAt']),
  );
}

DateTime _dateTimeFromFirestore(Object? value) {
  if (value is Timestamp) {
    return value.toDate().toUtc();
  }
  if (value is DateTime) {
    return value.toUtc();
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
