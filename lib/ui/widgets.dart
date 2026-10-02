import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'theme.dart';

String fmt0(num v) {
  final s = v.round().abs().toString();
  final b = StringBuffer(v.round() < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String fmt1(num v) => v.toStringAsFixed(1);

/// [word] with the Korean particle that fits it (을/를, 이/가, 은/는, and
/// (으)로 with [ro]); in other languages [word] as it is.
String josa(
  String locale,
  String word,
  String afterFinal,
  String afterVowel, {
  bool ro = false,
}) {
  // The sound that matters is the last letter, past quotes and brackets.
  final core = word.replaceAll(RegExp(r'''[\s'"’”)\]]+$'''), '');
  if (!locale.startsWith('ko') || core.isEmpty) return word;
  final last = core.runes.last;
  int? jong;
  if (last >= 0xAC00 && last <= 0xD7A3) {
    jong = (last - 0xAC00) % 28;
  } else if (last >= 0x30 && last <= 0x39) {
    // 영 일 이 삼 사 오 육 칠 팔 구: does the number end in a consonant?
    jong = const [21, 8, 0, 16, 0, 0, 1, 8, 8, 0][last - 0x30];
  }
  // Not a Hangul syllable or digit (an English name): say both.
  if (jong == null) return '$word$afterFinal($afterVowel)';
  // (으)로: a final ㄹ (8) takes 로 like a vowel.
  final plain = jong == 0 || (ro && jong == 8);
  return '$word${plain ? afterVowel : afterFinal}';
}

String signed1(num v) => '${v > 0 ? '+' : ''}${v.toStringAsFixed(1)}';

/// White rounded card with a soft shadow.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.card,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: Motion.medium,
      curve: Motion.ease,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14B98B6E),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return onTap == null ? card : Squish(child: card);
  }
}

/// Circular progress ring.
class Ring extends StatelessWidget {
  final double progress;
  final double size;
  final double stroke;
  final Color color;
  final Color track;
  final Widget? child;

  const Ring({
    super.key,
    required this.progress,
    required this.color,
    required this.track,
    this.size = 180,
    this.stroke = 16,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0, 1.0)),
      duration: Motion.slow,
      curve: Motion.emphasized,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v, color, track, stroke),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double p;
  final Color color;
  final Color track;
  final double stroke;

  _RingPainter(this.p, this.color, this.track, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, paint..color = track);
    if (p > 0) {
      canvas.drawArc(
        r,
        -math.pi / 2,
        math.pi * 2 * p,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.p != p || old.color != color || old.track != track;
}

/// Horizontal rounded progress bar with label.
class MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final Color color;
  final Color track;

  /// Replaces the "value / target g" text (e.g. for an upper limit).
  final String? amountText;

  /// [target] is a maximum: past it the bar and text turn red.
  final bool isLimit;

  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    required this.track,
    this.amountText,
    this.isLimit = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    final over = isLimit && value > target;
    final barColor = over ? AppColors.over : color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: headingFont,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              amountText ?? '${fmt0(value)} / ${fmt0(target)}g',
              style: TextStyle(
                fontSize: 12.5,
                color: over ? AppColors.over : AppColors.inkSoft,
                fontWeight: over ? FontWeight.w800 : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: p),
            duration: Motion.slow,
            curve: Motion.emphasized,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 10,
              color: barColor,
              backgroundColor: track,
            ),
          ),
        ),
      ],
    );
  }
}

enum MascotMood { happy, thinking, cheer, sleepy }

/// A small round peach buddy drawn in code (no image assets needed).
class Mascot extends StatelessWidget {
  final double size;
  final MascotMood mood;
  final Color color;

  /// Gentle idle float.
  final bool animate;

  const Mascot({
    super.key,
    this.size = 88,
    this.mood = MascotMood.happy,
    this.color = AppColors.peach,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final face = SizedBox(
      width: size,
      height: size,
      child: AnimatedSwitcher(
        duration: Motion.medium,
        switchInCurve: Motion.ease,
        transitionBuilder: (c, a) => ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(a),
          child: FadeTransition(opacity: a, child: c),
        ),
        child: CustomPaint(
          key: ValueKey(mood),
          size: Size.square(size),
          painter: _MascotPainter(mood, color),
        ),
      ),
    );
    return animate ? Floaty(amplitude: size / 30, child: face) : face;
  }
}

class _MascotPainter extends CustomPainter {
  final MascotMood mood;
  final Color color;
  _MascotPainter(this.mood, this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final body = Paint()..color = color;
    // Leaf sprout.
    final leaf = Paint()..color = AppColors.mint;
    canvas.save();
    canvas.translate(w * 0.56, w * 0.14);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.22, height: w * 0.11),
      leaf,
    );
    canvas.restore();
    // Body (slightly squished circle).
    canvas.drawOval(Rect.fromLTWH(w * 0.06, w * 0.16, w * 0.88, w * 0.8), body);
    // Highlight.
    canvas.drawOval(
      Rect.fromLTWH(w * 0.2, w * 0.26, w * 0.16, w * 0.1),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
    // Cheeks.
    final blush = Paint()
      ..color = const Color(0xFFFF5E7A).withValues(alpha: 0.35);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.26, w * 0.66),
        width: w * 0.15,
        height: w * 0.08,
      ),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.74, w * 0.66),
        width: w * 0.15,
        height: w * 0.08,
      ),
      blush,
    );
    // Eyes.
    final ink = Paint()
      ..color = AppColors.ink
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final eyeY = w * 0.55;
    switch (mood) {
      case MascotMood.happy:
      case MascotMood.thinking:
        canvas.drawCircle(
          Offset(w * 0.36, eyeY),
          w * 0.045,
          Paint()..color = AppColors.ink,
        );
        canvas.drawCircle(
          Offset(w * 0.64, eyeY),
          w * 0.045,
          Paint()..color = AppColors.ink,
        );
      case MascotMood.cheer:
        for (final x in [0.36, 0.64]) {
          final p = Path()
            ..moveTo(w * (x - 0.06), eyeY + w * 0.02)
            ..quadraticBezierTo(
              w * x,
              eyeY - w * 0.06,
              w * (x + 0.06),
              eyeY + w * 0.02,
            );
          canvas.drawPath(p, ink);
        }
      case MascotMood.sleepy:
        for (final x in [0.36, 0.64]) {
          canvas.drawLine(
            Offset(w * (x - 0.05), eyeY),
            Offset(w * (x + 0.05), eyeY),
            ink,
          );
        }
    }
    // Mouth.
    final mouthY = w * 0.68;
    if (mood == MascotMood.thinking) {
      canvas.drawCircle(
        Offset(w * 0.5, mouthY + w * 0.01),
        w * 0.025,
        ink..style = PaintingStyle.stroke,
      );
    } else {
      final m = Path()
        ..moveTo(w * 0.44, mouthY)
        ..quadraticBezierTo(
          w * 0.5,
          mouthY + w * (mood == MascotMood.cheer ? 0.08 : 0.05),
          w * 0.56,
          mouthY,
        );
      canvas.drawPath(m, ink..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.mood != mood || old.color != color;
}

/// Speech bubble next to the mascot.
class MascotSays extends StatelessWidget {
  final String text;
  final MascotMood mood;
  final double size;

  const MascotSays({
    super.key,
    required this.text,
    this.mood = MascotMood.happy,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Mascot(size: size, mood: mood),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x10B98B6E),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.45),
            ),
          ),
        ),
      ],
    );
  }
}

/// Big tappable choice tile used in onboarding.
class ChoiceTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color soft;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const ChoiceTile({
    super.key,
    required this.icon,
    required this.color,
    required this.soft,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Squish(
      child: AnimatedContainer(
        duration: Motion.fast,
        decoration: BoxDecoration(
          color: selected ? soft : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? color : AppColors.line,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: soft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: headingFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: Motion.fast,
                    child: Icon(Icons.check_circle_rounded, color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small colored pill.
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color soft;
  final IconData? icon;

  const Pill({
    super.key,
    required this.text,
    required this.color,
    required this.soft,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: headingFont,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stepper: [-] value [+]
class CountStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const CountStepper({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 14,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData i, VoidCallback? f) => IconButton.filledTonal(
      onPressed: f,
      icon: Icon(i),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.peachSoft,
        foregroundColor: AppColors.peach,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(
          Icons.remove_rounded,
          value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: headingFont,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
        ),
        btn(Icons.add_rounded, value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  /// A short explanation behind a small ? next to the title.
  final String? info;
  const SectionTitle(this.text, {super.key, this.trailing, this.info});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
    child: Row(
      children: [
        // Short titles: shrink a little on narrow screens rather than wrap.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(text, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        if (info != null) InfoTip(info!),
        const Spacer(),
        ?trailing,
      ],
    ),
  );
}

/// A small ? that opens a speech bubble with [message] pointing at it.
/// Tapping anywhere (or waiting a few seconds) closes it.
class InfoTip extends StatefulWidget {
  final String message;
  final double size;
  const InfoTip(this.message, {super.key, this.size = 17});

  @override
  State<InfoTip> createState() => _InfoTipState();
}

class _InfoTipState extends State<InfoTip> {
  OverlayEntry? _entry;

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  void _open() {
    if (_entry != null) return _close();
    final box = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (box == null || overlayBox == null) return;
    final at = box.localToGlobal(
      box.size.center(Offset.zero),
      ancestor: overlayBox,
    );
    final top = box.localToGlobal(Offset.zero, ancestor: overlayBox).dy;
    final bottom = top + box.size.height;
    final screen = overlayBox.size;
    // Below the ? unless that runs off the screen.
    final below = bottom + 160 < screen.height;
    _entry = OverlayEntry(
      builder: (_) => _InfoBubble(
        message: widget.message,
        anchorX: at.dx,
        anchorY: below ? bottom + 4 : top - 4,
        below: below,
        screen: screen,
        onClose: _close,
      ),
    );
    overlay.insert(_entry!);
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) _close();
    });
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.message,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _open,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.help_outline_rounded,
          size: widget.size,
          color: AppColors.inkSoft.withValues(alpha: 0.75),
        ),
      ),
    ),
  );
}

class _InfoBubble extends StatelessWidget {
  final String message;
  final double anchorX;
  final double anchorY;
  final bool below;
  final Size screen;
  final VoidCallback onClose;
  const _InfoBubble({
    required this.message,
    required this.anchorX,
    required this.anchorY,
    required this.below,
    required this.screen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    const margin = 16.0;
    const tail = 8.0;
    final width = math.min(300.0, screen.width - margin * 2);
    final left = (anchorX - width / 2).clamp(
      margin,
      screen.width - margin - width,
    );
    final bubble = Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
    final arrow = CustomPaint(
      size: const Size(16, tail),
      painter: _TailPainter(up: below),
    );
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClose,
          ),
        ),
        Positioned(
          left: left,
          top: below ? anchorY : null,
          bottom: below ? null : screen.height - anchorY,
          child: GestureDetector(
            onTap: onClose,
            child: FadeSlideIn(
              dy: below ? -4 : 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (below)
                    Padding(
                      padding: EdgeInsets.only(left: anchorX - left - 8),
                      child: arrow,
                    ),
                  bubble,
                  if (!below)
                    Padding(
                      padding: EdgeInsets.only(left: anchorX - left - 8),
                      child: arrow,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  final bool up;
  const _TailPainter({required this.up});

  @override
  void paint(Canvas canvas, Size size) {
    final path = up
        ? (Path()
            ..moveTo(0, size.height)
            ..lineTo(size.width / 2, 0)
            ..lineTo(size.width, size.height))
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width / 2, size.height)
            ..lineTo(size.width, 0));
    canvas.drawPath(path..close(), Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.up != up;
}
