/// Company headcount band.
///
/// Kept as a small, stable enum (not a free-form number) so it round-trips
/// cleanly to Firestore and localizes to EN/AR. Enum names are stored as-is;
/// [fromName] also tolerates the human range strings ("11-50", "1000+").
enum CompanySize {
  size1_10,
  size11_50,
  size51_200,
  size201_500,
  size501_1000,
  size1000plus;

  /// The human range label backing each band (used for tolerant parsing; the
  /// UI reads localized labels via `company_l10n.dart`).
  String get range => switch (this) {
        CompanySize.size1_10 => '1-10',
        CompanySize.size11_50 => '11-50',
        CompanySize.size51_200 => '51-200',
        CompanySize.size201_500 => '201-500',
        CompanySize.size501_1000 => '501-1000',
        CompanySize.size1000plus => '1000+',
      };

  static CompanySize? fromName(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase();
    for (final size in CompanySize.values) {
      if (size.name.toLowerCase() == normalized) return size;
    }
    // Tolerate the human range encoding ("11-50", "1000+").
    final compact = normalized.replaceAll(' ', '');
    for (final size in CompanySize.values) {
      if (size.range.replaceAll(' ', '') == compact) return size;
    }
    return null;
  }
}
