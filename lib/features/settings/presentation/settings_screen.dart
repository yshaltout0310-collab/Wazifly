import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/app_user.dart';
import '../../auth/application/auth_providers.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../user_type/application/user_type_controller.dart';
import '../../user_type/domain/user_type.dart';
import '../application/notifications_controller.dart';
import 'widgets/option_sheet.dart';
import 'widgets/settings_tile.dart';

/// Central preferences hub: profile, language, theme, notifications, replay
/// onboarding, and logout.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _themeLabel(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
        ThemeMode.light => l10n.themeLight,
        ThemeMode.dark => l10n.themeDark,
        ThemeMode.system => l10n.themeSystem,
      };

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = Localizations.localeOf(context).languageCode;
    return showOptionSheet<String>(
      context: context,
      title: l10n.settingsLanguage,
      current: current == 'ar' ? 'ar' : 'en',
      options: [
        OptionItem(value: 'en', label: l10n.languageEnglish, leading: _flag('🇬🇧')),
        OptionItem(value: 'ar', label: l10n.languageArabic, leading: _flag('🇸🇦')),
      ],
      onSelected: (code) =>
          ref.read(localeControllerProvider.notifier).setLanguage(code),
    );
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return showOptionSheet<ThemeMode>(
      context: context,
      title: l10n.theme,
      current: ref.read(themeControllerProvider),
      options: [
        OptionItem(
          value: ThemeMode.system,
          label: l10n.themeSystem,
          leading: const Icon(Icons.brightness_auto_rounded),
        ),
        OptionItem(
          value: ThemeMode.light,
          label: l10n.themeLight,
          leading: const Icon(Icons.light_mode_rounded),
        ),
        OptionItem(
          value: ThemeMode.dark,
          label: l10n.themeDark,
          leading: const Icon(Icons.dark_mode_rounded),
        ),
      ],
      onSelected: (mode) =>
          ref.read(themeControllerProvider.notifier).setThemeMode(mode),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    context.goNamed(RouteNames.welcome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;
    final themeMode = ref.watch(themeControllerProvider);
    final notifications = ref.watch(notificationsControllerProvider);
    final type = ref.watch(userTypeControllerProvider);
    final langLabel = Localizations.localeOf(context).languageCode == 'ar'
        ? l10n.languageArabic
        : l10n.languageEnglish;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.horizontalGutter,
              AppSpacing.md,
              context.horizontalGutter,
              AppSpacing.xl,
            ),
            children: [
              SettingsSection(
                title: l10n.settingsAccount,
                children: [
                  _ProfileRow(
                    user: user,
                    role: switch (type) {
                      UserType.jobSeeker => l10n.jobSeeker,
                      UserType.employer => l10n.employer,
                      null => '',
                    },
                    guestLabel: l10n.profileNotSignedIn,
                    onTap: () => context.pushNamed(RouteNames.profile),
                  ),
                  if (user?.method == AuthMethod.email)
                    SettingsTile(
                      icon: Icons.password_rounded,
                      title: l10n.settingsChangePassword,
                      subtitle: l10n.settingsChangePasswordSubtitle,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () =>
                          context.pushNamed(RouteNames.changePassword),
                    ),
                  SettingsTile(
                    icon: Icons.logout_rounded,
                    title: l10n.logout,
                    destructive: true,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSection(
                title: l10n.settingsPreferences,
                children: [
                  SettingsTile(
                    icon: Icons.translate_rounded,
                    title: l10n.settingsLanguage,
                    subtitle: langLabel,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _pickLanguage(context, ref),
                  ),
                  SettingsTile(
                    icon: Icons.palette_outlined,
                    title: l10n.theme,
                    subtitle: _themeLabel(l10n, themeMode),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _pickTheme(context, ref),
                  ),
                  SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: l10n.settingsNotifications,
                    subtitle: l10n.settingsNotificationsSubtitle,
                    trailing: Switch(
                      value: notifications.master,
                      onChanged: (v) => ref
                          .read(notificationsControllerProvider.notifier)
                          .setMaster(value: v),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.work_outline_rounded,
                    title: l10n.notifyJobAlerts,
                    subtitle: l10n.notifyJobAlertsSubtitle,
                    trailing: Switch(
                      value: notifications.effectiveJobAlerts,
                      onChanged: notifications.master
                          ? (v) => ref
                              .read(notificationsControllerProvider.notifier)
                              .setJobAlerts(value: v)
                          : null,
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.assignment_turned_in_outlined,
                    title: l10n.notifyApplicationUpdates,
                    subtitle: l10n.notifyApplicationUpdatesSubtitle,
                    trailing: Switch(
                      value: notifications.effectiveApplicationUpdates,
                      onChanged: notifications.master
                          ? (v) => ref
                              .read(notificationsControllerProvider.notifier)
                              .setApplicationUpdates(value: v)
                          : null,
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.tips_and_updates_outlined,
                    title: l10n.notifyCoachTips,
                    subtitle: l10n.notifyCoachTipsSubtitle,
                    trailing: Switch(
                      value: notifications.effectiveCoachTips,
                      onChanged: notifications.master
                          ? (v) => ref
                              .read(notificationsControllerProvider.notifier)
                              .setCoachTips(value: v)
                          : null,
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.replay_rounded,
                    title: l10n.settingsReplayOnboarding,
                    subtitle: l10n.settingsReplayOnboardingSubtitle,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.pushNamed(
                      RouteNames.onboarding,
                      queryParameters: {OnboardingScreen.replayParam: 'true'},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSection(
                title: l10n.settingsSupport,
                children: [
                  SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: l10n.settingsVersion,
                    trailing: Text(
                      AppConstants.appVersion,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _flag(String emoji) =>
      Text(emoji, style: const TextStyle(fontSize: 22));
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.user,
    required this.role,
    required this.guestLabel,
    required this.onTap,
  });

  final AppUser? user;
  final String role;
  final String guestLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = user?.label;
    final subtitle = user?.email ?? user?.phoneNumber;
    final initial =
        (name != null && name.isNotEmpty) ? name.characters.first.toUpperCase() : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: AppColors.ctaGradient,
                  shape: BoxShape.circle,
                ),
                child: user == null
                    ? const Icon(Icons.person_outline_rounded,
                        color: AppColors.white)
                    : Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user == null ? guestLabel : (name ?? ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != null || role.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle ?? role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
