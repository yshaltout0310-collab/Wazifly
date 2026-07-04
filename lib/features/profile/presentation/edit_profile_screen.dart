import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/services/user_profile/user_profile_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/presentation/widgets/auth_error.dart';
import '../application/profile_completion_provider.dart';
import '../application/profile_edit_controller.dart';
import '../application/profile_photo_controller.dart';
import '../domain/experience_level.dart';
import '../../../shared/widgets/chip_input.dart';
import 'profile_l10n.dart';

/// Full editor for the extended profile: photo, identity, headline/location/bio,
/// skills, experience level, preferred job titles, and links.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _headline;
  late final TextEditingController _location;
  late final TextEditingController _bio;
  late final TextEditingController _portfolio;
  late final TextEditingController _github;
  late final TextEditingController _linkedin;

  List<String> _skills = const [];
  List<String> _preferredTitles = const [];
  ExperienceLevel? _experienceLevel;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    // Controllers start empty; the form is seeded once the profile stream first
    // resolves (see the guard in build) so we don't seed from the auth-only
    // fallback before the stored document arrives.
    _name = TextEditingController();
    _headline = TextEditingController();
    _location = TextEditingController();
    _bio = TextEditingController();
    _portfolio = TextEditingController();
    _github = TextEditingController();
    _linkedin = TextEditingController();
  }

  void _seedFrom(UserProfile? p) {
    if (p == null) return;
    _name.text = p.displayName ?? '';
    _headline.text = p.headline ?? '';
    _location.text = p.location ?? '';
    _bio.text = p.bio ?? '';
    _portfolio.text = p.portfolioUrl ?? '';
    _github.text = p.githubUrl ?? '';
    _linkedin.text = p.linkedinUrl ?? '';
    _skills = p.skills;
    _preferredTitles = p.preferredJobTitles;
    _experienceLevel = p.experienceLevel;
  }

  @override
  void dispose() {
    _name.dispose();
    _headline.dispose();
    _location.dispose();
    _bio.dispose();
    _portfolio.dispose();
    _github.dispose();
    _linkedin.dispose();
    super.dispose();
  }

  String? _clean(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final base = ref.read(currentUserProfileProvider) ??
        const UserProfile(uid: '');
    final updated = base.copyWith(
      displayName: _clean(_name),
      headline: _clean(_headline),
      location: _clean(_location),
      bio: _clean(_bio),
      skills: _skills,
      experienceLevel: _experienceLevel,
      preferredJobTitles: _preferredTitles,
      portfolioUrl: _clean(_portfolio),
      githubUrl: _clean(_github),
      linkedinUrl: _clean(_linkedin),
    );

    final ok = await ref.read(profileEditControllerProvider.notifier).save(updated);
    if (!mounted) return;
    if (ok) {
      showAuthSnack(context, l10n.profileSaved);
      if (context.canPop()) context.pop();
    } else {
      showAuthSnack(context, l10n.profileSaveFailed, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(currentUserProfileProvider);
    final saving = ref.watch(profileEditControllerProvider).isSaving;

    // Seed the form once the profile document stream first resolves (data or a
    // definitive null), merging the auth identity fallback.
    if (!_seeded && !ref.watch(userProfileProvider).isLoading) {
      _seeded = true;
      _seedFrom(profile);
    }

    // Surface photo-upload failures.
    ref.listen(profilePhotoControllerProvider, (prev, next) {
      if (next.status == PhotoStatus.error) {
        showAuthSnack(context, l10n.profilePhotoUploadFailed, isError: true);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfileTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.horizontalGutter,
              AppSpacing.lg,
              context.horizontalGutter,
              AppSpacing.xl,
            ),
            children: [
              Center(child: _PhotoEditor(photoUrl: profile?.photoUrl)),
              const SizedBox(height: AppSpacing.xl),
              _field(l10n.profileNameLabel, _name),
              _field(l10n.profileHeadlineLabel, _headline,
                  hint: l10n.profileHeadlineHint),
              _field(l10n.profileLocationLabel, _location,
                  hint: l10n.profileLocationHint),
              _field(l10n.profileBioLabel, _bio,
                  hint: l10n.profileBioHint, maxLines: 4),
              const SizedBox(height: AppSpacing.md),
              ChipInput(
                label: l10n.profileSkillsLabel,
                hint: l10n.profileSkillsHint,
                icon: Icons.bolt_outlined,
                values: _skills,
                onChanged: (v) => setState(() => _skills = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ExperiencePicker(
                selected: _experienceLevel,
                onSelected: (v) => setState(() => _experienceLevel = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              ChipInput(
                label: l10n.profilePreferredTitlesLabel,
                hint: l10n.profilePreferredTitlesHint,
                icon: Icons.work_outline_rounded,
                values: _preferredTitles,
                onChanged: (v) => setState(() => _preferredTitles = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.profileLinksLabel,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              _field(l10n.profilePortfolioLabel, _portfolio,
                  hint: l10n.profileLinkHint,
                  keyboardType: TextInputType.url),
              _field(l10n.profileGithubLabel, _github,
                  hint: l10n.profileLinkHint,
                  keyboardType: TextInputType.url),
              _field(l10n.profileLinkedinLabel, _linkedin,
                  hint: l10n.profileLinkHint,
                  keyboardType: TextInputType.url),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: l10n.save,
                icon: Icons.check_rounded,
                loading: saving,
                onPressed: saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
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
          labelText: label,
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }
}

class _PhotoEditor extends ConsumerWidget {
  const _PhotoEditor({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final working = ref.watch(profilePhotoControllerProvider).isWorking;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 104,
              height: 104,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.ctaGradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.brandGlow,
                image: photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(photoUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: working
                  ? const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    )
                  : (photoUrl == null
                      ? const Icon(Icons.person_rounded,
                          color: AppColors.white, size: 48)
                      : null),
            ),
            Material(
              color: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: working
                    ? null
                    : () => ref
                        .read(profilePhotoControllerProvider.notifier)
                        .pickAndUpload(),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Icon(Icons.camera_alt_rounded,
                      color: AppColors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: working
              ? null
              : () => ref
                  .read(profilePhotoControllerProvider.notifier)
                  .pickAndUpload(),
          icon: const Icon(Icons.image_outlined, size: 18),
          label: Text(l10n.profileChangePhoto),
        ),
      ],
    );
  }
}

class _ExperiencePicker extends StatelessWidget {
  const _ExperiencePicker({required this.selected, required this.onSelected});

  final ExperienceLevel? selected;
  final ValueChanged<ExperienceLevel?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profileExperienceLabel,
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final level in ExperienceLevel.values)
              ChoiceChip(
                label: Text(level.label(l10n)),
                selected: selected == level,
                onSelected: (on) => onSelected(on ? level : null),
              ),
          ],
        ),
      ],
    );
  }
}
