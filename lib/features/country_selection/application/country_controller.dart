import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/countries_data.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/storage/storage_keys.dart';
import '../../../shared/models/country_model.dart';

/// Holds the user's selected country and persists it as JSON.
///
/// Defaults to [CountriesData.defaultCountry] (Qatar) so the whole app has a
/// sensible location context out of the box; a previously-persisted choice
/// overrides it, and the user can change it any time.
class CountryController extends StateNotifier<CountryModel?> {
  CountryController(this._ref) : super(CountriesData.defaultCountry) {
    _load();
  }

  final Ref _ref;

  void _load() {
    final json =
        _ref.read(localStorageProvider).getJson(StorageKeys.selectedCountry);
    if (json != null) state = CountryModel.fromJson(json);
  }

  Future<void> select(CountryModel country) async {
    state = country;
    await _ref
        .read(localStorageProvider)
        .setJson(StorageKeys.selectedCountry, country.toJson());
  }
}

final countryControllerProvider =
    StateNotifierProvider<CountryController, CountryModel?>(
  CountryController.new,
);
