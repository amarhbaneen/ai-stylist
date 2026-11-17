import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_stylist/ai/garment/garment_classifier.dart';
import 'package:ai_stylist/ai/garment/garment_labels.dart';
import 'package:ai_stylist/ai/garment/garment_model_loader.dart';
import 'package:ai_stylist/ai/model_registry.dart';
import 'package:ai_stylist/features/clothing_analysis/presentation/apply_suggestions.dart';
import 'package:ai_stylist/features/wardrobe/presentation/clothing_attributes_form.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../support/fakes.dart';

const _labelsAsset = 'assets/models/garment-tier1.labels.json';
final _bundledLabels = GarmentLabels.tryParse(
  File(_labelsAsset).readAsStringSync(),
)!;
const _src = AnalysisSource(modelId: 'garment-tier1', modelVersion: '1.0.0');
final _at = DateTime.utc(2026, 11, 17);

/// Probabilities with [hot] label(s) set and the rest spread evenly.
Float32List _probs(List<String> names, Map<String, double> hot) {
  final rest =
      (1 - hot.values.fold<double>(0, (a, b) => a + b)) /
      (names.length - hot.length);
  return Float32List.fromList([for (final n in names) hot[n] ?? rest]);
}

List<String> get _typeNames => [for (final t in _bundledLabels.types) t.label];
List<String> get _patternNames => [
  for (final p in _bundledLabels.patterns) p.code,
];

GarmentScores _scores(Map<String, double> type, Map<String, double> pattern) =>
    (type: _probs(_typeNames, type), pattern: _probs(_patternNames, pattern));

final class _FakeSession implements GarmentModelSession {
  _FakeSession(this.respond);

  final Future<GarmentScores> Function(Float32List rgb) respond;
  final inputs = <Float32List>[];
  var closed = false;

  @override
  Future<GarmentScores> run(Float32List rgb) {
    inputs.add(rgb);
    return respond(rgb);
  }

  @override
  Future<void> close() async => closed = true;
}

void main() {
  group('GarmentLabels', () {
    test('the bundled table matches the app taxonomy and model outputs', () {
      expect(_bundledLabels.types, hasLength(23));
      expect(_bundledLabels.patterns, hasLength(8));
      final shirt = _bundledLabels.types.first;
      expect(shirt.label, 'shirt_blouse');
      expect(shirt.category, GarmentCategory.top);
      expect(shirt.subcategory, isNull);
      expect(
        _bundledLabels.subcategoryCodes,
        isNot(contains('pants')),
        reason: 'ambiguous classes suggest a category only',
      );
    });

    Map<String, Object?> table() =>
        jsonDecode(File(_labelsAsset).readAsStringSync())
            as Map<String, Object?>;

    String edit(void Function(Map<String, Object?> outputs) change) {
      final t = table();
      change(t['outputs']! as Map<String, Object?>);
      return jsonEncode(t);
    }

    test('rejects a table the app cannot trust', () {
      final bad = {
        'not JSON': '{',
        'other schema': jsonEncode({...table(), 'schemaVersion': 2}),
        'unknown pattern': edit((o) => (o['pattern']! as List).add('PAISLEY')),
        'duplicate label': edit((o) {
          final types = o['type']! as List;
          types.add(types.first);
        }),
        'type in another category': edit((o) {
          (o['type']! as List).add({
            'label': 'odd',
            'category': 'TOP',
            'subcategory': 'JEANS',
          });
        }),
        'unknown category': edit((o) {
          (o['type']! as List).add({'label': 'x', 'category': 'SOCKS'});
        }),
        'empty outputs': edit((o) => o['type'] = <Object>[]),
      };
      for (final MapEntry(:key, :value) in bad.entries) {
        expect(GarmentLabels.tryParse(value), isNull, reason: key);
      }
    });
  });

  group('bundled model', () {
    Future<Uint8List> fromDisk(String key) async {
      final file = File(key);
      if (!file.existsSync()) throw AssetMissingException(key);
      return file.readAsBytes();
    }

    test('is in the manifest and passes its SHA-256 check', () async {
      final registry = await ModelRegistry.fromManifest(fromDisk);
      final model = registry.forTask(garmentTask);
      expect(model, isNotNull);
      expect(model!.labelsAsset, _labelsAsset);
      expect(await registry.loadVerified(model), isA<Success<Uint8List>>());
      final labels = await registry.loadText(model.labelsAsset!);
      expect(
        GarmentLabels.tryParse((labels as Success<String>).value),
        isNotNull,
      );
    });

    test('a missing label table is a typed failure', () async {
      final registry = await ModelRegistry.fromManifest(
        (key) => key == _labelsAsset
            ? throw const AssetMissingException(_labelsAsset)
            : fromDisk(key),
      );
      final result = await openGarmentModel(registry);
      expect(result, isA<Failure<Object>>());
      expect((result as Failure).failure, isA<ModelUnavailableFailure>());
    });
  });

  group('toAnalysis', () {
    final classifier = GarmentClassifier(
      open: () async => throw UnimplementedError(),
      clock: FixedClock(),
    );
    ClothingAnalysis analyse(
      Map<String, double> type, [
      Map<String, double> pattern = const {'SOLID': 0.9},
    ]) => classifier.toAnalysis(
      _scores(type, pattern),
      _bundledLabels,
      _src,
      _at,
    );

    test('sums types into their category and keeps provenance', () {
      final a = analyse({'jacket': 0.5, 'coat': 0.35});
      expect(a.category!.value, GarmentCategory.outerwear);
      expect(a.category!.confidence, greaterThan(0.85));
      expect(a.category!.source, _src);
      expect(a.subcategory!.value, GarmentSubcategory.jacket);
      expect(a.subcategory!.confidence, closeTo(0.5, 0.001));
      expect(a.subcategory!.alternatives.first.$1, GarmentSubcategory.coat);
      expect(a.pattern!.value, GarmentPattern.solid);
      expect(a.primaryColor, isNull, reason: 'colour is Tier 0');
    });

    test('an ambiguous class suggests the category, not a type', () {
      final a = analyse({'pants': 0.9});
      expect(a.category!.value, GarmentCategory.bottom);
      expect(a.subcategory, isNull);
    });

    test('a type never contradicts the suggested category', () {
      // Tops win as a category, but the best single *type* is a skirt.
      final a = analyse({
        'shirt_blouse': 0.3,
        'top_tshirt_sweatshirt': 0.3,
        'skirt': 0.35,
      });
      expect(a.category!.value, GarmentCategory.top);
      expect(a.subcategory, isNull);
    });

    test('alternatives stay inside the category', () {
      final a = analyse({'dress': 0.6, 'jumpsuit': 0.2, 'skirt': 0.15});
      expect(a.subcategory!.value, GarmentSubcategory.dress);
      expect(
        a.subcategory!.alternatives.map((e) => e.$1),
        everyElement(
          predicate<GarmentSubcategory>(
            (s) => s.category == GarmentCategory.onePiece,
          ),
        ),
      );
    });

    test('uncertain pattern stays a low-confidence suggestion', () {
      final a = analyse({'dress': 0.9}, {'FLORAL': 0.3, 'OTHER': 0.3});
      expect(a.pattern!.confidence, lessThan(0.5));
      expect(a.pattern!.alternatives, isNotEmpty);
    });
  });

  group('analyze', () {
    late Directory tmp;
    late String photo;
    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('garment');
      photo = p.join(tmp.path, 'item.jpg');
      final image = img.Image(width: 320, height: 240);
      img.fill(image, color: img.ColorRgb8(200, 30, 40));
      await File(photo).writeAsBytes(img.encodeJpg(image));
    });
    tearDown(() => tmp.delete(recursive: true));

    AnalysisInput input([String? path]) =>
        AnalysisInput(itemId: 'i', imagePath: path ?? photo);

    GarmentClassifier make(_FakeSession session, {void Function()? onOpen}) =>
        GarmentClassifier(
          open: () async {
            onOpen?.call();
            return Success((session, _bundledLabels, _src));
          },
          clock: FixedClock(),
        );

    test('feeds a 224×224 RGB 0-255 image and returns suggestions', () async {
      final session = _FakeSession(
        (_) async => _scores({'dress': 0.92}, {'STRIPED': 0.8}),
      );
      var opens = 0;
      final classifier = make(session, onOpen: () => opens++);

      final first = await classifier.analyze(input());
      final second = await classifier.analyze(input());

      final a = (first as Success<ClothingAnalysis>).value;
      expect(a.category!.value, GarmentCategory.onePiece);
      expect(a.subcategory!.value, GarmentSubcategory.dress);
      expect(a.pattern!.value, GarmentPattern.striped);
      expect(second, isA<Success<ClothingAnalysis>>());
      expect(opens, 1, reason: 'the model is opened once and reused');

      final rgb = session.inputs.first;
      expect(rgb, hasLength(224 * 224 * 3));
      // A red photo stays red, in 0-255 (the model normalises internally).
      expect(rgb[0], greaterThan(150));
      expect(rgb[1], lessThan(80));
      await classifier.close();
      expect(session.closed, isTrue);
      expect(await classifier.analyze(input()), isA<Failure<Object>>());
    });

    test('every problem is a typed failure, never a throw', () async {
      final cases = <String, (GarmentClassifier, AnalysisInput, Type)>{
        'model missing': (
          GarmentClassifier(
            open: () async =>
                const Failure(ModelUnavailableFailure('not bundled')),
            clock: FixedClock(),
          ),
          input(),
          ModelUnavailableFailure,
        ),
        'unreadable photo': (
          make(_FakeSession((_) async => _scores({'dress': 1}, {}))),
          input(p.join(tmp.path, 'missing.jpg')),
          UnsupportedImageFailure,
        ),
        'runtime error': (
          make(_FakeSession((_) async => throw StateError('native'))),
          input(),
          InferenceFailure,
        ),
        'output does not match labels': (
          make(
            _FakeSession(
              (_) async => (type: Float32List(5), pattern: Float32List(8)),
            ),
          ),
          input(),
          ModelCorruptFailure,
        ),
      };
      for (final MapEntry(key: name, value: (c, i, type)) in cases.entries) {
        final result = await c.analyze(i);
        expect(result, isA<Failure<Object>>(), reason: name);
        expect((result as Failure).failure.runtimeType, type, reason: name);
      }
    });
  });

  group('applySuggestions for category, type and pattern (D-09)', () {
    const policy = ConfidencePolicy();
    Suggestion<T> s<T>(T v, double c) =>
        Suggestion(value: v, confidence: c, source: _src, analyzedAt: _at);

    test('prefills confident values that agree with each other', () {
      final d = AttributesDraft.from(ClothingAttributes());
      final applied = applySuggestions(
        d,
        ClothingAnalysis(
          category: s(GarmentCategory.outerwear, 0.9),
          subcategory: s(GarmentSubcategory.coat, 0.6),
          pattern: s(GarmentPattern.checked, 0.7),
        ),
        policy,
      );
      expect(d.category, GarmentCategory.outerwear);
      expect(d.subcategory, GarmentSubcategory.coat);
      expect(d.pattern, GarmentPattern.checked);
      expect(applied, {
        AnalyzedAttribute.category,
        AnalyzedAttribute.subcategory,
        AnalyzedAttribute.pattern,
      });
      d.dispose();
    });

    test('leaves hints, user choices and mismatched types alone', () {
      final chosen = AttributesDraft.from(
        ClothingAttributes(category: GarmentCategory.bottom),
      )..touched.add(AnalyzedAttribute.pattern);
      applySuggestions(
        chosen,
        ClothingAnalysis(
          category: s(GarmentCategory.outerwear, 0.95),
          subcategory: s(GarmentSubcategory.coat, 0.9),
          pattern: s(GarmentPattern.checked, 0.9),
        ),
        policy,
      );
      expect(chosen.category, GarmentCategory.bottom);
      expect(chosen.subcategory, isNull, reason: 'a coat is not a bottom');
      expect(chosen.pattern, GarmentPattern.unknown);
      chosen.dispose();

      final unsure = AttributesDraft.from(ClothingAttributes());
      applySuggestions(
        unsure,
        ClothingAnalysis(
          category: s(GarmentCategory.top, 0.4),
          pattern: s(GarmentPattern.floral, 0.3),
        ),
        policy,
      );
      expect(unsure.category, GarmentCategory.unknown);
      expect(unsure.pattern, GarmentPattern.unknown);
      unsure.dispose();
    });
  });
}
