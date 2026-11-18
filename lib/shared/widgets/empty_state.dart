import 'package:material_ui/material_ui.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../../core/theme/tokens.dart';
import '../taxonomy_labels.dart';
import 'motion.dart';

/// A designed state for "nothing here yet": a quiet icon, a serif title, one
/// sentence of what to do, and at most one action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) =>
      _StateLayout(icon: icon, title: title, message: message, action: action);
}

/// A designed error state: what went wrong in plain words, and a retry when
/// trying again can help.
///
/// [error] is shown with [failureMessage] when it is an [AppFailure];
/// anything else shows [fallback].
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.title,
    this.error,
    this.fallback = 'Something unexpected happened on this screen.',
    this.onRetry,
    super.key,
  });

  final String title;
  final Object? error;
  final String fallback;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final e = error;
    return _StateLayout(
      icon: Icons.error_outline,
      iconColor: Theme.of(context).colorScheme.error,
      title: title,
      message: e is AppFailure ? failureMessage(e) : fallback,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
    );
  }
}

/// A loading state that says what is happening, for waits the user notices.
/// Content that has a known shape uses [Skeleton] instead.
class LoadingState extends StatelessWidget {
  const LoadingState({this.label, super.key});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            if (label case final text?) ...[
              const SizedBox(height: Space.lg),
              Text(
                text,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
    this.action,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.xxl,
          vertical: Space.xl,
        ),
        child: FadeSlideIn(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Icon(
                      icon,
                      size: 28,
                      color: iconColor ?? colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: Space.xl),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (action != null) ...[
                  const SizedBox(height: Space.xl),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A placeholder block with a slow pulse, standing in for content whose
/// shape is known (grid tiles, list rows). Still when animations are off.
class Skeleton extends StatefulWidget {
  const Skeleton({this.width, this.height, this.aspectRatio, super.key});

  final double? width;
  final double? height;
  final double? aspectRatio;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget box = FadeTransition(
      opacity: Tween(
        begin: 0.55,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _pulse, curve: Motion.standard)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: Radii.all,
        ),
        child: SizedBox(width: widget.width, height: widget.height),
      ),
    );
    if (widget.aspectRatio case final ratio?) {
      box = AspectRatio(aspectRatio: ratio, child: box);
    }
    return ExcludeSemantics(child: box);
  }
}
