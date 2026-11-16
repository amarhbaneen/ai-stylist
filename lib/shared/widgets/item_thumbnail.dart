import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';

/// Shows a stored image by its app-relative path, with a neutral placeholder
/// when the file is missing or cannot be decoded.
class StoredImage extends ConsumerWidget {
  const StoredImage({
    required this.relativePath,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.semanticLabel,
    super.key,
  });

  final String? relativePath;
  final BoxFit fit;

  /// Decode width in physical pixels; keeps grid memory use low.
  final int? cacheWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = relativePath;
    if (path == null) return _placeholder(context);
    final file = ref.watch(fileStoreProvider).resolve(path);
    return Image.file(
      file,
      fit: fit,
      cacheWidth: cacheWidth,
      semanticLabel: semanticLabel,
      errorBuilder: (context, error, stackTrace) => _placeholder(context),
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
