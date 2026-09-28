import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';

/// Weekly training sessions (stacked strength/cardio bars) for the last
/// 8 weeks, with the profile's planned sessions as a dashed line.
class WorkoutTrendCard extends StatelessWidget {
  const WorkoutTrendCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final weeks = s.workoutWeeks();
    final p = s.profile!;
    final planned = p.strengthPerWeek + p.cardioPerWeek;
    final last = weeks.last;
    final last4 = weeks.sublist(weeks.length - 4);
    final avg = last4.fold(0, (a, w) => a + w.sessions) / 4;
    final locale = Localizations.localeOf(context).toString();
    final hasData = weeks.any((w) => w.sessions > 0);

    Widget stat(String label, String value, Color c) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: headingFont,
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: c,
            ),
          ),
        ],
      ),
    );

    Widget legend(Color c, String label, {bool dashed = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dashed ? 16 : 10,
          height: dashed ? 3 : 10,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
        ),
      ],
    );

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: !hasData
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                t.noWorkoutData,
                style: const TextStyle(color: AppColors.inkSoft),
              ),
            )
          : Column(
              children: [
                Row(
                  children: [
                    stat(
                      t.workoutThisWeek,
                      t.workoutThisWeekValue(
                        '${last.sessions}',
                        '${last.minutes}',
                      ),
                      AppColors.mint,
                    ),
                    stat(
                      t.workoutAvg4w,
                      t.workoutAvgValue(avg.toStringAsFixed(1)),
                      AppColors.sky,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 150,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Motion.slow,
                    curve: Motion.emphasized,
                    builder: (context, v, _) => CustomPaint(
                      size: Size.infinite,
                      painter: _WorkoutBarsPainter(
                        weeks,
                        planned,
                        v,
                        DateFormat.Md(locale),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    legend(AppColors.mint, t.strength),
                    legend(AppColors.sky, t.cardio),
                    legend(AppColors.peach, t.legendPlanned, dashed: true),
                  ],
                ),
              ],
            ),
    );
  }
}

class _WorkoutBarsPainter extends CustomPainter {
  final List<WorkoutWeek> weeks;
  final int planned;
  final double progress;
  final DateFormat fmt;

  _WorkoutBarsPainter(this.weeks, this.planned, this.progress, this.fmt);

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 22.0, bottomPad = 20.0, topPad = 6.0;
    final chart = Rect.fromLTRB(
      leftPad,
      topPad,
      size.width,
      size.height - bottomPad,
    );
    final maxV = math.max(
      planned,
      weeks.map((w) => w.sessions).fold(0, math.max),
    );
    final top = math.max(4, (maxV + 1)).toDouble();
    double y(num v) => chart.bottom - chart.height * v / top;

    // Grid + y labels at 0, half, top.
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (final v in {0, (top / 2).round(), top.round()}) {
      canvas.drawLine(
        Offset(chart.left, y(v)),
        Offset(chart.right, y(v)),
        grid,
      );
      _text(
        canvas,
        '$v',
        Offset(0, y(v) - 7),
        width: leftPad - 6,
        align: TextAlign.right,
      );
    }

    final slot = chart.width / weeks.length;
    final barW = math.min(22.0, slot * 0.55);
    for (var i = 0; i < weeks.length; i++) {
      final w = weeks[i];
      // Stagger bar growth left to right.
      final local = ((progress * 1.4) - i * 0.05).clamp(0.0, 1.0);
      final cx = chart.left + slot * (i + 0.5);
      final sH = chart.height * w.strength / top * local;
      final cH = chart.height * w.cardio / top * local;
      final r = const Radius.circular(7);
      if (w.cardio > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(cx - barW / 2, chart.bottom - sH - cH, barW, cH),
            topLeft: r,
            topRight: r,
            bottomLeft: w.strength == 0 ? r : Radius.zero,
            bottomRight: w.strength == 0 ? r : Radius.zero,
          ),
          Paint()..color = AppColors.sky,
        );
      }
      if (w.strength > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(cx - barW / 2, chart.bottom - sH, barW, sH),
            topLeft: w.cardio == 0 ? r : Radius.zero,
            topRight: w.cardio == 0 ? r : Radius.zero,
            bottomLeft: r,
            bottomRight: r,
          ),
          Paint()..color = AppColors.mint,
        );
      }
      if (i == 0 || i == weeks.length - 1 || i == weeks.length ~/ 2) {
        _text(
          canvas,
          fmt.format(w.start),
          Offset(cx - 24, chart.bottom + 6),
          width: 48,
          align: TextAlign.center,
        );
      }
    }

    if (planned > 0) {
      final py = y(planned);
      final dash = Paint()
        ..color = AppColors.peach
        ..strokeWidth = 2;
      for (var dx = chart.left; dx < chart.right; dx += 9) {
        canvas.drawLine(
          Offset(dx, py),
          Offset(math.min(dx + 5, chart.right), py),
          dash,
        );
      }
    }
  }

  void _text(
    Canvas c,
    String s,
    Offset o, {
    double width = 40,
    TextAlign align = TextAlign.left,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.inkSoft,
          fontFamily: bodyFont,
          fontWeight: bodyWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(c, o);
  }

  @override
  bool shouldRepaint(_WorkoutBarsPainter old) =>
      old.progress != progress || old.weeks != weeks || old.planned != planned;
}
