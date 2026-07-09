import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/services/interview_store/in_memory_interview_history_repository.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/interview_models.dart';
import 'interview_l10n.dart';
import 'widgets/score_display.dart';

/// Lists the user's past practice interviews (newest first).
class InterviewHistoryScreen extends ConsumerWidget {
  const InterviewHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sessions = ref.watch(interviewSessionsProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.interviewHistoryTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: sessions.isEmpty
              ? StatusView.empty(
                  icon: Icons.history_rounded,
                  title: l10n.interviewHistoryEmpty,
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                      AppSpacing.lg, context.horizontalGutter, AppSpacing.xxl),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) =>
                      _SessionTile(session: sessions[i], l10n: l10n),
                ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.l10n});

  final InterviewSession session;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final date = session.createdAt == null
        ? ''
        : DateFormat.yMMMd(locale).format(session.createdAt!);
    final title = session.role.isEmpty
        ? interviewTypeName(l10n, session.type)
        : '${interviewTypeName(l10n, session.type)} · ${session.role}';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        onTap: () => context.pushNamed(
          RouteNames.interviewSessionDetail,
          pathParameters: {'id': session.id},
        ),
        leading: OverallScoreGauge(score: session.overallScore, size: 44),
        title: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(
          [date, l10n.interviewQuestionsCount(session.questions.length)]
              .where((s) => s.isNotEmpty)
              .join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

