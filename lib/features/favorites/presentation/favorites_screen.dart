import 'package:material_ui/material_ui.dart';

import '../../../shared/widgets/empty_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: const EmptyState(
        icon: Icons.favorite_border,
        title: 'No favorites yet',
        message: 'Outfits you save will appear here.',
      ),
    );
  }
}
