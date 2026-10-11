enum CustomerEmailConsentStatus { unknown, granted, denied, tacit }

enum CustomerEmailConsentMethod { written, contract, email, portalAccess, other }

class CustomerEmail {
  const CustomerEmail({
    required this.id,
    required this.email,
    required this.isDefault,
    required this.active,
    required this.consentStatus,
    required this.consentMethod,
    this.label,
    this.contactName,
    this.evidenceReference,
  });

  final String id;
  final String email;
  final String? label;
  final String? contactName;
  final bool isDefault;
  final bool active;
  final CustomerEmailConsentStatus consentStatus;
  final CustomerEmailConsentMethod consentMethod;
  final String? evidenceReference;

  CustomerEmail copyWith({
    String? id,
    String? email,
    String? label,
    String? contactName,
    bool? isDefault,
    bool? active,
    CustomerEmailConsentStatus? consentStatus,
    CustomerEmailConsentMethod? consentMethod,
    String? evidenceReference,
  }) {
    return CustomerEmail(
      id: id ?? this.id,
      email: email ?? this.email,
      label: label ?? this.label,
      contactName: contactName ?? this.contactName,
      isDefault: isDefault ?? this.isDefault,
      active: active ?? this.active,
      consentStatus: consentStatus ?? this.consentStatus,
      consentMethod: consentMethod ?? this.consentMethod,
      evidenceReference: evidenceReference ?? this.evidenceReference,
    );
  }
}
