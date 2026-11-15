import 'dart:io';
import 'dart:typed_data';

import 'package:ai_stylist/core/storage/file_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wardrobe_domain/wardrobe_domain.dart';

void main() {
  late Directory tmp;
  late LocalFileStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('file_store_test');
    store = LocalFileStore(Directory(p.join(tmp.path, 'files')));
  });

  tearDown(() => tmp.delete(recursive: true));

  final bytes = Uint8List.fromList([1, 2, 3, 4]);

  test('writes atomically and reads back, creating folders', () async {
    final result = await store.writeBytes('images/originals/a.jpg', bytes);
    expect(result.isSuccess, isTrue);

    final read = await store.readBytes('images/originals/a.jpg');
    expect(read.valueOrNull, bytes);
    expect(
      await File('${store.resolve('images/originals/a.jpg').path}.tmp')
          .exists(),
      isFalse,
    );
  });

  test('overwrites an existing file', () async {
    await store.writeBytes('a.bin', bytes);
    await store.writeBytes('a.bin', Uint8List.fromList([9]));
    expect((await store.readBytes('a.bin')).valueOrNull, [9]);
  });

  test('copies a source file in', () async {
    final source = File(p.join(tmp.path, 'picked.jpg'));
    await source.writeAsBytes(bytes);

    final result = await store.copyIn(source, 'images/originals/b.jpg');

    expect(result.isSuccess, isTrue);
    expect(await store.exists('images/originals/b.jpg'), isTrue);
    expect(await source.exists(), isTrue, reason: 'source is not moved');
  });

  test(
    'copying a missing source fails without leaving partial files',
    () async {
      final result = await store.copyIn(
        File(p.join(tmp.path, 'does-not-exist.jpg')),
        'images/originals/c.jpg',
      );

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).failure, isA<StorageFailure>());
      expect((await store.list('images')).valueOrNull, isEmpty);
    },
  );

  test('reading a missing file is a NotFoundFailure', () async {
    final result = await store.readBytes('nope.jpg');
    expect((result as Failure<Uint8List>).failure, isA<NotFoundFailure>());
  });

  test('deleting a missing file succeeds', () async {
    expect((await store.delete('nope.jpg')).isSuccess, isTrue);
  });

  test('lists relative, forward-slash paths and skips temp files', () async {
    await store.writeBytes('images/thumbs/z.jpg', bytes);
    await store.writeBytes('images/originals/a.jpg', bytes);
    await File('${store.resolve('images/originals/a.jpg').path}.tmp')
        .writeAsBytes(bytes);

    expect((await store.list('images')).valueOrNull, [
      'images/originals/a.jpg',
      'images/thumbs/z.jpg',
    ]);
    expect((await store.list('missing-dir')).valueOrNull, isEmpty);
  });

  group('rejects unsafe paths', () {
    for (final bad in [
      '',
      '/etc/passwd',
      r'C:\Windows\x',
      'C:/Windows/x',
      '../escape.jpg',
      'images/../../escape.jpg',
      'images//double.jpg',
      './a.jpg',
      r'images\win.jpg',
    ]) {
      test('"$bad"', () {
        expect(() => store.resolve(bad), throwsA(isA<InvalidStorePathError>()));
      });
    }
  });
}
