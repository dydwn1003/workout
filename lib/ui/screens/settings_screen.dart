import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/coach_engine/coach_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';
import 'labels.dart';
import 'onboarding_screen.dart';
import 'sign_in_sheet.dart';
import 'today_screen.dart' show showReminderResult;

/// Where the privacy policy is published (web/privacy.html on GitHub Pages).
const privacyPolicyUrl = String.fromEnvironment(
  'PRIVACY_URL',
  defaultValue: 'https://dydwn1003.github.io/workout/privacy.html',
);

/// Picks one of [options] (value, label) in a bottom sheet; null when
/// dismissed. The sheet closes with a short pause so the check lands first.
Future<T?> pickOption<T>(
  BuildContext context, {
  required String title,
  required T current,
  required List<(T, String)> options,
}) => showModalBottomSheet<T>(
  context: context,
  sheetAnimationStyle: Motion.sheet,
  builder: (ctx) =>
      _OptionSheet<T>(title: title, current: current, options: options),
);

class _OptionSheet<T> extends StatefulWidget {
  final String title;
  final T current;
  final List<(T, String)> options;
  const _OptionSheet({
    required this.title,
    required this.current,
    required this.options,
  });

  @override
  State<_OptionSheet<T>> createState() => _OptionSheetState<T>();
}

class _OptionSheetState<T> extends State<_OptionSheet<T>> {
  late T _selected = widget.current;

  Future<void> _pick(T v) async {
    setState(() => _selected = v);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (mounted) Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final (value, label) in widget.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Squish(
                  child: AnimatedContainer(
                    duration: Motion.medium,
                    curve: Motion.ease,
                    decoration: BoxDecoration(
                      color: value == _selected
                          ? AppColors.peachSoft
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: value == _selected
                            ? AppColors.peach
                            : AppColors.line,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        label,
                        style: const TextStyle(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      trailing: AnimatedScale(
                        scale: value == _selected ? 1 : 0,
                        duration: Motion.medium,
                        curve: Curves.easeOutBack,
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.peach,
                        ),
                      ),
                      onTap: () => _pick(value),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Current value of a setting with a chevron; the value cross-fades.
class _SettingValue extends StatelessWidget {
  final String text;
  const _SettingValue(this.text);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedSwitcher(
        duration: Motion.medium,
        switchInCurve: Motion.ease,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (c, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(a),
            child: c,
          ),
        ),
        child: Text(
          text,
          key: ValueKey(text),
          style: const TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 4),
      const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.inkSoft,
        size: 20,
      ),
    ],
  );
}

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
              if (s.auth != null)
                group(t.sectionAccount, [
                  if (!s.signedIn)
                    ListTile(
                      leading: icon(
                        Icons.cloud_sync_rounded,
                        AppColors.sky,
                        AppColors.skySoft,
                      ),
                      title: Text(t.signInCta),
                      subtitle: Text(t.signInBody),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showSignInSheet(context),
                    )
                  else ...[
                    ListTile(
                      leading: icon(
                        Icons.account_circle_rounded,
                        AppColors.sky,
                        AppColors.skySoft,
                      ),
                      title: Text(s.accountLabel ?? ''),
                      subtitle: Text(
                        s.syncing
                            ? t.syncing
                            : s.syncFailed
                            ? t.syncFailed
                            : s.lastSynced == null
                            ? ''
                            : t.syncedAt(
                                DateFormat.jm(locale).format(s.lastSynced!),
                              ),
                        style: TextStyle(
                          color: s.syncFailed ? const Color(0xFFE5484D) : null,
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: t.syncNow,
                        onPressed: s.syncing ? null : s.syncNow,
                        icon: const Icon(Icons.sync_rounded),
                      ),
                    ),
                    ListTile(
                      leading: icon(
                        Icons.logout_rounded,
                        AppColors.inkSoft,
                        AppColors.line,
                      ),
                      title: Text(t.signOut),
                      onTap: () async {
                        if (await _confirm(context, t.signOutConfirm)) {
                          await s.signOut();
                        }
                      },
                    ),
                    ListTile(
                      leading: icon(
                        Icons.person_remove_rounded,
                        const Color(0xFFE5484D),
                        const Color(0xFFFFE4E4),
                      ),
                      title: Text(
                        t.deleteAccount,
                        style: const TextStyle(color: Color(0xFFE5484D)),
                      ),
                      onTap: () async {
                        if (await _confirm(
                          context,
                          t.deleteAccountConfirm,
                          destructive: true,
                        )) {
                          await s.deleteAccount();
                        }
                      },
                    ),
                  ],
                ]),
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
                  trailing: _SettingValue(
                    {null: t.langSystem, 'ko': '한국어', 'en': 'English'}[lang] ??
                        t.langSystem,
                  ),
                  onTap: () async {
                    // '' = follow the system; null = sheet dismissed.
                    final v = await pickOption<String>(
                      context,
                      title: t.language,
                      current: lang ?? '',
                      options: [
                        ('', t.langSystem),
                        ('ko', '한국어'),
                        ('en', 'English'),
                      ],
                    );
                    // The app switches language after the sheet has closed.
                    if (v == null || v == (lang ?? '')) return;
                    s.updateSettings(
                      s.settings.copyWith(language: () => v.isEmpty ? null : v),
                    );
                  },
                ),
                ListTile(
                  leading: icon(
                    Icons.event_rounded,
                    AppColors.peach,
                    AppColors.peachSoft,
                  ),
                  title: Text(t.checkinDay),
                  // 2024-01-01 is a Monday.
                  trailing: _SettingValue(
                    DateFormat.EEEE(locale)
                        .format(DateTime(2024, 1, s.settings.checkinWeekday)),
                  ),
                  onTap: () async {
                    final v = await pickOption<int>(
                      context,
                      title: t.checkinDay,
                      current: s.settings.checkinWeekday,
                      options: [
                        for (var d = 1; d <= 7; d++)
                          (
                            d,
                            DateFormat.EEEE(locale)
                                .format(DateTime(2024, 1, d)),
                          ),
                      ],
                    );
                    if (v != null && v != s.settings.checkinWeekday) {
                      s.updateSettings(s.settings.copyWith(checkinWeekday: v));
                    }
                  },
                ),
                // Reminders are local notifications: apps only.
                if (s.remindersSupported)
                  SwitchListTile(
                    secondary: icon(
                      Icons.notifications_rounded,
                      const Color(0xFFD49B1F),
                      AppColors.butterSoft,
                    ),
                    title: Text(t.remindersTitle),
                    subtitle: Text(
                      t.remindersDesc,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    value: s.remindersOn,
                    activeThumbColor: AppColors.peach,
                    onChanged: (v) async {
                      final r = await s.setReminders(v);
                      if (v && context.mounted) showReminderResult(context, r);
                    },
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
                SwitchListTile(
                  secondary: icon(
                    Icons.insights_rounded,
                    AppColors.sky,
                    AppColors.skySoft,
                  ),
                  title: Text(t.usageAnalytics),
                  subtitle: Text(
                    t.usageAnalyticsDesc,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  value: s.settings.usageAnalytics,
                  activeThumbColor: AppColors.peach,
                  onChanged: (v) =>
                      s.updateSettings(s.settings.copyWith(usageAnalytics: v)),
                ),
                ListTile(
                  leading: icon(
                    Icons.privacy_tip_rounded,
                    AppColors.mint,
                    AppColors.mintSoft,
                  ),
                  title: Text(t.privacyPolicy),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse(privacyPolicyUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
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
