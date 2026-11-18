import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/media/file_hasher.dart';
import '../../../core/media/image_processor.dart';
import '../../../core/storage/file_store.dart';
import 'clothing_item_mapper.dart';

/// Drift + [FileStore] implementation of [WardrobeRepository].
///
/// Image layout under the file store root:
/// `images/originals/<id>.<ext>`, `images/working/<id>.jpg`,
/// `images/thumbs/<id>.jpg`, for cut-outs `images/cutouts/<name>.png` and
/// `<name>_thumb.png`, and for product photos `images/products/<name>.jpg`
/// and `<name>_thumb.jpg` (a fresh name each time, so image caches never
/// show a replaced file).
final class DriftWardrobeRepository implements WardrobeRepository {
  DriftWardrobeRepository({
    required AppDatabase database,
    required this._files,
    required this._images,
    required this._hasher,
    required this._clock,
    required this._ids,
  }) : _db = database;

  final AppDatabase _db;
  final FileStore _files;
  final ImageProcessor _images;
  final FileHasher _hasher;
  final Clock _clock;
  final IdGenerator _ids;

  static const imagesDir = 'images';
  static const workingMaxEdge = 1024;
  static const thumbnailMaxEdge = 320;

  /// Formats accepted for import. HEIC/HEIF are decoded natively on iOS and
  /// on Android 9+ (DECISIONS D-21).
  static const supportedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.heic',
    '.heif',
    '.webp',
  };

  // ---------------------------------------------------------------- reading

  @override
  Stream<List<ClothingItem>> watchItems(WardrobeFilter filter) {
    final query = _db.select(_db.clothingItems)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (filter.statuses.isNotEmpty) {
      query.where((t) => t.status.isIn(filter.statuses.map((s) => s.code)));
    }
    if (filter.categories.isNotEmpty) {
      query.where((t) => t.category.isIn(filter.categories.map((c) => c.code)));
    }
    // Colour, season, formality and text are matched in memory with the
    // same predicate the domain defines, so both paths always agree.
    return query.watch().asyncMap((rows) async {
      final items = await _hydrate(rows);
      return items.where(filter.matches).toList(growable: false);
    });
  }

  @override
  Stream<ClothingItem?> watchItem(String id) {
    final query = _db.select(_db.clothingItems)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    return query.watchSingleOrNull().asyncMap(
      (row) async => row == null ? null : (await _hydrate([row])).single,
    );
  }

  @override
  Future<Result<ClothingItem>> getItem(String id) async {
    try {
      final item = await _load(id);
      return item == null
          ? Failure(NotFoundFailure('No clothing item $id'))
          : Success(item);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read item $id', cause: e));
    }
  }

  Future<ClothingItem?> _load(String id) async {
    final row = await (_db.select(
      _db.clothingItems,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return row == null ? null : (await _hydrate([row])).single;
  }

  /// Loads colours, seasons and images for [rows] with one query each.
  Future<List<ClothingItem>> _hydrate(List<ClothingItemRow> rows) async {
    if (rows.isEmpty) return const [];
    final ids = rows.map((r) => r.id).toList();
    final colors = await (_db.select(
      _db.clothingItemColors,
    )..where((t) => t.itemId.isIn(ids))).get();
    final seasons = await (_db.select(
      _db.clothingItemSeasons,
    )..where((t) => t.itemId.isIn(ids))).get();
    final images = await (_db.select(
      _db.clothingImages,
    )..where((t) => t.itemId.isIn(ids))).get();
    return [
      for (final row in rows)
        ClothingItemMapper.toDomain(
          row,
          colors: [
            for (final c in colors)
              if (c.itemId == row.id) c,
          ],
          seasons: [
            for (final s in seasons)
              if (s.itemId == row.id) s,
          ],
          images: [
            for (final i in images)
              if (i.itemId == row.id) i,
          ],
        ),
    ];
  }

  // ---------------------------------------------------------------- import

  @override
  Future<Result<ClothingItem>> importImage(String sourcePath) async {
    final ext = p.extension(sourcePath).toLowerCase();
    if (!supportedExtensions.contains(ext)) {
      return Failure(UnsupportedImageFailure('Unsupported file type "$ext"'));
    }
    if (!await File(sourcePath).exists()) {
      return const Failure(StorageFailure('The selected photo is unavailable'));
    }

    final String hash;
    try {
      hash = await _hasher(sourcePath);
    } on FileSystemException catch (e) {
      return Failure(StorageFailure('Could not read the photo', cause: e));
    }

    final duplicate = await _findByHash(hash);
    if (duplicate != null) {
      return Failure(
        DuplicateItemFailure(
          'This photo is already in your wardrobe',
          existingItemId: duplicate,
        ),
      );
    }

    final id = _ids.newId();
    final originalPath = '$imagesDir/originals/$id$ext';
    final workingPath = '$imagesDir/working/$id.jpg';
    final thumbPath = '$imagesDir/thumbs/$id.jpg';
    final written = <String>[];

    Future<Result<ClothingItem>> fail(AppFailure failure) async {
      for (final path in written) {
        await _files.delete(path);
      }
      return Failure(failure);
    }

    final copied = await _files.copyIn(File(sourcePath), originalPath);
    if (copied case Failure(:final failure)) return fail(failure);
    written.add(originalPath);

    final sizes = <String, int>{};
    for (final (path, edge, quality) in [
      (workingPath, workingMaxEdge, 85),
      (thumbPath, thumbnailMaxEdge, 80),
    ]) {
      final bytes = await _images.downscaleToJpeg(
        sourcePath,
        maxEdge: edge,
        quality: quality,
      );
      if (bytes == null || bytes.isEmpty) {
        return fail(
          const UnsupportedImageFailure('This photo could not be opened'),
        );
      }
      final saved = await _files.writeBytes(path, bytes);
      if (saved case Failure(:final failure)) return fail(failure);
      written.add(path);
      sizes[path] = bytes.length;
    }

    final now = toEpochMillisUtc(_clock.nowUtc());
    try {
      await _db.transaction(() async {
        await _db
            .into(_db.clothingItems)
            .insert(
              ClothingItemsCompanion.insert(
                id: id,
                category: GarmentCategory.unknown.code,
                status: ItemStatus.draft.code,
                contentSha256: Value(hash),
                createdAt: now,
                updatedAt: now,
              ),
            );
        for (final (kind, path) in [
          (ImageKind.original, originalPath),
          (ImageKind.working, workingPath),
          (ImageKind.thumbnail, thumbPath),
        ]) {
          await _db
              .into(_db.clothingImages)
              .insert(
                ClothingImagesCompanion.insert(
                  id: _ids.newId(),
                  itemId: id,
                  kind: kind,
                  relativePath: path,
                  byteSize: Value(sizes[path]),
                  createdAt: now,
                ),
              );
        }
      });
    } on Exception catch (e) {
      return fail(StorageFailure('Could not save the new item', cause: e));
    }

    final item = await _load(id);
    return item == null
        ? const Failure(StorageFailure('The new item could not be read back'))
        : Success(item);
  }

  Future<String?> _findByHash(String hash) async {
    final row =
        await (_db.select(_db.clothingItems)
              ..where(
                (t) => t.contentSha256.equals(hash) & t.deletedAt.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    return row?.id;
  }

  // ---------------------------------------------------------------- editing

  @override
  Future<Result<ClothingItem>> saveAttributes(
    String id,
    ClothingAttributes attributes, {
    required bool activate,
  }) async {
    try {
      final existing = await _load(id);
      if (existing == null) return Failure(NotFoundFailure('No item $id'));
      final now = toEpochMillisUtc(_clock.nowUtc());
      final status = activate && existing.status == ItemStatus.draft
          ? ItemStatus.active
          : existing.status;

      await _db.transaction(() async {
        await (_db.update(
          _db.clothingItems,
        )..where((t) => t.id.equals(id))).write(
          ClothingItemMapper.attributeColumns(
            attributes,
            updatedAt: now,
          ).copyWith(status: Value(status.code)),
        );
        await (_db.delete(
          _db.clothingItemColors,
        )..where((t) => t.itemId.equals(id))).go();
        await (_db.delete(
          _db.clothingItemSeasons,
        )..where((t) => t.itemId.equals(id))).go();
        await _db.batch((b) {
          b.insertAll(
            _db.clothingItemColors,
            ClothingItemMapper.colorRows(id, attributes),
          );
          b.insertAll(
            _db.clothingItemSeasons,
            ClothingItemMapper.seasonRows(id, attributes),
          );
        });
      });
      final saved = await _load(id);
      return saved == null
          ? Failure(NotFoundFailure('No item $id'))
          : Success(saved);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not save item $id', cause: e));
    }
  }

  // ---------------------------------------------------------------- pictures

  @override
  Future<Result<ClothingItem>> saveCutout(String id, CutoutImages cutout) {
    final stem = '$imagesDir/cutouts/${_ids.newId()}';
    return _replacePicture(
      id,
      view: ItemView.cutout,
      files: [
        _NewFile(
          '$stem.png',
          ImageKind.cutout,
          cutout.image,
          width: cutout.width,
          height: cutout.height,
        ),
        _NewFile(
          '${stem}_thumb.png',
          ImageKind.cutoutThumbnail,
          cutout.thumbnail,
        ),
        if (cutout.isPolished) ...[
          _NewFile('${stem}_raw.png', ImageKind.cutoutRaw, cutout.rawImage!),
          _NewFile(
            '${stem}_raw_thumb.png',
            ImageKind.cutoutRawThumbnail,
            cutout.rawThumbnail!,
          ),
        ],
      ],
    );
  }

  @override
  Future<Result<ClothingItem>> flipCutout(String id) async {
    final ItemPicture? cutout;
    final ClothingItem? existing;
    try {
      existing = await _load(id);
      if (existing == null) return Failure(NotFoundFailure('No item $id'));
      cutout = existing.images?.cutout;
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read item $id', cause: e));
    }
    if (cutout == null) {
      return const Failure(ValidationFailure('This item has no cut-out'));
    }
    // The raw copy (D-44) is flipped too, so analysis sees the same garment.
    final raw = existing.images?.cutoutRaw;
    final paths = [
      cutout.image,
      cutout.thumbnail,
      if (raw != null) ...[raw.image, raw.thumbnail],
    ];
    final pngs = <Uint8List>[];
    for (final path in paths) {
      final bytes = await _files.readBytes(path);
      if (bytes case Failure(:final failure)) return Failure(failure);
      pngs.add((bytes as Success<Uint8List>).value);
    }
    final List<Uint8List>? flipped;
    try {
      flipped = await Isolate.run(() => _flipPngs(pngs));
    } on Exception catch (e) {
      return Failure(
        UnsupportedImageFailure('Could not flip the cut-out', cause: e),
      );
    }
    if (flipped == null) {
      return const Failure(
        UnsupportedImageFailure('The cut-out could not be read'),
      );
    }
    final stem = '$imagesDir/cutouts/${_ids.newId()}';
    return _replacePicture(
      id,
      view: ItemView.cutout,
      files: [
        _NewFile('$stem.png', ImageKind.cutout, flipped[0]),
        _NewFile('${stem}_thumb.png', ImageKind.cutoutThumbnail, flipped[1]),
        if (flipped.length == 4) ...[
          _NewFile('${stem}_raw.png', ImageKind.cutoutRaw, flipped[2]),
          _NewFile(
            '${stem}_raw_thumb.png',
            ImageKind.cutoutRawThumbnail,
            flipped[3],
          ),
        ],
      ],
    );
  }

  @override
  Future<Result<ClothingItem>> saveProductPhoto(
    String id,
    String sourcePath,
  ) async {
    if (!await File(sourcePath).exists()) {
      return const Failure(StorageFailure('The selected image is unavailable'));
    }
    final large = await _images.downscaleToJpeg(
      sourcePath,
      maxEdge: workingMaxEdge,
      quality: 90,
    );
    final small = await _images.downscaleToJpeg(
      sourcePath,
      maxEdge: thumbnailMaxEdge,
      quality: 85,
    );
    if (large == null || large.isEmpty || small == null || small.isEmpty) {
      return const Failure(
        UnsupportedImageFailure('This image could not be opened'),
      );
    }
    final stem = '$imagesDir/products/${_ids.newId()}';
    return _replacePicture(
      id,
      view: ItemView.product,
      files: [
        _NewFile('$stem.jpg', ImageKind.product, large),
        _NewFile('${stem}_thumb.jpg', ImageKind.productThumbnail, small),
      ],
    );
  }

  @override
  Future<Result<ClothingItem>> removeProductPhoto(String id) async {
    final List<ClothingImageRow> previous;
    try {
      final existing = await _load(id);
      if (existing == null) return Failure(NotFoundFailure('No item $id'));
      previous = await _imageRows(id, _productKinds);
      final view = existing.images?.cutout == null
          ? ItemView.photo
          : ItemView.cutout;
      await _db.transaction(() async {
        await _deleteRows(previous);
        await _touch(id, toEpochMillisUtc(_clock.nowUtc()), view);
      });
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not update item $id', cause: e));
    }
    await _deleteFiles(previous.map((i) => i.relativePath));
    return _reload(id);
  }

  @override
  Future<Result<ClothingItem>> setView(String id, ItemView view) async {
    try {
      final existing = await _load(id);
      if (existing == null) return Failure(NotFoundFailure('No item $id'));
      if (!(existing.images?.has(view) ?? view == ItemView.photo)) {
        return const Failure(ValidationFailure('This item has no such image'));
      }
      await _touch(id, toEpochMillisUtc(_clock.nowUtc()), view);
      return await _reload(id);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not update item $id', cause: e));
    }
  }

  static const _cutoutKinds = {
    ImageKind.cutout,
    ImageKind.cutoutThumbnail,
    ImageKind.cutoutRaw,
    ImageKind.cutoutRawThumbnail,
  };
  static const _productKinds = {ImageKind.product, ImageKind.productThumbnail};

  /// Writes a new cut-out or product photo (fresh file names, so image
  /// caches never show a replaced file), swaps all rows of that picture in
  /// one transaction, shows it, then deletes the old files. On failure
  /// nothing changes.
  Future<Result<ClothingItem>> _replacePicture(
    String id, {
    required ItemView view,
    required List<_NewFile> files,
  }) async {
    final kinds = view == ItemView.cutout ? _cutoutKinds : _productKinds;
    final List<ClothingImageRow> previous;
    try {
      if (await _load(id) == null) return Failure(NotFoundFailure('No $id'));
      previous = await _imageRows(id, kinds);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read item $id', cause: e));
    }

    final written = <String>[];
    Future<Result<ClothingItem>> fail(AppFailure failure) async {
      await _deleteFiles(written);
      return Failure(failure);
    }

    for (final f in files) {
      final saved = await _files.writeBytes(f.path, f.bytes);
      if (saved case Failure(:final failure)) return fail(failure);
      written.add(f.path);
    }

    final now = toEpochMillisUtc(_clock.nowUtc());
    try {
      await _db.transaction(() async {
        await _deleteRows(previous);
        for (final f in files) {
          await _db
              .into(_db.clothingImages)
              .insert(
                ClothingImagesCompanion.insert(
                  id: _ids.newId(),
                  itemId: id,
                  kind: f.kind,
                  relativePath: f.path,
                  width: Value(f.width),
                  height: Value(f.height),
                  byteSize: Value(f.bytes.length),
                  createdAt: now,
                ),
              );
        }
        await _touch(id, now, view);
      });
    } on Exception catch (e) {
      return fail(StorageFailure('Could not save the image', cause: e));
    }
    await _deleteFiles(previous.map((i) => i.relativePath));
    return _reload(id);
  }

  Future<void> _deleteRows(List<ClothingImageRow> rows) => (_db.delete(
    _db.clothingImages,
  )..where((t) => t.id.isIn(rows.map((i) => i.id)))).go();

  @override
  Future<Result<ClothingItem>> copyPhotoToNewItem(String sourceId) async {
    final ClothingItemRow? source;
    final List<ClothingImageRow> photo;
    try {
      source =
          await (_db.select(_db.clothingItems)
                ..where((t) => t.id.equals(sourceId) & t.deletedAt.isNull()))
              .getSingleOrNull();
      photo = await _imageRows(sourceId, ImageKind.photo);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read item $sourceId', cause: e));
    }
    if (source == null || photo.isEmpty) {
      return Failure(NotFoundFailure('No photo for item $sourceId'));
    }

    final id = _ids.newId();
    final copies = <(ClothingImageRow, String)>[];
    Future<Result<ClothingItem>> fail(AppFailure failure) async {
      await _deleteFiles(copies.map((c) => c.$2));
      return Failure(failure);
    }

    for (final row in photo) {
      final dir = p.posix.dirname(row.relativePath);
      final ext = p.posix.extension(row.relativePath);
      final target = '$dir/$id$ext';
      final copied = await _files.copyIn(
        _files.resolve(row.relativePath),
        target,
      );
      if (copied case Failure(:final failure)) return fail(failure);
      copies.add((row, target));
    }

    final now = toEpochMillisUtc(_clock.nowUtc());
    try {
      await _db.transaction(() async {
        await _db
            .into(_db.clothingItems)
            .insert(
              ClothingItemsCompanion.insert(
                id: id,
                category: GarmentCategory.unknown.code,
                status: ItemStatus.draft.code,
                contentSha256: Value(source!.contentSha256),
                createdAt: now,
                updatedAt: now,
              ),
            );
        for (final (row, path) in copies) {
          await _db
              .into(_db.clothingImages)
              .insert(
                ClothingImagesCompanion.insert(
                  id: _ids.newId(),
                  itemId: id,
                  kind: row.kind,
                  relativePath: path,
                  width: Value(row.width),
                  height: Value(row.height),
                  byteSize: Value(row.byteSize),
                  createdAt: now,
                ),
              );
        }
      });
    } on Exception catch (e) {
      return fail(StorageFailure('Could not save the new item', cause: e));
    }
    return _reload(id);
  }

  Future<List<ClothingImageRow>> _imageRows(String id, Set<String> kinds) =>
      (_db.select(
        _db.clothingImages,
      )..where((t) => t.itemId.equals(id) & t.kind.isIn(kinds))).get();

  Future<void> _touch(String id, int now, ItemView view) =>
      (_db.update(_db.clothingItems)..where((t) => t.id.equals(id))).write(
        ClothingItemsCompanion(
          showCutout: Value(view == ItemView.cutout),
          showProduct: Value(view == ItemView.product),
          updatedAt: Value(now),
        ),
      );

  Future<Result<ClothingItem>> _reload(String id) async {
    final item = await _load(id);
    return item == null
        ? Failure(NotFoundFailure('No item $id'))
        : Success(item);
  }

  @override
  Future<Result<ClothingItem>> setStatus(String id, ItemStatus status) async {
    try {
      final existing = await _load(id);
      if (existing == null) return Failure(NotFoundFailure('No item $id'));
      final allowed = switch ((existing.status, status)) {
        (ItemStatus.active, ItemStatus.archived) => true,
        (ItemStatus.archived, ItemStatus.active) => true,
        (final from, final to) => from == to,
      };
      if (!allowed) {
        return Failure(
          ValidationFailure(
            'Cannot change ${existing.status.code} to ${status.code}',
          ),
        );
      }
      await (_db.update(
        _db.clothingItems,
      )..where((t) => t.id.equals(id))).write(
        ClothingItemsCompanion(
          status: Value(status.code),
          updatedAt: Value(toEpochMillisUtc(_clock.nowUtc())),
        ),
      );
      final saved = await _load(id);
      return saved == null
          ? Failure(NotFoundFailure('No item $id'))
          : Success(saved);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not update item $id', cause: e));
    }
  }

  // ---------------------------------------------------------------- deleting

  @override
  Future<Result<DeleteOutcome>> deleteItem(String id) async {
    try {
      final images = await (_db.select(
        _db.clothingImages,
      )..where((t) => t.itemId.equals(id))).get();
      final usage = _db.outfitItems.itemId.count();
      final usedInHistory =
          (await (_db.selectOnly(_db.outfitItems)
                    ..addColumns([usage])
                    ..where(_db.outfitItems.itemId.equals(id)))
                  .map((r) => r.read(usage))
                  .getSingle() ??
              0) >
          0;

      if (usedInHistory) {
        // Keep the row and thumbnails so outfit history still renders.
        final toRemove = [
          for (final i in images)
            if (!ImageKind.history.contains(i.kind)) i,
        ];
        await _db.transaction(() async {
          await (_db.update(
            _db.clothingItems,
          )..where((t) => t.id.equals(id))).write(
            ClothingItemsCompanion(
              status: Value(ItemStatus.archived.code),
              deletedAt: Value(toEpochMillisUtc(_clock.nowUtc())),
              // Allow the same photo to be imported again later.
              contentSha256: const Value(null),
            ),
          );
          await (_db.delete(
            _db.clothingImages,
          )..where((t) => t.id.isIn(toRemove.map((i) => i.id)))).go();
        });
        await _deleteFiles(toRemove.map((i) => i.relativePath));
        return const Success(DeleteOutcome.hiddenForHistory);
      }

      final deleted = await (_db.delete(
        _db.clothingItems,
      )..where((t) => t.id.equals(id))).go();
      if (deleted == 0) return Failure(NotFoundFailure('No item $id'));
      await _deleteFiles(images.map((i) => i.relativePath));
      return const Success(DeleteOutcome.removed);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not delete item $id', cause: e));
    }
  }

  /// File removal after the database commit. A failure leaves an orphan that
  /// [removeOrphanFiles] cleans up later, so it is logged, not surfaced.
  Future<void> _deleteFiles(Iterable<String> paths) async {
    for (final path in paths) {
      final result = await _files.delete(path);
      if (result case Failure(:final failure)) {
        AppLogger.error('Leaving orphan file $path', failure);
      }
    }
  }

  @override
  Future<Result<int>> removeOrphanFiles() async {
    final listed = await _files.list(imagesDir);
    final List<String> onDisk;
    switch (listed) {
      case Failure(:final failure):
        return Failure(failure);
      case Success(:final value):
        onDisk = value;
    }
    try {
      final referenced = (await _db.select(_db.clothingImages).get())
          .map((i) => i.relativePath)
          .toSet();
      var removed = 0;
      for (final path in onDisk) {
        if (referenced.contains(path)) continue;
        if ((await _files.delete(path)).isSuccess) removed++;
      }
      return Success(removed);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not clean up files', cause: e));
    }
  }
}

/// One image file of a picture, before it is written.
final class _NewFile {
  const _NewFile(this.path, this.kind, this.bytes, {this.width, this.height});

  final String path;

  /// [ImageKind] of its row.
  final String kind;
  final Uint8List bytes;
  final int? width;
  final int? height;
}

/// Mirrors PNGs left to right (runs on an isolate). `null` if one cannot
/// be decoded.
List<Uint8List>? _flipPngs(List<Uint8List> pngs) {
  final out = <Uint8List>[];
  for (final bytes in pngs) {
    final image = img.decodePng(bytes);
    if (image == null) return null;
    out.add(img.encodePng(img.flipHorizontal(image)));
  }
  return out;
}
