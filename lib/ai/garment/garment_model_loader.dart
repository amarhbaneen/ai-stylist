import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../model_registry.dart';
import 'garment_classifier.dart';
import 'garment_labels.dart';
import 'litert_garment_session.dart';

/// Manifest task of the Tier-1 garment classifier.
const garmentTask = 'garment-type-pattern';

/// Finds the garment model in [registry], checks its SHA-256 and label
/// table, and starts a LiteRT session. Every problem is a typed failure.
Future<Result<(GarmentModelSession, GarmentLabels, AnalysisSource)>>
openGarmentModel(ModelRegistry registry) async {
  final model = registry.forTask(garmentTask);
  if (model == null) {
    return const Failure(ModelUnavailableFailure('No garment model bundled'));
  }
  final labelsKey = model.labelsAsset;
  if (labelsKey == null) {
    return Failure(ModelCorruptFailure('${model.id} has no label table'));
  }
  final GarmentLabels labels;
  switch (await registry.loadText(labelsKey)) {
    case Failure(:final failure):
      return Failure(failure);
    case Success(:final value):
      final parsed = GarmentLabels.tryParse(value);
      if (parsed == null) {
        return Failure(
          ModelCorruptFailure('${model.id} label table is invalid'),
        );
      }
      labels = parsed;
  }
  switch (await registry.loadVerified(model)) {
    case Failure(:final failure):
      return Failure(failure);
    case Success(value: final bytes):
      return switch (await LiteRtGarmentSession.open(bytes, labels)) {
        Success(value: final session) => Success((
          session,
          labels,
          model.source,
        )),
        Failure(:final failure) => Failure(failure),
      };
  }
}
