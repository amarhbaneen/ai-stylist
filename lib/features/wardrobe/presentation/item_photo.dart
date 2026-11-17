import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/item_thumbnail.dart';
import '../wardrobe_providers.dart';

/// The item's large image. When a cut-out exists, a switch lets the user
/// choose it or the original photo, which is always kept (FR-05, D-39).
class ItemPhoto extends ConsumerStatefulWidget {
  const ItemPhoto({required this.item, required this.semanticLabel, super.key});

  final ClothingItem item;
  final String semanticLabel;

  @override
  ConsumerState<ItemPhoto> createState() => _ItemPhotoState();
}

class _ItemPhotoState extends ConsumerState<ItemPhoto> {
  var _busy = false;

  Future<void> _choose(bool cutout) async {
    setState(() => _busy = true);
    final result = await ref
        .read(showCutoutProvider)
        .call(widget.item.id, show: cutout);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Failure(:final failure)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureMessage(failure))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.item.images;
    final hasCutout = images?.cutout != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: StoredImage(
                relativePath: images?.display,
                fit: BoxFit.contain,
                semanticLabel: widget.semanticLabel,
              ),
            ),
          ),
        ),
        if (hasCutout) ...[
          const SizedBox(height: 8),
          Center(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.content_cut),
                  label: Text('Background removed'),
                ),
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.image_outlined),
                  label: Text('Original'),
                ),
              ],
              selected: {images!.showCutout},
              showSelectedIcon: false,
              onSelectionChanged: _busy ? null : (s) => _choose(s.single),
            ),
          ),
        ],
      ],
    );
  }
}
