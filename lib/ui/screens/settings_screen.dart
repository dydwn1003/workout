import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/coach_engine/coach_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'labels.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<bool> _confirm(
    BuildContext context,
    String msg, {
    bool destructive = false,
  }) async {
    final t = L.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(msg, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: destructive
                ? TextButton.styleFrom(foregroundColor: const Color(0xFFE5484D))
                : null,
            child: Text(destructive ? t.delete : t.confirm),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final p = s.profile!;
    final locale = Localizations.localeOf(context).toString();
    final lang = s.settings.language;

    Widget group(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title),
        SoftCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 20, endIndent: 20),
                children[i],
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );

    Widget icon(IconData i, Color c, Color soft) => Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(i, color: c, size: 20),
    );

    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              group(t.sectionProfile, [
                ListTile(
                  leading: const Mascot(size: 40),
                  title: Text(
                    goalLabel(t, p.goalType),
                    style: const TextStyle(
                      fontFamily: headingFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  subtitle: Text(
                    t.profileSummary(
                      p.sex == Sex.male ? t.male : t.female,
                      '${p.coachProfile.ageOn(s.today)}',
                      fmt0(p.heightCm),
                    ),
                  ),
                  trailing: p.targetWeightKg == null
                      ? null
                      : Pill(
                          text: '${fmt1(p.targetWeightKg!)}kg',
                          color: AppColors.mint,
                          soft: AppColors.mintSoft,
                        ),
                ),
                ListTile(
                  leading: icon(
                    Icons.flag_rounded,
                    AppColors.peach,
                    AppColors.peachSoft,
                  ),
                  title: Text(t.editGoal),
                  subtitle: Text(
                    t.editGoalDesc,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OnboardingScreen(editing: true),
                    ),
                  ),
                ),
                ListTile(
                  leading: icon(
                    Icons.bookmark_rounded,
                    AppColors.lilac,
                    AppColors.lilacSoft,
                  ),
                  title: Text(t.savedMealsManage),
                  trailing: Text(
                    '${s.savedMeals.length}',
                    style: const TextStyle(
                      fontFamily: headingFont,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () => _savedMeals(context),
                ),
              ]),
              group(t.sectionApp, [
                ListTile(
                  leading: icon(
                    Icons.translate_rounded,
                    AppColors.sky,
                    AppColors.skySoft,
                  ),
                  title: Text(t.language),
                  trailing: DropdownButton<String?>(
                    value: lang,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(16),
                    items: [
                      DropdownMenuItem(value: null, child: Text(t.langSystem)),
                      const DropdownMenuItem(value: 'ko', child: Text('한국어')),
                      const DropdownMenuItem(
                        value: 'en',
                        child: Text('English'),
                      ),
                    ],
                    onChanged: (v) => s.updateSettings(
                      s.settings.copyWith(language: () => v),
                    ),
                  ),
                ),
                ListTile(
                  leading: icon(
                    Icons.event_rounded,
                    AppColors.peach,
                    AppColors.peachSoft,
                  ),
                  title: Text(t.checkinDay),
                  trailing: DropdownButton<int>(
                    value: s.settings.checkinWeekday,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(16),
                    items: [
                      for (var d = 1; d <= 7; d++)
                        DropdownMenuItem(
                          value: d,
                          // 2024-01-01 is a Monday.
                          child: Text(
                            DateFormat.EEEE(locale)
                                .format(DateTime(2024, 1, d)),
                          ),
                        ),
                    ],
                    onChanged: (v) => s.updateSettings(
                      s.settings.copyWith(checkinWeekday: v),
                    ),
                  ),
                ),
                SwitchListTile(
                  secondary: icon(
                    Icons.notifications_rounded,
                    const Color(0xFFD49B1F),
                    AppColors.butterSoft,
                  ),
                  title: Text(t.notifications),
                  subtitle: Text(
                    t.notificationsDesc,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  value: s.settings.notifications,
                  activeThumbColor: AppColors.peach,
                  onChanged: (v) =>
                      s.updateSettings(s.settings.copyWith(notifications: v)),
                ),
                ListTile(
                  leading: icon(
                    Icons.straighten_rounded,
                    AppColors.mint,
                    AppColors.mintSoft,
                  ),
                  title: Text(t.units),
                  trailing: const Text(
                    'kg · kcal',
                    style: TextStyle(
                      fontFamily: headingFont,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ]),
              group(t.sectionData, [
                ListTile(
                  leading: icon(
                    Icons.science_rounded,
                    AppColors.lilac,
                    AppColors.lilacSoft,
                  ),
                  title: Text(t.demoData),
                  subtitle: Text(
                    t.demoDataDesc,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  onTap: () async {
                    if (!await _confirm(context, t.demoConfirm)) return;
                    if (!context.mounted) return;
                    await s.loadDemoData(
                      korean:
                          Localizations.localeOf(context).languageCode == 'ko',
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(t.demoLoaded)));
                  },
                ),
                if (s.settings.consentedAt != null)
                  ListTile(
                    leading: icon(
                      Icons.verified_user_rounded,
                      AppColors.mint,
                      AppColors.mintSoft,
                    ),
                    title: Text(
                      t.consentGiven(
                        DateFormat.yMMMd(locale)
                            .format(s.settings.consentedAt!),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ListTile(
                  leading: icon(
                    Icons.delete_forever_rounded,
                    const Color(0xFFE5484D),
                    const Color(0xFFFFE4E4),
                  ),
                  title: Text(
                    t.deleteAll,
                    style: const TextStyle(color: Color(0xFFE5484D)),
                  ),
                  onTap: () async {
                    if (await _confirm(
                      context,
                      t.deleteAllConfirm,
                      destructive: true,
                    )) {
                      await s.deleteAll();
                    }
                  },
                ),
              ]),
              group(t.sectionAbout, [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    t.disclaimer,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkSoft,
                      height: 1.5,
                    ),
                  ),
                ),
                ListTile(
                  leading: icon(
                    Icons.menu_book_rounded,
                    AppColors.mint,
                    AppColors.mintSoft,
                  ),
                  title: Text(
                    t.foodDataSource,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    t.foodDataSourceDesc,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
                ListTile(
                  title: Text(t.version),
                  trailing: const Text(
                    '0.1.0 (MVP)',
                    style: TextStyle(color: AppColors.inkSoft),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _savedMeals(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final t = L.of(ctx);
        return ListenableBuilder(
          listenable: AppScope.read(context),
          builder: (ctx, _) {
            final s = AppScope.read(context);
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.savedMealsManage,
                    style: Theme.of(ctx).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  if (s.savedMeals.isEmpty)
                    Text(
                      t.noSavedMeals,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        height: 1.5,
                      ),
                    ),
                  for (final m in s.savedMeals)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.name),
                      subtitle: Text('${fmt0(m.kcal)} kcal'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => s.deleteSavedMeal(m.id),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
