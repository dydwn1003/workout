import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/entities.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';
import 'add_meal_sheet.dart';
import 'home_shell.dart';
import 'weight_sheet.dart';

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
  const _DayBody({super.key, required this.date, required this.isToday});

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
        if (isToday) ...[
          const SizedBox(height: 14),
          enter(const _StreakCard()),
        ],
        const SizedBox(height: 10),
        SectionTitle(isToday ? t.mealsTitle : t.mealsOnDay),
        if (meals.isEmpty)
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
          )
        else
          enter(
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (var j = 0; j < meals.length; j++) ...[
                    if (j > 0)
                      const Divider(height: 1, indent: 20, endIndent: 20),
                    _MealRow(meal: meals[j]),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard();

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
                      today: i == log.length - 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Pill(
                text: t.weekMeals('$mealDays'),
                color: AppColors.peach,
                soft: AppColors.peachSoft,
              ),
              const SizedBox(width: 6),
              Pill(
                text: t.weekWeighs('$weighs'),
                color: AppColors.sky,
                soft: AppColors.skySoft,
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
  final bool today;
  const _DayDot({
    required this.label,
    required this.meal,
    required this.weight,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final full = meal && weight;
    final any = meal || weight;
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
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: today ? AppColors.ink : AppColors.inkSoft,
            fontWeight: today ? FontWeight.w800 : FontWeight.w400,
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
          backgroundColor: AppColors.peachSoft,
          child: Icon(_icon, color: AppColors.peach, size: 20),
        ),
        title: Text(meal.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${DateFormat.Hm().format(meal.time)} · ${t.protein} ${fmt0(meal.proteinG)}g · ${t.carbs} ${fmt0(meal.carbsG)}g · ${t.fat} ${fmt0(meal.fatG)}g',
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
