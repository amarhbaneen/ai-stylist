import 'package:drift/drift.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../core/database/app_database.dart';

/// Suggestions with provenance in `clothing_attributes` (FR-04): one row
/// per suggested value, with confidence, model ID/version, analysis time and
/// whether the user kept it.
final class DriftAnalysisRepository implements AnalysisRepository {
  DriftAnalysisRepository({required AppDatabase database, required this._ids})
    : _db = database;

  final AppDatabase _db;
  final IdGenerator _ids;

  @override
  Future<Result<void>> save(String itemId, ClothingAnalysis analysis) async {
    final rows = <ClothingAttributesCompanion>[];
    void add<T extends CodedEnum>(AnalyzedAttribute attr, Suggestion<T> s) =>
        rows.add(
          ClothingAttributesCompanion.insert(
            id: _ids.newId(),
            itemId: itemId,
            attribute: attr.code,
            value: s.value.code,
            confidence: Value(s.confidence),
            modelId: Value(s.source.modelId),
            modelVersion: Value(s.source.modelVersion),
            analyzedAt: Value(toEpochMillisUtc(s.analyzedAt)),
          ),
        );

    if (analysis.primaryColor case final p?) {
      add(AnalyzedAttribute.primaryColor, p);
      for (final (alt, conf) in p.alternatives) {
        add(
          AnalyzedAttribute.primaryColorAlternative,
          Suggestion(
            value: alt,
            confidence: conf,
            source: p.source,
            analyzedAt: p.analyzedAt,
          ),
        );
      }
    }
    for (final s in analysis.secondaryColors) {
      add(AnalyzedAttribute.secondaryColor, s);
    }
    if (analysis.category case final s?) add(AnalyzedAttribute.category, s);
    if (analysis.subcategory case final s?) {
      add(AnalyzedAttribute.subcategory, s);
    }
    if (analysis.pattern case final s?) add(AnalyzedAttribute.pattern, s);

    try {
      await _db.transaction(() async {
        // Re-analysis replaces earlier suggestions for the item.
        await (_db.delete(
          _db.clothingAttributes,
        )..where((t) => t.itemId.equals(itemId))).go();
        await _db.batch((b) => b.insertAll(_db.clothingAttributes, rows));
      });
      return const Success(null);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not save suggestions', cause: e));
    }
  }

  @override
  Future<Result<ClothingAnalysis?>> load(String itemId) async {
    try {
      final rows = await (_db.select(
        _db.clothingAttributes,
      )..where((t) => t.itemId.equals(itemId))).get();
      if (rows.isEmpty) return const Success(null);
      return Success(_toDomain(rows));
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not read suggestions', cause: e));
    }
  }

  @override
  Future<Result<void>> markConfirmed(
    String itemId,
    Map<AnalyzedAttribute, Set<String>> keptCodes,
  ) async {
    try {
      final rows = await (_db.select(
        _db.clothingAttributes,
      )..where((t) => t.itemId.equals(itemId))).get();
      await _db.transaction(() async {
        for (final r in rows) {
          final attr = AnalyzedAttribute.tryFromCode(r.attribute);
          // Alternatives were offers, not proposals: never "confirmed".
          final kept =
              attr != null &&
              attr != AnalyzedAttribute.primaryColorAlternative &&
              (keptCodes[attr]?.contains(r.value) ?? false);
          if (kept != r.userConfirmed) {
            await (_db.update(_db.clothingAttributes)
                  ..where((t) => t.id.equals(r.id)))
                .write(ClothingAttributesCompanion(userConfirmed: Value(kept)));
          }
        }
      });
      return const Success(null);
    } on Exception catch (e) {
      return Failure(StorageFailure('Could not update suggestions', cause: e));
    }
  }

  static ClothingAnalysis _toDomain(List<ClothingAttributeRow> rows) {
    Suggestion<T>? suggestion<T>(ClothingAttributeRow r, T? value) {
      if (value == null) return null;
      return Suggestion(
        value: value,
        confidence: r.confidence ?? 0,
        source: AnalysisSource(
          modelId: r.modelId ?? 'unknown',
          modelVersion: r.modelVersion ?? 'unknown',
        ),
        analyzedAt: fromEpochMillisUtc(r.analyzedAt ?? 0),
      );
    }

    Iterable<ClothingAttributeRow> of(AnalyzedAttribute a) =>
        rows.where((r) => r.attribute == a.code);
    final sorted = rows.toList()
      ..sort((a, b) => (b.confidence ?? 0).compareTo(a.confidence ?? 0));

    Suggestion<ColorFamily>? primary;
    for (final r in of(AnalyzedAttribute.primaryColor)) {
      primary = suggestion(r, ColorFamily.tryFromCode(r.value));
    }
    if (primary != null) {
      primary = Suggestion(
        value: primary.value,
        confidence: primary.confidence,
        source: primary.source,
        analyzedAt: primary.analyzedAt,
        alternatives: [
          for (final r in sorted)
            if (r.attribute == AnalyzedAttribute.primaryColorAlternative.code)
              if (ColorFamily.tryFromCode(r.value) case final c?)
                (c, r.confidence ?? 0),
        ],
      );
    }
    return ClothingAnalysis(
      primaryColor: primary,
      secondaryColors: [
        for (final r in sorted)
          if (r.attribute == AnalyzedAttribute.secondaryColor.code)
            ?suggestion(r, ColorFamily.tryFromCode(r.value)),
      ],
      category: [
        for (final r in of(AnalyzedAttribute.category))
          ?suggestion(r, switch (GarmentCategory.fromCode(r.value)) {
            GarmentCategory.unknown => null,
            final c => c,
          }),
      ].firstOrNull,
      subcategory: [
        for (final r in of(AnalyzedAttribute.subcategory))
          ?suggestion(r, GarmentSubcategory.tryFromCode(r.value)),
      ].firstOrNull,
      pattern: [
        for (final r in of(AnalyzedAttribute.pattern))
          ?suggestion(r, switch (GarmentPattern.fromCode(r.value)) {
            GarmentPattern.unknown => null,
            final p => p,
          }),
      ].firstOrNull,
    );
  }
}
