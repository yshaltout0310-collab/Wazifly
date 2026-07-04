import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/widgets/chip_input.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/cv_data.dart';

/// Opens the experience editor sheet; returns the edited entry, or null on cancel.
Future<CvExperience?> editExperience(BuildContext context, CvExperience initial) {
  return _showSheet<CvExperience>(
    context,
    (ctx) => _ExperienceForm(initial: initial),
  );
}

Future<CvEducation?> editEducation(BuildContext context, CvEducation initial) {
  return _showSheet<CvEducation>(
    context,
    (ctx) => _EducationForm(initial: initial),
  );
}

Future<T?> _showSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: builder(ctx),
    ),
  );
}

Widget _field(TextEditingController c, String label,
    {int maxLines = 1, TextInputType? keyboardType}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

// --- Experience ---

class _ExperienceForm extends StatefulWidget {
  const _ExperienceForm({required this.initial});
  final CvExperience initial;

  @override
  State<_ExperienceForm> createState() => _ExperienceFormState();
}

class _ExperienceFormState extends State<_ExperienceForm> {
  late final _role = TextEditingController(text: widget.initial.role);
  late final _company = TextEditingController(text: widget.initial.company);
  late final _location = TextEditingController(text: widget.initial.location);
  late final _start = TextEditingController(text: widget.initial.startDate);
  late final _end = TextEditingController(text: widget.initial.endDate);
  late bool _current = widget.initial.current;
  late List<String> _bullets = widget.initial.bullets;

  @override
  void dispose() {
    for (final c in [_role, _company, _location, _start, _end]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SheetBody(
      title: l10n.cvExperienceSection,
      onSave: () => Navigator.of(context).pop(
        CvExperience(
          role: _role.text.trim(),
          company: _company.text.trim(),
          location: _location.text.trim(),
          startDate: _start.text.trim(),
          endDate: _current ? '' : _end.text.trim(),
          current: _current,
          bullets: _bullets,
        ),
      ),
      children: [
        _field(_role, l10n.cvRole),
        _field(_company, l10n.cvCompany),
        _field(_location, l10n.cvLocation),
        Row(
          children: [
            Expanded(child: _field(_start, l10n.cvStartDate)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: IgnorePointer(
                ignoring: _current,
                child: Opacity(
                  opacity: _current ? 0.5 : 1,
                  child: _field(_end, l10n.cvEndDate),
                ),
              ),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.cvCurrentRole),
          value: _current,
          onChanged: (v) => setState(() => _current = v),
        ),
        const SizedBox(height: AppSpacing.sm),
        ChipInput(
          label: l10n.cvHighlights,
          hint: l10n.cvAddHighlight,
          icon: Icons.star_outline_rounded,
          values: _bullets,
          onChanged: (v) => setState(() => _bullets = v),
        ),
      ],
    );
  }
}

// --- Education ---

class _EducationForm extends StatefulWidget {
  const _EducationForm({required this.initial});
  final CvEducation initial;

  @override
  State<_EducationForm> createState() => _EducationFormState();
}

class _EducationFormState extends State<_EducationForm> {
  late final _degree = TextEditingController(text: widget.initial.degree);
  late final _institution =
      TextEditingController(text: widget.initial.institution);
  late final _start = TextEditingController(text: widget.initial.startYear);
  late final _end = TextEditingController(text: widget.initial.endYear);
  late final _details = TextEditingController(text: widget.initial.details);

  @override
  void dispose() {
    for (final c in [_degree, _institution, _start, _end, _details]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SheetBody(
      title: l10n.cvEducationSection,
      onSave: () => Navigator.of(context).pop(
        CvEducation(
          degree: _degree.text.trim(),
          institution: _institution.text.trim(),
          startYear: _start.text.trim(),
          endYear: _end.text.trim(),
          details: _details.text.trim(),
        ),
      ),
      children: [
        _field(_degree, l10n.cvDegree),
        _field(_institution, l10n.cvInstitution),
        Row(
          children: [
            Expanded(child: _field(_start, l10n.cvStartDate)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _field(_end, l10n.cvEndDate)),
          ],
        ),
        _field(_details, l10n.cvSummaryHint, maxLines: 2),
      ],
    );
  }
}

/// Shared scrollable sheet chrome (title + fields + save button).
class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.title,
    required this.children,
    required this.onSave,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              ...children,
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: l10n.save,
                icon: Icons.check_rounded,
                onPressed: onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
