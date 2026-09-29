import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/coach_engine/coach_engine.dart';
import '../../data/entities.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';
import 'add_meal_sheet.dart';
import 'home_shell.dart';
import 'log_calendar_sheet.dart';
import 'weight_sheet.dart';
import 'workout_sheet.dart';
import 'workout_tips.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DateTime? _date; // null = today
  var _forward = true;

  void _shift(int days, DateTime today) {
    final cur = _date ?? today;
    final next = DateTime(cur.year, cur.month, cur.day + days);
    if (next.isAfter(today)) return;
    setState(() {
      _forward = days > 0;
      _date = next == today ? null : next;
    });
  }

  void _goTo(DateTime day, DateTime today) {
    final d = dayOnly(day);
    if (d.isAfter(today)) return;
    setState(() {
      _forward = !d.isBefore(_date ?? today);
      _date = d == today ? null : d;
    });
  }

  Future<void> _pickDate(AppState s) async {
    final today = s.today;
    final start = s.logStart;
    final cur = _date ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: cur.isBefore(start) ? start : cur,
      firstDate: start,
      lastDate: today,
      helpText: L.of(context).pickDate,
    );
    if (picked != null) _goTo(picked, s.today);
  }

  Future<void> _openLogCalendar(AppState s) async {
    final picked = await showLogCalendarSheet(context);
    if (picked != null) _goTo(picked, s.today);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final today = s.today;
    final date = _date ?? today;
    final isToday = _date == null;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddMealSheet(context, date: date),
        backgroundColor: AppColors.peach,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          t.addMeal,
          style: const TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                _header(context, t, s, date, isToday, locale),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  reverseDuration: const Duration(milliseconds: 160),
                  switchInCurve: Motion.ease,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (cur, prev) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...prev, ?cur],
                  ),
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                        begin: Offset(_forward ? 0.05 : -0.05, 0),
                        end: Offset.zero,
                      ).animate(a),
                      child: child,
                    ),
                  ),
                  child: _DayBody(
                    key: ValueKey(dateKey(date)),
                    date: date,
                    isToday: isToday,
                    onOpenLogCalendar: () => _openLogCalendar(s),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    L t,
    AppState s,
    DateTime date,
    bool isToday,
    String locale,
  ) {
    final canForward = !isToday;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _navBtn(
                    Icons.chevron_left_rounded,
                    () => _shift(-1, s.today),
                  ),
                  Tooltip(
                    message: t.pickDate,
                    child: InkWell(
                      onTap: () => _pickDate(s),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: Motion.fast,
                              child: Text(
                                DateFormat.MMMEd(locale).format(date),
                                key: ValueKey(date),
                                style: const TextStyle(
                                  color: AppColors.inkSoft,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                              color: AppColors.inkSoft,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: canForward ? 1 : 0.25,
                    duration: Motion.fast,
                    child: _navBtn(
                      Icons.chevron_right_rounded,
                      canForward ? () => _shift(1, s.today) : null,
                    ),
                  ),
                  AnimatedSize(
                    duration: Motion.medium,
                    curve: Motion.ease,
                    child: isToday
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Squish(
                              child: ActionChip(
                                label: Text(t.backToToday),
                                visualDensity: VisualDensity.compact,
                                onPressed: () => setState(() {
                                  _forward = true;
                                  _date = null;
                                }),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  isToday ? t.todayGreeting : t.pastDayGreeting,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
        ),
        Mascot(
          size: 56,
          mood: isToday ? MascotMood.happy : MascotMood.thinking,
        ),
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) => InkResponse(
    onTap: onTap,
    radius: 20,
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Icon(icon, color: AppColors.inkSoft, size: 22),
    ),
  );
}

class _DayBody extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final VoidCallback onOpenLogCalendar;
  const _DayBody({
    super.key,
    required this.date,
    required this.isToday,
    required this.onOpenLogCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final plan = s.planOn(date)!;
    final totals = s.totalsOn(date);
    final meals = s.mealsOn(date).reversed.toList();
    final left = plan.targetKcal - totals.kcal;
    final w = s.weightOn(date);
    final trend = s.trendWeight;
    var i = 0;
    Widget enter(Widget child) =>
        FadeSlideIn(delay: stagger(i++), child: child);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isToday && s.checkinDue) ...[
          enter(
            SoftCard(
              color: AppColors.peachSoft,
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              onTap: () => HomeShell.goTo(context, 2),
              child: Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: AppColors.peach),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.checkinDueBanner,
                      style: const TextStyle(fontSize: 14.5),
                    ),
                  ),
                  TextButton(
                    onPressed: () => HomeShell.goTo(context, 2),
                    child: Text(t.checkinGo),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        enter(
          SoftCard(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                Ring(
                  progress: plan.targetKcal <= 0
                      ? 0
                      : totals.kcal / plan.targetKcal,
                  color: left >= 0 ? AppColors.peach : const Color(0xFFFF6B6B),
                  track: AppColors.peachSoft,
                  size: 190,
                  stroke: 18,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CountUp(
                        value: left.abs(),
                        format: fmt0,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      Text(
                        left >= 0 ? t.kcalLeft : '${t.kcal} ${t.kcalOver}',
                        style: const TextStyle(color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  t.eatenOfTarget(fmt0(totals.kcal), fmt0(plan.targetKcal)),
                  style: const TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 18),
                MacroBar(
                  label: t.protein,
                  value: totals.proteinG,
                  target: plan.proteinG,
                  color: AppColors.mint,
                  track: AppColors.mintSoft,
                ),
                const SizedBox(height: 12),
                MacroBar(
                  label: t.carbs,
                  value: totals.carbsG,
                  target: plan.carbsG,
                  color: AppColors.butter,
                  track: AppColors.butterSoft,
                ),
                const SizedBox(height: 12),
                MacroBar(
                  label: t.fat,
                  value: totals.fatG,
                  target: plan.fatG,
                  color: AppColors.lilac,
                  track: AppColors.lilacSoft,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        enter(
          SoftCard(
            padding: const EdgeInsets.all(16),
            onTap: () => showWeightSheet(context, date: date),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.skySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.monitor_weight_rounded,
                    color: AppColors.sky,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? t.weightToday : t.weightOnDay,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      Text(
                        w == null ? t.logWeight : '${fmt1(w.kg)} kg',
                        style: const TextStyle(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isToday && trend != null)
                  Pill(
                    text: t.trendKg(fmt1(trend)),
                    color: AppColors.sky,
                    soft: AppColors.skySoft,
                    icon: Icons.trending_flat_rounded,
                  ),
                const SizedBox(width: 4),
                Icon(
                  w == null ? Icons.add_circle_rounded : Icons.edit_rounded,
                  color: AppColors.sky,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        enter(_WorkoutCard(date: date, isToday: isToday)),
        if (isToday) ...[
          const SizedBox(height: 14),
          enter(_StreakCard(onTap: onOpenLogCalendar)),
        ],
        const SizedBox(height: 10),
        SectionTitle(isToday ? t.mealsTitle : t.mealsOnDay),
        if (meals.isEmpty) ...[
          enter(
            SoftCard(
              child: Column(
                children: [
                  const Mascot(size: 60, mood: MascotMood.sleepy),
                  const SizedBox(height: 10),
                  Text(
                    isToday ? t.noMealsYet : t.noMealsPast,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        for (final slot in MealSlot.values) ...[
          enter(
            _SlotCard(
              slot: slot,
              date: date,
              meals: meals
                  .where((m) => m.slot == slot)
                  .toList()
                  .reversed
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  final MealSlot slot;
  final DateTime date;
  final List<Meal> meals;
  const _SlotCard({
    required this.slot,
    required this.date,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final kcal = meals.fold(0.0, (a, m) => a + m.kcal);
    final (color, soft) = slotColors(slot);
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: soft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(slotIcon(slot), size: 18, color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  slotLabel(t, slot),
                  style: const TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: Motion.medium,
                  child: Text(
                    meals.isEmpty ? '—' : '${fmt0(kcal)} kcal',
                    key: ValueKey(kcal.round()),
                    style: const TextStyle(
                      fontFamily: headingFont,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: t.addMeal,
                  onPressed: () =>
                      showAddMealSheet(context, date: date, slot: slot),
                  icon: Icon(Icons.add_circle_rounded, color: color, size: 28),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: Motion.medium,
            curve: Motion.ease,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                for (final m in meals) ...[
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _MealRow(meal: m),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  const _WorkoutCard({required this.date, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final list = s.workoutsOn(date);
    final tips = isToday ? s.workoutTips() : const <WorkoutTip>[];
    Widget add(WorkoutType type, IconData icon, Color c, Color soft) => Squish(
      child: Material(
        color: soft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showWorkoutSheet(context, date: date, type: type),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: c),
                const SizedBox(width: 4),
                Text(
                  workoutLabel(t, type),
                  style: TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: c,
                  ),
                ),
                Icon(Icons.add_rounded, size: 16, color: c),
              ],
            ),
          ),
        ),
      ),
    );
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isToday ? t.workoutsTitle : t.workoutsOnDay,
                  style: const TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              add(
                WorkoutType.strength,
                Icons.fitness_center_rounded,
                AppColors.mint,
                AppColors.mintSoft,
              ),
              const SizedBox(width: 6),
              add(
                WorkoutType.cardio,
                Icons.directions_run_rounded,
                AppColors.sky,
                AppColors.skySoft,
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: Motion.medium,
            curve: Motion.ease,
            alignment: Alignment.topLeft,
            child: list.isEmpty
                ? Text(
                    t.noWorkouts,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkSoft,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final w in list)
                        _WorkoutChip(
                          workout: w,
                          onDelete: () {
                            s.deleteWorkout(w.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t.workoutDeleted)),
                            );
                          },
                        ),
                    ],
                  ),
          ),
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            WorkoutTipRow(tip: tips.first),
          ],
        ],
      ),
    );
  }
}

class _WorkoutChip extends StatelessWidget {
  final Workout workout;
  final VoidCallback onDelete;
  const _WorkoutChip({required this.workout, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final strength = workout.type == WorkoutType.strength;
    final c = strength ? AppColors.mint : AppColors.sky;
    return FadeSlideIn(
      dy: 6,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        decoration: BoxDecoration(
          color: strength ? AppColors.mintSoft : AppColors.skySoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              strength
                  ? Icons.fitness_center_rounded
                  : Icons.directions_run_rounded,
              size: 16,
              color: c,
            ),
            const SizedBox(width: 6),
            Text(
              '${workoutLabel(t, workout.type)} · ${t.minutesN('${workout.minutes}')}',
              style: TextStyle(
                fontFamily: headingFont,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: c,
              ),
            ),
            InkResponse(
              onTap: onDelete,
              radius: 16,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 14, color: c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final VoidCallback onTap;
  const _StreakCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final log = s.weekLog();
    final streak = s.loggingStreak;
    final mealDays = log.where((d) => d.$2).length;
    final weighs = log.where((d) => d.$3).length;
    final ready = mealDays >= 5 && weighs >= 3;
    final locale = Localizations.localeOf(context).toString();
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.peach,
                size: 22,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  streak > 0 ? t.streakTitle('$streak') : t.streakZero,
                  style: const TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkSoft,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < log.length; i++)
                Expanded(
                  child: FadeSlideIn(
                    delay: Duration(milliseconds: 200 + 50 * i),
                    dy: 8,
                    child: _DayDot(
                      label: DateFormat.E(locale).format(log[i].$1),
                      meal: log[i].$2,
                      weight: log[i].$3,
                      workout: log[i].$4,
                      today: i == log.length - 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pill(
                text: t.weekMeals('$mealDays'),
                color: AppColors.peach,
                soft: AppColors.peachSoft,
              ),
              Pill(
                text: t.weekWeighs('$weighs'),
                color: AppColors.sky,
                soft: AppColors.skySoft,
              ),
              Pill(
                text: t.weekWorkouts('${s.weekWorkouts}'),
                color: AppColors.mint,
                soft: AppColors.mintSoft,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ready ? t.weekLogReady : t.weekLogHint,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: ready ? AppColors.mint : AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final bool meal;
  final bool weight;
  final bool workout;
  final bool today;
  const _DayDot({
    required this.label,
    required this.meal,
    required this.weight,
    required this.workout,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final full = meal && weight;
    final any = meal || weight || workout;
    return Column(
      children: [
        AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.ease,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: full
                ? AppColors.peach
                : (any ? AppColors.peachSoft : AppColors.bg),
            shape: BoxShape.circle,
            border: Border.all(
              color: today ? AppColors.peach : AppColors.line,
              width: today ? 2 : 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (meal)
                Icon(
                  Icons.restaurant_rounded,
                  size: 12,
                  color: full ? Colors.white : AppColors.peach,
                ),
              if (weight)
                Icon(
                  Icons.monitor_weight_rounded,
                  size: 12,
                  color: full ? Colors.white : AppColors.sky,
                ),
              // Only room for two icons; workouts show when one is free.
              if (workout && !(meal && weight))
                Icon(
                  Icons.fitness_center_rounded,
                  size: 12,
                  color: full ? Colors.white : AppColors.mint,
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: today ? AppColors.ink : AppColors.inkSoft,
            fontWeight: today ? FontWeight.w800 : bodyWeight,
          ),
        ),
      ],
    );
  }
}

class _MealRow extends StatelessWidget {
  final Meal meal;
  const _MealRow({required this.meal});

  IconData get _icon => switch (meal.source) {
    MealSource.photo => Icons.photo_camera_rounded,
    MealSource.text => Icons.edit_note_rounded,
    MealSource.saved => Icons.bookmark_rounded,
    MealSource.manual => Icons.restaurant_rounded,
    MealSource.search => Icons.search_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.read(context);
    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.peachSoft,
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.peach),
      ),
      onDismissed: (_) {
        s.deleteMeal(meal.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.mealDeleted),
            action: SnackBarAction(
              label: t.undo,
              textColor: AppColors.peachSoft,
              onPressed: () => s.addMeal(
                name: meal.name,
                kcal: meal.kcal,
                proteinG: meal.proteinG,
                carbsG: meal.carbsG,
                fatG: meal.fatG,
                source: meal.source,
                edited: meal.edited,
                date: parseDateKey(meal.date),
              ),
            ),
          ),
        );
      },
      child: ListTile(
        onTap: () => showEditMealSheet(context, meal),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: slotColors(meal.slot).$2,
          child: Icon(_icon, color: slotColors(meal.slot).$1, size: 20),
        ),
        title: Text(meal.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${meal.portion ?? DateFormat.Hm().format(meal.time)} · ${t.protein} ${fmt0(meal.proteinG)}g · ${t.carbs} ${fmt0(meal.carbsG)}g · ${t.fat} ${fmt0(meal.fatG)}g',
          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          fmt0(meal.kcal),
          style: const TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}
