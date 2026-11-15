import 'package:material_ui/material_ui.dart';

import '../../../shared/widgets/empty_state.dart';

class StylistScreen extends StatelessWidget {
  const StylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stylist')),
      body: const EmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'Nothing to style yet',
        message: 'Outfits are built only from items in your wardrobe.',
      ),
    );
  }
}
