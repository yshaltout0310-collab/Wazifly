import 'dart:async';

import 'package:flutter/foundation.dart';

/// Error handling for Firestore `.snapshots()` streams.
///
/// ## The bug this replaces
///
/// Every Firestore-backed repository used to end its stream pipeline with:
///
/// ```dart
/// .handleError((Object e) {
///   debugPrint('[Tag] watch failed: $e');
/// });
/// ```
///
/// `Stream.handleError`, given a handler and no `test`, **consumes** the error:
/// it does not forward it downstream. A Firestore `snapshots()` stream
/// *terminates* on error, so the transformed stream closed having emitted
/// **no value and no error at all**. A Riverpod `StreamProvider` that has
/// received neither stays in `AsyncLoading` **forever** — which is why a rules
/// denial, an App Check rejection, an offline cold cache, or Firestore web
/// persistence failing in a second browser tab all presented identically: a
/// spinner that never ends, on a screen with no way to recover and no
/// user-visible diagnostic.
///
/// ## The contract now
///
/// [logAndForwardErrors] keeps the diagnostics (and the optional security-audit
/// hook) but **forwards the error downstream**, so the provider resolves to
/// `AsyncError` and the UI can tell "nothing here yet" apart from "this is
/// broken — retry".
///
/// It uses an explicit [StreamTransformer] sink rather than `handleError` +
/// `throw`: both forward the error, but `addError` states the intent plainly and
/// passes the original [StackTrace] through without relying on `handleError`'s
/// rethrow semantics.
extension FirestoreStreamErrors<T> on Stream<T> {
  /// Logs any stream error under [tag], notifies [onError] (e.g. a
  /// `SecurityAuditLog` recorder), then **re-emits the error downstream**.
  ///
  /// Data and completion events pass through untouched. [onError] is treated as
  /// best-effort: it is invoked for its side effect only, and a throw from it
  /// would replace the original error, so callers must keep it non-throwing
  /// (`SecurityAuditLog.record` already guarantees this).
  Stream<T> logAndForwardErrors(
    String tag, {
    void Function(Object error)? onError,
  }) {
    return transform(
      StreamTransformer<T, T>.fromHandlers(
        handleError: (Object error, StackTrace stack, EventSink<T> sink) {
          debugPrint('[$tag] stream failed: $error');
          onError?.call(error);
          sink.addError(error, stack);
        },
      ),
    );
  }
}
