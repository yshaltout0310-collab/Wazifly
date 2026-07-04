import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/services/company/company_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/company.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/presentation/widgets/auth_error.dart';
import '../application/company_edit_controller.dart';
import '../application/company_logo_controller.dart';
import '../application/company_providers.dart';
import '../domain/company_size.dart';
import '../domain/industry.dart';
import 'company_l10n.dart';

/// Full editor for the company: logo, name, industry, size, website, HQ,
/// description, contact information, and optional social links.
class EditCompanyScreen extends ConsumerStatefulWidget {
  const EditCompanyScreen({super.key});

  @override
  ConsumerState<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends ConsumerState<EditCompanyScreen> {
  late final TextEditingController _name;
  late final TextEditingController _website;
  late final TextEditingController _hq;
  late final TextEditingController _description;
  late final TextEditingController _contactEmail;
  late final TextEditingController _contactPhone;
  late final TextEditingController _linkedin;
  late final TextEditingController _x;
  late final TextEditingController _facebook;

  Industry? _industry;
  CompanySize? _size;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _website = TextEditingController();
    _hq = TextEditingController();
    _description = TextEditingController();
    _contactEmail = TextEditingController();
    _contactPhone = TextEditingController();
    _linkedin = TextEditingController();
    _x = TextEditingController();
    _facebook = TextEditingController();
  }

  void _seedFrom(Company? c) {
    if (c == null) return;
    _name.text = c.name ?? '';
    _website.text = c.website ?? '';
    _hq.text = c.headquarters ?? '';
    _description.text = c.description ?? '';
    _contactEmail.text = c.contactEmail ?? '';
    _contactPhone.text = c.contactPhone ?? '';
    _linkedin.text = c.linkedinUrl ?? '';
    _x.text = c.xUrl ?? '';
    _facebook.text = c.facebookUrl ?? '';
    _industry = c.industry;
    _size = c.size;
  }

  @override
  void dispose() {
    _name.dispose();
    _website.dispose();
    _hq.dispose();
    _description.dispose();
    _contactEmail.dispose();
    _contactPhone.dispose();
    _linkedin.dispose();
    _x.dispose();
    _facebook.dispose();
    super.dispose();
  }

  String? _clean(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final base = ref.read(currentCompanyProvider) ??
        const Company(companyId: '', ownerUid: '');
    final updated = base.copyWith(
      name: _clean(_name),
      industry: _industry,
      size: _size,
      website: _clean(_website),
      headquarters: _clean(_hq),
      description: _clean(_description),
      contactEmail: _clean(_contactEmail),
      contactPhone: _clean(_contactPhone),
      linkedinUrl: _clean(_linkedin),
      xUrl: _clean(_x),
      facebookUrl: _clean(_facebook),
    );

    final ok = await ref.read(companyEditControllerProvider.notifier).save(updated);
    if (!mounted) return;
    if (ok) {
      showAuthSnack(context, l10n.companySaved);
      if (context.canPop()) context.pop();
    } else {
      showAuthSnack(context, l10n.companyErrGeneric, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final company = ref.watch(currentCompanyProvider);
    final saving = ref.watch(companyEditControllerProvider).isSaving;

    // Seed the form once the company document stream first resolves.
    if (!_seeded && !ref.watch(companyProvider).isLoading) {
      _seeded = true;
      _seedFrom(company);
    }

    // Surface logo-upload failures.
    ref.listen(companyLogoControllerProvider, (prev, next) {
      if (next.status == LogoStatus.error) {
        showAuthSnack(context, companyFailureMessage(l10n, next.failure!),
            isError: true);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editCompanyTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: EdgeInsets.fromLTRB(context.horizontalGutter,
                AppSpacing.lg, context.horizontalGutter, AppSpacing.xl),
            children: [
              Center(child: _LogoEditor(logoUrl: company?.logoUrl)),
              const SizedBox(height: AppSpacing.xl),
              _field(l10n.companyNameLabel, _name, hint: l10n.companyNameHint),
              const SizedBox(height: AppSpacing.sm),
              _IndustryPicker(
                selected: _industry,
                onSelected: (v) => setState(() => _industry = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SizePicker(
                selected: _size,
                onSelected: (v) => setState(() => _size = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              _field(l10n.companyWebsiteLabel, _website,
                  hint: l10n.companyWebsiteHint,
                  keyboardType: TextInputType.url),
              _field(l10n.companyHqLabel, _hq, hint: l10n.companyHqHint),
              _field(l10n.companyDescriptionLabel, _description,
                  hint: l10n.companyDescriptionHint, maxLines: 4),
              const SizedBox(height: AppSpacing.md),
              _label(context, l10n.companyContactLabel),
              const SizedBox(height: AppSpacing.sm),
              _field(l10n.companyContactEmailLabel, _contactEmail,
                  keyboardType: TextInputType.emailAddress),
              _field(l10n.companyContactPhoneLabel, _contactPhone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: AppSpacing.md),
              _label(context, l10n.companyLinksLabel),
              const SizedBox(height: AppSpacing.sm),
              _field(l10n.companyLinkedinLabel, _linkedin,
                  hint: l10n.profileLinkHint, keyboardType: TextInputType.url),
              _field(l10n.companyXLabel, _x,
                  hint: l10n.profileLinkHint, keyboardType: TextInputType.url),
              _field(l10n.companyFacebookLabel, _facebook,
                  hint: l10n.profileLinkHint, keyboardType: TextInputType.url),
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

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      );

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

class _IndustryPicker extends StatelessWidget {
  const _IndustryPicker({required this.selected, required this.onSelected});
  final Industry? selected;
  final ValueChanged<Industry?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.companyIndustryLabel,
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final industry in Industry.values)
              ChoiceChip(
                label: Text(industry.label(l10n)),
                selected: selected == industry,
                onSelected: (on) => onSelected(on ? industry : null),
              ),
          ],
        ),
      ],
    );
  }
}

class _SizePicker extends StatelessWidget {
  const _SizePicker({required this.selected, required this.onSelected});
  final CompanySize? selected;
  final ValueChanged<CompanySize?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.companySizeLabel,
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final size in CompanySize.values)
              ChoiceChip(
                label: Text(size.label(l10n)),
                selected: selected == size,
                onSelected: (on) => onSelected(on ? size : null),
              ),
          ],
        ),
      ],
    );
  }
}

class _LogoEditor extends ConsumerWidget {
  const _LogoEditor({this.logoUrl});
  final String? logoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final working = ref.watch(companyLogoControllerProvider).isWorking;

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
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.brandGlow,
                image: logoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(logoUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: working
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white))
                  : (logoUrl == null
                      ? const Icon(Icons.business_rounded,
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
                        .read(companyLogoControllerProvider.notifier)
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
                  .read(companyLogoControllerProvider.notifier)
                  .pickAndUpload(),
          icon: const Icon(Icons.image_outlined, size: 18),
          label: Text(l10n.companyChangeLogo),
        ),
      ],
    );
  }
}
