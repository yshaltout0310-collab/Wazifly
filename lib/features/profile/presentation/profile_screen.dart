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
import '../../../shared/widgets/primary_button.dart';
import '../../auth/application/auth_providers.dart';
import '../../user_type/application/user_type_controller.dart';
import '../../user_type/domain/user_type.dart';

/// Read-only profile view. Editing arrives in a later phase; for now it
/// surfaces the authenticated identity (or an empty state when signed out).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;
    final type = ref.watch(userTypeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: user == null
              ? _EmptyState(l10n: l10n)
              : _ProfileBody(user: user, type: type, l10n: l10n),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.user, required this.type, required this.l10n});

  final AppUser user;
  final UserType? type;
  final AppLocalizations l10n;

  String get _methodLabel => switch (user.method) {
        AuthMethod.google => 'Google',
        AuthMethod.phone => 'Phone',
        AuthMethod.email => 'Email',
      };

  String? get _roleLabel => switch (type) {
        UserType.jobSeeker => l10n.jobSeeker,
        UserType.employer => l10n.employer,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial =
        user.label.isNotEmpty ? user.label.characters.first.toUpperCase() : '?';

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
                  image: user.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(user.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user.photoUrl == null
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
                user.label,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ).animate(delay: 120.ms).fadeIn(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _InfoCard(
          rows: [
            if (user.email != null)
              (icon: Icons.mail_outline_rounded, label: l10n.profileEmailLabel, value: user.email!),
            if (user.phoneNumber != null)
              (icon: Icons.phone_outlined, label: l10n.profilePhoneLabel, value: user.phoneNumber!),
            if (_roleLabel != null)
              (icon: Icons.badge_outlined, label: l10n.profileRoleLabel, value: _roleLabel!),
            (icon: Icons.verified_user_outlined, label: l10n.profileMethodLabel, value: _methodLabel),
          ],
        ).animate(delay: 200.ms).fadeIn().moveY(begin: 12, end: 0),
      ],
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
