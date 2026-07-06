import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/applicant_snapshot.dart';
import '../../../shared/models/application.dart';
import '../../../shared/widgets/application_status_chip.dart';
import '../../../shared/widgets/status_timeline.dart';
import '../application/employer_applicants_controller.dart';
import '../application/employer_applicants_providers.dart';
import '../application/employer_notes_controller.dart';
import 'applicant_action_handler.dart';
import 'applicant_actions.dart';
import 'employer_applicants_l10n.dart';
import 'widgets/applicant_avatar.dart';
import 'widgets/application_note_tile.dart';
import 'widgets/interview_readiness_card.dart';
import 'widgets/match_score_badge.dart';
import 'widgets/note_editor_sheet.dart';
import 'widgets/resume_summary_card.dart';

/// Full applicant detail: profile, AI match, resume analysis + file, timeline,
/// interview readiness, and private notes, with the status action bar. Reads only
/// the denormalized [Application] (+ its owner-private notes) — no cross-user
/// fetches. Pops if the application disappears.
class EmployerApplicantDetailScreen extends ConsumerWidget {
  const EmployerApplicantDetailScreen({required this.appId, super.key});

  final String appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final app = ref.watch(applicantByIdProvider(appId));

    ref.listen(employerApplicantsControllerProvider, (prev, next) {
      final failure = next.failure;
      if (failure != null && failure != prev?.failure) {
        _snack(context, applicantsActionFailureMessage(l10n, failure));
        ref.read(employerApplicantsControllerProvider.notifier).clearFailure();
      }
    });

    if (app == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.jobActionFailed)),
      );
    }

    final snap = app.applicant;
    final name = (snap?.name.trim().isNotEmpty ?? false)
        ? snap!.name.trim()
        : l10n.employerApplicantsTitle;
    final material = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 640,
          child: ListView(
            padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                AppSpacing.lg, context.horizontalGutter, AppSpacing.xxl),
            children: [
              _Header(app: app, name: name),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.applicantAppliedOn(material.formatMediumDate(app.appliedAt))} · ${l10n.applicantVia(app.source.label(l10n))}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6)),
              ),
              if (snap == null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.applicantNoProfile,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6))),
              ] else ...[
                _MatchSection(snapshot: snap),
                _Section(
                  title: l10n.applicantSectionResume,
                  child: _ResumeSection(snapshot: snap),
                ),
                if (snap.skills.isNotEmpty)
                  _Section(
                    title: l10n.applicantSectionSkills,
                    child: _SkillChips(skills: snap.skills),
                  ),
                if (_hasLinks(snap))
                  _Section(
                    title: l10n.applicantSectionLinks,
                    child: _Links(snapshot: snap),
                  ),
                _Section(
                  title: l10n.applicantSectionInterview,
                  child: InterviewReadinessCard(snapshot: snap),
                ),
              ],
              _Section(
                title: l10n.applicantSectionTimeline,
                child: StatusTimeline(history: app.history),
              ),
              _Section(
                title: l10n.applicantSectionNotes,
                child: _NotesSection(applicationId: app.id),
              ),
              const SizedBox(height: AppSpacing.md),
              _Actions(app: app),
            ],
          ),
        ),
      ),
    );
  }
}

bool _hasLinks(ApplicantSnapshot s) =>
    (s.portfolioUrl ?? '').isNotEmpty ||
    (s.githubUrl ?? '').isNotEmpty ||
    (s.linkedinUrl ?? '').isNotEmpty;

void _snack(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating, content: Text(message)));

class _Header extends StatelessWidget {
  const _Header({required this.app, required this.name});
  final Application app;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snap = app.applicant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ApplicantAvatar(name: name, photoUrl: snap?.photoUrl, radius: 30),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              if ((snap?.headline ?? '').isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(snap!.headline!,
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7))),
              ],
              if ((snap?.location ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.place_outlined,
                      size: 14,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(snap!.location!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6))),
                ]),
              ],
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusChip(status: app.status),
                  if (snap?.matchScore != null)
                    MatchScoreBadge(score: snap!.matchScore!),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatchSection extends StatelessWidget {
  const _MatchSection({required this.snapshot});
  final ApplicantSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _Section(
      title: l10n.applicantSectionMatch,
      child: !snapshot.hasMatch
          ? Text(l10n.applicantNoMatch,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.applicantMatchPercent(snapshot.matchScore!),
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: MatchScoreBadge.colorFor(snapshot.matchScore!),
                        fontWeight: FontWeight.w800)),
                if ((snapshot.matchReason ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(snapshot.matchReason!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
                ],
                if (snapshot.matchingSkills.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _LabeledChips(
                      label: l10n.applicantMatchMatching,
                      skills: snapshot.matchingSkills,
                      color: AppColors.emerald),
                ],
                if (snapshot.missingSkills.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _LabeledChips(
                      label: l10n.applicantMatchMissing,
                      skills: snapshot.missingSkills,
                      color: AppColors.warning),
                ],
              ],
            ),
    );
  }
}

class _ResumeSection extends StatelessWidget {
  const _ResumeSection({required this.snapshot});
  final ApplicantSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resume file access (graceful when Storage isn't provisioned / no URL).
        if (snapshot.hasResumeFile)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: snapshot.resumeUrl!));
              if (context.mounted) _snack(context, l10n.applicantResumeView);
            },
            icon: const Icon(Icons.description_outlined, size: 18),
            label: Text(l10n.applicantResumeView),
          )
        else
          Row(children: [
            Icon(Icons.description_outlined,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(l10n.applicantResumeUnavailable,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6))),
            ),
          ]),
        const SizedBox(height: AppSpacing.md),
        ResumeSummaryCard(snapshot: snapshot),
      ],
    );
  }
}

class _SkillChips extends StatelessWidget {
  const _SkillChips({required this.skills});
  final List<String> skills;

  @override
  Widget build(BuildContext context) => _LabeledChips(
      label: '', skills: skills, color: AppColors.teal, showLabel: false);
}

class _LabeledChips extends StatelessWidget {
  const _LabeledChips({
    required this.label,
    required this.skills,
    required this.color,
    this.showLabel = true,
  });
  final String label;
  final List<String> skills;
  final Color color;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(label,
              style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 6),
        ],
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final s in skills)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: color.withValues(alpha: 0.30)),
                ),
                child: Text(s,
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.emeraldDark,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ],
    );
  }
}

class _Links extends StatelessWidget {
  const _Links({required this.snapshot});
  final ApplicantSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final links = <({IconData icon, String label, String url})>[
      if ((snapshot.portfolioUrl ?? '').isNotEmpty)
        (icon: Icons.language_rounded, label: 'Portfolio', url: snapshot.portfolioUrl!),
      if ((snapshot.githubUrl ?? '').isNotEmpty)
        (icon: Icons.code_rounded, label: 'GitHub', url: snapshot.githubUrl!),
      if ((snapshot.linkedinUrl ?? '').isNotEmpty)
        (icon: Icons.business_center_outlined, label: 'LinkedIn', url: snapshot.linkedinUrl!),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final l in links)
          ActionChip(
            avatar: Icon(l.icon, size: 16),
            label: Text(l.label),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: l.url));
              if (context.mounted) _snack(context, l.url);
            },
          ),
      ],
    );
  }
}

class _NotesSection extends ConsumerWidget {
  const _NotesSection({required this.applicationId});
  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notes = ref.watch(visibleNotesProvider(applicationId));
    final action = ref.watch(employerNotesControllerProvider);
    final controller = ref.read(employerNotesControllerProvider.notifier);

    ref.listen(employerNotesControllerProvider, (prev, next) {
      final failure = next.failure;
      if (failure != null && failure != prev?.failure) {
        _snack(context, notesActionFailureMessage(l10n, failure));
        controller.clearFailure();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.notesPrivateHint,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: AppSpacing.sm),
        if (notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(l10n.notesEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          )
        else
          for (final note in notes)
            ApplicationNoteTile(
              note: note,
              pending: action.isPending(note.id),
              onEdit: () async {
                final text =
                    await showNoteEditor(context, initialText: note.text);
                if (text != null && text.isNotEmpty) {
                  await controller.edit(note, text);
                }
              },
              onDelete: () async {
                final ok = await _confirmDelete(context, l10n);
                if (ok) await controller.delete(note);
              },
            ),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: () async {
            final text = await showNoteEditor(context);
            if (text != null && text.isNotEmpty) {
              await controller.add(applicationId, text);
            }
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.noteAdd),
        ),
      ],
    );
  }

  Future<bool> _confirmDelete(BuildContext context, AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noteDeleteTitle),
        content: Text(l10n.noteDeleteBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.jobUnsavedCancel)),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.noteDelete),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.app});
  final Application app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const compact = Size(0, 42);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final a in availableApplicantActions(app.status))
          a.isPrimary
              ? FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: compact),
                  onPressed: () => runApplicantAction(context, ref, app, a),
                  icon: Icon(a.icon, size: 18),
                  label: Text(a.label(l10n)),
                )
              : OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: compact,
                    foregroundColor:
                        a.isDestructive ? theme.colorScheme.error : null,
                  ),
                  onPressed: () => runApplicantAction(context, ref, app, a),
                  icon: Icon(a.icon, size: 18),
                  label: Text(a.label(l10n)),
                ),
      ],
    );
  }
}

/// A titled section with a top divider — the detail screen's layout unit.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}
