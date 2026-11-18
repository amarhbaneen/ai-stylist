import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../core/media/media_picker.dart';
import '../../../core/providers.dart';
import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/item_thumbnail.dart';
import '../wardrobe_providers.dart';

/// Product-style backdrop for cut-outs and product photos.
const _studioBackground = Color(0xFFF4F4F2);

/// The item's large image, a switch between the images it has (photo,
/// cut-out, product photo), and the actions on them (FR-05, D-39, D-41):
/// flip a mirrored cut-out, find the official photo with a visual search
/// app, and use a photo the user saved from it.
class ItemPhoto extends ConsumerStatefulWidget {
  const ItemPhoto({required this.item, required this.semanticLabel, super.key});

  final ClothingItem item;
  final String semanticLabel;

  @override
  ConsumerState<ItemPhoto> createState() => _ItemPhotoState();
}

class _ItemPhotoState extends ConsumerState<ItemPhoto> {
  var _busy = false;

  Future<void> _run(
    Future<Result<Object?>> Function() action, {
    String? done,
  }) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Failure(failure: CancelledFailure()):
        break;
      case Failure(:final failure):
        messenger.showSnackBar(
          SnackBar(content: Text(failureMessage(failure))),
        );
      case Success():
        if (done != null) {
          messenger.showSnackBar(SnackBar(content: Text(done)));
        }
    }
  }

  String get _id => widget.item.id;

  void _choose(ItemView view) =>
      _run(() => ref.read(chooseItemViewProvider).call(_id, view));

  void _flip() => _run(() => ref.read(flipCutoutProvider).call(_id));

  void _find(ItemImages images) {
    // Search with the garment alone when there is a cut-out: no face, no
    // room, and a better match.
    final path = images.cutout?.image ?? images.working;
    final file = ref.read(fileStoreProvider).resolve(path);
    _run(
      () => ref.read(visualSearchProvider).search(file.path),
      done:
          'In the search results, open the matching product, save its '
          'photo, then tap "Use official photo".',
    );
  }

  void _useOfficial() => _run(() async {
    final picked = await ref
        .read(mediaPickerProvider)
        .pick(MediaSourceKind.gallery);
    return switch (picked) {
      Success(value: final path) =>
        await ref.read(manageProductPhotoProvider).use(_id, path),
      Failure(:final failure) => Failure(failure),
    };
  });

  void _removeOfficial() =>
      _run(() => ref.read(manageProductPhotoProvider).remove(_id));

  @override
  Widget build(BuildContext context) {
    final images = widget.item.images;
    if (images == null) {
      return _Frame(
        studio: false,
        child: StoredImage(
          relativePath: null,
          semanticLabel: widget.semanticLabel,
        ),
      );
    }
    final shown = images.shown;
    final views = [
      for (final v in [ItemView.cutout, ItemView.product, ItemView.photo])
        if (images.has(v)) v,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Frame(
          studio: shown != ItemView.photo,
          child: StoredImage(
            relativePath: images.display,
            fit: BoxFit.contain,
            semanticLabel: widget.semanticLabel,
          ),
        ),
        if (views.length > 1) ...[
          const SizedBox(height: 8),
          Center(
            child: SegmentedButton<ItemView>(
              segments: [for (final v in views) _segment(v)],
              selected: {shown},
              showSelectedIcon: false,
              onSelectionChanged: _busy ? null : (s) => _choose(s.single),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            if (shown == ItemView.cutout)
              TextButton.icon(
                onPressed: _busy ? null : _flip,
                icon: const Icon(Icons.flip),
                label: const Text('Flip'),
              ),
            TextButton.icon(
              onPressed: _busy ? null : () => _find(images),
              icon: const Icon(Icons.image_search),
              label: const Text('Find official photo'),
            ),
            TextButton.icon(
              onPressed: _busy ? null : _useOfficial,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                images.product == null
                    ? 'Use official photo'
                    : 'Change official photo',
              ),
            ),
            if (images.product != null)
              TextButton.icon(
                onPressed: _busy ? null : _removeOfficial,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove official photo'),
              ),
          ],
        ),
      ],
    );
  }

  static ButtonSegment<ItemView> _segment(ItemView v) => switch (v) {
    ItemView.cutout => const ButtonSegment(
      value: ItemView.cutout,
      icon: Icon(Icons.content_cut),
      label: Text('Cut-out'),
    ),
    ItemView.product => const ButtonSegment(
      value: ItemView.product,
      icon: Icon(Icons.verified_outlined),
      label: Text('Official'),
    ),
    ItemView.photo => const ButtonSegment(
      value: ItemView.photo,
      icon: Icon(Icons.image_outlined),
      label: Text('Original'),
    ),
  };
}

/// Rounded 4:3 frame; [studio] uses a light product-style backdrop with
/// some padding.
class _Frame extends StatelessWidget {
  const _Frame({required this.studio, required this.child});

  final bool studio;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: ColoredBox(
      color: studio
          ? _studioBackground
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Padding(padding: EdgeInsets.all(studio ? 16 : 0), child: child),
      ),
    ),
  );
}
