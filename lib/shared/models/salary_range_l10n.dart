import 'package:intl/intl.dart';

import '../../core/localization/generated/app_localizations.dart';
import '../../features/employer/domain/salary_period.dart';
import 'salary_range.dart';

/// Localized, human-readable rendering of a [SalaryRange] for the job detail —
/// e.g. "QAR 15,000 – 20,000 · per month", "From USD 90,000 · per year".
extension SalaryRangeDisplay on SalaryRange {
  /// Returns an empty string when there is nothing to show.
  String display(AppLocalizations l10n, {String? localeName}) {
    if (isEmpty) return '';
    final nf = NumberFormat.decimalPattern(localeName);
    final cur = currency.trim().toUpperCase();

    final String amount;
    if (min != null && max != null) {
      amount = '$cur ${nf.format(min)} – ${nf.format(max)}';
    } else if (min != null) {
      amount = '${l10n.salaryFrom} $cur ${nf.format(min)}';
    } else {
      amount = '${l10n.salaryUpTo} $cur ${nf.format(max)}';
    }
    return '$amount · ${_periodLabel(l10n)}';
  }

  String _periodLabel(AppLocalizations l10n) => switch (period) {
        SalaryPeriod.yearly => l10n.salaryYearly,
        SalaryPeriod.monthly => l10n.salaryMonthly,
        SalaryPeriod.hourly => l10n.salaryHourly,
      };
}
