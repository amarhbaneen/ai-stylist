import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../app/routes.dart';
import '../../../core/media/media_picker.dart';
import '../../../shared/taxonomy_labels.dart';
import '../wardrobe_providers.dart';

/// Camera/gallery choice → import → review form (REQUIREMENTS §6.2).
///
/// Permissions are requested by the platform only for the source the user
/// taps; nothing is requested in advance.
abstract final class AddClothingFlow {
  static Future<void> start(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<MediaSourceKind>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _SourceSheet(),
    );
    if (source == null || !context.mounted) return;

    final picked = await ref.read(mediaPickerProvider).pick(source);
    if (!context.mounted) return;
    switch (picked) {
      case Failure(failure: CancelledFailure()):
        return;
      case Failure(:final failure):
        _snack(context, failureMessage(failure));
      case Success(:final value):
        await importPath(context, ref, value);
    }
  }

  /// Imports [path] with a progress dialog, then opens the review form.
  static Future<void> importPath(
    BuildContext context,
    WidgetRef ref,
    String path,
  ) async {
    final importer = ref.read(importClothingPhotoProvider);
    final result = await showDialog<Result<ClothingItem>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ImportProgress(task: importer(path)),
    );
    if (result == null || !context.mounted) return;
    switch (result) {
      case Success(:final value):
        await context.push(AppRoutes.editItem(value.id, confirm: true));
      case Failure(failure: DuplicateItemFailure(:final existingItemId)):
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: const Text('This photo is already in your wardrobe.'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => context.push(AppRoutes.item(existingItemId)),
            ),
          ),
        );
      case Failure(:final failure):
        _snack(context, failureMessage(failure));
    }
  }

  /// Delivers a photo that Android returned after killing the app mid-pick.
  static Future<void> recoverLostPick(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final path = await ref.read(mediaPickerProvider).recoverLostPick();
    if (path != null && context.mounted) await importPath(context, ref, path);
  }

  static void _snack(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: const Text('Take a photo'),
          onTap: () => Navigator.pop(context, MediaSourceKind.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Choose from photos'),
          onTap: () => Navigator.pop(context, MediaSourceKind.gallery),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Text(
            'The photo is copied into the app and stays on this device.',
          ),
        ),
      ],
    ),
  );
}

/// Modal progress while an import runs; pops with the result.
class _ImportProgress extends StatefulWidget {
  const _ImportProgress({required this.task});

  final Future<Result<ClothingItem>> task;

  @override
  State<_ImportProgress> createState() => _ImportProgressState();
}

class _ImportProgressState extends State<_ImportProgress> {
  @override
  void initState() {
    super.initState();
    widget.task.then((result) {
      if (mounted) Navigator.pop(context, result);
    });
  }

  @override
  Widget build(BuildContext context) => const PopScope(
    canPop: false,
    child: AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 24),
          Expanded(child: Text('Adding photo…')),
        ],
      ),
    ),
  );
}
