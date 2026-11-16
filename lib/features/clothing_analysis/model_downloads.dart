import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../ai/download/model_download_manager.dart';
import '../../ai/model_registry.dart';
import 'analysis_providers.dart';

part 'model_downloads.g.dart';

/// Install state of one optional model, by ID.
@riverpod
Future<ModelInstallState> modelInstallState(Ref ref, String modelId) async {
  final registry = await ref.watch(modelRegistryProvider.future);
  final model = registry.downloadable.where((m) => m.id == modelId).first;
  return ref.watch(modelDownloadManagerProvider).stateOf(model);
}

/// Running downloads (model ID → progress 0..1). Kept alive so a download
/// continues if the user leaves the model screen.
@Riverpod(keepAlive: true)
class ModelDownloads extends _$ModelDownloads {
  final _tokens = <String, DownloadCancelToken>{};

  @override
  Map<String, double> build() => const {};

  Future<Result<void>> start(ModelDescriptor m) async {
    if (_tokens.containsKey(m.id)) return const Success(null);
    final token = _tokens[m.id] = DownloadCancelToken();
    state = {...state, m.id: 0};
    final result = await ref
        .read(modelDownloadManagerProvider)
        .install(
          m,
          cancel: token,
          onProgress: (received, total) {
            final p = received / total;
            // Throttle rebuilds to whole percents.
            if (ref.mounted &&
                (p * 100).floor() > ((state[m.id] ?? 0) * 100).floor()) {
              state = {...state, m.id: p};
            }
          },
        );
    _tokens.remove(m.id);
    if (ref.mounted) {
      state = {...state}..remove(m.id);
      ref.invalidate(modelInstallStateProvider(m.id));
    }
    return result;
  }

  /// Stops the download; the partial file is kept for resuming.
  void pause(ModelDescriptor m) => _tokens[m.id]?.cancel();

  Future<Result<void>> remove(ModelDescriptor m) async {
    pause(m);
    final result = await ref.read(modelDownloadManagerProvider).remove(m);
    ref.invalidate(modelInstallStateProvider(m.id));
    return result;
  }
}
