import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'intake_trend.dart';
import 'labels.dart';
import 'trend_sections.dart';
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
    final allLogs = s.dayLogs();
    final logs = _range == 0 || allLogs.length <= _range
        ? allLogs
        : allLogs.sublist(allLogs.length - _range);
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
            tooltip: t.logWeight,
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
                  const Spacer(),
                  InfoTip(t.infoChart),
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
                          _WeightChart(
                            key: ValueKey(_range),
                            pts: pts,
                            goal: goal,
                            locale: locale,
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
                      info: t.infoTrend,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _stat(
                      t.weeklyChange,
                      change == null ? '—' : '${signed1(change)}kg',
                      AppColors.sky,
                      AppColors.skySoft,
                      info: t.infoWeekly,
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
                      // Shrinks a little on a narrow phone rather than
                      // pushing the ETA pill off the card.
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${t.goalWeight} ${fmt1(goal)}kg',
                            style: const TextStyle(
                              fontFamily: headingFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      InfoTip(t.infoEta),
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
              SectionTitle(t.intakeTrendTitle, info: t.infoIntake),
              IntakeTrendCard(key: ValueKey(_range), days: logs),
              const SizedBox(height: 8),
              if (s.foodSwaps() case final swaps when swaps.isNotEmpty) ...[
                SectionTitle(t.swapsTitle, info: t.infoSwaps),
                FoodSwapsCard(swaps: swaps),
                const SizedBox(height: 8),
              ],
              SectionTitle(t.workoutTrendTitle, info: t.infoWorkout),
              const WorkoutTrendCard(),
              const SizedBox(height: 8),
              SectionTitle(t.bodyCompTitle, info: t.infoBodyComp),
              if (s.muscleWarning) ...[
                MascotSays(
                  text: t.muscleWarn,
                  mood: MascotMood.thinking,
                  size: 48,
                ),
                const SizedBox(height: 10),
              ],
              const BodyCompGuide(),
              const SizedBox(height: 10),
              BodyCompCard(entries: comp),
              const SizedBox(height: 8),
              SectionTitle(t.weightHistory, info: t.infoHistory),
              const WeightHistoryCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(
    String label,
    String value,
    Color c,
    Color soft, {
    String? info,
  }) => SoftCard(
    padding: const EdgeInsets.fromLTRB(16, 10, 8, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
            if (info != null) InfoTip(info, size: 15),
          ],
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
/// The weight chart plus a scrubber: tap or drag to put a vertical line on
/// a day and see that day's weight, trend, intake and workouts. The
/// selection stays after lifting the finger; tapping the same day clears it.
class _WeightChart extends StatefulWidget {
  final List<(DateTime, double?, double?)> pts;
  final double? goal;
  final String locale;
  const _WeightChart({
    super.key,
    required this.pts,
    required this.goal,
    required this.locale,
  });

  @override
  State<_WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<_WeightChart> {
  static const _height = 240.0;
  int? _sel;
  var _dragged = false;

  int _indexAt(double dx, double width) {
    final r = WeightChartPainter.chartRect(Size(width, _height));
    final f = ((dx - r.left) / r.width).clamp(0.0, 1.0);
    return (f * (widget.pts.length - 1)).round();
  }

  void _select(int i) {
    if (i == _sel) return;
    HapticFeedback.selectionClick();
    setState(() => _sel = i);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final sel = _sel;
        return Column(
          children: [
            // Tapping anywhere outside the chart closes the day's tooltip.
            TapRegion(
              onTapOutside: (_) {
                if (_sel != null) setState(() => _sel = null);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) {
                  final i = _indexAt(d.localPosition.dx, w);
                  if (i == _sel && !_dragged) {
                    setState(() => _sel = null);
                  } else {
                    _select(i);
                  }
                  _dragged = false;
                },
                onHorizontalDragStart: (d) {
                  _dragged = true;
                  _select(_indexAt(d.localPosition.dx, w));
                },
                onHorizontalDragUpdate: (d) =>
                    _select(_indexAt(d.localPosition.dx, w)),
                onHorizontalDragEnd: (_) => _dragged = false,
                child: SizedBox(
                  height: _height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: WeightChartPainter(
                            widget.pts,
                            widget.goal,
                            DateFormat.Md(widget.locale),
                            selected: sel,
                          ),
                        ),
                      ),
                      if (sel != null && sel < widget.pts.length)
                        _tooltip(context, t, sel, w),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: sel == null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        t.chartHint,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        );
      },
    );
  }

  Widget _tooltip(BuildContext context, L t, int i, double width) {
    final s = AppScope.of(context);
    final (day, raw, trend) = widget.pts[i];
    final meals = s.mealsOn(day);
    final eaten = s.totalsOn(day).kcal;
    final target = s.planOn(day)?.targetKcal;
    final minutes = s.workoutsOn(day).fold(0, (a, w) => a + w.minutes);
    final r = WeightChartPainter.chartRect(Size(width, _height));
    final x = r.left + r.width * i / math.max(1, widget.pts.length - 1);
    const tipW = 168.0;
    // Beside the line, on the roomier side, so the day's points stay visible.
    final left = (x < width / 2 ? x + 10 : x - 10 - tipW)
        .clamp(0.0, width - tipW)
        .toDouble();

    Widget row(String label, String value, Color c, {bool muted = false}) =>
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: muted ? Colors.white54 : Colors.white,
                ),
              ),
            ],
          ),
        );

    return Positioned(
      left: left,
      top: 0,
      width: tipW,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat.MMMEd(widget.locale).format(day),
                style: const TextStyle(
                  fontFamily: headingFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              row(
                t.tipWeight,
                raw == null ? t.tipNone : '${fmt1(raw)}kg',
                AppColors.sky,
                muted: raw == null,
              ),
              if (trend != null)
                row(t.tipTrend, '${fmt1(trend)}kg', AppColors.peach),
              row(
                t.tipIntake,
                meals.isEmpty
                    ? t.tipNone
                    : target == null
                    ? '${fmt0(eaten)} kcal'
                    : '${fmt0(eaten)} / ${fmt0(target)}',
                AppColors.butter,
                muted: meals.isEmpty,
              ),
              row(
                t.tipWorkout,
                minutes == 0 ? t.tipNone : t.tipMinutes('$minutes'),
                AppColors.mint,
                muted: minutes == 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WeightChartPainter extends CustomPainter {
  final List<(DateTime, double?, double?)> pts;
  final double? goal;
  final DateFormat dateFmt;
  final int? selected;

  WeightChartPainter(this.pts, this.goal, this.dateFmt, {this.selected});

  static const _leftPad = 36.0;
  static const _bottomPad = 22.0;

  /// The plotting area inside [size] (shared with the scrubber's hit test).
  static Rect chartRect(Size size) => Rect.fromLTWH(
    _leftPad,
    6,
    size.width - _leftPad - 4,
    size.height - _bottomPad - 6,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    const leftPad = _leftPad;
    final chart = chartRect(size);

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
    // Scrubber: vertical line and the selected day's points.
    final sel = selected;
    if (sel != null && sel < pts.length) {
      final sx = x(sel);
      canvas.drawLine(
        Offset(sx, chart.top),
        Offset(sx, chart.bottom),
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.35)
          ..strokeWidth = 1.5,
      );
      final raw = pts[sel].$2;
      if (raw != null) {
        canvas.drawCircle(Offset(sx, y(raw)), 6, Paint()..color = Colors.white);
        canvas.drawCircle(
          Offset(sx, y(raw)),
          4.5,
          Paint()..color = AppColors.sky,
        );
      }
      final tv = pts[sel].$3;
      if (tv != null) {
        canvas.drawCircle(Offset(sx, y(tv)), 6, Paint()..color = Colors.white);
        canvas.drawCircle(
          Offset(sx, y(tv)),
          4.5,
          Paint()..color = AppColors.peach,
        );
      }
    }
    final last = pts.last.$3;
    if (sel == null && last != null) {
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
      old.pts != pts || old.goal != goal || old.selected != selected;
}
