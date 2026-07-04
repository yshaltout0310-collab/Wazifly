import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/company.dart';
import '../../../shared/widgets/completion_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/application/auth_providers.dart';
import '../application/company_providers.dart';
import 'company_l10n.dart';

/// Company profile view: logo/name/industry header, completion indicator, and
/// the editable company details (industry, size, website, HQ, contact, links).
class CompanyProfileScreen extends ConsumerWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;
    final company = ref.watch(currentCompanyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.companyProfileTitle),
        actions: [
          if (user != null)
            IconButton(
              tooltip: l10n.companyEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.pushNamed(RouteNames.editCompany),
            ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: user == null || company == null
              ? _EmptyState(l10n: l10n)
              : _CompanyBody(company: company, l10n: l10n),
        ),
      ),
    );
  }
}

class _CompanyBody extends ConsumerWidget {
  const _CompanyBody({required this.company, required this.l10n});

  final Company company;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final completion = ref.watch(companyCompletionProvider);
    final name = company.name?.trim().isNotEmpty == true
        ? company.name!.trim()
        : l10n.employerCompanyFallback;

    final rows = <({IconData icon, String label, String value})>[
      if (company.industry != null)
        (icon: Icons.category_outlined, label: l10n.companyIndustryLabel, value: company.industry!.label(l10n)),
      if (company.size != null)
        (icon: Icons.groups_outlined, label: l10n.companySizeLabel, value: company.size!.label(l10n)),
      if (company.headquarters != null)
        (icon: Icons.place_outlined, label: l10n.companyHqLabel, value: company.headquarters!),
      if (company.website != null)
        (icon: Icons.language_rounded, label: l10n.companyWebsiteLabel, value: company.website!),
      if (company.contactEmail != null)
        (icon: Icons.mail_outline_rounded, label: l10n.companyContactEmailLabel, value: company.contactEmail!),
      if (company.contactPhone != null)
        (icon: Icons.phone_outlined, label: l10n.companyContactPhoneLabel, value: company.contactPhone!),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.xl,
          context.horizontalGutter, AppSpacing.xl),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 104,
                height: 104,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.ctaGradient,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.brandGlow,
                  image: company.logoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(company.logoUrl!),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: company.logoUrl == null
                    ? const Icon(Icons.business_rounded,
                        color: AppColors.white, size: 48)
                    : null,
              ).animate().scale(duration: 450.ms, curve: AppCurves.spring),
              const SizedBox(height: AppSpacing.md),
              Text(name,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800))
                  .animate(delay: 120.ms)
                  .fadeIn(),
              if (company.industry != null) ...[
                const SizedBox(height: 4),
                Text(company.industry!.label(l10n),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7)))
                    .animate(delay: 160.ms)
                    .fadeIn(),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        CompletionIndicator(
          percent: completion,
          title: l10n.companyCompletionTitle,
          nudge: l10n.companyCompletionNudge,
          complete: l10n.companyCompletionComplete,
        ).animate(delay: 200.ms).fadeIn().moveY(begin: 12, end: 0),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: l10n.companyEdit,
          icon: Icons.edit_outlined,
          onPressed: () => context.pushNamed(RouteNames.editCompany),
        ),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _InfoCard(rows: rows)
              .animate(delay: 260.ms)
              .fadeIn()
              .moveY(begin: 12, end: 0),
        ],
        if (company.description != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: l10n.companyDescriptionLabel,
            child: Text(company.description!, style: theme.textTheme.bodyMedium),
          ),
        ],
        if (company.hasAnySocial) ...[
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: l10n.companyLinksLabel,
            child: Column(
              children: [
                if (company.linkedinUrl != null)
                  _LinkRow(
                      icon: Icons.business_center_outlined,
                      label: l10n.companyLinkedinLabel,
                      value: company.linkedinUrl!),
                if (company.xUrl != null)
                  _LinkRow(
                      icon: Icons.alternate_email_rounded,
                      label: l10n.companyXLabel,
                      value: company.xUrl!),
                if (company.facebookUrl != null)
                  _LinkRow(
                      icon: Icons.public_rounded,
                      label: l10n.companyFacebookLabel,
                      value: company.facebookUrl!),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6)),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});
  final List<({IconData icon, String label, String value})> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        boxShadow: AppShadows.card(dark: dark),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  indent: 56,
                  color: theme.colorScheme.outline.withValues(alpha: 0.4)),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 14),
              child: Row(
                children: [
                  Icon(rows[i].icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Text(rows[i].label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6))),
                  const Spacer(),
                  Flexible(
                    child: Text(rows[i].value,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.profileNotSignedIn,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.profileNotSignedInBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: l10n.signIn,
            icon: Icons.login_rounded,
            expanded: false,
            onPressed: () => context.goNamed(RouteNames.welcome),
          ),
        ],
      ),
    );
  }
}
