enum CompanyEmailProvider { gmailOauth, smtp, microsoftOauth }

enum CompanyEmailAccountStatus { pending, connected, error, revoked }

class CompanyEmailAccount {
  const CompanyEmailAccount({
    required this.id,
    required this.companyId,
    required this.email,
    required this.displayName,
    required this.provider,
    required this.status,
    required this.isDefault,
    this.replyTo,
  });

  final String id;
  final String companyId;
  final String email;
  final String displayName;
  final String? replyTo;
  final CompanyEmailProvider provider;
  final CompanyEmailAccountStatus status;
  final bool isDefault;

  CompanyEmailAccount copyWith({
    String? id,
    String? companyId,
    String? email,
    String? displayName,
    String? replyTo,
    CompanyEmailProvider? provider,
    CompanyEmailAccountStatus? status,
    bool? isDefault,
  }) {
    return CompanyEmailAccount(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      replyTo: replyTo ?? this.replyTo,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
