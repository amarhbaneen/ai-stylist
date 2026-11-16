import 'package:outfit_engine/outfit_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../stylist_providers.dart';

part 'stylist_controller.g.dart';

/// Latest generation on the Stylist tab. `null` until the user generates.
@riverpod
class StylistResults extends _$StylistResults {
  @override
  AsyncValue<GenerationOutcome>? build() => null;

  Future<void> generate(StylistQuery query) async {
    state = const AsyncLoading();
    final result = await ref.read(generateOutfitsProvider).call(query);
    if (!ref.mounted) return;
    state = switch (result) {
      Success(:final value) => AsyncData(value),
      Failure(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
