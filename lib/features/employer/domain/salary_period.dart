/// The period a salary range refers to.
enum SalaryPeriod {
  yearly,
  monthly,
  hourly;

  static SalaryPeriod fromName(Object? value) {
    if (value is! String) return SalaryPeriod.yearly;
    final v = value.trim().toLowerCase();
    for (final p in SalaryPeriod.values) {
      if (p.name == v) return p;
    }
    return SalaryPeriod.yearly;
  }
}
