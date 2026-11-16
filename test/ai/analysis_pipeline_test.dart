import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_stylist/ai/color/color_tier0_analyzer.dart';
import 'package:ai_stylist/ai/composite_analyzer.dart';
import 'package:ai_stylist/ai/model_registry.dart';
import 'package:ai_stylist/features/clothing_analysis/presentation/apply_suggestions.dart';
import 'package:ai_stylist/features/wardrobe/presentation/clothing_attributes_form.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../support/fakes.dart';

typedef Rgb = (int, int, int);

/// Writes a synthetic "product photo": a garment shape on a plain backdrop.
Future<String> _photo(
  Directory dir,
  String name,
  Rgb Function(int x, int y) garment, {
  Rgb backdrop = (236, 236, 231),
}) async {
  final image = img.Image(width: 320, height: 400);
  img.fill(image, color: img.ColorRgb8(backdrop.$1, backdrop.$2, backdrop.$3));
  for (var y = 60; y < 360; y++) {
    for (var x = 80; x < 240; x++) {
      final (r, g, b) = garment(x - 80, y - 60);
      image.setPixelRgb(x, y, r, g, b);
    }
  }
  final path = p.join(dir.path, '$name.jpg');
  await File(path).writeAsBytes(img.encodeJpg(image, quality: 90));
  return path;
}

final class _ScriptedAnalyzer implements ClothingAnalyzer {
  _ScriptedAnalyzer(this.respond);

  final Future<Result<ClothingAnalysis>> Function() respond;

  @override
  Future<Result<ClothingAnalysis>> analyze(AnalysisInput input) => respond();
}

const _src = AnalysisSource(modelId: 'm', modelVersion: '1');
final _at = DateTime.utc(2026, 11, 16);
Suggestion<ColorFamily> _s(ColorFamily c, double conf) =>
    Suggestion(value: c, confidence: conf, source: _src, analyzedAt: _at);

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('analysis'));
  tearDown(() => tmp.delete(recursive: true));

  group('golden set: Tier-0 colour analysis on synthetic photos', () {
    final analyzer = ColorTier0Analyzer(clock: FixedClock());
    const policy = ConfidencePolicy();

    // name, garment painter, expected primary, expect confident (prefill)
    final cases = <(String, Rgb Function(int, int), ColorFamily, bool)>[
      ('navy_tee', (_, _) => (31, 42, 74), ColorFamily.navy, true),
      ('red_dress', (_, _) => (200, 30, 40), ColorFamily.red, true),
      ('green_shirt', (_, _) => (46, 139, 87), ColorFamily.green, true),
      ('beige_chinos', (_, _) => (210, 190, 150), ColorFamily.beige, true),
      ('black_coat', (_, _) => (20, 20, 22), ColorFamily.black, true),
    ];
    Rgb stripes(int _, int y) => y % 30 < 18 ? (25, 25, 28) : (250, 250, 250);

    for (final (name, paint, expected, confident) in cases) {
      test(name, () async {
        final path = await _photo(tmp, name, paint);
        final result = await analyzer.analyze(
          AnalysisInput(itemId: name, imagePath: path),
        );
        final primary = result.valueOrNull!.primaryColor!;
        expect(primary.value, expected);
        expect(primary.source, ColorTier0Analyzer.source);
        expect(
          policy.levelOf(primary.confidence) == SuggestionLevel.prefill,
          confident,
          reason: 'confidence ${primary.confidence}',
        );
      });
    }

    test('black-and-white stripes on a grey backdrop: both colours, '
        'and not confident enough to prefill', () async {
      final path = await _photo(
        tmp,
        'stripes',
        stripes,
        backdrop: (128, 128, 128),
      );
      final a = (await analyzer.analyze(
        AnalysisInput(itemId: 's', imagePath: path),
      )).valueOrNull!;
      expect(a.primaryColor!.value, ColorFamily.black);
      expect(
        policy.levelOf(a.primaryColor!.confidence),
        isNot(SuggestionLevel.prefill),
      );
      expect(
        a.secondaryColors.map((s) => s.value),
        contains(ColorFamily.white),
      );
      expect(a.category, isNull, reason: 'Tier 0 never guesses categories');
    });

    test('KNOWN LIMITATION: white parts on a white backdrop are treated as '
        'background (needs segmentation, FR-05)', () async {
      final path = await _photo(tmp, 'stripes_on_white', stripes);
      final a = (await analyzer.analyze(
        AnalysisInput(itemId: 's', imagePath: path),
      )).valueOrNull!;
      // Documents current behaviour so a future fix is noticed: the white
      // stripes merge with the backdrop, leaving only black.
      expect(a.primaryColor!.value, ColorFamily.black);
      expect(a.secondaryColors, isEmpty);
    });

    test('an unreadable file is a typed failure', () async {
      final path = p.join(tmp.path, 'bad.jpg');
      await File(path).writeAsBytes([1, 2, 3]);
      final r = await analyzer.analyze(
        AnalysisInput(itemId: 'x', imagePath: path),
      );
      expect((r as Failure).failure, isA<UnsupportedImageFailure>());
    });
  });

  group('CompositeClothingAnalyzer', () {
    const input = AnalysisInput(itemId: 'i', imagePath: '/none');

    test('one failing analyzer does not block the others', () async {
      final composite = CompositeClothingAnalyzer([
        _ScriptedAnalyzer(() async => const Failure(InferenceFailure('boom'))),
        _ScriptedAnalyzer(
          () async => Success(
            ClothingAnalysis(primaryColor: _s(ColorFamily.navy, 0.9)),
          ),
        ),
      ]);
      final r = await composite.analyze(input);
      expect(r.valueOrNull!.primaryColor!.value, ColorFamily.navy);
    });

    test('a hanging analyzer times out and reports failure', () async {
      final composite = CompositeClothingAnalyzer([
        _ScriptedAnalyzer(() async {
          await Future<void>.delayed(const Duration(seconds: 5));
          return Success(ClothingAnalysis.empty);
        }),
      ], timeout: const Duration(milliseconds: 50));
      final r = await composite.analyze(input);
      expect((r as Failure).failure, isA<InferenceFailure>());
    });

    test('no analyzers means AI is unavailable', () async {
      final r = await CompositeClothingAnalyzer(const []).analyze(input);
      expect((r as Failure).failure, isA<ModelUnavailableFailure>());
    });
  });

  group('ModelRegistry', () {
    final modelBytes = Uint8List.fromList(List.generate(64, (i) => i));
    final goodSha = sha256.convert(modelBytes).toString();

    AssetLoader loader(Map<String, List<int>> assets) => (key) async {
      final bytes = assets[key];
      if (bytes == null) throw AssetMissingException(key);
      return Uint8List.fromList(bytes);
    };

    List<int> manifest(List<Object?> models, {int schema = 1}) =>
        utf8.encode(jsonEncode({'schemaVersion': schema, 'models': models}));

    Map<String, Object?> entry({String? sha, String asset = 'm.tflite'}) => {
      'id': 'garment',
      'version': '1.0.0',
      'task': 'garment-category',
      'asset': asset,
      'sha256': sha ?? goodSha,
      'license': 'Apache-2.0',
      'labels': {'tshirt': 'TOP'},
    };

    test('the bundled manifest format with no models', () async {
      final r = await ModelRegistry.fromManifest(
        loader({ModelRegistry.manifestAsset: manifest([])}),
      );
      expect(r.models, isEmpty);
      expect(r.forTask('garment-category'), isNull);
    });

    test('loads a model only when its SHA-256 matches', () async {
      final r = await ModelRegistry.fromManifest(
        loader({
          ModelRegistry.manifestAsset: manifest([entry()]),
          'm.tflite': modelBytes,
        }),
      );
      final model = r.forTask('garment-category')!;
      expect(model.labels, {'tshirt': 'TOP'});
      expect(model.source.modelId, 'garment');
      expect((await r.loadVerified(model)).valueOrNull, modelBytes);
    });

    test('a tampered or corrupt file is rejected', () async {
      final r = await ModelRegistry.fromManifest(
        loader({
          ModelRegistry.manifestAsset: manifest([entry()]),
          'm.tflite': [...modelBytes]..[0] = 255,
        }),
      );
      final result = await r.loadVerified(r.models.single);
      expect((result as Failure).failure, isA<ModelCorruptFailure>());
    });

    test('a missing model file is "unavailable", not a crash', () async {
      final r = await ModelRegistry.fromManifest(
        loader({
          ModelRegistry.manifestAsset: manifest([entry()]),
        }),
      );
      final result = await r.loadVerified(r.models.single);
      expect((result as Failure).failure, isA<ModelUnavailableFailure>());
    });

    test('malformed manifests and entries are ignored safely', () async {
      expect(
        (await ModelRegistry.fromManifest(loader({}))).models,
        isEmpty,
        reason: 'no manifest',
      );
      expect(
        (await ModelRegistry.fromManifest(
          loader({ModelRegistry.manifestAsset: utf8.encode('{not json')}),
        )).models,
        isEmpty,
      );
      expect(
        (await ModelRegistry.fromManifest(
          loader({
            ModelRegistry.manifestAsset: manifest([entry()], schema: 2),
          }),
        )).models,
        isEmpty,
        reason: 'unsupported schema version',
      );
      final mixed = await ModelRegistry.fromManifest(
        loader({
          ModelRegistry.manifestAsset: manifest([
            entry(sha: 'not-a-hash'),
            {'id': 'incomplete'},
            entry(),
          ]),
        }),
      );
      expect(mixed.models, hasLength(1));
    });
  });

  group('applySuggestions (D-09)', () {
    const policy = ConfidencePolicy();

    AttributesDraft draft({ColorFamily? primary}) =>
        AttributesDraft.from(ClothingAttributes(primaryColor: primary));

    test('prefills confident and "please confirm" suggestions', () {
      for (final conf in [0.95, 0.6]) {
        final d = draft();
        final applied = applySuggestions(
          d,
          ClothingAnalysis(primaryColor: _s(ColorFamily.navy, conf)),
          policy,
        );
        expect(d.primaryColor, ColorFamily.navy, reason: '$conf');
        expect(applied, {AnalyzedAttribute.primaryColor});
        d.dispose();
      }
    });

    test('never prefills a low-confidence hint', () {
      final d = draft();
      applySuggestions(
        d,
        ClothingAnalysis(primaryColor: _s(ColorFamily.navy, 0.3)),
        policy,
      );
      expect(d.primaryColor, isNull);
      d.dispose();
    });

    test('never overwrites the user\'s choice', () {
      final touched = draft()..touched.add(AnalyzedAttribute.primaryColor);
      final chosen = draft(primary: ColorFamily.red);
      for (final d in [touched, chosen]) {
        final before = d.primaryColor;
        applySuggestions(
          d,
          ClothingAnalysis(primaryColor: _s(ColorFamily.navy, 0.99)),
          policy,
        );
        expect(d.primaryColor, before);
        d.dispose();
      }
    });

    test('secondary colours are offered, never prefilled', () {
      final d = draft();
      applySuggestions(
        d,
        ClothingAnalysis(
          primaryColor: _s(ColorFamily.navy, 0.9),
          secondaryColors: [_s(ColorFamily.white, 0.3)],
        ),
        policy,
      );
      expect(d.secondaryColors, isEmpty);
      d.dispose();
    });
  });
}
