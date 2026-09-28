import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/coach_engine/coach_engine.dart';
import '../../data/entities.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';
import 'labels.dart';

enum _Step { welcome, goal, body, target, pace, activity, result }

/// 6-step goal setup (plus a welcome/consent page). Also used to edit the
/// goal later with [editing] = true.
class OnboardingScreen extends StatefulWidget {
  final bool editing;
  const OnboardingScreen({super.key, this.editing = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  var _index = 0;
  var _consent = false;
  GoalType? _goal;
  Sex _sex = Sex.male;
  final _birth = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _bf = TextEditingController();
  final _smm = TextEditingController();
  final _targetW = TextEditingController();
  final _targetBf = TextEditingController();
  var _byBodyFat = false;
  Pace _pace = Pace.normal;
  int _strength = 3;
  int _cardio = 1;
  var _busy = false;
  var _forward = true;

  @override
  void initState() {
    super.initState();
    if (widget.editing) {
      final s = AppScope.read(context);
      final p = s.profile!;
      _consent = true;
      _goal = p.goalType;
      _sex = p.sex;
      _birth.text = '${p.birthYear}';
      _height.text = _trim(p.heightCm);
      final w = s.trendWeight ?? s.latestWeight?.kg;
      if (w != null) _weight.text = w.toStringAsFixed(1);
      final bf = s.latestBodyFat;
      if (bf != null) _bf.text = _trim(bf);
      if (p.targetWeightKg != null) {
        _targetW.text = p.targetWeightKg!.toStringAsFixed(1);
      }
      if (p.targetBodyFatPct != null) {
        _targetBf.text = _trim(p.targetBodyFatPct!);
        _byBodyFat = true;
      }
      _pace = p.pace;
      _strength = p.strengthPerWeek;
      _cardio = p.cardioPerWeek;
    }
    for (final c in [
      _birth,
      _height,
      _weight,
      _bf,
      _smm,
      _targetW,
      _targetBf,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  @override
  void dispose() {
    for (final c in [
      _birth,
      _height,
      _weight,
      _bf,
      _smm,
      _targetW,
      _targetBf,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<_Step> get _steps => [
    if (!widget.editing) _Step.welcome,
    _Step.goal,
    _Step.body,
    if (_goal != GoalType.maintain) ...[_Step.target, _Step.pace],
    _Step.activity,
    _Step.result,
  ];

  _Step get _step => _steps[_index.clamp(0, _steps.length - 1)];

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));

  double? get _currentBf {
    final v = _num(_bf);
    return v != null && v > 2 && v < 70 ? v : null;
  }

  double? get _targetWeight {
    if (_goal == GoalType.maintain) return null;
    if (_byBodyFat) {
      final w = _num(_weight);
      final t = _num(_targetBf);
      final cur = _currentBf;
      if (w == null || t == null || cur == null || t <= 2 || t >= 70) {
        return null;
      }
      return targetWeightFromBodyFat(
        weightKg: w,
        currentBodyFatPct: cur,
        targetBodyFatPct: t,
      );
    }
    final t = _num(_targetW);
    return t != null && t > 25 && t < 300 ? t : null;
  }

  bool get _canNext {
    switch (_step) {
      case _Step.welcome:
        return _consent;
      case _Step.goal:
        return _goal != null;
      case _Step.body:
        final y = _num(_birth);
        final h = _num(_height);
        final w = _num(_weight);
        return y != null &&
            y > 1900 &&
            y <= DateTime.now().year &&
            h != null &&
            h > 100 &&
            h < 250 &&
            w != null &&
            w > 25 &&
            w < 300;
      case _Step.target:
        return _targetWeight != null;
      case _Step.pace:
      case _Step.activity:
        return true;
      case _Step.result:
        return _issues.isEmpty;
    }
  }

  UserProfile get _profile => UserProfile(
    sex: _sex,
    birthYear: _num(_birth)!.round(),
    heightCm: _num(_height)!,
    goalType: _goal!,
    pace: _pace,
    strengthPerWeek: _strength,
    cardioPerWeek: _cardio,
    targetWeightKg: _targetWeight,
    targetBodyFatPct: _byBodyFat && _goal != GoalType.maintain
        ? _num(_targetBf)
        : null,
    createdAt: DateTime.now(),
  );

  List<GoalIssue> get _issues => validateGoal(
    profile: _profile.coachProfile,
    weightKg: _num(_weight)!,
    goal: _profile.coachGoal,
    today: DateTime.now(),
  );

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (_step == _Step.result) {
      setState(() => _busy = true);
      final state = AppScope.read(context);
      final smm = _num(_smm);
      await state.completeOnboarding(
        profile: _profile,
        weightKg: _num(_weight)!,
        bodyFatPct: _currentBf,
        skeletalMuscleKg: smm != null && smm > 5 && smm < 100 ? smm : null,
      );
      if (mounted && widget.editing) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _forward = true;
      _index++;
    });
  }

  Future<void> _demo() async {
    final state = AppScope.read(context);
    final korean = Localizations.localeOf(context).languageCode == 'ko';
    await state.loadDemoData(korean: korean);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final steps = _steps;
    final showHeader = _step != _Step.welcome;
    final progressIndex = widget.editing ? _index : _index - 1;
    final progressTotal = widget.editing ? steps.length : steps.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                if (showHeader)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () {
                            if (_index == 0) {
                              Navigator.of(context).maybePop();
                            } else {
                              setState(() {
                                _forward = false;
                                _index--;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Row(
                            children: [
                              for (var i = 0; i < progressTotal; i++)
                                Expanded(
                                  child: AnimatedContainer(
                                    duration: Motion.medium,
                                    curve: Motion.ease,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: i <= progressIndex
                                          ? AppColors.peach
                                          : AppColors.line,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 460),
                    reverseDuration: const Duration(milliseconds: 200),
                    switchInCurve: Motion.ease,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, ?current],
                    ),
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                          begin: Offset(_forward ? 0.06 : -0.06, 0),
                          end: Offset.zero,
                        ).animate(a),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: _buildStep(t),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _canNext && !_busy ? _next : null,
                          child: Text(
                            _step == _Step.welcome
                                ? t.getStarted
                                : _step == _Step.result
                                ? t.startApp
                                : t.next,
                          ),
                        ),
                      ),
                      if (_step == _Step.welcome) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _consent ? _demo : null,
                          child: Text(t.tryDemo),
                        ),
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

  Widget _title(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 20, top: 8),
    child: Text(s, style: Theme.of(context).textTheme.headlineMedium),
  );

  Widget _buildStep(L t) {
    switch (_step) {
      case _Step.welcome:
        return _welcome(t);
      case _Step.goal:
        return _goalStep(t);
      case _Step.body:
        return _bodyStep(t);
      case _Step.target:
        return _targetStep(t);
      case _Step.pace:
        return _paceStep(t);
      case _Step.activity:
        return _activityStep(t);
      case _Step.result:
        return _resultStep(t);
    }
  }

  Widget _welcome(L t) {
    final state = AppScope.of(context);
    final lang =
        state.settings.language ?? Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.peachSoft,
              side: const BorderSide(color: AppColors.line),
              visualDensity: VisualDensity.compact,
            ),
            segments: const [
              ButtonSegment(value: 'ko', label: Text('한국어')),
              ButtonSegment(value: 'en', label: Text('EN')),
            ],
            selected: {lang == 'en' ? 'en' : 'ko'},
            onSelectionChanged: (v) => state.updateSettings(
              state.settings.copyWith(language: () => v.first),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Center(child: Mascot(size: 140, mood: MascotMood.cheer)),
        const SizedBox(height: 28),
        Text(t.welcomeTitle, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 14),
        Text(
          t.welcomeBody,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 28),
        SoftCard(
          padding: const EdgeInsets.all(16),
          color: AppColors.butterSoft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFD49B1F),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.disclaimer,
                  style: const TextStyle(fontSize: 13.5, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _consent = !_consent),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _consent,
                  activeColor: AppColors.peach,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: (v) => setState(() => _consent = v ?? false),
                ),
                Expanded(
                  child: Text(
                    t.consentLabel,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _goalStep(L t) {
    Widget tile(GoalType g, IconData icon, Color c, Color soft) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ChoiceTile(
        icon: icon,
        color: c,
        soft: soft,
        title: goalLabel(t, g),
        subtitle: goalDesc(t, g),
        selected: _goal == g,
        onTap: () => setState(() => _goal = g),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(t.stepGoalTitle),
        tile(
          GoalType.lose,
          Icons.local_fire_department_rounded,
          AppColors.peach,
          AppColors.peachSoft,
        ),
        tile(
          GoalType.maintain,
          Icons.balance_rounded,
          AppColors.sky,
          AppColors.skySoft,
        ),
        tile(
          GoalType.gain,
          Icons.fitness_center_rounded,
          AppColors.mint,
          AppColors.mintSoft,
        ),
        tile(
          GoalType.recomp,
          Icons.auto_awesome_rounded,
          AppColors.lilac,
          AppColors.lilacSoft,
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, {bool decimal = true}) =>
      TextField(
        controller: c,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(labelText: label),
      );

  Widget _bodyStep(L t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(t.stepBodyTitle),
        SegmentedButton<Sex>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.peachSoft,
            side: const BorderSide(color: AppColors.line, width: 1.5),
            minimumSize: const Size(0, 50),
            textStyle: const TextStyle(
              fontFamily: headingFont,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          segments: [
            ButtonSegment(value: Sex.male, label: Text(t.male)),
            ButtonSegment(value: Sex.female, label: Text(t.female)),
          ],
          selected: {_sex},
          onSelectionChanged: (v) => setState(() => _sex = v.first),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _field(_birth, t.birthYear, decimal: false)),
            const SizedBox(width: 12),
            Expanded(child: _field(_height, t.heightCm)),
          ],
        ),
        const SizedBox(height: 12),
        _field(_weight, t.weightKg),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _field(_bf, t.bodyFatOptional)),
            const SizedBox(width: 12),
            Expanded(child: _field(_smm, t.smmOptional)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lightbulb_outline_rounded,
              size: 18,
              color: AppColors.inkSoft,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                t.bodyCompHint,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _targetStep(L t) {
    final tw = _targetWeight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(t.stepTargetTitle),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.peachSoft,
            side: const BorderSide(color: AppColors.line, width: 1.5),
            minimumSize: const Size(0, 50),
            textStyle: const TextStyle(
              fontFamily: headingFont,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          segments: [
            ButtonSegment(value: false, label: Text(t.targetByWeight)),
            ButtonSegment(
              value: true,
              label: Text(t.targetByBodyFat),
              enabled: _currentBf != null,
            ),
          ],
          selected: {_byBodyFat && _currentBf != null},
          onSelectionChanged: (v) => setState(() => _byBodyFat = v.first),
        ),
        const SizedBox(height: 16),
        if (_byBodyFat && _currentBf != null) ...[
          _field(_targetBf, t.targetBodyFatField),
          if (tw != null) ...[
            const SizedBox(height: 14),
            SoftCard(
              color: AppColors.lilacSoft,
              padding: const EdgeInsets.all(16),
              child: Text(
                t.targetBfResult(tw.toStringAsFixed(1)),
                style: const TextStyle(
                  fontFamily: headingFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ] else
          _field(_targetW, t.targetWeightField),
        if (_currentBf == null) ...[
          const SizedBox(height: 12),
          Text(
            t.targetBfNeedsCurrent,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
        ],
      ],
    );
  }

  Widget _paceStep(L t) {
    final w = _num(_weight) ?? 70;
    Widget tile(Pace p, IconData icon) {
      final pct = ratePctPerWeek(_goal!, p);
      final kg = pct / 100 * w;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ChoiceTile(
          icon: icon,
          color: AppColors.peach,
          soft: AppColors.peachSoft,
          title: paceLabel(t, p),
          subtitle: t.paceDesc(kg.toStringAsFixed(2), pct.toStringAsFixed(2)),
          selected: _pace == p,
          onTap: () => setState(() => _pace = p),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(t.stepPaceTitle),
        tile(Pace.relaxed, Icons.spa_rounded),
        tile(Pace.normal, Icons.directions_walk_rounded),
        tile(Pace.fast, Icons.directions_run_rounded),
        const SizedBox(height: 4),
        Text(
          t.paceHint,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.inkSoft,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _activityStep(L t) {
    Widget row(
      IconData icon,
      Color c,
      Color soft,
      String label,
      int v,
      ValueChanged<int> f,
    ) => SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                Text(
                  t.timesPerWeek,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          CountStepper(value: v, onChanged: f),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(t.stepActivityTitle),
        row(
          Icons.fitness_center_rounded,
          AppColors.mint,
          AppColors.mintSoft,
          t.strength,
          _strength,
          (v) => setState(() => _strength = v),
        ),
        const SizedBox(height: 12),
        row(
          Icons.directions_bike_rounded,
          AppColors.sky,
          AppColors.skySoft,
          t.cardio,
          _cardio,
          (v) => setState(() => _cardio = v),
        ),
        const SizedBox(height: 16),
        Text(
          t.activityHint,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.inkSoft,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _resultStep(L t) {
    final issues = _issues;
    final profile = _profile;
    final w = _num(_weight)!;
    final plan = initialPlan(
      profile: profile.coachProfile,
      goal: profile.coachGoal,
      weightKg: w,
      today: DateTime.now(),
      bodyFatPct: _currentBf,
    );
    final eta = profile.targetWeightKg == null
        ? null
        : etaWeeks(
            trend: [w],
            targetKg: profile.targetWeightKg!,
            plannedKgPerWeek: plannedKgPerWeek(
              profile.goalType,
              profile.pace,
              w,
            ),
          );
    final m = plan.macros;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(t.stepResultTitle),
        if (issues.isNotEmpty) ...[
          MascotSays(
            text: issues.map((i) => issueLabel(t, i)).join('\n'),
            mood: MascotMood.thinking,
          ),
        ] else ...[
          SoftCard(
            child: Column(
              children: [
                const Mascot(size: 72, mood: MascotMood.cheer),
                const SizedBox(height: 8),
                Text(
                  t.dailyTarget,
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
                CountUp(
                  value: m.kcal,
                  format: (v) => '${fmt0(v)} kcal',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _macroChip(
                      t.protein,
                      m.proteinG,
                      AppColors.mint,
                      AppColors.mintSoft,
                    ),
                    const SizedBox(width: 8),
                    _macroChip(
                      t.carbs,
                      m.carbsG,
                      const Color(0xFFD49B1F),
                      AppColors.butterSoft,
                    ),
                    const SizedBox(width: 8),
                    _macroChip(
                      t.fat,
                      m.fatG,
                      AppColors.lilac,
                      AppColors.lilacSoft,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  t.estTdee,
                  '${fmt0(plan.tdee)} kcal',
                  Icons.bolt_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoTile(
                  t.etaLabel,
                  profile.goalType == GoalType.maintain ? '—' : etaText(t, eta),
                  Icons.flag_rounded,
                ),
              ),
            ],
          ),
          if (plan.floorHit) ...[
            const SizedBox(height: 12),
            MascotSays(
              text: t.floorNotice(fmt0(kcalFloor(_sex))),
              mood: MascotMood.thinking,
              size: 48,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            t.resultNote,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _macroChip(String label, double g, Color c, Color soft) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: c,
              fontFamily: headingFont,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${fmt0(g)}g',
            style: const TextStyle(
              fontFamily: headingFont,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _infoTile(String label, String value, IconData icon) => SoftCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.peach),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ],
    ),
  );
}
