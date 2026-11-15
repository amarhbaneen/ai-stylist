import 'package:material_ui/material_ui.dart';

import '../../../shared/widgets/empty_state.dart';

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wardrobe')),
      body: const EmptyState(
        icon: Icons.checkroom_outlined,
        title: 'Your wardrobe is empty',
        message: 'Clothes you add are stored only on this device.',
      ),
    );
  }
}
