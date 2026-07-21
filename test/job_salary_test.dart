// Test fixtures are plain JSON-shaped literals; const adds nothing here.
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:careerbridge/core/localization/generated/app_localizations.dart';
import 'package:careerbridge/features/employer/domain/salary_period.dart';
import 'package:careerbridge/shared/models/job.dart';
import 'package:careerbridge/shared/models/salary_range.dart';
import 'package:careerbridge/shared/models/salary_range_l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Job.fromJson parses a nested salary object', () {
    final job = Job.fromJson({
      'id': 'j1',
      'title': 'Engineer',
      'salary': {
        'min': 15000,
        'max': 20000,
        'currency': 'QAR',
        'period': 'monthly',
      },
    });
    expect(job.salary, isNotNull);
    expect(job.salary!.min, 15000);
    expect(job.salary!.max, 20000);
    expect(job.salary!.currency, 'QAR');
    expect(job.salary!.period, SalaryPeriod.monthly);
  });

  test('Job.fromJson leaves salary null when absent or malformed', () {
    expect(Job.fromJson({'id': 'j1', 'title': 'X'}).salary, isNull);
    expect(Job.fromJson({'id': 'j1', 'title': 'X', 'salary': 'nope'}).salary,
        isNull);
  });

  group('SalaryRange.display', () {
    late AppLocalizations en;
    setUpAll(() async {
      en = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('formats a min–max range with currency and period', () {
      const s = SalaryRange(
          min: 15000, max: 20000, currency: 'QAR', period: SalaryPeriod.monthly);
      expect(s.display(en, localeName: 'en'),
          'QAR 15,000 – 20,000 · ${en.salaryMonthly}');
    });

    test('formats open-ended ranges (From / Up to)', () {
      const from = SalaryRange(min: 90000, currency: 'USD');
      expect(from.display(en, localeName: 'en'),
          '${en.salaryFrom} USD 90,000 · ${en.salaryYearly}');
      const upto = SalaryRange(max: 120000, currency: 'USD');
      expect(upto.display(en, localeName: 'en'),
          '${en.salaryUpTo} USD 120,000 · ${en.salaryYearly}');
    });

    test('empty range renders nothing', () {
      expect(const SalaryRange().display(en, localeName: 'en'), '');
    });
  });
}
