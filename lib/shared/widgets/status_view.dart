import 'package:flutter/material.dart';

import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_dimensions.dart';
import 'primary_button.dart';

enum _StatusKind { loading, empty, error }

/// The one shared full-screen state surface — **loading**, **empty**, and
/// **error** — so every feature renders these identically instead of
/// hand-rolling its own (previously ~13 near-duplicate `_Loading`/`_Empty`/
/// `_Error` classes with drifting spacing, icon sizes, and colors).
///
/// Lives beside the other cross-feature widgets (`JobDetailView`, `StatusChip`,
/// `OfflineBanner`) and depends only on core theme/l10n — **zero feature
/// coupling**. All metrics come from the design tokens (`AppSpacing`/`AppRadius`/
/// `AppDurations`/`AppCurves`), it's RTL- and text-scale-safe (centered, scrollable,
/// `TextAlign.center`), and it carries accessibility semantics (title `header`,
/// a screen-reader "loading" announcement).
class StatusView extends StatelessWidget {
  /// Full-screen loading: a centered spinner + optional title/hint.
  const StatusView.loading({this.title, this.message, super.key})
      : _kind = _StatusKind.loading,
        icon = null,
        action = null,
        onRetry = null,
        retryLabel = null;

  /// Empty state: a badged [icon] + [title] + optional [message] + optional
  /// [action] (e.g. a `PrimaryButton` CTA).
  const StatusView.empty({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    super.key,
  })  : _kind = _StatusKind.empty,
        onRetry = null,
        retryLabel = null;

  /// Error state: a badged error [icon] + [message] + a retry button.
  const StatusView.error({
    required this.message,
    required this.onRetry,
    this.title,
    this.retryLabel,
    this.icon = Icons.error_outline_rounded,
    super.key,
  })  : _kind = _StatusKind.error,
        action = null;

  final _StatusKind _kind;
  final IconData? icon;
  final String? title;
  final String? message;

  /// Optional CTA for [StatusView.empty].
  final Widget? action;

  /// Retry callback for [StatusView.error].
  final VoidCallback? onRetry;

  /// Optional custom retry label ([StatusView.error]); defaults to a localized
  /// "Try again".
  final String? retryLabel;

  // Canonical metrics (chosen to unify the previous drift: 84/88 badges + bare
  // 56/64 icons -> one 84 badge / 40 icon; lg/md spacing -> lg; 0.35–0.7
  // opacities -> 0.6).
  static const double _badgeSize = 84;
  static const double _iconSize = 40;
  static const double _mutedAlpha = 0.6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final Widget content = switch (_kind) {
      _StatusKind.loading => _loading(theme, l10n),
      _StatusKind.empty => _standard(
          theme,
          badgeColor: theme.colorScheme.primary,
          child: _figure(theme, theme.colorScheme.primary),
          action: action,
        ),
      _StatusKind.error => _standard(
          theme,
          badgeColor: theme.colorScheme.error,
          child: _figure(theme, theme.colorScheme.error),
          action: PrimaryButton(
            label: retryLabel ?? l10n.commonRetry,
            icon: Icons.refresh_rounded,
            expanded: false,
            onPressed: onRetry,
          ),
        ),
    };

    // No self-entrance animation: these states are typically hosted inside an
    // AnimatedSwitcher (which animates the transition) — matching the prior
    // behaviour of the per-feature state widgets and keeping the widget
    // const/timer-free.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: content,
      ),
    );
  }

  /// The badge (tinted circle around the icon).
  Widget _figure(ThemeData theme, Color color) => Container(
        width: _badgeSize,
        height: _badgeSize,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: _iconSize, color: color),
      );

  /// Shared empty/error layout: badge -> title -> message -> action.
  Widget _standard(
    ThemeData theme, {
    required Color badgeColor,
    required Widget child,
    Widget? action,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: child),
        if (title != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(
              title!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
        if (message != null) ...[
          SizedBox(height: title != null ? AppSpacing.sm : AppSpacing.lg),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: _mutedAlpha),
              height: 1.4,
            ),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: AppSpacing.xl),
          action,
        ],
      ],
    );
  }

  Widget _loading(ThemeData theme, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: l10n.commonLoading,
          liveRegion: true,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 4),
          ),
        ),
        if (title != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
        if (message != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: _mutedAlpha),
            ),
          ),
        ],
      ],
    );
  }
}
