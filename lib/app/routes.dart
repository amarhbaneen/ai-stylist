/// Route paths (REQUIREMENTS §13). Kept separate from the router so screens
/// can navigate without importing each other.
abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const preferences = '/home/preferences';
  static const wardrobe = '/wardrobe';
  static const stylist = '/stylist';
  static const favorites = '/favorites';

  static String item(String id) => '/wardrobe/item/$id';

  /// Review/edit form. [confirm] is true for a newly imported draft.
  static String editItem(String id, {bool confirm = false}) =>
      '/wardrobe/item/$id/edit${confirm ? '?confirm=1' : ''}';
}
