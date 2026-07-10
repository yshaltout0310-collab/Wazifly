import 'package:careerbridge/core/services/secure_store/in_memory_secure_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemorySecureStore', () {
    late InMemorySecureStore store;

    setUp(() => store = InMemorySecureStore());

    test('read returns null when absent', () async {
      expect(await store.read('missing'), isNull);
    });

    test('write then read round-trips', () async {
      await store.write('k', 'v');
      expect(await store.read('k'), 'v');
    });

    test('bool defaults and round-trips', () async {
      expect(await store.readBool('flag'), isFalse);
      expect(await store.readBool('flag', defaultValue: true), isTrue);
      await store.writeBool('flag', value: true);
      expect(await store.readBool('flag'), isTrue);
      await store.writeBool('flag', value: false);
      expect(await store.readBool('flag'), isFalse);
    });

    test('delete removes a single key', () async {
      await store.write('a', '1');
      await store.write('b', '2');
      await store.delete('a');
      expect(await store.read('a'), isNull);
      expect(await store.read('b'), '2');
    });

    test('deleteAll clears everything', () async {
      await store.write('a', '1');
      await store.write('b', '2');
      await store.deleteAll();
      expect(await store.read('a'), isNull);
      expect(await store.read('b'), isNull);
    });
  });
}
