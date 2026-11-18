import 'package:material_ui/material_ui.dart';

import '../../core/theme/tokens.dart';

/// Fades and lifts its child into place once, when first built. [index]
/// staggers items of a list or grid (capped, so long lists do not wait).
/// Shows the child at once when the user turned animations off.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({required this.child, this.index = 0, super.key});

  final Widget child;
  final int index;

  /// Stagger per item, and the most items that wait for it.
  static const step = Duration(milliseconds: 40);
  static const maxStaggered = 8;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  // The stagger is part of the animation (an Interval), not a timer.
  late final Duration _delay =
      FadeSlideIn.step * widget.index.clamp(0, FadeSlideIn.maxStaggered);
  late final _controller = AnimationController(
    vsync: this,
    duration: Motion.long + _delay,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _delay.inMicroseconds / (Motion.long + _delay).inMicroseconds,
      1,
      curve: Motion.enter,
    ),
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(_curve),
      child: widget.child,
    ),
  );
}

/// Cross-fades between states (loading, content, empty, error) so the
/// screen does not jump.
class StateSwitcher extends StatelessWidget {
  const StateSwitcher({required this.child, super.key});

  /// Give each state a distinct key (or type) so the switch animates.
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: Motion.of(context, Motion.medium),
    switchInCurve: Motion.enter,
    switchOutCurve: Motion.standard,
    child: child,
  );
}
