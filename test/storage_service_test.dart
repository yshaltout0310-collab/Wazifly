import 'dart:typed_data';

import 'package:careerbridge/core/services/cloud_storage/in_memory_storage_service.dart';
import 'package:careerbridge/core/services/cloud_storage/storage_paths.dart';
import 'package:careerbridge/core/services/cloud_storage/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final bytes = Uint8List.fromList([1, 2, 3, 4]);

  test('upload stores bytes, reports progress, records metadata, returns url',
      () async {
    final s = InMemoryStorageService();
    final fractions = <double>[];
    final url = await s.upload(
      path: 'users/u/profile.jpg',
      bytes: bytes,
      metadata: const StorageMetadata(
          contentType: 'image/jpeg', cacheControl: 'public,max-age=60'),
      onProgress: (p) => fractions.add(p.fraction),
    );

    expect(url, 'memory://users/u/profile.jpg');
    expect(fractions.last, 1.0);
    expect(fractions.first, lessThan(1.0));
    expect(s.files.containsKey('users/u/profile.jpg'), isTrue);
    expect(s.lastMetadata?.contentType, 'image/jpeg');
    expect(s.lastMetadata?.cacheControl, 'public,max-age=60');
  });

  test('failUploads returns null and stores nothing', () async {
    final s = InMemoryStorageService(failUploads: true);
    final url = await s.upload(path: 'p', bytes: bytes);
    expect(url, isNull);
    expect(s.files, isEmpty);
  });

  test('delete removes the object and records the path', () async {
    final s = InMemoryStorageService();
    await s.upload(path: 'p', bytes: bytes);
    await s.delete('p');
    expect(s.files.containsKey('p'), isFalse);
    expect(s.deleted, contains('p'));
    expect(await s.downloadUrl('p'), isNull);
  });

  test('StorageUploadProgress.fraction clamps and guards zero total', () {
    expect(const StorageUploadProgress(bytesTransferred: 1, totalBytes: 2).fraction, 0.5);
    expect(const StorageUploadProgress(bytesTransferred: 5, totalBytes: 0).fraction, 0);
    expect(StorageUploadProgress.none.fraction, 0);
  });

  test('StoragePaths are the rule-authorized paths', () {
    expect(StoragePaths.profilePhoto('u1'), 'users/u1/profile.jpg');
    expect(StoragePaths.companyLogo('c1'), 'companies/c1/logo.jpg');
    expect(StoragePaths.resume('u1', 'cv.pdf'), 'users/u1/resumes/cv.pdf');
  });
}
