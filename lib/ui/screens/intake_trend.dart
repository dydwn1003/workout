import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/coach_engine/coach_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';

/// 섭취 칼로리 per day against the day's calorie target, for the trend
/// screen's range. Tap or drag to read a day.
class IntakeTrendCard extends StatefulWidget {
  /// Days shown, oldest first (same range as the weight chart).
  final List<DayLog> days;
  const IntakeTrendCard({super.key, required this.days});

  @override
  State<IntakeTrendCard> createState() => _IntakeTrendCardState();
}

class _IntakeTrendCardState extends State<IntakeTrendCard> {
  int? _sel;

  void _pick(Offset p, double width) {
    final n = widget.days.length;
    if (n == 0) return;
    final i = (p.dx / width * n).floor().clamp(0, n - 1);
    if (i != _sel) setState(() => _sel = i);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final locale = Localizations.localeOf(context).toString();
    final days = widget.days;
    final targets = [for (final d in days) s.planOn(d.date)?.targetKcal];
    final logged = [
      for (final d in days)
        if (d.intakeKcal != null) d.intakeKcal!,
    ];
    final loggedTargets = [
      for (var i = 0; i < days.length; i++)
        if (days[i].intakeKcal != null && targets[i] != null) targets[i]!,
    ];
    final avg = logged.isEmpty
        ? null
        : logged.reduce((a, b) => a + b) / logged.length;
    final avgTarget = loggedTargets.isEmpty
        ? null
        : loggedTargets.reduce((a, b) => a + b) / loggedTargets.length;
    final sel = _sel != null && _sel! < days.length ? _sel : null;

    String readout() {
      if (sel == null) return t.intakeTapHint;
      final d = days[sel];
      final eaten = d.intakeKcal;
      final target = targets[sel];
      return '${DateFormat.MMMEd(locale).format(d.date)} · '
          '${eaten == null ? t.intakeNotLogged : '${fmt0(eaten)} kcal'}'
          '${target == null ? '' : ' / ${t.intakeTarget} ${fmt0(target)}'}';
    }

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _stat(
                  t.intakeAvg,
                  avg == null ? '—' : '${fmt0(avg)} kcal',
                ),
              ),
              Expanded(
                child: _stat(
                  t.intakeAvgTarget,
                  avgTarget == null ? '—' : '${fmt0(avgTarget)} kcal',
                ),
              ),
              Expanded(
                child: _stat(
                  t.intakeLoggedDays,
                  '${logged.length}/${days.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: Motion.fast,
            child: Text(
              readout(),
              key: ValueKey(sel),
              style: TextStyle(
                fontSize: 12.5,
                color: sel == null ? AppColors.inkSoft : AppColors.ink,
                fontWeight: sel == null ? null : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, box) => GestureDetector(
              onTapDown: (e) => _pick(e.localPosition, box.maxWidth),
              onHorizontalDragUpdate: (e) =>
                  _pick(e.localPosition, box.maxWidth),
              child: SizedBox(
                height: 150,
                width: box.maxWidth,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Motion.slow,
                  curve: Motion.ease,
                  builder: (context, grow, _) => CustomPaint(
                    painter: _IntakePainter(
                      eaten: [for (final d in days) d.intakeKcal],
                      targets: targets,
                      selected: sel,
                      grow: grow,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (days.isNotEmpty)
            Row(
              children: [
                Text(
                  DateFormat.MMMd(locale).format(days.first.date),
                  style: _axis,
                ),
                const Spacer(),
                Text(
                  DateFormat.MMMd(locale).format(days.last.date),
                  style: _axis,
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.peach,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Text(t.intakeLegend, style: _axis),
              const SizedBox(width: 14),
              CustomPaint(size: const Size(16, 4), painter: _DashPainter()),
              const SizedBox(width: 5),
              Text(t.intakeTarget, style: _axis),
            ],
          ),
        ],
      ),
    );
  }

  static const _axis = TextStyle(fontSize: 12, color: AppColors.inkSoft);

  Widget _stat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: _axis),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    ],
  );
}

class _IntakePainter extends CustomPainter {
  final List<double?> eaten;
  final List<double?> targets;
  final int? selected;
  final double grow;
  _IntakePainter({
    required this.eaten,
    required this.targets,
    required this.selected,
    required this.grow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = eaten.length;
    if (n == 0) return;
    final top = [
      for (final v in eaten) ?v,
      for (final v in targets) ?v,
    ].fold(0.0, math.max);
    if (top <= 0) return;
    final maxY = top * 1.1;
    double y(double v) => size.height - v / maxY * size.height;
    final slot = size.width / n;
    const gap = 2.0;
    final barW = math.max(1.0, slot - gap);

    // Baseline.
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = AppColors.line
        ..strokeWidth = 1,
    );

    for (var i = 0; i < n; i++) {
      final v = eaten[i];
      if (v == null || v <= 0) continue;
      final h = (size.height - y(v)) * grow;
      final x = i * slot + gap / 2;
      final r = math.min(4.0, barW / 2);
      final dim = selected != null && selected != i;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, size.height - h, barW, h),
          topLeft: Radius.circular(r),
          topRight: Radius.circular(r),
        ),
        Paint()
          ..color = dim
              ? AppColors.peach.withValues(alpha: 0.35)
              : AppColors.peach,
      );
    }

    // Target: a dashed step line (the target can change at a check-in).
    final dash = Paint()
      ..color = AppColors.inkSoft
      ..strokeWidth = 1.5;
    for (var i = 0; i < n; i++) {
      final v = targets[i];
      if (v == null) continue;
      final yy = y(v);
      for (var x = i * slot; x < (i + 1) * slot; x += 6) {
        canvas.drawLine(
          Offset(x, yy),
          Offset(math.min(x + 3, (i + 1) * slot), yy),
          dash,
        );
      }
    }

    if (selected != null) {
      final cx = (selected! + 0.5) * slot;
      canvas.drawLine(
        Offset(cx, 0),
        Offset(cx, size.height),
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.25)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_IntakePainter old) =>
      old.grow != grow ||
      old.selected != selected ||
      old.eaten != eaten ||
      old.targets != targets;
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.inkSoft
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + 3, size.width), size.height / 2),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}
