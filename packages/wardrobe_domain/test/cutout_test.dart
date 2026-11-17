import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

CutoutImages _cutout(int tag) => CutoutImages(
  image: Uint8List.fromList([tag]),
  thumbnail: Uint8List.fromList([tag, tag]),
  width: 10,
  height: 20,
);

ClothingItem _item(String id) => ClothingItem(
  id: id,
  attributes: ClothingAttributes(),
  status: ItemStatus.draft,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

/// Records calls; [failCopyAt] / [failCutoutAt] make the n-th call fail.
final class _Repo implements WardrobeRepository {
  final cutouts = <String, CutoutImages>{};
  final created = <String>[];
  final deleted = <String>[];
  int? failCopyAt;
  int? failCutoutAt;
  var _copies = 0;
  var _cutoutCalls = 0;

  @override
  Future<Result<ClothingItem>> saveCutout(String id, CutoutImages c) async {
    if (++_cutoutCalls == failCutoutAt) {
      return const Failure(StorageFailure('disk full'));
    }
    cutouts[id] = c;
    return Success(_item(id));
  }

  @override
  Future<Result<ClothingItem>> copyPhotoToNewItem(String sourceId) async {
    if (++_copies == failCopyAt) {
      return const Failure(StorageFailure('disk full'));
    }
    final id = 'copy-$_copies';
    created.add(id);
    return Success(_item(id));
  }

  @override
  Future<Result<DeleteOutcome>> deleteItem(String id) async {
    deleted.add(id);
    return const Success(DeleteOutcome.removed);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ItemImages', () {
    const cutout = ItemCutout(image: 'c.png', thumbnail: 'c_thumb.png');

    test('shows the photo without a cut-out', () {
      const images = ItemImages(
        original: 'o.jpg',
        working: 'w.jpg',
        thumbnail: 't.jpg',
        showCutout: true,
      );
      expect(images.display, 'w.jpg');
      expect(images.displayThumbnail, 't.jpg');
    });

    test('shows the cut-out only when chosen', () {
      const shown = ItemImages(
        original: 'o.jpg',
        working: 'w.jpg',
        thumbnail: 't.jpg',
        cutout: cutout,
        showCutout: true,
      );
      expect(shown.display, 'c.png');
      expect(shown.displayThumbnail, 'c_thumb.png');

      const hidden = ItemImages(
        original: 'o.jpg',
        working: 'w.jpg',
        thumbnail: 't.jpg',
        cutout: cutout,
      );
      expect(hidden.display, 'w.jpg');
      expect(hidden.displayThumbnail, 't.jpg');
    });
  });

  group('AddGarmentsFromPhoto', () {
    test('first cut-out goes to the item, others to new items', () async {
      final repo = _Repo();
      final result = await AddGarmentsFromPhoto(repo)('item', [
        _cutout(1),
        _cutout(2),
        _cutout(3),
      ]);
      expect(result.valueOrNull!.map((i) => i.id), [
        'item',
        'copy-1',
        'copy-2',
      ]);
      expect(repo.cutouts['item']!.image, [1]);
      expect(repo.cutouts['copy-1']!.image, [2]);
      expect(repo.cutouts['copy-2']!.image, [3]);
      expect(repo.deleted, isEmpty);
    });

    test('nothing selected is a validation failure', () async {
      final result = await AddGarmentsFromPhoto(_Repo())('item', const []);
      expect(result, isA<Failure<List<ClothingItem>>>());
    });

    test('a failed copy removes the items already created', () async {
      final repo = _Repo()..failCopyAt = 2;
      final result = await AddGarmentsFromPhoto(repo)('item', [
        _cutout(1),
        _cutout(2),
        _cutout(3),
      ]);
      expect(result, isA<Failure<List<ClothingItem>>>());
      expect(repo.deleted, ['copy-1']);
      // The first item keeps its photo: it is never deleted.
      expect(repo.deleted, isNot(contains('item')));
    });

    test('a failed cut-out removes its new item too', () async {
      final repo = _Repo()..failCutoutAt = 2;
      final result = await AddGarmentsFromPhoto(repo)('item', [
        _cutout(1),
        _cutout(2),
      ]);
      expect(result, isA<Failure<List<ClothingItem>>>());
      expect(repo.deleted, ['copy-1']);
    });

    test('a failure on the first item creates nothing', () async {
      final repo = _Repo()..failCutoutAt = 1;
      final result = await AddGarmentsFromPhoto(repo)('item', [
        _cutout(1),
        _cutout(2),
      ]);
      expect(result, isA<Failure<List<ClothingItem>>>());
      expect(repo.created, isEmpty);
    });
  });
}
