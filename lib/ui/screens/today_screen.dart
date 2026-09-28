import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/entities.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'add_meal_sheet.dart';
import 'home_shell.dart';
import 'weight_sheet.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final plan = s.currentPlan!;
    final today = s.today;
    final totals = s.totalsOn(today);
    final meals = s.mealsOn(today).reversed.toList();
    final left = plan.targetKcal - totals.kcal;
    final locale = Localizations.localeOf(context).toString();
    final w = s.weightOn(today);
    final trend = s.trendWeight;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddMealSheet(context),
        backgroundColor: AppColors.peach,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          t.addMeal,
          style: const TextStyle(fontFamily: headingFont, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.MMMEd(locale).format(today),
                            style: const TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.todayGreeting,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                    const Mascot(size: 56),
                  ],
                ),
                const SizedBox(height: 16),
                if (s.checkinDue) ...[
                  SoftCard(
                    color: AppColors.peachSoft,
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    onTap: () => HomeShell.goTo(context, 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.celebration_rounded,
                          color: AppColors.peach,
                        ),
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
                  const SizedBox(height: 14),
                ],
                SoftCard(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    children: [
                      Ring(
                        progress: plan.targetKcal <= 0
                            ? 0
                            : totals.kcal / plan.targetKcal,
                        color: left >= 0
                            ? AppColors.peach
                            : const Color(0xFFFF6B6B),
                        track: AppColors.peachSoft,
                        size: 190,
                        stroke: 18,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fmt0(left.abs()),
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            Text(
                              left >= 0
                                  ? t.kcalLeft
                                  : '${t.kcal} ${t.kcalOver}',
                              style: const TextStyle(color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t.eatenOfTarget(
                          fmt0(totals.kcal),
                          fmt0(plan.targetKcal),
                        ),
                        style: const TextStyle(
                          fontFamily: headingFont,
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
                const SizedBox(height: 14),
                SoftCard(
                  padding: const EdgeInsets.all(16),
                  onTap: () => showWeightSheet(context),
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
                              t.weightToday,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            Text(
                              w == null ? t.logWeight : '${fmt1(w.kg)} kg',
                              style: const TextStyle(
                                fontFamily: headingFont,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (trend != null)
                        Pill(
                          text: t.trendKg(fmt1(trend)),
                          color: AppColors.sky,
                          soft: AppColors.skySoft,
                          icon: Icons.trending_flat_rounded,
                        ),
                      const SizedBox(width: 4),
                      Icon(
                        w == null
                            ? Icons.add_circle_rounded
                            : Icons.edit_rounded,
                        color: AppColors.sky,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SectionTitle(t.mealsTitle),
                if (meals.isEmpty)
                  SoftCard(
                    child: Column(
                      children: [
                        const Mascot(size: 60, mood: MascotMood.sleepy),
                        const SizedBox(height: 10),
                        Text(
                          t.noMealsYet,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.inkSoft,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SoftCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        for (var i = 0; i < meals.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, indent: 20, endIndent: 20),
                          _MealRow(meal: meals[i]),
                        ],
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
          style: const TextStyle(fontFamily: headingFont, fontSize: 17),
        ),
      ),
    );
  }
}
