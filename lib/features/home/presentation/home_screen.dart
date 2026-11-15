import 'package:material_ui/material_ui.dart';

import '../../../shared/widgets/empty_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const EmptyState(
        icon: Icons.wb_sunny_outlined,
        title: 'No suggestion yet',
        message: 'Add a few items to your wardrobe to get a daily outfit idea.',
      ),
    );
  }
}
