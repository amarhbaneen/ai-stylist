import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/taxonomy_labels.dart';
import '../wardrobe_providers.dart';

/// The "Studio polish" switch in Style preferences (DECISIONS D-44).
class StudioPolishSection extends ConsumerWidget {
  const StudioPolishSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(studioPolishEnabledProvider).value;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: Space.xxxl),
        Text('Cut-outs', style: text.titleMedium),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Studio polish'),
          subtitle: const Text(
            'Cleans edges and small holes, straightens and evens the light '
            'of new cut-outs, on this phone. Only real pixels are used; '
            'detected colours and types are not affected.',
          ),
          value: enabled ?? true,
          onChanged: enabled == null
              ? null
              : (on) async {
                  final r = await ref
                      .read(studioPolishEnabledProvider.notifier)
                      .set(enabled: on);
                  if (r case Failure(:final failure) when context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(failureMessage(failure))),
                    );
                  }
                },
        ),
      ],
    );
  }
}
