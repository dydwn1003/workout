import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/entities.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';

/// Every day since the start as a month calendar: ✓ logged, ✗ missed.
/// Resolves to the tapped day, if any.
Future<DateTime?> showLogCalendarSheet(BuildContext context) =>
    showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: Motion.sheet,
      builder: (_) => const LogCalendarSheet(),
    );

class LogCalendarSheet extends StatelessWidget {
  const LogCalendarSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final locale = Localizations.localeOf(context).toString();
    final today = s.today;
    final start = s.logStart;
    final logged = s.loggedDays;
    final total = today.difference(start).inDays + 1;
    var done = 0;
    for (var i = 0; i < total; i++) {
      if (logged.contains(
        dateKey(DateTime(start.year, start.month, start.day + i)),
      )) {
        done++;
      }
    }
    // Today isn't missed until it's over.
    final missed = total - done - (logged.contains(dateKey(today)) ? 0 : 1);
    final months = [
      for (
        var m = DateTime(today.year, today.month);
        !m.isBefore(DateTime(start.year, start.month));
        m = DateTime(m.year, m.month - 1)
      )
        m,
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Text(
            t.logCalendarTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pill(
                text: t.logCalendarDays('$done', '$total'),
                color: AppColors.peach,
                soft: AppColors.peachSoft,
              ),
              Pill(
                text: t.logCurrentStreak('${s.loggingStreak}'),
                color: AppColors.peach,
                soft: AppColors.peachSoft,
                icon: Icons.local_fire_department_rounded,
              ),
              Pill(
                text: t.logLongestStreak('${s.longestLoggingStreak}'),
                color: AppColors.mint,
                soft: AppColors.mintSoft,
              ),
              Pill(
                text: t.logMissedDays('$missed'),
                color: AppColors.inkSoft,
                soft: AppColors.line,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t.logCalendarHint,
            style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legend(_Mark.done, t.logLegendDone),
              const SizedBox(width: 14),
              _legend(_Mark.missed, t.logLegendMissed),
              const SizedBox(width: 14),
              _legend(_Mark.today, t.logLegendToday),
            ],
          ),
          for (final m in months) ...[
            const SizedBox(height: 18),
            _Month(
              month: m,
              start: start,
              today: today,
              logged: logged,
              locale: locale,
            ),
          ],
        ],
      ),
    );
  }

  Widget _legend(_Mark mark, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _DayMark(mark: mark, size: 18),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
      ),
    ],
  );
}

enum _Mark { done, missed, today, none }

class _Month extends StatelessWidget {
  final DateTime month;
  final DateTime start;
  final DateTime today;
  final Set<String> logged;
  final String locale;
  const _Month({
    required this.month,
    required this.start,
    required this.today,
    required this.logged,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    final lead = DateTime(month.year, month.month).weekday % 7; // Sunday first
    final sunday = DateTime(2024, 1, 7);
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              DateFormat.yMMMM(locale).format(month),
              style: const TextStyle(
                fontFamily: headingFont,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat.E(locale)
                          .format(sunday.add(Duration(days: i))),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.8,
            children: [
              for (var i = 0; i < lead; i++) const SizedBox.shrink(),
              for (var d = 1; d <= days; d++)
                _cell(context, DateTime(month.year, month.month, d)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, DateTime d) {
    final inRange = !d.isBefore(start) && !d.isAfter(today);
    final isToday = d == today;
    final mark = !inRange
        ? _Mark.none
        : logged.contains(dateKey(d))
        ? _Mark.done
        : isToday
        ? _Mark.today
        : _Mark.missed;
    final cell = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${d.day}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            color: inRange
                ? (isToday ? AppColors.peach : AppColors.ink)
                : AppColors.line,
          ),
        ),
        const SizedBox(height: 3),
        _DayMark(mark: mark, size: 26),
      ],
    );
    if (!inRange) return cell;
    return InkResponse(
      radius: 22,
      onTap: () => Navigator.of(context).pop(d),
      child: cell,
    );
  }
}

class _DayMark extends StatelessWidget {
  final _Mark mark;
  final double size;
  const _DayMark({required this.mark, required this.size});

  @override
  Widget build(BuildContext context) {
    final (bg, border, icon, fg) = switch (mark) {
      _Mark.done => (
        AppColors.peach,
        AppColors.peach,
        Icons.check_rounded,
        Colors.white,
      ),
      _Mark.missed => (
        AppColors.bg,
        AppColors.line,
        Icons.close_rounded,
        AppColors.inkSoft,
      ),
      _Mark.today => (AppColors.card, AppColors.peach, null, null),
      _Mark.none => (Colors.transparent, Colors.transparent, null, null),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: mark == _Mark.today ? 2 : 1.5),
      ),
      child: icon == null ? null : Icon(icon, size: size * 0.62, color: fg),
    );
  }
}
