class Company {
  const Company({
    required this.id,
    required this.legalName,
    required this.taxId,
    required this.active,
  });

  final String id;
  final String legalName;
  final String taxId;
  final bool active;

  Company copyWith({
    String? id,
    String? legalName,
    String? taxId,
    bool? active,
  }) {
    return Company(
      id: id ?? this.id,
      legalName: legalName ?? this.legalName,
      taxId: taxId ?? this.taxId,
      active: active ?? this.active,
    );
  }
}
