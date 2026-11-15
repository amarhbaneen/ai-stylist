import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/favorites/presentation/favorites_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/stylist/presentation/stylist_screen.dart';
import '../features/wardrobe/presentation/wardrobe_screen.dart';

/// Route paths for the primary navigation (REQUIREMENTS §13).
abstract final class AppRoutes {
  static const home = '/home';
  static const wardrobe = '/wardrobe';
  static const stylist = '/stylist';
  static const favorites = '/favorites';
}

GoRouter buildRouter() => GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        _branch(AppRoutes.home, const HomeScreen()),
        _branch(AppRoutes.wardrobe, const WardrobeScreen()),
        _branch(AppRoutes.stylist, const StylistScreen()),
        _branch(AppRoutes.favorites, const FavoritesScreen()),
      ],
    ),
  ],
);

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);

/// Bottom-navigation scaffold that keeps each tab's state alive.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the current tab returns to its first screen.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: 'Wardrobe',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Stylist',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}
