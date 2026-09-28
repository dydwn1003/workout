import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../data/entities.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'labels.dart';
import 'weight_sheet.dart';
import 'workout_trend.dart';

class TrendScreen extends StatefulWidget {
  const TrendScreen({super.key});

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen> {
  var _range = 28; // days; 0 = all

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final all = s.trendPoints();
    final pts = _range == 0 || all.length <= _range
        ? all
        : all.sublist(all.length - _range);
    final weighIns = pts.where((p) => p.$2 != null).length;
    final goal = s.profile?.targetWeightKg;
    final trend = s.trendWeight;
    final change = s.weeklyTrendChange;
    final locale = Localizations.localeOf(context).toString();
    final comp = s.weights
        .where((w) => w.bodyFatPct != null || w.skeletalMuscleKg != null)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.trendTitle),
        actions: [
          IconButton(
            onPressed: () => showWeightSheet(context),
            icon: const Icon(
              Icons.add_circle_rounded,
              color: AppColors.sky,
              size: 30,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Row(
                children: [
                  for (final (days, label) in [
                    (28, t.range4w),
                    (84, t.range12w),
                    (0, t.rangeAll),
                  ]) ...[
                    ChoiceChip(
                      label: Text(label),
                      selected: _range == days,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _range = days),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              SoftCard(
                padding: const EdgeInsets.fromLTRB(12, 18, 16, 12),
                child: weighIns < 2
                    ? SizedBox(
                        height: 220,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Mascot(
                                size: 64,
                                mood: MascotMood.sleepy,
                                color: AppColors.sky,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                t.notEnoughData,
                                style: const TextStyle(
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 240,
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: WeightChartPainter(
                                pts,
                                goal,
                                DateFormat.Md(locale),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _legendDot(
                                AppColors.sky.withValues(alpha: 0.5),
                                t.legendRaw,
                              ),
                              const SizedBox(width: 14),
                              _legendLine(AppColors.peach, t.legendTrend),
                              if (goal != null) ...[
                                const SizedBox(width: 14),
                                _legendLine(AppColors.mint, t.legendGoal),
                              ],
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  t.trendExplain,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      t.currentTrend,
                      trend == null ? '—' : '${fmt1(trend)}kg',
                      AppColors.peach,
                      AppColors.peachSoft,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _stat(
                      t.weeklyChange,
                      change == null ? '—' : '${signed1(change)}kg',
                      AppColors.sky,
                      AppColors.skySoft,
                    ),
                  ),
                ],
              ),
              if (goal != null) ...[
                const SizedBox(height: 10),
                SoftCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: AppColors.mint),
                      const SizedBox(width: 10),
                      Text(
                        '${t.goalWeight} ${fmt1(goal)}kg',
                        style: const TextStyle(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Pill(
                        text: etaText(t, s.eta),
                        color: AppColors.mint,
                        soft: AppColors.mintSoft,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SectionTitle(t.workoutTrendTitle),
              const WorkoutTrendCard(),
              const SizedBox(height: 8),
              SectionTitle(t.bodyCompTitle),
              if (s.muscleWarning) ...[
                MascotSays(
                  text: t.muscleWarn,
                  mood: MascotMood.thinking,
                  size: 48,
                ),
                const SizedBox(height: 10),
              ],
              SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: comp.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          t.noBodyComp,
                          style: const TextStyle(color: AppColors.inkSoft),
                        ),
                      )
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                            child: Row(
                              children: [
                                const Expanded(child: SizedBox()),
                                Expanded(
                                  child: Text(
                                    t.bodyFatField,
                                    textAlign: TextAlign.end,
                                    style: _hdr,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    t.smmField,
                                    textAlign: TextAlign.end,
                                    style: _hdr,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final w in comp.reversed.take(6))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      DateFormat.MMMd(locale)
                                          .format(parseDateKey(w.date)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      w.bodyFatPct == null
                                          ? '—'
                                          : '${fmt1(w.bodyFatPct!)}%',
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontFamily: headingFont,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      w.skeletalMuscleKg == null
                                          ? '—'
                                          : '${fmt1(w.skeletalMuscleKg!)}kg',
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontFamily: headingFont,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              SectionTitle(t.weightHistory),
              SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (final w in s.weights.reversed.take(10))
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.only(
                          left: 20,
                          right: 8,
                        ),
                        title: Text(
                          DateFormat.MMMEd(locale).format(parseDateKey(w.date)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${fmt1(w.kg)} kg',
                              style: const TextStyle(
                                fontFamily: headingFont,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.inkSoft,
                              ),
                              onPressed: () => s.deleteWeight(w.date),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _hdr = TextStyle(fontSize: 12, color: AppColors.inkSoft);

  Widget _stat(String label, String value, Color c, Color soft) => SoftCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: c,
          ),
        ),
      ],
    ),
  );

  Widget _legendDot(Color c, String label) => Row(
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
      ),
    ],
  );

  Widget _legendLine(Color c, String label) => Row(
    children: [
      Container(
        width: 16,
        height: 4,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
      ),
    ],
  );
}

/// Raw weigh-in dots + EMA trend line + dashed goal line.
class WeightChartPainter extends CustomPainter {
  final List<(DateTime, double?, double?)> pts;
  final double? goal;
  final DateFormat dateFmt;

  WeightChartPainter(this.pts, this.goal, this.dateFmt);

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    const leftPad = 36.0;
    const bottomPad = 22.0;
    final chart = Rect.fromLTWH(
      leftPad,
      6,
      size.width - leftPad - 4,
      size.height - bottomPad - 6,
    );

    final values = <double>[
      for (final p in pts) ...[?p.$2, ?p.$3],
    ];
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    // Show the goal line if it's reasonably close to the data.
    final g = goal;
    final showGoal = g != null && g > lo - 8 && g < hi + 8;
    if (showGoal) {
      lo = math.min(lo, g);
      hi = math.max(hi, g);
    }
    lo = (lo - 0.5).floorToDouble();
    hi = (hi + 0.5).ceilToDouble();
    if (hi - lo < 2) hi = lo + 2;

    double x(int i) => chart.left + chart.width * i / (pts.length - 1);
    double y(double v) => chart.bottom - chart.height * (v - lo) / (hi - lo);

    // Grid + y labels.
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    final step = ((hi - lo) / 4).ceilToDouble().clamp(1, 100).toDouble();
    for (var v = lo; v <= hi + 0.001; v += step) {
      canvas.drawLine(
        Offset(chart.left, y(v)),
        Offset(chart.right, y(v)),
        grid,
      );
      _text(
        canvas,
        v.toStringAsFixed(0),
        Offset(0, y(v) - 7),
        11,
        AppColors.inkSoft,
        width: leftPad - 6,
        align: TextAlign.right,
      );
    }

    // X labels.
    for (final i in {0, (pts.length - 1) ~/ 2, pts.length - 1}) {
      final label = dateFmt.format(pts[i].$1);
      final dx = (x(i) - 20)
          .clamp(chart.left - 10, chart.right - 40)
          .toDouble();
      _text(
        canvas,
        label,
        Offset(dx, chart.bottom + 6),
        11,
        AppColors.inkSoft,
        width: 40,
        align: i == 0
            ? TextAlign.left
            : (i == pts.length - 1 ? TextAlign.right : TextAlign.center),
      );
    }

    // Goal line (dashed).
    if (showGoal) {
      final gp = Paint()
        ..color = AppColors.mint
        ..strokeWidth = 2;
      for (var dx = chart.left; dx < chart.right; dx += 10) {
        canvas.drawLine(
          Offset(dx, y(g)),
          Offset(math.min(dx + 5, chart.right), y(g)),
          gp,
        );
      }
    }

    // Raw dots.
    final dot = Paint()..color = AppColors.sky.withValues(alpha: 0.45);
    for (var i = 0; i < pts.length; i++) {
      final v = pts[i].$2;
      if (v != null) {
        canvas.drawCircle(Offset(x(i), y(v)), pts.length > 60 ? 2.5 : 3.5, dot);
      }
    }

    // Trend line with soft fill.
    final path = Path();
    var started = false;
    var firstX = 0.0;
    var lastX = 0.0;
    for (var i = 0; i < pts.length; i++) {
      final v = pts[i].$3;
      if (v == null) continue;
      if (!started) {
        path.moveTo(x(i), y(v));
        firstX = x(i);
        started = true;
      } else {
        path.lineTo(x(i), y(v));
      }
      lastX = x(i);
    }
    final fill = Path.from(path)
      ..lineTo(lastX, chart.bottom)
      ..lineTo(firstX, chart.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.peach.withValues(alpha: 0.18),
            AppColors.peach.withValues(alpha: 0),
          ],
        ).createShader(chart),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.peach
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final last = pts.last.$3;
    if (last != null) {
      canvas.drawCircle(
        Offset(x(pts.length - 1), y(last)),
        6,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(x(pts.length - 1), y(last)),
        4.5,
        Paint()..color = AppColors.peach,
      );
    }
  }

  void _text(
    Canvas c,
    String s,
    Offset o,
    double size,
    Color color, {
    double width = 60,
    TextAlign align = TextAlign.left,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: size,
          color: color,
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
  bool shouldRepaint(WeightChartPainter old) =>
      old.pts != pts || old.goal != goal;
}
