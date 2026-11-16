import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:outfit_engine/outfit_engine.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../core/database/app_database.dart';

/// Stores generated outfits in `outfits` / `outfit_items` (schema v1).
///
/// `breakdown_json` holds `{template, scores, weights}`; `reasons_json` holds
/// reason codes. Item references use RESTRICT, so a garment that appears in
/// history is hidden rather than deleted (DECISIONS D-19).
final class DriftOutfitRepository implements OutfitRepository {
  DriftOutfitRepository({
    required AppDatabase database,
    required this._clock,
    required this._ids,
  }) : _db = database;

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  /// Upper bound on history rows considered for variety.
  static const historyLimit = 60;

  @override
  Future<Result<List<SavedOutfit>>> saveGenerated(
    OutfitRequest request,
    List<Outfit> outfits,
  ) async {
    final now = _clock.nowUtc();
    final saved = <SavedOutfit>[];
    try {
      await _db.transaction(() async {
        for (final outfit in outfits) {
          final id = _ids.newId();
          await _db
              .into(_db.outfits)
              .insert(
                OutfitsCompanion.insert(
                  id: id,
                  signature: outfit.signature,
                  occasion: request.occasion.code,
                  requestJson: jsonEncode(request.toJson()),
                  totalScore: outfit.totalScore,
                  breakdownJson: jsonEncode({
                    'template': outfit.templateId,
                    'scores': {
                      for (final e in outfit.breakdown.entries)
                        e.key.name: e.value,
                    },
                    'weights': {
                      for (final e in outfit.weights.entries)
                        e.key.name: e.value,
                    },
                  }),
                  reasonsJson: jsonEncode([
                    for (final r in outfit.reasons) r.code,
                  ]),
                  weatherConsidered: outfit.weatherConsidered,
                  createdAt: toEpochMillisUtc(now),
                ),
              );
          await _db.batch(
            (b) => b.insertAll(_db.outfitItems, [
              for (final p in outfit.pieces)
                OutfitItemsCompanion.insert(
                  outfitId: id,
                  itemId: p.itemId,
                  slot: p.slot.code,
                ),
            ]),
          );
          saved.add(
            SavedOutfit(
              id: id,
              occasion: request.occasion,
              outfit: outfit,
              createdAt: now,
            ),
          );
        }
      });
      return Success(saved);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not save outfits', cause: e));
    }
  }

  @override
  Future<Result<RecentHistory>> recentHistory({required DateTime since}) async {
    try {
      final rows =
          await (_db.select(_db.outfits)
                ..where(
                  (t) =>
                      t.createdAt.isBiggerOrEqualValue(toEpochMillisUtc(since)),
                )
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
                ..limit(historyLimit))
              .get();
      if (rows.isEmpty) return Success(RecentHistory.empty);
      final pieces = await (_db.select(
        _db.outfitItems,
      )..where((t) => t.outfitId.isIn(rows.map((r) => r.id)))).get();
      final use = <String, int>{};
      for (final p in pieces) {
        use[p.itemId] = (use[p.itemId] ?? 0) + 1;
      }
      return Success(
        RecentHistory(
          signatures: {for (final r in rows) r.signature},
          itemUse: use,
        ),
      );
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read outfit history', cause: e));
    }
  }

  @override
  Stream<SavedOutfit?> watchOutfit(String id) {
    final query = _db.select(_db.outfits)..where((t) => t.id.equals(id));
    return query.watchSingleOrNull().asyncMap((row) async {
      if (row == null) return null;
      final pieces = await (_db.select(
        _db.outfitItems,
      )..where((t) => t.outfitId.equals(id))).get();
      return _toDomain(row, pieces);
    });
  }

  static SavedOutfit _toDomain(OutfitRow row, List<OutfitItemRow> rows) {
    final breakdown = _decodeMap(row.breakdownJson);
    Map<ScoreComponent, double> components(Object? json) => {
      if (json is Map)
        for (final c in ScoreComponent.values)
          if (json[c.name] case final num v) c: v.toDouble(),
    };
    final pieces = [
      for (final r in rows)
        if (Slot.tryFromCode(r.slot) case final slot?)
          OutfitPiece(slot, r.itemId),
    ]..sort((a, b) => a.slot.index.compareTo(b.slot.index));
    final reasonCodes = jsonDecode(row.reasonsJson);
    return SavedOutfit(
      id: row.id,
      occasion: Occasion.fromCode(row.occasion),
      createdAt: fromEpochMillisUtc(row.createdAt),
      isFavorite: row.isFavorite,
      outfit: Outfit(
        templateId: breakdown['template'] as String? ?? '',
        pieces: pieces,
        totalScore: row.totalScore,
        breakdown: components(breakdown['scores']),
        weights: components(breakdown['weights']),
        reasons: [
          if (reasonCodes is List)
            for (final c in reasonCodes.whereType<String>())
              ?ReasonCode.tryFromCode(c),
        ],
        weatherConsidered: row.weatherConsidered,
      ),
    );
  }

  static Map<String, Object?> _decodeMap(String json) {
    try {
      final decoded = jsonDecode(json);
      return decoded is Map<String, Object?> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}
