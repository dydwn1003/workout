import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/coach_engine/models.dart' show GoalType;
import '../../data/entities.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';
import 'weight_sheet.dart';

/// 체성분 추이: one tile per measure (latest value, change since the first
/// measurement, sparkline), then the latest few measurements.
class BodyCompCard extends StatelessWidget {
  /// Weigh-ins with body fat or muscle, oldest first.
  final List<WeightEntry> entries;
  const BodyCompCard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final locale = Localizations.localeOf(context).toString();
    if (entries.isEmpty) {
      return SoftCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const _IconBadge(
              icon: Icons.monitor_weight_outlined,
              color: AppColors.lilac,
              soft: AppColors.lilacSoft,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.noBodyComp,
                style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }
    final fat = [
      for (final w in entries)
        if (w.bodyFatPct != null) (parseDateKey(w.date), w.bodyFatPct!),
    ];
    final muscle = [
      for (final w in entries)
        if (w.skeletalMuscleKg != null)
          (parseDateKey(w.date), w.skeletalMuscleKg!),
    ];
    final recent = entries.reversed.take(4).toList();

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _CompTile(
                    label: t.bodyFat,
                    unit: '%',
                    deltaUnit: '%p',
                    points: fat,
                    color: AppColors.lilac,
                    soft: AppColors.lilacSoft,
                    lowerIsBetter: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompTile(
                    label: t.smm,
                    unit: 'kg',
                    deltaUnit: 'kg',
                    points: muscle,
                    color: AppColors.mint,
                    soft: AppColors.mintSoft,
                    lowerIsBetter: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              t.compRecent,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (final (i, w) in recent.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.MMMEd(locale).format(parseDateKey(w.date)),
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                  _MiniValue(
                    text: w.bodyFatPct == null
                        ? '—'
                        : '${fmt1(w.bodyFatPct!)}%',
                    color: AppColors.lilac,
                  ),
                  const SizedBox(width: 8),
                  _MiniValue(
                    text: w.skeletalMuscleKg == null
                        ? '—'
                        : '${fmt1(w.skeletalMuscleKg!)}kg',
                    color: AppColors.mint,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniValue extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniValue({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    child: Text(
      text,
      textAlign: TextAlign.end,
      style: TextStyle(
        fontFamily: headingFont,
        fontWeight: FontWeight.w800,
        fontSize: 14,
        color: text == '—' ? AppColors.inkSoft : color,
      ),
    ),
  );
}

class _CompTile extends StatelessWidget {
  final String label;
  final String unit;
  final String deltaUnit;
  final List<(DateTime, double)> points;
  final Color color;
  final Color soft;
  final bool lowerIsBetter;

  const _CompTile({
    required this.label,
    required this.unit,
    required this.deltaUnit,
    required this.points,
    required this.color,
    required this.soft,
    required this.lowerIsBetter,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final locale = Localizations.localeOf(context).toString();
    final last = points.isEmpty ? null : points.last.$2;
    final delta = points.length < 2 ? null : points.last.$2 - points.first.$2;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: soft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: last == null ? '—' : fmt1(last),
                  style: TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: last == null ? AppColors.inkSoft : color,
                  ),
                ),
                if (last != null)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontFamily: headingFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (delta != null)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DeltaChip(
                  delta: delta,
                  unit: deltaUnit,
                  lowerIsBetter: lowerIsBetter,
                ),
                Text(
                  t.compSince(DateFormat.MMMd(locale).format(points.first.$1)),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          const Spacer(),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: points.length < 2
                ? const SizedBox()
                : TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Motion.slow,
                    curve: Motion.ease,
                    builder: (context, v, _) => CustomPaint(
                      size: Size.infinite,
                      painter: _SparkPainter(
                        [for (final p in points) p.$2],
                        color,
                        v,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// "▼ 0.4kg": green when the change is the good direction, coral when not.
class DeltaChip extends StatelessWidget {
  final double delta;
  final String unit;

  /// null: neither direction is better (shown in blue).
  final bool? lowerIsBetter;

  const DeltaChip({
    super.key,
    required this.delta,
    required this.unit,
    required this.lowerIsBetter,
  });

  @override
  Widget build(BuildContext context) {
    final flat = delta.abs() < 0.05;
    final good = lowerIsBetter == null ? null : (delta < 0) == lowerIsBetter;
    final (c, soft) = flat
        ? (AppColors.inkSoft, AppColors.line)
        : good == null
        ? (AppColors.sky, AppColors.skySoft)
        : good
        ? (AppColors.mint, AppColors.mintSoft)
        : (AppColors.peach, AppColors.peachSoft);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        flat
            ? '– 0.0$unit'
            : '${delta < 0 ? '▼' : '▲'} ${fmt1(delta.abs())}$unit',
        style: TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          color: c,
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double progress;
  _SparkPainter(this.values, this.color, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final lo = values.reduce(math.min), hi = values.reduce(math.max);
    final span = math.max(hi - lo, 0.4); // flat-ish lines stay flat
    final mid = (hi + lo) / 2;
    const pad = 4.0;
    Offset at(int i) => Offset(
      values.length == 1 ? size.width : i / (values.length - 1) * size.width,
      size.height / 2 - (values[i] - mid) / span * (size.height - pad * 2),
    );

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      final a = at(i - 1), b = at(i);
      final cx = (a.dx + b.dx) / 2;
      line.cubicTo(cx, a.dy, cx, b.dy, b.dx, b.dy);
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
    if (progress >= 1) {
      final end = at(values.length - 1);
      canvas.drawCircle(end, 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(end, 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.progress != progress || old.values != values || old.color != color;
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color soft;
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: soft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color, size: 20),
  );
}

/// 체중 기록: newest first, with the change from the weigh-in before.
/// Tap a row to edit it, swipe it away to delete (with undo).
class WeightHistoryCard extends StatefulWidget {
  const WeightHistoryCard({super.key});

  @override
  State<WeightHistoryCard> createState() => _WeightHistoryCardState();
}

class _WeightHistoryCardState extends State<WeightHistoryCard> {
  static const _collapsed = 7;
  var _all = false;

  void _delete(WeightEntry w) {
    final s = AppScope.read(context);
    final t = L.of(context);
    s.deleteWeight(w.date);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(t.weightDeleted),
          action: SnackBarAction(
            label: t.undo,
            textColor: AppColors.peachSoft,
            onPressed: () => s.upsertWeight(w, notify: true),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final locale = Localizations.localeOf(context).toString();
    final ws = s.weights.reversed.toList();
    if (ws.isEmpty) {
      return SoftCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const _IconBadge(
              icon: Icons.scale_rounded,
              color: AppColors.sky,
              soft: AppColors.skySoft,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.noWeights,
                style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }
    final goal = s.profile?.goalType;
    final lowerIsBetter = switch (goal) {
      GoalType.lose || GoalType.recomp => true,
      GoalType.gain => false,
      _ => null,
    };
    final shown = _all ? ws : ws.take(_collapsed).toList();

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
            child: Text(
              t.weightRowHint,
              style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
            ),
          ),
          AnimatedSize(
            duration: Motion.medium,
            curve: Motion.ease,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                for (final (i, w) in shown.indexed)
                  _WeightRow(
                    key: ValueKey(w.date),
                    entry: w,
                    prev: i + 1 < ws.length ? ws[i + 1] : null,
                    lowerIsBetter: lowerIsBetter,
                    locale: locale,
                    divider: i > 0,
                    onTap: () =>
                        showWeightSheet(context, date: parseDateKey(w.date)),
                    onDelete: () => _delete(w),
                  ),
              ],
            ),
          ),
          if (ws.length > _collapsed)
            TextButton.icon(
              onPressed: () => setState(() => _all = !_all),
              icon: AnimatedRotation(
                turns: _all ? 0.5 : 0,
                duration: Motion.fast,
                child: const Icon(Icons.expand_more_rounded, size: 20),
              ),
              label: Text(_all ? t.showLess : t.showAllN('${ws.length}')),
              style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
            ),
        ],
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  final WeightEntry entry;
  final WeightEntry? prev;
  final bool? lowerIsBetter;
  final String locale;
  final bool divider;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WeightRow({
    super.key,
    required this.entry,
    required this.prev,
    required this.lowerIsBetter,
    required this.locale,
    required this.divider,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final d = parseDateKey(entry.date);
    final hasComp = entry.bodyFatPct != null || entry.skeletalMuscleKg != null;
    TextSpan compPart(String text, Color c) => TextSpan(
      children: [
        TextSpan(
          text: '● ',
          style: TextStyle(color: c, fontSize: 8),
        ),
        TextSpan(text: '$text  '),
      ],
    );

    return Dismissible(
      key: ValueKey('weight-${entry.date}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.peachSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.peach),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              border: divider
                  ? const Border(top: BorderSide(color: AppColors.line))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.skySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    DateFormat.E(locale).format(d),
                    style: const TextStyle(
                      fontFamily: headingFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.sky,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat.MMMd(locale).format(d),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasComp)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                if (entry.bodyFatPct != null)
                                  compPart(
                                    '${fmt1(entry.bodyFatPct!)}%',
                                    AppColors.lilac,
                                  ),
                                if (entry.skeletalMuscleKg != null)
                                  compPart(
                                    '${fmt1(entry.skeletalMuscleKg!)}kg',
                                    AppColors.mint,
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (prev != null) ...[
                  DeltaChip(
                    delta: entry.kg - prev!.kg,
                    unit: '',
                    lowerIsBetter: lowerIsBetter,
                  ),
                  const SizedBox(width: 10),
                ],
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: fmt1(entry.kg),
                        style: const TextStyle(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const TextSpan(
                        text: ' kg',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
