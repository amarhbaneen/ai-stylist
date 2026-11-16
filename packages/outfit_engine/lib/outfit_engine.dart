/// Pure-Dart outfit recommendation engine for AI Stylist.
///
/// Must never import Flutter, database or AI-runtime packages.
library;

export 'src/constraints.dart';
export 'src/engine.dart';
export 'src/feedback.dart';
export 'src/feedback_use_cases.dart';
export 'src/generate_outfits.dart';
export 'src/history.dart';
export 'src/learner.dart';
export 'src/outfit.dart';
export 'src/request.dart';
export 'src/score_weights.dart';
export 'src/scoring/color_harmony.dart' show colorScore, pairHarmony;
export 'src/templates.dart';
