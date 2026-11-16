import 'package:drift/drift.dart';
import 'package:outfit_engine/outfit_engine.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../core/database/app_database.dart';
import '../../stylist/data/drift_outfit_repository.dart';

/// Feedback (append-only events), favourites and history over SQLite.
final class DriftFeedbackRepository implements FeedbackRepository {
  DriftFeedbackRepository({
    required AppDatabase database,
    required this._clock,
    required this._ids,
  }) : _db = database;

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  static const maxNoteLength = 300;

  /// History shown in the app; older rows stay stored for learning.
  static const historyLimit = 200;

  @override
  Future<Result<OutfitFeedback>> addFeedback({
    required String outfitId,
    required FeedbackKind kind,
    FeedbackReason? reason,
    String? note,
  }) async {
    final trimmed = note?.trim();
    final cleanNote = (trimmed == null || trimmed.isEmpty)
        ? null
        : trimmed.substring(0, trimmed.length.clamp(0, maxNoteLength));
    try {
      return await _db.transaction(() async {
        final exists = await _outfitExists(outfitId);
        if (!exists) {
          return Failure<OutfitFeedback>(
            NotFoundFailure('No outfit $outfitId'),
          );
        }
        // "Latest opinion wins" needs a strict order per outfit. Two taps in
        // the same millisecond (or a clock step backwards) would otherwise
        // tie, and ties fall back to random IDs. Keep timestamps increasing.
        final latest = _db.outfitFeedback.createdAt.max();
        final previous =
            await (_db.selectOnly(_db.outfitFeedback)
                  ..addColumns([latest])
                  ..where(_db.outfitFeedback.outfitId.equals(outfitId)))
                .map((r) => r.read(latest))
                .getSingle();
        var millis = toEpochMillisUtc(_clock.nowUtc());
        if (previous != null && millis <= previous) millis = previous + 1;

        final feedback = OutfitFeedback(
          id: _ids.newId(),
          outfitId: outfitId,
          kind: kind,
          reason: reason,
          note: cleanNote,
          createdAt: fromEpochMillisUtc(millis),
        );
        await _db
            .into(_db.outfitFeedback)
            .insert(
              OutfitFeedbackCompanion.insert(
                id: feedback.id,
                outfitId: outfitId,
                kind: kind.code,
                reasonCode: Value(reason?.code),
                reasonText: Value(cleanNote),
                createdAt: millis,
              ),
            );
        return Success(feedback);
      });
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not save feedback', cause: e));
    }
  }

  @override
  Future<Result<void>> setFavorite(
    String outfitId, {
    required bool favorite,
  }) async {
    try {
      final updated =
          await (_db.update(_db.outfits)..where((t) => t.id.equals(outfitId)))
              .write(OutfitsCompanion(isFavorite: Value(favorite)));
      return updated == 0
          ? Failure(NotFoundFailure('No outfit $outfitId'))
          : const Success(null);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not update favourite', cause: e));
    }
  }

  @override
  Stream<List<OutfitHistoryEntry>> watchHistory({bool favoritesOnly = false}) {
    // Re-run when outfits *or* feedback change, so ratings stay current.
    return _db
        .customSelect(
          'SELECT id FROM outfits '
          '${favoritesOnly ? 'WHERE is_favorite = 1 ' : ''}'
          'ORDER BY created_at DESC, id DESC LIMIT $historyLimit',
          readsFrom: {_db.outfits, _db.outfitFeedback},
        )
        .watch()
        .asyncMap(
          (rows) => _entries([for (final r in rows) r.read<String>('id')]),
        );
  }

  @override
  Stream<OutfitHistoryEntry?> watchEntry(String outfitId) => _db
      .customSelect(
        'SELECT id FROM outfits WHERE id = ?',
        variables: [Variable.withString(outfitId)],
        readsFrom: {_db.outfits, _db.outfitFeedback},
      )
      .watch()
      .asyncMap((rows) async {
        if (rows.isEmpty) return null;
        final entries = await _entries([outfitId]);
        return entries.isEmpty ? null : entries.single;
      });

  @override
  Future<Result<List<FeedbackEvent>>> feedbackSince(DateTime? since) async {
    try {
      final query = _db.select(_db.outfitFeedback)
        ..orderBy([
          (t) => OrderingTerm.asc(t.createdAt),
          (t) => OrderingTerm.asc(t.id),
        ]);
      if (since != null) {
        query.where(
          (t) => t.createdAt.isBiggerThanValue(toEpochMillisUtc(since)),
        );
      }
      final rows = await query.get();
      final items = await _itemsByOutfit({for (final r in rows) r.outfitId});
      return Success([
        for (final r in rows)
          FeedbackEvent(
            feedback: _feedbackFromRow(r),
            itemIds: items[r.outfitId] ?? const [],
          ),
      ]);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read feedback', cause: e));
    }
  }

  // ------------------------------------------------------------- helpers

  Future<bool> _outfitExists(String id) async =>
      await (_db.select(
        _db.outfits,
      )..where((t) => t.id.equals(id))).getSingleOrNull() !=
      null;

  Future<List<OutfitHistoryEntry>> _entries(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final outfits = await (_db.select(
      _db.outfits,
    )..where((t) => t.id.isIn(ids))).get();
    final pieces = await (_db.select(
      _db.outfitItems,
    )..where((t) => t.outfitId.isIn(ids))).get();
    final feedback =
        await (_db.select(_db.outfitFeedback)
              ..where((t) => t.outfitId.isIn(ids))
              ..orderBy([
                (t) => OrderingTerm.asc(t.createdAt),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    final latest = <String, OutfitFeedbackRow>{
      for (final f in feedback) f.outfitId: f, // last one wins
    };
    final byId = {for (final o in outfits) o.id: o};
    return [
      for (final id in ids)
        if (byId[id] case final row?)
          OutfitHistoryEntry(
            saved: DriftOutfitRepository.toDomain(row, [
              for (final p in pieces)
                if (p.outfitId == id) p,
            ]),
            latestFeedback: switch (latest[id]) {
              final f? => _feedbackFromRow(f),
              null => null,
            },
          ),
    ];
  }

  Future<Map<String, List<String>>> _itemsByOutfit(Set<String> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await (_db.select(
      _db.outfitItems,
    )..where((t) => t.outfitId.isIn(ids))).get();
    final map = <String, List<String>>{};
    for (final r in rows) {
      (map[r.outfitId] ??= []).add(r.itemId);
    }
    return map;
  }

  static OutfitFeedback _feedbackFromRow(OutfitFeedbackRow r) => OutfitFeedback(
    id: r.id,
    outfitId: r.outfitId,
    kind: FeedbackKind.fromCode(r.kind),
    reason: FeedbackReason.tryFromCode(r.reasonCode),
    note: r.reasonText,
    createdAt: fromEpochMillisUtc(r.createdAt),
  );
}
