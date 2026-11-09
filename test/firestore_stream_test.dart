import 'dart:async';
import 'dart:io';

import 'package:careerbridge/core/services/firebase/firestore_stream.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the stream-error contract every Firestore-backed repository relies on.
///
/// The bug these tests exist for: `Stream.handleError`, given a handler and no
/// `test`, **consumes** the error instead of forwarding it. Firestore's
/// `snapshots()` stream terminates on error, so a pipeline ending in
/// `.handleError((e) { debugPrint(...); })` closed having emitted **no value and
/// no error**. A Riverpod `StreamProvider` that receives neither stays in
/// `AsyncLoading` forever — an endless spinner on a screen with no way to
/// recover and no user-visible diagnostic.
///
/// Both halves matter, so both are tested: the error must still be *reported*
/// (log + audit hook), and it must *reach the listener*.
void main() {
  group('logAndForwardErrors', () {
    test('forwards the error to the listener instead of swallowing it',
        () async {
      final controller = StreamController<int>();
      final errors = <Object>[];

      final sub = controller.stream
          .logAndForwardErrors('Test')
          .listen((_) {}, onError: errors.add);

      final failure = StateError('denied');
      controller.addError(failure);
      await pumpEventQueue();

      expect(errors, [same(failure)],
          reason: 'the listener must see the error — this is the regression '
              'that left StreamProviders loading forever');

      await sub.cancel();
      await controller.close();
    });

    test('preserves the original stack trace', () async {
      final controller = StreamController<int>();
      final stack = StackTrace.current;
      StackTrace? received;

      final sub = controller.stream.logAndForwardErrors('Test').listen(
            (_) {},
            onError: (Object _, StackTrace s) => received = s,
          );

      controller.addError(StateError('denied'), stack);
      await pumpEventQueue();

      expect(received, same(stack));

      await sub.cancel();
      await controller.close();
    });

    test('invokes the onError side effect (the security-audit hook)', () async {
      final controller = StreamController<int>();
      final audited = <Object>[];

      final sub = controller.stream
          .logAndForwardErrors('Test', onError: audited.add)
          .listen((_) {}, onError: (Object _) {});

      final failure = StateError('permission-denied');
      controller.addError(failure);
      await pumpEventQueue();

      expect(audited, [same(failure)]);

      await sub.cancel();
      await controller.close();
    });

    test('passes data and completion through untouched', () async {
      final values = await Stream<int>.fromIterable([1, 2, 3])
          .logAndForwardErrors('Test')
          .toList();

      expect(values, [1, 2, 3]);
    });

    test('keeps delivering after a non-terminal error', () async {
      final controller = StreamController<int>();
      final values = <int>[];
      final errors = <Object>[];

      final sub = controller.stream
          .logAndForwardErrors('Test')
          .listen(values.add, onError: errors.add);

      controller.add(1);
      controller.addError(StateError('transient'));
      controller.add(2);
      await pumpEventQueue();

      expect(values, [1, 2]);
      expect(errors, hasLength(1));

      await sub.cancel();
      await controller.close();
    });
  });

  test('no Firestore repository swallows stream errors with handleError', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // The extension itself documents the old pattern and names the handler
      // parameter of StreamTransformer.fromHandlers.
      if (entity.uri.pathSegments.last == 'firestore_stream.dart') continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue; // doc comments
        if (line.contains('.handleError(')) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'handleError() consumes the error without forwarding it, which '
          'leaves a StreamProvider in AsyncLoading forever (endless spinner, '
          'no diagnostic). Use .logAndForwardErrors() instead: $offenders',
    );
  });
}
