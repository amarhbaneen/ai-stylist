import 'package:meta/meta.dart';

import '../core/result.dart';
import '../taxonomy/coded_enum.dart';
import '../taxonomy/taxonomy.dart';
import '../wardrobe/clothing_attributes.dart';

/// Attributes the analysis can suggest. Codes are stored in
/// `clothing_attributes.attribute`.
enum AnalyzedAttribute implements CodedEnum {
  primaryColor('PRIMARY_COLOR'),

  /// Alternative values for the main colour (shown as hint chips).
  primaryColorAlternative('PRIMARY_COLOR_ALT'),
  secondaryColor('SECONDARY_COLOR'),
  category('CATEGORY'),
  subcategory('SUBCATEGORY'),
  pattern('PATTERN');

  const AnalyzedAttribute(this.code);

  @override
  final String code;

  static AnalyzedAttribute? tryFromCode(String? code) {
    for (final a in values) {
      if (a.code == code) return a;
    }
    return null;
  }
}

/// Which model (or deterministic algorithm) produced a suggestion (FR-04).
@immutable
final class AnalysisSource {
  const AnalysisSource({required this.modelId, required this.modelVersion});

  final String modelId;
  final String modelVersion;

  @override
  bool operator ==(Object other) =>
      other is AnalysisSource &&
      other.modelId == modelId &&
      other.modelVersion == modelVersion;

  @override
  int get hashCode => Object.hash(modelId, modelVersion);

  @override
  String toString() => '$modelId@$modelVersion';
}

/// A suggested value with its confidence and provenance. Suggestions are
/// never applied silently: the user confirms or edits them (CLAUDE.md #8).
@immutable
final class Suggestion<T> {
  Suggestion({
    required this.value,
    required double confidence,
    required this.source,
    required this.analyzedAt,
    List<(T, double)> alternatives = const [],
  }) : confidence = confidence.clamp(0.0, 1.0),
       alternatives = List.unmodifiable(alternatives);

  final T value;

  /// 0–1. See [ConfidencePolicy] for how it is used.
  final double confidence;
  final AnalysisSource source;

  /// UTC.
  final DateTime analyzedAt;

  /// Other plausible values, most likely first (for hint chips).
  final List<(T, double)> alternatives;
}

/// Everything one analysis suggested for a garment. Any field may be absent:
/// an analyzer only fills what it can (Tier 0 fills colours only).
@immutable
final class ClothingAnalysis {
  ClothingAnalysis({
    this.primaryColor,
    List<Suggestion<ColorFamily>> secondaryColors = const [],
    this.category,
    this.subcategory,
    this.pattern,
  }) : secondaryColors = List.unmodifiable(secondaryColors);

  static final empty = ClothingAnalysis();

  final Suggestion<ColorFamily>? primaryColor;
  final List<Suggestion<ColorFamily>> secondaryColors;
  final Suggestion<GarmentCategory>? category;
  final Suggestion<GarmentSubcategory>? subcategory;
  final Suggestion<GarmentPattern>? pattern;

  bool get isEmpty =>
      primaryColor == null &&
      secondaryColors.isEmpty &&
      category == null &&
      subcategory == null &&
      pattern == null;

  /// Combines two analyses; values already present in `this` win.
  ClothingAnalysis mergedWith(ClothingAnalysis other) => ClothingAnalysis(
    primaryColor: primaryColor ?? other.primaryColor,
    secondaryColors: secondaryColors.isNotEmpty
        ? secondaryColors
        : other.secondaryColors,
    category: category ?? other.category,
    subcategory: subcategory ?? other.subcategory,
    pattern: pattern ?? other.pattern,
  );
}

/// How a suggestion is presented, by confidence (DECISIONS D-09).
enum SuggestionLevel {
  /// Prefilled; the user can change it.
  prefill,

  /// Prefilled but marked "please confirm".
  confirm,

  /// Not prefilled; offered as tappable hints.
  hint,
}

/// Confidence thresholds. Configurable so they can be calibrated against a
/// golden set without code changes elsewhere.
@immutable
final class ConfidencePolicy {
  const ConfidencePolicy({this.prefillAt = 0.80, this.confirmAt = 0.50})
    : assert(confirmAt <= prefillAt, 'confirmAt must not exceed prefillAt');

  final double prefillAt;
  final double confirmAt;

  SuggestionLevel levelOf(double confidence) {
    if (confidence >= prefillAt) return SuggestionLevel.prefill;
    if (confidence >= confirmAt) return SuggestionLevel.confirm;
    return SuggestionLevel.hint;
  }
}

/// Input to an analyzer: the stored item and a local, app-private image.
@immutable
final class AnalysisInput {
  const AnalysisInput({required this.itemId, required this.imagePath});

  final String itemId;

  /// Absolute path of an app-private image (the thumbnail is enough).
  final String imagePath;
}

/// On-device analysis behind a replaceable interface (REQUIREMENTS §12).
/// Implementations never upload anything and never throw: failures are
/// returned as typed results so manual entry always remains possible.
abstract interface class ClothingAnalyzer {
  Future<Result<ClothingAnalysis>> analyze(AnalysisInput input);
}

/// Stores suggestions with provenance in `clothing_attributes` (FR-04).
abstract interface class AnalysisRepository {
  Future<Result<void>> save(String itemId, ClothingAnalysis analysis);

  /// `null` when the item has never been analysed.
  Future<Result<ClothingAnalysis?>> load(String itemId);

  /// Marks each stored suggestion as confirmed when the saved attributes
  /// kept its value, and unconfirmed otherwise.
  Future<Result<void>> markConfirmed(
    String itemId,
    Map<AnalyzedAttribute, Set<String>> keptCodes,
  );
}

/// Analyses a photo once and caches the result; reopening a draft shows the
/// same suggestions instead of re-running the model.
final class AnalyzeClothingItem {
  const AnalyzeClothingItem(this._analyzer, this._repository);

  final ClothingAnalyzer _analyzer;
  final AnalysisRepository _repository;

  Future<Result<ClothingAnalysis>> call(AnalysisInput input) async {
    final cached = await _repository.load(input.itemId);
    if (cached case Success(value: final ClothingAnalysis existing)) {
      return Success(existing);
    }
    final result = await _analyzer.analyze(input);
    if (result case Success(:final value) when !value.isEmpty) {
      // A storage failure only loses the cache, not the suggestions.
      await _repository.save(input.itemId, value);
    }
    return result;
  }
}

/// Records which suggestions the user kept when saving (provenance).
final class ConfirmAnalysis {
  const ConfirmAnalysis(this._repository);

  final AnalysisRepository _repository;

  Future<Result<void>> call(String itemId, ClothingAttributes saved) =>
      _repository.markConfirmed(itemId, {
        AnalyzedAttribute.primaryColor: {?saved.primaryColor?.code},
        AnalyzedAttribute.secondaryColor: {
          for (final c in saved.secondaryColors) c.code,
        },
        AnalyzedAttribute.category: {saved.category.code},
        AnalyzedAttribute.subcategory: {?saved.subcategory?.code},
        AnalyzedAttribute.pattern: {saved.pattern.code},
      });
}
