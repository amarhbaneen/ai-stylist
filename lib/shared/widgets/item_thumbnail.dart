import 'dart:ui' show ImageFilter;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';

/// Hero tag shared by an item's grid tile and its large photo.
String itemPhotoHeroTag(String itemId) => 'item-photo-$itemId';

/// Shows a stored image by its app-relative path, with a neutral placeholder
/// when the file is missing or cannot be decoded.
class StoredImage extends ConsumerWidget {
  const StoredImage({
    required this.relativePath,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.semanticLabel,
    this.cutoutShadow = false,
    super.key,
  });

  final String? relativePath;
  final BoxFit fit;

  /// Decode width in physical pixels; keeps grid memory use low.
  final int? cacheWidth;
  final String? semanticLabel;

  /// For transparent cut-outs: a soft shadow traced from the garment's own
  /// outline, so a white garment still stands out on a light backdrop.
  final bool cutoutShadow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = relativePath;
    if (path == null) return _placeholder(context);
    final file = ref.watch(fileStoreProvider).resolve(path);
    Widget image({String? label}) => Image.file(
      file,
      fit: fit,
      cacheWidth: cacheWidth,
      semanticLabel: label,
      excludeFromSemantics: label == null,
      errorBuilder: (context, error, stackTrace) => _placeholder(context),
    );
    if (!cutoutShadow) return image(label: semanticLabel);
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.translate(
          offset: const Offset(0, 4),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: ColorFiltered(
              // Keep only the garment's shape, as a faint grey.
              colorFilter: const ColorFilter.mode(
                Color(0x47000000),
                BlendMode.srcIn,
              ),
              child: image(),
            ),
          ),
        ),
        image(label: semanticLabel),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.checkroom_outlined, color: scheme.outline),
      ),
    );
  }
}
