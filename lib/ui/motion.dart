import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared motion tokens. Everything eases out (fast start, soft landing).
class Motion {
  Motion._();
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 380);
  static const slow = Duration(milliseconds: 900);
  static const ease = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutQuart;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Bottom sheet slide-up style.
  static const sheet = AnimationStyle(
    duration: Duration(milliseconds: 420),
    reverseDuration: Duration(milliseconds: 260),
    curve: Curves.easeOutCubic,
  );
}

/// Page route transition: gentle fade + short upward drift.
class SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Motion.medium;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final a = CurvedAnimation(
      parent: animation,
      curve: Motion.ease,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(a),
        child: child,
      ),
    );
  }
}

/// Fades and slides a child in once, after [delay]. Used for staggered
/// entrance of cards.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double dy;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.dy = 14,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Motion.ease,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _a.value) * widget.dy),
          child: child,
        ),
      ),
    );
  }
}

/// Staggered delay helper: 60ms per item, capped.
Duration stagger(int i) => Duration(milliseconds: 60 * math.min(i, 8));

/// Scales down slightly while pressed, then springs back.
class Squish extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const Squish({super.key, required this.child, this.enabled = true});

  @override
  State<Squish> createState() => _SquishState();
}

class _SquishState extends State<Squish> {
  var _down = false;

  void _set(bool v) {
    if (widget.enabled && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.965 : 1,
        duration: _down
            ? const Duration(milliseconds: 90)
            : const Duration(milliseconds: 420),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

/// Animated number that counts from its previous value to the new one.
class CountUp extends StatefulWidget {
  final double value;
  final String Function(double) format;
  final TextStyle? style;
  final Duration duration;

  const CountUp({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = Motion.slow,
  });

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> {
  late double _from = widget.value * 0.6;

  @override
  void didUpdateWidget(CountUp old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _from = old.value;
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) {
      return Text(widget.format(widget.value), style: widget.style);
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.value),
      tween: Tween(begin: _from, end: widget.value),
      duration: widget.duration,
      curve: Motion.emphasized,
      builder: (context, v, _) => Text(widget.format(v), style: widget.style),
    );
  }
}

/// Soft cross-fade + tiny drift whenever [index] changes, while keeping
/// every child alive (like IndexedStack).
class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    value: 1,
  );

  @override
  void didUpdateWidget(FadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Motion.ease);
    return AnimatedBuilder(
      animation: a,
      builder: (context, child) => Opacity(
        opacity: 0.2 + 0.8 * a.value,
        child: Transform.translate(
          offset: Offset(0, (1 - a.value) * 10),
          child: child,
        ),
      ),
      child: IndexedStack(index: widget.index, children: widget.children),
    );
  }
}

/// Gentle idle float for the mascot.
class Floaty extends StatefulWidget {
  final Widget child;
  final double amplitude;
  const Floaty({super.key, required this.child, this.amplitude = 4});

  @override
  State<Floaty> createState() => _FloatyState();
}

class _FloatyState extends State<Floaty> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = math.sin(_c.value * 2 * math.pi);
        return Transform.translate(
          offset: Offset(0, t * widget.amplitude),
          child: Transform.rotate(angle: t * 0.03, child: child),
        );
      },
    );
  }
}
