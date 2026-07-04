// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:careerbridge/features/employer/domain/company_size.dart';
import 'package:careerbridge/features/employer/domain/company_verification_status.dart';
import 'package:careerbridge/features/employer/domain/industry.dart';
import 'package:careerbridge/shared/models/company.dart';
import 'package:flutter_test/flutter_test.dart';

Company _full() => const Company(
      companyId: 'c1',
      ownerUid: 'c1',
      name: 'Acme',
      industry: Industry.technology,
      size: CompanySize.size11_50,
      website: 'https://acme.co',
      headquarters: 'Doha, Qatar',
      description: 'We build things.',
      contactEmail: 'jobs@acme.co',
    );

void main() {
  group('completion', () {
    test('empty company is 0%', () {
      expect(Company.empty('c1').completionPercent, 0);
    });

    test('all tracked fields filled is 100%', () {
      expect(_full().copyWith(logoUrl: 'https://acme.co/logo.png').completionPercent, 100);
    });

    test('half the tracked fields is ~50%', () {
      // 4 of 8 tracked fields (name, industry, size, website).
      final c = Company.empty('c1').copyWith(
        name: 'Acme',
        industry: Industry.finance,
        size: CompanySize.size51_200,
        website: 'https://x.co',
      );
      expect(c.completionPercent, 50);
      expect(c.missingFields, contains(CompanyField.logo));
      expect(c.missingFields, contains(CompanyField.contactEmail));
    });
  });

  group('fromJson', () {
    test('round-trips through toJson (incl. new fields)', () {
      final original = _full().copyWith(
        logoUrl: 'https://acme.co/logo.png',
        companySlug: 'acme',
        verificationStatus: CompanyVerificationStatus.verified,
        contactPhone: '+97412345678',
        linkedinUrl: 'https://linkedin.com/acme',
        xUrl: 'https://x.com/acme',
        facebookUrl: 'https://facebook.com/acme',
        strength: CompanyStrength(
          score: 82,
          summary: 'Strong profile',
          strengths: ['clear'],
          improvements: ['add logo'],
          analyzedAt: DateTime(2026, 7, 4),
        ),
      );
      final back = Company.fromJson({...original.toJson(), 'companyId': 'c1'});
      expect(back.name, 'Acme');
      expect(back.industry, Industry.technology);
      expect(back.size, CompanySize.size11_50);
      expect(back.companySlug, 'acme');
      expect(back.verificationStatus, CompanyVerificationStatus.verified);
      expect(back.xUrl, 'https://x.com/acme');
      expect(back.strength?.score, 82);
      expect(back.strength?.strengths, ['clear']);
    });

    test('tolerates snake_case + human size range + bad industry', () {
      final c = Company.fromJson({
        'company_id': 'c9',
        'owner_uid': 'c9',
        'name': 'Globex',
        'industry': 'not-a-real-industry', // -> null
        'size': '11-50', // human range -> size11_50
        'contact_email': 'hi@globex.co',
        'logo_url': 'https://g/logo.png',
      });
      expect(c.companyId, 'c9');
      expect(c.ownerUid, 'c9');
      expect(c.industry, isNull);
      expect(c.size, CompanySize.size11_50);
      expect(c.contactEmail, 'hi@globex.co');
      expect(c.hasLogo, isTrue);
    });

    test('verificationStatus defaults to pending; parses dates', () {
      expect(Company.fromJson({'ownerUid': 'c1'}).verificationStatus,
          CompanyVerificationStatus.pending);
      final millis = DateTime(2026, 7, 4).millisecondsSinceEpoch;
      expect(
        Company.fromJson({'ownerUid': 'c1', 'created_at': millis}).createdAt,
        DateTime.fromMillisecondsSinceEpoch(millis),
      );
    });
  });

  test('slugify produces URL-safe handles', () {
    expect(Company.slugify('Acme Corporation!'), 'acme-corporation');
    expect(Company.slugify('  Globex   Inc  '), 'globex-inc');
  });

  test('CompanyStrength defensive parse + isEmpty', () {
    expect(const CompanyStrength().isEmpty, isTrue);
    final s = CompanyStrength.fromJson({'score': 150, 'summary': 'ok'});
    expect(s.score, 100); // clamped
    expect(s.isEmpty, isFalse);
  });
}
