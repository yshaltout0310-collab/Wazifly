/// Deterministic, cross-platform content fingerprints.
///
/// Used wherever a value must hash the *same* on every run, isolate, platform,
/// and app launch — CV import de-duplication, learning-interest ids. Dart's
/// `Object.hashCode` is explicitly **not** stable across runs, so it can't be
/// used for anything that is persisted or compared later.
library;

/// FNV-1a offset basis (32-bit).
const int _offsetBasis = 0x811C9DC5;

/// FNV-1a prime (32-bit).
const int _prime = 0x01000193;

/// A deterministic 16-hex-character digest of [units] (UTF-16 code units or
/// raw bytes).
///
/// **Why two 32-bit lanes instead of one 64-bit lane:** the canonical 64-bit
/// FNV-1a constants (`0xcbf29ce484222325`, `0xFFFFFFFFFFFFFFFF`) cannot be
/// represented exactly in JavaScript, so a 64-bit implementation fails to
/// compile for the web target. Two independently seeded 32-bit lanes — the
/// second consuming the input in reverse so the lanes stay independent —
/// concatenate to a digest that keeps the original 16-character width and
/// ~64-bit collision resistance while every intermediate stays inside the range
/// JavaScript represents exactly.
///
/// Digests differ from the pre-web 64-bit implementation. Only **determinism**
/// is contractual (see `test/cv_document_test.dart`); a digest persisted by an
/// older build simply won't match, which at worst costs one missed duplicate
/// detection on re-import.
String stableHashOfUnits(List<int> units) {
  final forward = _fnv1a32(units, _offsetBasis, reverse: false);
  final backward = _fnv1a32(units, _prime, reverse: true);
  return backward.toRadixString(16).padLeft(8, '0') +
      forward.toRadixString(16).padLeft(8, '0');
}

/// A deterministic 16-hex-character digest of [input].
String stableHash(String input) => stableHashOfUnits(input.codeUnits);

/// One 32-bit FNV-1a lane over [units], seeded with [seed].
int _fnv1a32(List<int> units, int seed, {required bool reverse}) {
  var hash = seed;
  for (var i = 0; i < units.length; i++) {
    final unit = units[reverse ? units.length - 1 - i : i];
    hash = (hash ^ (unit & 0xFFFF)) & 0xFFFFFFFF;
    // hash * _prime, split into 16-bit halves so no intermediate product
    // exceeds 2^53 (JavaScript's exact-integer ceiling).
    final low = (hash & 0xFFFF) * _prime;
    final high = ((hash >> 16) & 0xFFFF) * _prime;
    hash = (low + ((high & 0xFFFF) << 16)) & 0xFFFFFFFF;
  }
  return hash;
}
