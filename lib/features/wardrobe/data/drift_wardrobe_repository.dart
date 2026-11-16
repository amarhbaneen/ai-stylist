import 'dart:io';

import 'package:drift/drift.dart';
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
/// `images/thumbs/<id>.jpg`.
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
        // Keep the row and thumbnail so outfit history still renders.
        final toRemove = [
          for (final i in images)
            if (i.kind != ImageKind.thumbnail) i,
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
