import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/application/auth_providers.dart';
import '../../user_type/application/user_type_controller.dart';
import '../../user_type/domain/user_type.dart';
import '../application/profile_completion_provider.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/completion_indicator.dart';
import 'profile_l10n.dart';

/// Profile view: identity, completion indicator, and the extended, editable
/// details (headline, skills, experience level, preferred titles, links).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;
    final profile = ref.watch(currentUserProfileProvider);
    final type = ref.watch(userTypeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          if (user != null)
            IconButton(
              tooltip: l10n.profileEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.pushNamed(RouteNames.editProfile),
            ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: user == null || profile == null
              ? _EmptyState(l10n: l10n)
              : _ProfileBody(
                  user: user, profile: profile, type: type, l10n: l10n),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({
    required this.user,
    required this.profile,
    required this.type,
    required this.l10n,
  });

  final AppUser user;
  final UserProfile profile;
  final UserType? type;
  final AppLocalizations l10n;

  String get _methodLabel => switch (user.method) {
        AuthMethod.phone => 'Phone',
        AuthMethod.email => 'Email',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final completion = ref.watch(profileCompletionProvider);
    final name = profile.displayName?.trim().isNotEmpty == true
        ? profile.displayName!
        : user.label;
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.horizontalGutter,
        AppSpacing.xl,
        context.horizontalGutter,
        AppSpacing.xl,
      ),
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
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.brandGlow,
                  image: profile.photoUrl != null
                      ? DecorationImage(
                          image: AppImage.provider(profile.photoUrl!,
                              context: context, logicalSize: 104),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profile.photoUrl == null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ).animate().scale(duration: 450.ms, curve: AppCurves.spring),
              const SizedBox(height: AppSpacing.md),
              Text(
                name,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ).animate(delay: 120.ms).fadeIn(),
              if (profile.headline != null) ...[
                const SizedBox(height: 4),
                Text(
                  profile.headline!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ).animate(delay: 160.ms).fadeIn(),
              ],
              if (profile.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place_outlined,
                        size: 16,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      profile.location!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ).animate(delay: 180.ms).fadeIn(),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        CompletionIndicator(percent: completion)
            .animate(delay: 200.ms)
            .fadeIn()
            .moveY(begin: 12, end: 0),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: l10n.profileEdit,
          icon: Icons.edit_outlined,
          onPressed: () => context.pushNamed(RouteNames.editProfile),
        ),
        const SizedBox(height: AppSpacing.xl),
        _InfoCard(
          rows: [
            if (user.email != null)
              (icon: Icons.mail_outline_rounded, label: l10n.profileEmailLabel, value: user.email!),
            if (user.phoneNumber != null)
              (icon: Icons.phone_outlined, label: l10n.profilePhoneLabel, value: user.phoneNumber!),
            if (type != null)
              (icon: Icons.badge_outlined, label: l10n.profileRoleLabel, value: userTypeLabel(l10n, type!)),
            if (profile.experienceLevel != null)
              (
                icon: Icons.workspace_premium_outlined,
                label: l10n.profileExperienceLabel,
                value: profile.experienceLevel!.label(l10n)
              ),
            (icon: Icons.verified_user_outlined, label: l10n.profileMethodLabel, value: _methodLabel),
          ],
        ).animate(delay: 260.ms).fadeIn().moveY(begin: 12, end: 0),
        if (profile.bio != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: l10n.profileBioLabel,
            child: Text(profile.bio!, style: theme.textTheme.bodyMedium),
          ),
        ],
        if (profile.skills.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: l10n.profileSkillsLabel,
            child: _Chips(values: profile.skills),
          ),
        ],
        if (profile.preferredJobTitles.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: l10n.profilePreferredTitlesLabel,
            child: _Chips(values: profile.preferredJobTitles),
          ),
        ],
        if (profile.hasAnyLink) ...[
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: l10n.profileLinksLabel,
            child: Column(
              children: [
                if (profile.portfolioUrl != null)
                  _LinkRow(
                      icon: Icons.link_rounded,
                      label: l10n.profilePortfolioLabel,
                      value: profile.portfolioUrl!),
                if (profile.githubUrl != null)
                  _LinkRow(
                      icon: Icons.code_rounded,
                      label: l10n.profileGithubLabel,
                      value: profile.githubUrl!),
                if (profile.linkedinUrl != null)
                  _LinkRow(
                      icon: Icons.business_center_outlined,
                      label: l10n.profileLinkedinLabel,
                      value: profile.linkedinUrl!),
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
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.values});
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final v in values)
          Chip(
            label: Text(v),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              )),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
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
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(rows[i].icon,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    rows[i].label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
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
          Icon(Icons.person_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.profileNotSignedIn,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.profileNotSignedInBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
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
