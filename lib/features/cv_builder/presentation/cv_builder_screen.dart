import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/chip_input.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/presentation/widgets/auth_error.dart';
import '../application/cv_builder_controller.dart';
import '../domain/cv_data.dart';
import 'cv_l10n.dart';
import 'widgets/cv_template_picker.dart';
import 'widgets/entry_editors.dart';

/// The CV Builder edit form: seeded from the profile (+ resume analysis),
/// hand-editable, with an AI "enhance" step and a preview/export handoff.
class CvBuilderScreen extends ConsumerStatefulWidget {
  const CvBuilderScreen({super.key});

  @override
  ConsumerState<CvBuilderScreen> createState() => _CvBuilderScreenState();
}

class _CvBuilderScreenState extends ConsumerState<CvBuilderScreen> {
  late final _fullName = TextEditingController();
  late final _headline = TextEditingController();
  late final _email = TextEditingController();
  late final _phone = TextEditingController();
  late final _location = TextEditingController();
  late final _portfolio = TextEditingController();
  late final _github = TextEditingController();
  late final _linkedin = TextEditingController();
  late final _targetRole = TextEditingController();
  late final _summary = TextEditingController();

  List<CvExperience> _experiences = const [];
  List<CvEducation> _education = const [];
  List<String> _skills = const [];

  @override
  void initState() {
    super.initState();
    _seedFrom(ref.read(cvBuilderControllerProvider).data);
  }

  @override
  void dispose() {
    for (final c in [
      _fullName, _headline, _email, _phone, _location,
      _portfolio, _github, _linkedin, _targetRole, _summary,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _seedFrom(CvData d) {
    _fullName.text = d.fullName;
    _headline.text = d.headline;
    _email.text = d.email;
    _phone.text = d.phone;
    _location.text = d.location;
    _portfolio.text = d.portfolioUrl;
    _github.text = d.githubUrl;
    _linkedin.text = d.linkedinUrl;
    _targetRole.text = d.targetRole;
    _summary.text = d.summary;
    _experiences = d.experiences;
    _education = d.education;
    _skills = d.skills;
  }

  CvData _collect() => CvData(
        fullName: _fullName.text.trim(),
        headline: _headline.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        location: _location.text.trim(),
        portfolioUrl: _portfolio.text.trim(),
        githubUrl: _github.text.trim(),
        linkedinUrl: _linkedin.text.trim(),
        summary: _summary.text.trim(),
        targetRole: _targetRole.text.trim(),
        experiences: _experiences,
        education: _education,
        skills: _skills,
      );

  void _sync() =>
      ref.read(cvBuilderControllerProvider.notifier).updateData(_collect());

  Future<void> _enhance() async {
    _sync();
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    await ref
        .read(cvBuilderControllerProvider.notifier)
        .enhance(languageCode: lang);
    if (!mounted) return;
    final state = ref.read(cvBuilderControllerProvider);
    if (state.failure != null) {
      showAuthSnack(context, cvFailureMessage(l10n, state.failure!),
          isError: true);
      ref.read(cvBuilderControllerProvider.notifier).clearFailure();
    } else {
      setState(() => _seedFrom(state.data)); // AI rewrote summary/bullets/skills
      showAuthSnack(context, l10n.cvEnhanced);
    }
  }

  void _preview() {
    _sync();
    context.pushNamed(RouteNames.cvPreview);
  }

  void _resetFromProfile() {
    ref.read(cvBuilderControllerProvider.notifier).resetFromProfile();
    setState(() => _seedFrom(ref.read(cvBuilderControllerProvider).data));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(cvBuilderControllerProvider);

    if (state.status == CvBuilderStatus.needsProfile) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.cvBuilderTitle)),
        body: SafeArea(child: _NeedsProfile(l10n: l10n)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cvBuilderTitle),
        actions: [
          IconButton(
            tooltip: l10n.cvResetFromProfile,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _resetFromProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.horizontalGutter,
              AppSpacing.lg,
              context.horizontalGutter,
              AppSpacing.xxl,
            ),
            children: [
              _sectionTitle(l10n.cvContactSection),
              _field(_fullName, l10n.cvFullName),
              _field(_headline, l10n.cvHeadline),
              _field(_email, l10n.cvEmail, keyboardType: TextInputType.emailAddress),
              _field(_phone, l10n.cvPhone, keyboardType: TextInputType.phone),
              _field(_location, l10n.cvLocation),
              const SizedBox(height: AppSpacing.md),
              _sectionTitle(l10n.cvLinksSection),
              _field(_portfolio, l10n.profilePortfolioLabel,
                  keyboardType: TextInputType.url),
              _field(_github, l10n.profileGithubLabel,
                  keyboardType: TextInputType.url),
              _field(_linkedin, l10n.profileLinkedinLabel,
                  keyboardType: TextInputType.url),
              const SizedBox(height: AppSpacing.md),
              _sectionTitle(l10n.cvTargetRole),
              _field(_targetRole, l10n.cvTargetRole, hint: l10n.cvTargetRoleHint),
              const SizedBox(height: AppSpacing.md),
              _sectionTitle(l10n.cvSummarySection),
              _field(_summary, l10n.cvSummarySection,
                  hint: l10n.cvSummaryHint, maxLines: 4),
              const SizedBox(height: AppSpacing.md),
              ChipInput(
                label: l10n.cvSkillsSection,
                hint: l10n.cvSkillHint,
                icon: Icons.bolt_outlined,
                values: _skills,
                onChanged: (v) {
                  setState(() => _skills = v);
                  _sync();
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _experienceSection(l10n),
              const SizedBox(height: AppSpacing.lg),
              _educationSection(l10n),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: l10n.cvEnhanceWithAi,
                icon: Icons.auto_awesome_rounded,
                loading: state.isEnhancing,
                onPressed: state.isEnhancing ? null : _enhance,
              ),
              const SizedBox(height: AppSpacing.xl),
              _sectionTitle(l10n.cvTemplateSection),
              const SizedBox(height: AppSpacing.sm),
              CvTemplatePicker(
                selected: state.templateId,
                onSelected: (id) => ref
                    .read(cvBuilderControllerProvider.notifier)
                    .selectTemplate(id),
              ),
              const SizedBox(height: AppSpacing.xl),
              _OutlinedAction(
                label: l10n.cvPreviewExport,
                icon: Icons.picture_as_pdf_outlined,
                onPressed: _preview,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Sections ---

  Widget _experienceSection(AppLocalizations l10n) {
    return _EntryList(
      title: l10n.cvExperienceSection,
      addLabel: l10n.cvAddExperience,
      onAdd: () async {
        final e = await editExperience(context, const CvExperience());
        if (e != null && !e.isBlank) {
          setState(() => _experiences = [..._experiences, e]);
          _sync();
        }
      },
      tiles: [
        for (var i = 0; i < _experiences.length; i++)
          _entryTile(
            title: [_experiences[i].role, _experiences[i].company]
                .where((s) => s.isNotEmpty)
                .join(' — '),
            subtitle: [_experiences[i].startDate, _experiences[i].endDate]
                .where((s) => s.isNotEmpty)
                .join(' – '),
            onTap: () async {
              final e = await editExperience(context, _experiences[i]);
              if (e == null) return;
              setState(() {
                final next = [..._experiences];
                e.isBlank ? next.removeAt(i) : next[i] = e;
                _experiences = next;
              });
              _sync();
            },
            onDelete: () {
              setState(() {
                final next = [..._experiences]..removeAt(i);
                _experiences = next;
              });
              _sync();
            },
          ),
      ],
    );
  }

  Widget _educationSection(AppLocalizations l10n) {
    return _EntryList(
      title: l10n.cvEducationSection,
      addLabel: l10n.cvAddEducation,
      onAdd: () async {
        final e = await editEducation(context, const CvEducation());
        if (e != null && !e.isBlank) {
          setState(() => _education = [..._education, e]);
          _sync();
        }
      },
      tiles: [
        for (var i = 0; i < _education.length; i++)
          _entryTile(
            title: [_education[i].degree, _education[i].institution]
                .where((s) => s.isNotEmpty)
                .join(' — '),
            subtitle: [_education[i].startYear, _education[i].endYear]
                .where((s) => s.isNotEmpty)
                .join(' – '),
            onTap: () async {
              final e = await editEducation(context, _education[i]);
              if (e == null) return;
              setState(() {
                final next = [..._education];
                e.isBlank ? next.removeAt(i) : next[i] = e;
                _education = next;
              });
              _sync();
            },
            onDelete: () {
              setState(() {
                final next = [..._education]..removeAt(i);
                _education = next;
              });
              _sync();
            },
          ),
      ],
    );
  }

  // --- Small builders ---

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: 2),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String fallbackLabel, {
    String? label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label ?? fallbackLabel,
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  Widget _entryTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title.isEmpty ? '—' : title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          color: AppColors.error,
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _EntryList extends StatelessWidget {
  const _EntryList({
    required this.title,
    required this.addLabel,
    required this.onAdd,
    required this.tiles,
  });

  final String title;
  final String addLabel;
  final VoidCallback onAdd;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(addLabel),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ...tiles,
      ],
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction(
      {required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

class _NeedsProfile extends StatelessWidget {
  const _NeedsProfile({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.badge_outlined,
              size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.cvNeedsProfileTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.cvNeedsProfileBody,
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
