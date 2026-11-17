import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

/// One output channel of the segmentation model.
@immutable
final class SegmentationClass {
  const SegmentationClass({required this.label, this.category});

  /// Model label, for example `background` or `pants`.
  final String label;

  /// `null` only for the background channel.
  final GarmentCategory? category;
}

/// The label table shipped next to the segmentation model
/// (`seg_labels.json` from `training/`, schema version 1). Channel `i` of
/// the output names class `i`; channel 0 is the background.
///
/// Parsing is strict, as for the classifier: anything unexpected rejects
/// the whole table, so the model never runs with a table it does not match.
@immutable
final class SegmentationLabels {
  SegmentationLabels._({
    required this.inputSize,
    required this.minAreaShare,
    required List<SegmentationClass> classes,
  }) : classes = List.unmodifiable(classes);

  static const supportedSchema = 1;
  static const task = 'garment-segmentation';

  /// The model's square input size, in pixels.
  final int inputSize;

  /// A garment covering less of the photo than this is not offered (D-39).
  final double minAreaShare;

  final List<SegmentationClass> classes;

  static SegmentationLabels? tryParse(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?> ||
        json['schemaVersion'] != supportedSchema ||
        json['task'] != task) {
      return null;
    }
    final input = json['input'];
    final size = input is Map<String, Object?> ? input['size'] : null;
    final share = json['minAreaShare'];
    final raw = json['classes'];
    if (size is! int || size <= 0 || share is! num || raw is! List) {
      return null;
    }
    if (share <= 0 || share >= 1 || raw.length < 2) return null;

    final classes = <SegmentationClass>[];
    for (var i = 0; i < raw.length; i++) {
      final c = raw[i];
      if (c is! Map<String, Object?> || c['index'] != i) return null;
      final label = c['label'];
      if (label is! String || label.isEmpty) return null;
      if (i == 0) {
        if (label != 'background' || c['category'] != null) return null;
        classes.add(SegmentationClass(label: label));
        continue;
      }
      final code = c['category'];
      final category = code is String ? GarmentCategory.fromCode(code) : null;
      if (category == null || category == GarmentCategory.unknown) {
        return null;
      }
      classes.add(SegmentationClass(label: label, category: category));
    }
    if (classes.map((c) => c.label).toSet().length != classes.length) {
      return null;
    }
    return SegmentationLabels._(
      inputSize: size,
      minAreaShare: share.toDouble(),
      classes: classes,
    );
  }
}
