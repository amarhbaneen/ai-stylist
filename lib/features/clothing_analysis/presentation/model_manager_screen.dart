import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../ai/download/model_download_manager.dart';
import '../../../ai/model_registry.dart';
import '../../../shared/taxonomy_labels.dart';
import '../analysis_providers.dart';
import '../model_downloads.dart';

/// Optional on-device models (FR-09). Downloads only start when the user
/// taps Download; the app works fully without any of them.
class ModelManagerScreen extends ConsumerWidget {
  const ModelManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(modelRegistryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('On-device models')),
      body: switch (registry) {
        AsyncData(:final value) when value.downloadable.isEmpty => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No optional models are available in this version.\n\n'
              'Colour detection is built in and works offline. You can '
              'always set every detail by hand.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Models run only on this phone. Downloading one sends a normal '
              'web request to its host; your photos never leave the device.',
            ),
            for (final m in value.downloadable) _ModelTile(model: m),
          ],
        ),
        AsyncError() => const Center(
          child: Text('Model information could not be loaded.'),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

String _megabytes(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

class _ModelTile extends ConsumerWidget {
  const _ModelTile({required this.model});

  final ModelDescriptor model;

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final download = model.download!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download ${model.title ?? model.id}?'),
        content: Text(
          '${_megabytes(download.sizeBytes)} from ${download.url.host}. '
          'Use Wi-Fi if your data plan is limited. The file is checked '
          'before it is used.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final result = await ref.read(modelDownloadsProvider.notifier).start(model);
    if (result case Failure(:final failure)) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (failure) {
            CancelledFailure() => 'Download paused. You can resume it later.',
            NetworkFailure() =>
              'Download stopped (no connection). Resume when you are online.',
            ModelCorruptFailure() =>
              'The downloaded file failed its check and was deleted.',
            _ => failureMessage(failure),
          }),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(modelDownloadsProvider)[model.id];
    final installState = ref.watch(modelInstallStateProvider(model.id)).value;
    final downloads = ref.read(modelDownloadsProvider.notifier);
    final subtitle = [
      _megabytes(model.download!.sizeBytes),
      'v${model.version}',
      model.license,
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model.title ?? model.id,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(subtitle),
            const SizedBox(height: 12),
            if (progress != null) ...[
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => downloads.pause(model),
                child: Text('Pause (${(progress * 100).floor()}%)'),
              ),
            ] else
              switch (installState) {
                ModelInstallState.installed => Row(
                  children: [
                    const Icon(Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Installed')),
                    TextButton(
                      onPressed: () => downloads.remove(model),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
                ModelInstallState.partial => Row(
                  children: [
                    FilledButton.tonal(
                      onPressed: () => _download(context, ref),
                      child: const Text('Resume download'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => downloads.remove(model),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
                ModelInstallState.notInstalled => FilledButton.tonal(
                  onPressed: () => _download(context, ref),
                  child: const Text('Download'),
                ),
                null => const SizedBox.shrink(),
              },
          ],
        ),
      ),
    );
  }
}
