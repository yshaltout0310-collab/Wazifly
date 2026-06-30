import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/countries_data.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/models/country_model.dart';
import '../../../shared/widgets/search_field.dart';
import '../application/country_controller.dart';
import 'widgets/country_tile.dart';

/// Searchable country picker (flag, name, dialing code).
///
/// Persists the chosen country and advances to onboarding.
class CountrySelectionScreen extends ConsumerStatefulWidget {
  const CountrySelectionScreen({super.key});

  @override
  ConsumerState<CountrySelectionScreen> createState() =>
      _CountrySelectionScreenState();
}

class _CountrySelectionScreenState
    extends ConsumerState<CountrySelectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CountryModel> get _filtered {
    if (_query.isEmpty) return CountriesData.all;
    final q = _query.toLowerCase();
    return CountriesData.all
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.dialCode.contains(q) ||
            c.isoCode.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _onSelect(CountryModel country) async {
    await ref.read(countryControllerProvider.notifier).select(country);
    if (!mounted) return;
    // push (not go) so the system Back button returns here.
    context.pushNamed(RouteNames.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(countryControllerProvider);
    final items = _filtered;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalGutter,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.countrySelectionTitle,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
                ).animate().fadeIn().moveY(begin: 10, end: 0),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.countrySelectionSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ).animate(delay: 80.ms).fadeIn(),
                const SizedBox(height: AppSpacing.lg),
                // Not wrapped in .animate() — see LanguageSelectionScreen note
                // (replaying animation on rebuild steals TextField focus).
                SearchField(
                  controller: _searchController,
                  hintText: l10n.countrySearchHint,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            '🔍',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.lg),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final country = items[index];
                            final tile = CountryTile(
                              country: country,
                              selected: selected?.isoCode == country.isoCode,
                              onTap: () => _onSelect(country),
                            );
                            // Animate only while browsing; filtered results
                            // appear instantly (no per-keystroke flicker).
                            if (_query.isNotEmpty) return tile;
                            return tile
                                .animate()
                                .fadeIn(
                                  delay: (25 * index).ms,
                                  duration: 220.ms,
                                )
                                .moveY(begin: 8, end: 0);
                          },
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
