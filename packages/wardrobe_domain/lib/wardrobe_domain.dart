/// Pure-Dart domain layer for AI Stylist.
///
/// This library must never import Flutter, database or AI-runtime packages.
library;

export 'src/core/app_failure.dart';
export 'src/core/clock.dart';
export 'src/core/id_generator.dart';
export 'src/core/result.dart';
export 'src/core/set_equality.dart';
export 'src/profile/profile_use_cases.dart';
export 'src/profile/style_profile.dart';
export 'src/taxonomy/coded_enum.dart';
export 'src/taxonomy/taxonomy.dart';
export 'src/wardrobe/clothing_attributes.dart';
export 'src/wardrobe/clothing_item.dart';
export 'src/wardrobe/wardrobe_filter.dart';
export 'src/wardrobe/wardrobe_repository.dart';
export 'src/wardrobe/wardrobe_use_cases.dart';
