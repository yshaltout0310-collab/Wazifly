import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/job_posting.dart';
import '../../../shared/widgets/chip_input.dart';
import '../application/job_editor_controller.dart';
import '../domain/employment_type.dart';
import '../domain/job_experience.dart';
import '../domain/job_validation.dart';
import '../domain/salary_period.dart';
import 'employer_jobs_l10n.dart';

/// Create/Edit form for a job posting. Field edits flow into the
/// [JobEditorController] (which debounce-auto-saves valid drafts); Publish
/// validates for publish, saves the draft, then routes to the Preview screen for
/// the final confirmation. A [PopScope] guards unsaved changes.
class JobEditorScreen extends ConsumerStatefulWidget {
  const JobEditorScreen({this.jobId, super.key});

  /// Null → create; a job id → edit that posting.
  final String? jobId;

  @override
  ConsumerState<JobEditorScreen> createState() => _JobEditorScreenState();
}

class _JobEditorScreenState extends ConsumerState<JobEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _openings;
  late final TextEditingController _salaryMin;
  late final TextEditingController _salaryMax;
  late final TextEditingController _currency;
  late SalaryPeriod _period;

  JobEditorController get _controller =>
      ref.read(jobEditorControllerProvider(widget.jobId).notifier);

  @override
  void initState() {
    super.initState();
    final draft = ref.read(jobEditorControllerProvider(widget.jobId)).draft;
    _title = TextEditingController(text: draft.title);
    _description = TextEditingController(text: draft.description);
    _location = TextEditingController(text: draft.location);
    _openings =
        TextEditingController(text: draft.openings?.toString() ?? '');
    _salaryMin =
        TextEditingController(text: draft.salary?.min?.toString() ?? '');
    _salaryMax =
        TextEditingController(text: draft.salary?.max?.toString() ?? '');
    _currency =
        TextEditingController(text: draft.salary?.currency ?? 'USD');
    _period = draft.salary?.period ?? SalaryPeriod.yearly;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _openings.dispose();
    _salaryMin.dispose();
    _salaryMax.dispose();
    _currency.dispose();
    super.dispose();
  }

  void _syncSalary() {
    final min = int.tryParse(_salaryMin.text.trim());
    final max = int.tryParse(_salaryMax.text.trim());
    if (min == null && max == null) {
      _controller.setSalary(null);
    } else {
      final currency =
          _currency.text.trim().isEmpty ? 'USD' : _currency.text.trim();
      _controller.setSalary(SalaryRange(
          min: min, max: max, currency: currency, period: _period));
    }
  }

  Future<void> _pickDate(DateTime? initial, ValueChanged<DateTime?> onPick) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) onPick(picked);
  }

  Future<void> _onPublish() async {
    final l10n = AppLocalizations.of(context);
    if (!_controller.publishValidation.isValid) {
      _controller.revealErrors();
      _snack(l10n.jobErrFixFields);
      return;
    }
    final saved = await _controller.saveDraft();
    if (!mounted || saved == null) return;
    context.pushNamed(RouteNames.jobPreview, extra: saved);
  }

  Future<void> _onSaveDraft() async {
    final l10n = AppLocalizations.of(context);
    final saved = await _controller.saveDraft();
    if (!mounted) return;
    _snack(saved != null ? l10n.jobDraftSaved : l10n.jobActionFailed);
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating, content: Text(message)));

  Future<void> _confirmLeave() async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<_LeaveChoice>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.jobUnsavedTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.jobUnsavedBody,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.save_outlined),
              title: Text(l10n.jobUnsavedSave),
              onTap: () => Navigator.of(context).pop(_LeaveChoice.save),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: Text(l10n.jobUnsavedDiscard),
              onTap: () => Navigator.of(context).pop(_LeaveChoice.discard),
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: Text(l10n.jobUnsavedCancel),
              onTap: () => Navigator.of(context).pop(_LeaveChoice.cancel),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _LeaveChoice.save:
        final saved = await _controller.saveDraft();
        if (mounted && saved != null) context.pop();
      case _LeaveChoice.discard:
        context.pop();
      case _LeaveChoice.cancel:
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(jobEditorControllerProvider(widget.jobId));
    final validation =
        state.showErrors ? _controller.publishValidation : JobValidationResult.valid;

    String? errText(JobField f) {
      final e = validation[f];
      return e == null ? null : jobErrorMessage(l10n, f, e);
    }

    return PopScope(
      canPop: !state.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.isNew ? l10n.createJobTitle : l10n.editJobTitle),
          actions: [
            Center(child: _AutoSaveIndicator(state: state)),
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: state.saving ? null : _onSaveDraft,
              child: Text(l10n.jobSaveDraft),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ResponsiveCenter(
            maxWidth: 640,
            child: ListView(
              padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                  AppSpacing.md, context.horizontalGutter, AppSpacing.xxl),
              children: [
                TextField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  onChanged: _controller.setTitle,
                  decoration: InputDecoration(
                    labelText: l10n.jobTitleLabel,
                    hintText: l10n.jobTitleHint,
                    errorText: errText(JobField.title),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _description,
                  minLines: 4,
                  maxLines: 8,
                  onChanged: _controller.setDescription,
                  decoration: InputDecoration(
                    labelText: l10n.jobDescLabel,
                    hintText: l10n.jobDescHint,
                    alignLabelWithHint: true,
                    errorText: errText(JobField.description),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ChipInput(
                  label: l10n.jobSkillsLabel,
                  hint: l10n.jobSkillsHint,
                  icon: Icons.bolt_outlined,
                  values: state.draft.requiredSkills,
                  onChanged: _controller.setSkills,
                ),
                if (errText(JobField.skills) != null)
                  _FieldError(errText(JobField.skills)!),
                const SizedBox(height: AppSpacing.lg),
                _Label(l10n.jobExperienceLabel),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final e in JobExperience.values)
                      ChoiceChip(
                        label: Text(e.label(l10n)),
                        selected: state.draft.experience == e,
                        onSelected: (_) => _controller.setExperience(
                            state.draft.experience == e ? null : e),
                      ),
                  ],
                ),
                if (errText(JobField.experience) != null)
                  _FieldError(errText(JobField.experience)!),
                const SizedBox(height: AppSpacing.lg),
                _Label(l10n.jobEmploymentTypeLabel),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final t in EmploymentType.values)
                      ChoiceChip(
                        label: Text(t.label(l10n)),
                        selected: state.draft.employmentType == t,
                        onSelected: (_) => _controller.setEmploymentType(
                            state.draft.employmentType == t ? null : t),
                      ),
                  ],
                ),
                if (errText(JobField.employmentType) != null)
                  _FieldError(errText(JobField.employmentType)!),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _location,
                  onChanged: _controller.setLocation,
                  decoration: InputDecoration(
                    labelText: l10n.jobLocationLabel,
                    hintText: l10n.jobLocationHint,
                    errorText: errText(JobField.location),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.jobRemoteLabel),
                  value: state.draft.remote,
                  onChanged: _controller.setRemote,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _openings,
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      _controller.setOpenings(int.tryParse(v.trim())),
                  decoration: InputDecoration(
                    labelText: l10n.jobOpeningsLabel,
                    hintText: l10n.jobOpeningsHint,
                    errorText: errText(JobField.openings),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Label(l10n.jobSalaryLabel),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _salaryMin,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _syncSalary(),
                        decoration:
                            InputDecoration(labelText: l10n.jobSalaryMin),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _salaryMax,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _syncSalary(),
                        decoration:
                            InputDecoration(labelText: l10n.jobSalaryMax),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _currency,
                        onChanged: (_) => _syncSalary(),
                        decoration:
                            InputDecoration(labelText: l10n.jobSalaryCurrency),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DropdownButtonFormField<SalaryPeriod>(
                        initialValue: _period,
                        isExpanded: true,
                        decoration:
                            InputDecoration(labelText: l10n.jobSalaryPeriod),
                        items: [
                          for (final p in SalaryPeriod.values)
                            DropdownMenuItem(
                                value: p, child: Text(p.label(l10n))),
                        ],
                        onChanged: (p) {
                          if (p == null) return;
                          setState(() => _period = p);
                          _syncSalary();
                        },
                      ),
                    ),
                  ],
                ),
                if (errText(JobField.salary) != null)
                  _FieldError(errText(JobField.salary)!),
                const SizedBox(height: AppSpacing.lg),
                _Label(l10n.jobAvailabilityLabel),
                _DateRow(
                  label: l10n.jobOpensAtLabel,
                  value: state.draft.opensAt,
                  onPick: () => _pickDate(
                      state.draft.opensAt, _controller.setOpensAt),
                  onClear: () => _controller.setOpensAt(null),
                ),
                _DateRow(
                  label: l10n.jobExpiresAtLabel,
                  value: state.draft.expiresAt,
                  onPick: () => _pickDate(
                      state.draft.expiresAt, _controller.setExpiresAt),
                  onClear: () => _controller.setExpiresAt(null),
                ),
                if (errText(JobField.availability) != null)
                  _FieldError(errText(JobField.availability)!),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _EditorBar(
          saving: state.saving,
          onPreview: () =>
              context.pushNamed(RouteNames.jobPreview, extra: state.draft),
          onPublish: _onPublish,
        ),
      ),
    );
  }
}

enum _LeaveChoice { save, discard, cancel }

class _AutoSaveIndicator extends StatelessWidget {
  const _AutoSaveIndicator({required this.state});
  final JobEditorState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall
        ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6));

    if (state.autosaving) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 6),
          Text(l10n.jobAutosaving, style: style),
        ],
      );
    }
    if (state.lastSavedAt != null) {
      final time = TimeOfDay.fromDateTime(state.lastSavedAt!).format(context);
      return Text(l10n.jobAutosaved(time), style: style);
    }
    return const SizedBox.shrink();
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = value == null
        ? l10n.jobDateNotSet
        : MaterialLocalizations.of(context).formatMediumDate(value!);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text('$label: $text',
                style: theme.textTheme.bodyMedium),
          ),
          if (value != null)
            TextButton(onPressed: onClear, child: Text(l10n.jobClearDate)),
          IconButton(
            tooltip: label,
            onPressed: onPick,
            icon: const Icon(Icons.calendar_today_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}

class _EditorBar extends StatelessWidget {
  const _EditorBar({
    required this.saving,
    required this.onPreview,
    required this.onPublish,
  });

  final bool saving;
  final VoidCallback onPreview;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(context.horizontalGutter, AppSpacing.sm,
          context.horizontalGutter, AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
            top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.4))),
      ),
      child: SafeArea(
        top: false,
        // Both buttons are Expanded so the theme's full-width (Size.fromHeight,
        // i.e. infinite-width) button style resolves to a bounded width in this
        // Row rather than asserting.
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.visibility_outlined, size: 20),
                label: Text(l10n.jobPreview),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: saving ? null : onPublish,
                icon: const Icon(Icons.publish_rounded, size: 20),
                label: Text(l10n.jobPublish),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(text,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.error)),
    );
  }
}
