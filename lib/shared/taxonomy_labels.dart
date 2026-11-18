import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

/// English UI labels for taxonomy values. Kept out of the domain layer so the
/// domain stays presentation-free; this is the single place to localise.
abstract final class Labels {
  static String category(GarmentCategory c) => switch (c) {
    GarmentCategory.top => 'Top',
    GarmentCategory.bottom => 'Bottom',
    GarmentCategory.onePiece => 'One-piece',
    GarmentCategory.outerwear => 'Outerwear',
    GarmentCategory.footwear => 'Footwear',
    GarmentCategory.accessory => 'Accessory',
    GarmentCategory.unknown => 'Uncategorised',
  };

  static String subcategory(GarmentSubcategory s) => switch (s) {
    GarmentSubcategory.tShirt => 'T-shirt',
    GarmentSubcategory.shirt => 'Shirt',
    GarmentSubcategory.blouse => 'Blouse',
    GarmentSubcategory.polo => 'Polo',
    GarmentSubcategory.sweater => 'Sweater',
    GarmentSubcategory.hoodie => 'Hoodie',
    GarmentSubcategory.tank => 'Tank top',
    GarmentSubcategory.jeans => 'Jeans',
    GarmentSubcategory.trousers => 'Trousers',
    GarmentSubcategory.chinos => 'Chinos',
    GarmentSubcategory.shorts => 'Shorts',
    GarmentSubcategory.skirt => 'Skirt',
    GarmentSubcategory.leggings => 'Leggings',
    GarmentSubcategory.dress => 'Dress',
    GarmentSubcategory.jumpsuit => 'Jumpsuit',
    GarmentSubcategory.overall => 'Overall',
    GarmentSubcategory.jacket => 'Jacket',
    GarmentSubcategory.blazer => 'Blazer',
    GarmentSubcategory.coat => 'Coat',
    GarmentSubcategory.cardigan => 'Cardigan',
    GarmentSubcategory.vest => 'Vest',
    GarmentSubcategory.sneakers => 'Sneakers',
    GarmentSubcategory.boots => 'Boots',
    GarmentSubcategory.dressShoes => 'Dress shoes',
    GarmentSubcategory.loafers => 'Loafers',
    GarmentSubcategory.sandals => 'Sandals',
    GarmentSubcategory.heels => 'Heels',
    GarmentSubcategory.flats => 'Flats',
    GarmentSubcategory.bag => 'Bag',
    GarmentSubcategory.hat => 'Hat',
    GarmentSubcategory.scarf => 'Scarf',
    GarmentSubcategory.belt => 'Belt',
    GarmentSubcategory.tie => 'Tie',
    GarmentSubcategory.otherTop ||
    GarmentSubcategory.otherBottom ||
    GarmentSubcategory.otherOnePiece ||
    GarmentSubcategory.otherOuterwear ||
    GarmentSubcategory.otherFootwear ||
    GarmentSubcategory.otherAccessory => 'Other',
  };

  static String color(ColorFamily c) => switch (c) {
    ColorFamily.black => 'Black',
    ColorFamily.white => 'White',
    ColorFamily.grey => 'Grey',
    ColorFamily.beige => 'Beige',
    ColorFamily.brown => 'Brown',
    ColorFamily.navy => 'Navy',
    ColorFamily.blue => 'Blue',
    ColorFamily.green => 'Green',
    ColorFamily.olive => 'Olive',
    ColorFamily.yellow => 'Yellow',
    ColorFamily.orange => 'Orange',
    ColorFamily.red => 'Red',
    ColorFamily.burgundy => 'Burgundy',
    ColorFamily.pink => 'Pink',
    ColorFamily.purple => 'Purple',
    ColorFamily.multicolor => 'Multicolour',
  };

  static String pattern(GarmentPattern p) => switch (p) {
    GarmentPattern.solid => 'Solid',
    GarmentPattern.striped => 'Striped',
    GarmentPattern.checked => 'Checked',
    GarmentPattern.floral => 'Floral',
    GarmentPattern.graphic => 'Graphic',
    GarmentPattern.dotted => 'Dotted',
    GarmentPattern.animal => 'Animal print',
    GarmentPattern.other => 'Other',
    GarmentPattern.unknown => 'Not set',
  };

  static String season(Season s) => switch (s) {
    Season.spring => 'Spring',
    Season.summer => 'Summer',
    Season.autumn => 'Autumn',
    Season.winter => 'Winter',
  };

  static String formality(Formality f) => switch (f) {
    Formality.lounge => 'Lounge',
    Formality.casual => 'Casual',
    Formality.smartCasual => 'Smart casual',
    Formality.business => 'Business',
    Formality.formal => 'Formal',
  };

  static String fit(GarmentFit f) => switch (f) {
    GarmentFit.slim => 'Slim',
    GarmentFit.regular => 'Regular',
    GarmentFit.relaxed => 'Relaxed',
    GarmentFit.oversized => 'Oversized',
    GarmentFit.unknown => 'Not set',
  };

  static String warmth(Warmth w) => switch (w) {
    Warmth.light => 'Light',
    Warmth.medium => 'Medium',
    Warmth.heavy => 'Heavy',
  };

  static String style(StylePreference s) => switch (s) {
    StylePreference.casual => 'Casual',
    StylePreference.classic => 'Classic',
    StylePreference.minimal => 'Minimal',
    StylePreference.sporty => 'Sporty',
    StylePreference.streetwear => 'Streetwear',
    StylePreference.elegant => 'Elegant',
    StylePreference.bohemian => 'Bohemian',
  };

  static String status(ItemStatus s) => switch (s) {
    ItemStatus.draft => 'Needs review',
    ItemStatus.active => 'Active',
    ItemStatus.archived => 'Archived',
  };

  /// Title for an item card: the user's name, else subcategory/category.
  static String itemTitle(ClothingItem item) {
    final a = item.attributes;
    if (a.displayName case final name?) return name;
    if (a.subcategory case final sub?) {
      final label = subcategory(sub);
      return label == 'Other' ? category(a.category) : label;
    }
    return category(a.category);
  }

  /// Representative swatch colours (display only, not stored).
  static Color swatch(ColorFamily c) => switch (c) {
    ColorFamily.black => const Color(0xFF1B1B1B),
    ColorFamily.white => const Color(0xFFF7F7F5),
    ColorFamily.grey => const Color(0xFF9E9E9E),
    ColorFamily.beige => const Color(0xFFD9C7A6),
    ColorFamily.brown => const Color(0xFF6D4C35),
    ColorFamily.navy => const Color(0xFF1F2A4A),
    ColorFamily.blue => const Color(0xFF2F6FD0),
    ColorFamily.green => const Color(0xFF2E8B57),
    ColorFamily.olive => const Color(0xFF6B7A3A),
    ColorFamily.yellow => const Color(0xFFF2C94C),
    ColorFamily.orange => const Color(0xFFEE8A2F),
    ColorFamily.red => const Color(0xFFC8352E),
    ColorFamily.burgundy => const Color(0xFF6E1F2F),
    ColorFamily.pink => const Color(0xFFE995B5),
    ColorFamily.purple => const Color(0xFF7B4FA8),
    ColorFamily.multicolor => const Color(0xFF888888),
  };
}

/// User-facing explanation for a failure. Technical detail stays in the log.
String failureMessage(AppFailure failure) => switch (failure) {
  PermissionDeniedFailure() =>
    'Access was turned off for this app. Allow it in your phone settings, '
        'or use the other option.',
  UnsupportedImageFailure() =>
    "That image couldn't be opened. Try a JPEG, PNG or HEIC photo.",
  DuplicateItemFailure() => 'This photo is already in your wardrobe.',
  InsufficientStorageFailure() =>
    'Your phone is out of space, so nothing was saved. Free some space '
        'and try again.',
  ValidationFailure(:final message) => message,
  NotFoundFailure() => 'That item no longer exists. It may have been deleted.',
  CancelledFailure() => 'Cancelled.',
  StorageFailure() =>
    "Couldn't read or write the app's storage. Try again; if it keeps "
        'happening, restart the app.',
  ModelUnavailableFailure() =>
    "The on-device model isn't available, so nothing was suggested. You "
        'can fill in the details yourself.',
  ModelCorruptFailure() =>
    'The on-device model file is damaged, so nothing was suggested. '
        'Reinstalling the app restores it; you can fill in the details '
        'yourself meanwhile.',
  InferenceFailure() =>
    "Couldn't analyse this photo. You can fill in the details yourself.",
  NetworkFailure() =>
    "Couldn't reach the internet. Check your connection and try again.",
  ArchiveValidationFailure() =>
    "This backup file isn't valid or is damaged, so nothing was imported.",
};
