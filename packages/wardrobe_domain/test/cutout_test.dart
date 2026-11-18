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
    const cutout = ItemPicture(image: 'c.png', thumbnail: 'c_thumb.png');
    const product = ItemPicture(image: 'p.jpg', thumbnail: 'p_thumb.jpg');

    test('falls back to the photo when the chosen image is missing', () {
      for (final view in ItemView.values) {
        final images = ItemImages(
          original: 'o.jpg',
          working: 'w.jpg',
          thumbnail: 't.jpg',
          view: view,
        );
        expect(images.shown, ItemView.photo);
        expect(images.display, 'w.jpg');
        expect(images.displayThumbnail, 't.jpg');
      }
    });

    test('shows the chosen image', () {
      ItemImages withView(ItemView view) => ItemImages(
        original: 'o.jpg',
        working: 'w.jpg',
        thumbnail: 't.jpg',
        cutout: cutout,
        product: product,
        view: view,
      );
      expect(withView(ItemView.photo).display, 'w.jpg');
      expect(withView(ItemView.cutout).display, 'c.png');
      expect(withView(ItemView.cutout).displayThumbnail, 'c_thumb.png');
      expect(withView(ItemView.product).display, 'p.jpg');
      expect(withView(ItemView.product).displayThumbnail, 'p_thumb.jpg');
      expect(withView(ItemView.photo).has(ItemView.product), isTrue);
    });

    test('defaults to the photo', () {
      const images = ItemImages(
        original: 'o.jpg',
        working: 'w.jpg',
        thumbnail: 't.jpg',
        cutout: cutout,
      );
      expect(images.shown, ItemView.photo);
      expect(images.has(ItemView.product), isFalse);
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
