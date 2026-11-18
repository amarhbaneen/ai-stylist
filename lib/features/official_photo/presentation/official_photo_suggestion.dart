import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/taxonomy_labels.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/motion.dart';
import '../../wardrobe/wardrobe_providers.dart';
import '../domain/official_photo.dart';
import '../official_photo_providers.dart';

/// Under a new cut-out: searches for the official product photo by itself
/// and offers it next to the cut-out (DECISIONS D-43). The user chooses;
/// nothing is applied without a tap.
class OfficialPhotoSuggestion extends ConsumerStatefulWidget {
  const OfficialPhotoSuggestion({
    required this.itemId,
    required this.cutoutPath,
    super.key,
  });

  final String itemId;

  /// App-relative path of the cut-out to search with.
  final String cutoutPath;

  @override
  ConsumerState<OfficialPhotoSuggestion> createState() =>
      _OfficialPhotoSuggestionState();
}

class _OfficialPhotoSuggestionState
    extends ConsumerState<OfficialPhotoSuggestion> {
  var _selected = 0;
  var _saving = false;
  var _dismissed = false;

  OfficialPhotoSuggestionsProvider get _provider =>
      officialPhotoSuggestionsProvider(widget.itemId, widget.cutoutPath);

  Future<void> _use(DownloadedCandidate c) async {
    setState(() => _saving = true);
    final r = await ref
        .read(manageProductPhotoProvider)
        .use(widget.itemId, c.path);
    if (!mounted) return;
    setState(() => _saving = false);
    if (r case Failure(:final failure)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureMessage(failure))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(officialPhotoStateProvider).value;
    if (_dismissed || settings == null || !settings.enabled) {
      return const SizedBox.shrink();
    }
    final text = Theme.of(context).textTheme;
    if (!settings.hasKey) {
      return _Panel(
        child: Text(
          'Add your Google Cloud API key in Style preferences to find the '
          'official photo automatically.',
          style: text.bodyMedium,
        ),
      );
    }

    final suggestions = ref.watch(_provider);
    return StateSwitcher(
      child: switch (suggestions) {
        AsyncData(value: Success(value: final list)) when list.isNotEmpty =>
          _Found(
            key: const ValueKey('found'),
            candidates: list,
            selected: _selected.clamp(0, list.length - 1),
            saving: _saving,
            onSelect: (i) => setState(() => _selected = i),
            onUse: (c) => _use(c),
            onKeep: () => setState(() => _dismissed = true),
          ),
        AsyncData(value: Success()) => _Panel(
          key: const ValueKey('none'),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'No official photo found online. The cut-out is used.',
                  style: text.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(_provider),
                child: const Text('Search again'),
              ),
            ],
          ),
        ),
        AsyncData(value: Failure(:final failure)) => _Panel(
          key: const ValueKey('error'),
          child: ErrorState(
            title: 'Official photo search failed',
            error: failure,
            onRetry: () => ref.invalidate(_provider),
          ),
        ),
        AsyncError(:final error) => _Panel(
          key: const ValueKey('error'),
          child: ErrorState(
            title: 'Official photo search failed',
            error: error,
            onRetry: () => ref.invalidate(_provider),
          ),
        ),
        _ => const _Searching(key: ValueKey('searching')),
      },
    );
  }
}

/// Quiet surface for the suggestion area.
class _Panel extends StatelessWidget {
  const _Panel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.lg),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: Radii.all,
      ),
      child: Padding(padding: const EdgeInsets.all(Space.lg), child: child),
    ),
  );
}

class _Searching extends StatelessWidget {
  const _Searching({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Looking for the official photo', style: text.titleSmall),
          const SizedBox(height: Space.xs),
          Text('Searching the web with the cut-out.', style: text.bodySmall),
          const SizedBox(height: Space.md),
          const Row(
            children: [
              Expanded(child: Skeleton(aspectRatio: 1)),
              SizedBox(width: Space.sm),
              Expanded(child: Skeleton(aspectRatio: 1)),
              SizedBox(width: Space.sm),
              Expanded(child: Skeleton(aspectRatio: 1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Found extends StatelessWidget {
  const _Found({
    required this.candidates,
    required this.selected,
    required this.saving,
    required this.onSelect,
    required this.onUse,
    required this.onKeep,
    super.key,
  });

  final List<DownloadedCandidate> candidates;
  final int selected;
  final bool saving;
  final ValueChanged<int> onSelect;
  final ValueChanged<DownloadedCandidate> onUse;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final exact = candidates.any(
      (c) => c.candidate.match != CandidateMatch.similar,
    );
    final chosen = candidates[selected];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            exact ? 'Official photo found' : 'Similar product photos',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: Space.xs),
          Text(
            exact
                ? 'Use it instead of your cut-out? You can switch back any '
                      'time.'
                : 'No exact match; these look alike. Use one only if it is '
                      'the same item.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              for (var i = 0; i < candidates.length; i++) ...[
                if (i > 0) const SizedBox(width: Space.sm),
                Expanded(
                  child: FadeSlideIn(
                    index: i,
                    child: Semantics(
                      selected: i == selected,
                      button: true,
                      label: 'Photo from ${candidates[i].candidate.source}',
                      child: InkWell(
                        borderRadius: Radii.all,
                        onTap: () => onSelect(i),
                        child: AnimatedContainer(
                          duration: Motion.of(context, Motion.short),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLowest,
                            borderRadius: Radii.all,
                            border: Border.all(
                              color: i == selected
                                  ? colors.onSurface
                                  : colors.outlineVariant,
                              width: i == selected ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: Radii.all,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Image.file(
                                File(candidates[i].path),
                                fit: BoxFit.contain,
                                cacheWidth: 300,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              // Keep tiles the same size when fewer than three were found.
              for (var i = candidates.length; i < 3; i++) ...[
                const SizedBox(width: Space.sm),
                const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(
            [
              'From ${chosen.candidate.source}',
              ?chosen.candidate.pageTitle,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.md),
          FilledButton(
            onPressed: saving ? null : () => onUse(chosen),
            child: const Text('Use this photo'),
          ),
          const SizedBox(height: Space.xs),
          TextButton(
            onPressed: saving ? null : onKeep,
            child: const Text('Keep my cut-out'),
          ),
        ],
      ),
    );
  }
}
