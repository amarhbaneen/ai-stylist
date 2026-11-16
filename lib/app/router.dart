import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/clothing_analysis/presentation/model_manager_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/preferences_screen.dart';
import '../features/stylist/presentation/outfit_details_screen.dart';
import '../features/stylist/presentation/stylist_screen.dart';
import '../features/wardrobe/presentation/item_details_screen.dart';
import '../features/wardrobe/presentation/item_editor_screen.dart';
import '../features/wardrobe/presentation/wardrobe_screen.dart';
import 'routes.dart';

export 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter buildRouter({required bool onboardingComplete}) => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: onboardingComplete ? AppRoutes.home : AppRoutes.onboarding,
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'preferences',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => const PreferencesScreen(),
                ),
                GoRoute(
                  path: 'models',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => const ModelManagerScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.wardrobe,
              builder: (context, state) => const WardrobeScreen(),
              routes: [
                GoRoute(
                  path: 'item/:id',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) =>
                      ItemDetailsScreen(itemId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: _rootKey,
                      builder: (context, state) => ItemEditorScreen(
                        itemId: state.pathParameters['id']!,
                        confirm: state.uri.queryParameters['confirm'] == '1',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.stylist,
              builder: (context, state) => const StylistScreen(),
              routes: [
                GoRoute(
                  path: 'outfit/:id',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => OutfitDetailsScreen(
                    outfitId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
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
