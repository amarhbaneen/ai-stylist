import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../core/media/file_hasher.dart';
import '../../core/media/image_processor.dart';
import '../../core/media/media_picker.dart';
import '../../core/providers.dart';
import 'data/drift_wardrobe_repository.dart';

part 'wardrobe_providers.g.dart';

@Riverpod(keepAlive: true)
ImageProcessor imageProcessor(Ref ref) => const NativeImageProcessor();

@Riverpod(keepAlive: true)
MediaPicker mediaPicker(Ref ref) => ImagePickerMediaPicker();

@Riverpod(keepAlive: true)
WardrobeRepository wardrobeRepository(Ref ref) => DriftWardrobeRepository(
  database: ref.watch(appDatabaseProvider),
  files: ref.watch(fileStoreProvider),
  images: ref.watch(imageProcessorProvider),
  hasher: sha256OfFile,
  clock: ref.watch(clockProvider),
  ids: ref.watch(idGeneratorProvider),
);

@riverpod
ImportClothingPhoto importClothingPhoto(Ref ref) =>
    ImportClothingPhoto(ref.watch(wardrobeRepositoryProvider));

@riverpod
SaveClothingItem saveClothingItem(Ref ref) =>
    SaveClothingItem(ref.watch(wardrobeRepositoryProvider));

@riverpod
ArchiveClothingItem archiveClothingItem(Ref ref) =>
    ArchiveClothingItem(ref.watch(wardrobeRepositoryProvider));

@riverpod
RestoreClothingItem restoreClothingItem(Ref ref) =>
    RestoreClothingItem(ref.watch(wardrobeRepositoryProvider));

@riverpod
DeleteClothingItem deleteClothingItem(Ref ref) =>
    DeleteClothingItem(ref.watch(wardrobeRepositoryProvider));

/// Current wardrobe filter (category chips, filter sheet, search).
@riverpod
class WardrobeFilterController extends _$WardrobeFilterController {
  @override
  WardrobeFilter build() => WardrobeFilter();

  void toggleCategory(GarmentCategory category) {
    final next = {...state.categories};
    if (!next.remove(category)) next.add(category);
    state = state.copyWith(categories: next);
  }

  void clearCategories() => state = state.copyWith(categories: {});

  void setQuery(String query) => state = state.copyWith(query: query);

  void replace(WardrobeFilter filter) => state = filter;
}

/// Items matching the current filter, kept live from the database.
@riverpod
Stream<List<ClothingItem>> wardrobeItems(Ref ref) {
  final filter = ref.watch(wardrobeFilterControllerProvider);
  return WatchWardrobe(ref.watch(wardrobeRepositoryProvider))(filter);
}

/// One item, live; `null` once deleted.
@riverpod
Stream<ClothingItem?> clothingItem(Ref ref, String id) =>
    ref.watch(wardrobeRepositoryProvider).watchItem(id);
