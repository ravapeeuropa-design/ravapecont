import 'package:cloud_firestore/cloud_firestore.dart';

import '../../customers/domain/customer_form_data.dart';
import '../../../shared/domain/bank_account.dart';

Map<String, Object?> customerToFirestoreMap(CustomerFormData customer) {
  final map = <String, Object?>{
    'legalName': customer.legalName,
    'addressLine1': customer.addressLine1,
    'postalCode': customer.postalCode,
    'city': customer.city,
    'country': customer.country,
    'emails': customer.emails,
    'active': customer.active,
    'billingAddress': <String, Object?>{
      'line1': customer.addressLine1,
      'line2': customer.addressLine2,
      'postalCode': customer.postalCode,
      'city': customer.city,
      'province': customer.province,
      'country': customer.country,
    },
    'shippingAddress': <String, Object?>{
      'line1': customer.shippingAddressLine1,
      'line2': customer.shippingAddressLine2,
      'postalCode': customer.shippingPostalCode,
      'city': customer.shippingCity,
      'province': customer.shippingProvince,
      'country': customer.shippingCountry,
    },
    'bankAccounts': normalizeBankAccounts(
      customer.bankAccounts,
    ).map((account) => account.toMap()).toList(growable: false),
    'createdAt': Timestamp.fromDate(customer.createdAt.toUtc()),
    'updatedAt': Timestamp.fromDate(customer.updatedAt.toUtc()),
  };
  if (customer.tradeName != null) map['tradeName'] = customer.tradeName;
  if (customer.taxId != null) map['taxId'] = customer.taxId;
  if (customer.addressLine2 != null) {
    map['addressLine2'] = customer.addressLine2;
  }
  if (customer.province != null) map['province'] = customer.province;
  if (customer.phone != null) map['phone'] = customer.phone;
  return map;
}

CustomerFormData customerFromFirestoreMap(
  String id,
  Map<String, dynamic> data,
) {
  final billing =
      data['billingAddress'] as Map<String, dynamic>? ?? <String, dynamic>{};
  final shipping =
      data['shippingAddress'] as Map<String, dynamic>? ?? <String, dynamic>{};
  return CustomerFormData(
    id: id,
    legalName: data['legalName'] as String,
    tradeName: data['tradeName'] as String?,
    taxId: data['taxId'] as String?,
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
    emails: List<String>.from(
      data['emails'] as List<dynamic>? ?? const <dynamic>[],
    ),
    phone: data['phone'] as String?,
    shippingAddressLine1: shipping['line1'] as String?,
    shippingAddressLine2: shipping['line2'] as String?,
    shippingPostalCode: shipping['postalCode'] as String?,
    shippingCity: shipping['city'] as String?,
    shippingProvince: shipping['province'] as String?,
    shippingCountry: shipping['country'] as String?,
    bankAccounts: normalizeBankAccounts(
      (data['bankAccounts'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(BankAccount.fromMap),
    ),
    active: data['active'] as bool,
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
