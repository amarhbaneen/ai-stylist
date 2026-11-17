import 'package:material_ui/material_ui.dart';

import '../../../ai/segmentation/garment_segmenter.dart';
import '../../../shared/taxonomy_labels.dart';

/// Lets the user choose which garments found in one photo become items
/// (FR-05, D-39). Pops with the chosen indices, or an empty list to keep
/// the whole photo as one item.
///
/// Garments covering at least [preselectShare] of the photo start ticked;
/// smaller finds are more often mistakes, so they start unticked.
class PickGarmentsScreen extends StatefulWidget {
  const PickGarmentsScreen({required this.garments, super.key});

  final List<FoundGarment> garments;

  static const preselectShare = 0.04;

  @override
  State<PickGarmentsScreen> createState() => _PickGarmentsScreenState();
}

class _PickGarmentsScreenState extends State<PickGarmentsScreen> {
  late final Set<int> _chosen = {
    for (var i = 0; i < widget.garments.length; i++)
      if (widget.garments[i].areaShare >= PickGarmentsScreen.preselectShare) i,
  };

  @override
  Widget build(BuildContext context) {
    final count = _chosen.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Choose items')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Text(
            'We found ${widget.garments.length} garments in this photo. '
            'Each one you keep becomes its own item.',
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < widget.garments.length; i++)
                _GarmentTile(
                  garment: widget.garments[i],
                  selected: _chosen.contains(i),
                  onChanged: (on) =>
                      setState(() => on ? _chosen.add(i) : _chosen.remove(i)),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: count == 0
                    ? null
                    : () => Navigator.pop(context, _chosen.toList()..sort()),
                child: Text(count == 1 ? 'Add 1 item' : 'Add $count items'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, const <int>[]),
                child: const Text('Keep the whole photo as one item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GarmentTile extends StatelessWidget {
  const _GarmentTile({
    required this.garment,
    required this.selected,
    required this.onChanged,
  });

  final FoundGarment garment;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = Labels.category(garment.category);
    return Semantics(
      label: label,
      checked: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!selected),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
                  child: Image.memory(
                    garment.cutout.thumbnail,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 8,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Checkbox(
                  value: selected,
                  onChanged: (v) => onChanged(v ?? false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
