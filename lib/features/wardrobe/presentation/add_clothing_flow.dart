import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../ai/segmentation/garment_segmenter.dart';
import '../../../app/routes.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/media/media_picker.dart';
import '../../../core/providers.dart';
import '../../../shared/taxonomy_labels.dart';
import '../../clothing_analysis/analysis_providers.dart';
import '../wardrobe_providers.dart';
import 'pick_garments_screen.dart';

/// An imported photo and the garments found in it (empty when background
/// removal is unavailable or found nothing).
typedef _Imported = (Result<ClothingItem>, List<FoundGarment>);

/// Camera/gallery choice → import → background removal → review form
/// (REQUIREMENTS §6.2, FR-05).
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

  /// Imports [path] with a progress dialog, cuts out the garments found in
  /// it, then opens the review form.
  static Future<void> importPath(
    BuildContext context,
    WidgetRef ref,
    String path,
  ) async {
    // Start the import exactly once. Creating it inside `builder` would start
    // a new import every time the dialog rebuilds.
    final task = _importAndFindGarments(ref, path);
    final imported = await showDialog<_Imported>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ImportProgress(task: task),
    );
    if (imported == null || !context.mounted) return;
    final (result, garments) = imported;
    switch (result) {
      case Success(:final value):
        final more = await _applyGarments(context, ref, value, garments);
        if (!context.mounted) return;
        if (more > 0) {
          _snack(
            context,
            more == 1
                ? '1 more item from this photo is waiting in your wardrobe '
                      'under "Needs review".'
                : '$more more items from this photo are waiting in your '
                      'wardrobe under "Needs review".',
          );
        }
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

  static Future<_Imported> _importAndFindGarments(
    WidgetRef ref,
    String path,
  ) async {
    final imported = await ref.read(importClothingPhotoProvider).call(path);
    final working = imported.valueOrNull?.images?.working;
    if (working == null) return (imported, const <FoundGarment>[]);
    final found = await ref
        .read(garmentFinderProvider)
        .findGarments(ref.read(fileStoreProvider).resolve(working).path);
    switch (found) {
      case Success(:final value):
        return (imported, value);
      case Failure(:final failure):
        // Background removal is optional: keep the photo as it is.
        AppLogger.error('Garments could not be found', failure);
        return (imported, const <FoundGarment>[]);
    }
  }

  /// Applies the cut-outs the user keeps (D-39). One garment is cut out
  /// directly; several are offered in a picker. Returns how many extra
  /// items were created. Any failure keeps the original photo.
  static Future<int> _applyGarments(
    BuildContext context,
    WidgetRef ref,
    ClothingItem item,
    List<FoundGarment> garments,
  ) async {
    final List<int> chosen;
    if (garments.length == 1) {
      // A lone small find is more likely a mistake than the garment.
      if (garments.single.areaShare < PickGarmentsScreen.preselectShare) {
        return 0;
      }
      chosen = const [0];
    } else if (garments.length > 1) {
      final picked = await Navigator.of(context).push<List<int>>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PickGarmentsScreen(garments: garments),
        ),
      );
      if (picked == null || picked.isEmpty) return 0;
      chosen = picked;
    } else {
      return 0;
    }

    final result = await ref.read(addGarmentsFromPhotoProvider).call(item.id, [
      for (final i in chosen) garments[i].cutout,
    ]);
    switch (result) {
      case Success(:final value):
        return value.length - 1;
      case Failure(:final failure):
        AppLogger.error('Cut-outs could not be saved', failure);
        if (context.mounted) {
          _snack(
            context,
            "The background couldn't be removed. You can still add the photo.",
          );
        }
        return 0;
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

  final Future<_Imported> task;

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
