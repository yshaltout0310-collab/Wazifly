import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/storage/storage_keys.dart';
import '../../../shared/models/country_model.dart';

/// Holds the user's selected country and persists it as JSON.
class CountryController extends StateNotifier<CountryModel?> {
  CountryController(this._ref) : super(null) {
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
