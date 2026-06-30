import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/languages_data.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/language_model.dart';
import '../../../shared/widgets/search_field.dart';
import 'widgets/language_tile.dart';

/// "Choose Your Language" screen.
///
/// Surfaces popular languages first, supports search, and reveals the full
/// list (any world language) under "More Languages". Selecting a supported
/// language persists it and advances to country selection.
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _showMore = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LanguageModel> get _filtered {
    final source = _showMore ? LanguagesData.all : LanguagesData.popular;
    if (_query.isEmpty) return source;
    final q = _query.toLowerCase();
    return LanguagesData.all
        .where((l) =>
            l.englishName.toLowerCase().contains(q) ||
            l.nativeName.toLowerCase().contains(q) ||
            l.code.toLowerCase().contains(q))
        .toList();
  }

  void _onSelect(LanguageModel language) {
    final l10n = AppLocalizations.of(context);
    if (!language.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.languageComingSoon(language.englishName))),
      );
      return;
    }
    // Navigate FIRST (push, so Back returns here), THEN change the locale.
    // Doing it in this order — and without awaiting the persist — keeps the
    // push in the same synchronous tick: awaiting lets the locale-driven app
    // rebuild swallow the navigation.
    context.pushNamed(RouteNames.country);
    ref.read(localeControllerProvider.notifier).setLanguage(language.code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeControllerProvider);
    final items = _filtered;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalGutter,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.languageSelectionTitle,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
                ).animate().fadeIn().moveY(begin: 10, end: 0),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.languageSelectionSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ).animate(delay: 80.ms).fadeIn(),
                const SizedBox(height: AppSpacing.lg),
                // NOTE: do NOT wrap this TextField in .animate(); replaying the
                // entrance animation on every keystroke steals focus and breaks
                // typing. A controller keeps the text stable across rebuilds.
                SearchField(
                  controller: _searchController,
                  hintText: l10n.languageSearchHint,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_query.isEmpty)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l10n.popularLanguages,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final lang = items[index];
                      final tile = LanguageTile(
                        language: lang,
                        selected: current?.languageCode == lang.code,
                        onTap: () => _onSelect(lang),
                      );
                      // Animate only while browsing; filtered results appear
                      // instantly (no per-keystroke flicker).
                      if (_query.isNotEmpty) return tile;
                      return tile
                          .animate()
                          .fadeIn(delay: (40 * index).ms, duration: 250.ms)
                          .moveY(begin: 10, end: 0);
                    },
                  ),
                ),
                if (_query.isEmpty && !_showMore)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showMore = true),
                      icon: const Icon(Icons.language_rounded),
                      label: Text(l10n.moreLanguages),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
