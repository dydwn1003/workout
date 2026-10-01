import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/entities.dart';
import '../../data/food.dart';
import '../../data/food_estimator.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';

String slotLabel(L t, MealSlot s) => switch (s) {
  MealSlot.breakfast => t.slotBreakfast,
  MealSlot.lunch => t.slotLunch,
  MealSlot.dinner => t.slotDinner,
  MealSlot.snack => t.slotSnack,
};

/// (color, soft background) of a meal slot.
(Color, Color) slotColors(MealSlot s) => switch (s) {
  MealSlot.breakfast => (AppColors.breakfast, AppColors.breakfastSoft),
  MealSlot.lunch => (AppColors.lunch, AppColors.lunchSoft),
  MealSlot.dinner => (AppColors.dinner, AppColors.dinnerSoft),
  MealSlot.snack => (AppColors.snack, AppColors.snackSoft),
};

IconData slotIcon(MealSlot s) => switch (s) {
  MealSlot.breakfast => Icons.wb_twilight_rounded,
  MealSlot.lunch => Icons.wb_sunny_rounded,
  MealSlot.dinner => Icons.nightlight_round,
  MealSlot.snack => Icons.cookie_rounded,
};

/// [replacing]: the first food added replaces this meal and closes the sheet.
/// 식사 기록 on the today screen: pick 아침/점심/저녁/간식 first (the one
/// for the time of day is highlighted), then log into it.
Future<void> showSlotThenAddMeal(BuildContext context, {DateTime? date}) async {
  final t = L.of(context);
  final now = MealSlot.forTime(DateTime.now());
  final slot = await showModalBottomSheet<MealSlot>(
    context: context,
    sheetAnimationStyle: Motion.sheet,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 14),
              child: Text(
                t.pickSlot,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.1,
              children: [
                for (final s in MealSlot.values)
                  Squish(
                    child: Material(
                      color: slotColors(s).$2,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(ctx, s),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: s == now
                                ? Border.all(color: slotColors(s).$1, width: 2)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(slotIcon(s), color: slotColors(s).$1),
                              const SizedBox(width: 8),
                              Text(
                                slotLabel(t, s),
                                style: TextStyle(
                                  fontFamily: headingFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: slotColors(s).$1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (slot == null || !context.mounted) return;
  await showAddMealSheet(context, date: date, slot: slot);
}

Future<void> showAddMealSheet(
  BuildContext context, {
  DateTime? date,
  MealSlot? slot,
  Meal? replacing,
}) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  sheetAnimationStyle: Motion.sheet,
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.92,
    child: AddMealSheet(date: date, slot: slot, replacing: replacing),
  ),
);

/// Deletes [meal] and offers to undo it in a snackbar.
void deleteMealWithUndo(BuildContext context, Meal meal) {
  final s = AppScope.read(context);
  final t = L.of(context);
  final messenger = ScaffoldMessenger.of(context);
  s.deleteMeal(meal.id);
  messenger.showSnackBar(
    SnackBar(
      content: Text(t.mealDeleted),
      action: SnackBarAction(
        label: t.undo,
        textColor: AppColors.peachSoft,
        onPressed: () => s.restoreMeal(meal),
      ),
    ),
  );
}

Future<void> showEditMealSheet(BuildContext context, Meal meal) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: Motion.sheet,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      L.of(ctx).editMeal,
                      style: Theme.of(ctx).textTheme.headlineSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showAddMealSheet(
                        context,
                        date: parseDateKey(meal.date),
                        slot: meal.slot,
                        replacing: meal,
                      );
                    },
                    icon: const Icon(Icons.search_rounded, size: 20),
                    label: Text(L.of(ctx).searchAgain),
                  ),
                  IconButton(
                    tooltip: L.of(ctx).delete,
                    onPressed: () {
                      Navigator.pop(ctx);
                      deleteMealWithUndo(context, meal);
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.peach,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _MealForm(
                withText: false,
                editing: meal,
                slot: meal.slot,
                onAdded: (_) {},
              ),
            ),
          ],
        ),
      ),
    );

class AddMealSheet extends StatefulWidget {
  final DateTime? date;
  final MealSlot? slot;

  /// The meal the first added food replaces (edit → 다시 검색).
  final Meal? replacing;
  const AddMealSheet({super.key, this.date, this.slot, this.replacing});

  @override
  State<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<AddMealSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  // Fixed: meals are logged from a slot's + on the today screen.
  late final MealSlot _slot =
      widget.replacing?.slot ?? widget.slot ?? MealSlot.forTime(DateTime.now());
  final _added = <String>[];

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// Search keeps the sheet open for more items; other tabs close it.
  void _onAdded(String name, {bool close = false}) {
    final t = L.of(context);
    if (widget.replacing case final old?) {
      AppScope.read(context).deleteMeal(old.id);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.mealReplaced(josa(t.localeName, name, '으로', '로', ro: true)),
          ),
        ),
      );
      return;
    }
    if (close) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.added(name))));
      return;
    }
    setState(() => _added.add(name));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.addedToSlot(name, slotLabel(t, _slot))),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  /// A quick-added meal was tapped again and taken back out.
  void _onRemoved(String name) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _added.remove(name));
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.replacing == null
                      ? t.addMealToSlot(slotLabel(t, _slot))
                      : t.replaceMeal,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              AnimatedSwitcher(
                duration: Motion.medium,
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: _added.isEmpty
                    ? const SizedBox.shrink()
                    : Row(
                        key: ValueKey(_added.length),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Pill(
                            text: t.addedCount('${_added.length}'),
                            color: AppColors.mint,
                            soft: AppColors.mintSoft,
                            icon: Icons.check_rounded,
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(t.done),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        TabBar(
          controller: _tabs,
          labelStyle: const TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          labelColor: AppColors.ink,
          unselectedLabelColor: AppColors.inkSoft,
          indicatorColor: AppColors.peach,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.line,
          tabs: [
            Tab(text: t.tabSearch),
            Tab(text: t.tabText),
            Tab(text: t.tabSaved),
            Tab(text: t.tabManual),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _SearchTab(
                date: widget.date,
                slot: _slot,
                onAdded: (n) => _onAdded(n),
                onRemoved: _onRemoved,
              ),
              _MealForm(
                withText: true,
                date: widget.date,
                slot: _slot,
                onAdded: (n) => _onAdded(n, close: true),
              ),
              _SavedList(
                date: widget.date,
                slot: _slot,
                onAdded: (n) => _onAdded(n),
                onRemoved: _onRemoved,
              ),
              _MealForm(
                withText: false,
                date: widget.date,
                slot: _slot,
                onAdded: (n) => _onAdded(n, close: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search tab: list -> detail -> add, or create a custom food.
// ---------------------------------------------------------------------------

class _SearchTab extends StatefulWidget {
  final DateTime? date;
  final MealSlot slot;
  final ValueChanged<String> onAdded;
  final ValueChanged<String> onRemoved;
  const _SearchTab({
    required this.date,
    required this.slot,
    required this.onAdded,
    required this.onRemoved,
  });

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

const _browseLimit = 100;

enum _View { list, detail, create }

class _SearchTabState extends State<_SearchTab>
    with AutomaticKeepAliveClientMixin {
  final _query = TextEditingController();
  String? _category; // null = recent
  var _categoryPicked = false;
  Food? _food;
  var _view = _View.list;
  var _forward = true;

  @override
  bool get wantKeepAlive => true;

  // Server results for _remoteQuery (the full DB on Supabase), fetched after
  // a short pause in typing and shown below the local ones.
  Timer? _debounce;
  var _remoteQuery = '';
  var _remote = const <Food>[];
  var _remoteLoading = false;
  var _remoteFailed = false;

  @override
  void initState() {
    super.initState();
    _query.addListener(_onQuery);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQuery() {
    final q = _query.text.trim();
    _debounce?.cancel();
    final s = AppScope.read(context);
    if (q.isNotEmpty && q != _remoteQuery && s.remoteSearch != null) {
      _debounce = Timer(
        const Duration(milliseconds: 350),
        () => _fetchRemote(q),
      );
    }
    setState(() {});
  }

  Future<void> _fetchRemote(String q) async {
    final s = AppScope.read(context);
    setState(() {
      _remoteQuery = q;
      _remote = const [];
      _remoteLoading = true;
      _remoteFailed = false;
    });
    List<Food> found;
    var failed = false;
    try {
      found = await s.searchRemoteFoods(q, s.searchAllFoods(q));
    } catch (e) {
      debugPrint('remote food search failed: $e');
      found = const [];
      failed = true;
    }
    if (!mounted || _remoteQuery != q) return;
    final local = s.searchAllFoods(q).length;
    s.analytics.log('food_search', {
      'len': q.length,
      'local': local,
      'remote': found.length,
      'results': local + found.length,
      'failed': failed,
      // Only queries that found nothing, to see what the database lacks.
      if (!failed && local + found.length == 0) 'q': q,
    });
    setState(() {
      _remote = found;
      _remoteLoading = false;
      _remoteFailed = failed;
    });
  }

  void _go(_View v, {Food? food}) {
    FocusScope.of(context).unfocus();
    // Opening a result counts the query as a search worth remembering.
    if (v == _View.detail) AppScope.read(context).rememberSearch(_query.text);
    setState(() {
      _forward = v != _View.list;
      _view = v;
      if (food != null) _food = food;
    });
  }

  /// Foods added while the sheet is open: food id -> meal id. Their + turns
  /// into a check, and tapping it again takes the meal back out.
  final _picked = <String, String>{};

  /// The unit and amount each picked food was added with.
  final _pickedAmount = <String, (FoodUnit, double)>{};
  final _busy = <String>{};

  /// Changes the amount of a food added in this sheet: takes that serving
  /// back out and adds the new amount.
  Future<void> _change(Food f, FoodUnit unit, double qty) async {
    final id = _picked.remove(f.id);
    if (id != null) {
      await AppScope.read(context).removeServing(id);
      widget.onRemoved(f.name); // the new amount is counted again below
    }
    await _log(f, unit, qty);
  }

  Future<void> _toggle(Food f) async {
    if (!_busy.add(f.id)) return; // ignore taps while saving
    HapticFeedback.selectionClick();
    try {
      final id = _picked[f.id];
      if (id == null) {
        await _log(f, f.units.first, 1);
        return;
      }
      setState(() => _picked.remove(f.id));
      await AppScope.read(context).removeServing(id);
      widget.onRemoved(f.name);
    } finally {
      _busy.remove(f.id);
    }
  }

  Future<void> _log(Food f, FoodUnit unit, double qty) async {
    final n = f.forPortion(unit, qty);
    final grams = unit.grams * qty;
    final q = qty == qty.roundToDouble() ? qty.round().toString() : '$qty';
    final portion = unit.isGram
        ? '${grams.round()}g'
        : f.custom
        ? '${unit.label} × $q'
        : '${unit.label} × $q (${grams.round()}g)';
    final s = AppScope.read(context);
    await s.rememberFood(f);
    final id = await s.addMeal(
      name: f.name,
      kcal: n.kcal,
      proteinG: n.proteinG,
      carbsG: n.carbsG,
      fatG: n.fatG,
      source: MealSource.search,
      date: widget.date,
      slot: widget.slot,
      portion: portion,
      foodId: f.id,
      sugarG: n.sugarG,
      satFatG: n.satFatG,
    );
    if (mounted) {
      setState(() {
        _picked[f.id] = id;
        _pickedAmount[f.id] = (unit, qty);
      });
    }
    widget.onAdded(f.name);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final child = switch (_view) {
      _View.list => _list(context),
      _View.detail => _FoodDetail(
        key: ValueKey(_food!.id),
        food: _food!,
        slot: widget.slot,
        onBack: () => _go(_View.list),
        picked: _picked.containsKey(_food!.id),
        initialAmount: _picked.containsKey(_food!.id)
            ? _pickedAmount[_food!.id]
            : null,
        onAdd: (u, q) async {
          await _log(_food!, u, q);
          if (mounted) _go(_View.list);
        },
        onChange: (u, q) async {
          await _change(_food!, u, q);
          if (mounted) _go(_View.list);
        },
        onRemove: () async {
          await _toggle(_food!);
          if (mounted) _go(_View.list);
        },
      ),
      _View.create => _CustomFoodForm(
        initialName: _query.text.trim(),
        onBack: () => _go(_View.list),
        onCreated: (f) => _go(_View.detail, food: f),
      ),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 160),
      switchInCurve: Motion.ease,
      layoutBuilder: (cur, prev) =>
          Stack(alignment: Alignment.topCenter, children: [...prev, ?cur]),
      transitionBuilder: (c, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: Offset(_forward ? 0.06 : -0.06, 0),
            end: Offset.zero,
          ).animate(a),
          child: c,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(_view), child: child),
    );
  }

  Widget _list(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final q = _query.text.trim();
    final cats = categoriesOf(s.allFoods);
    final recent = s.recentFoods();
    // With no history yet, open on the first category instead of an empty
    // list, and stay there when the first food added creates a history.
    final showRecent = recent.isNotEmpty;
    if (!_categoryPicked) {
      _categoryPicked = true;
      if (!showRecent) _category = cats.first;
    }
    final category = _category ?? (showRecent ? null : cats.first);
    final List<Food> found = q.isNotEmpty
        ? s.searchAllFoods(q)
        : category == null
        ? recent
        : s.allFoods.where((f) => f.category == category).toList();
    // Imported categories can hold thousands of foods; browse shows the
    // first ones and search finds the rest.
    final foods = found.take(_browseLimit).toList();
    final remotePending =
        q.isNotEmpty &&
        s.remoteSearch != null &&
        (_remoteQuery != q || _remoteLoading);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      children: [
        TextField(
          controller: _query,
          textInputAction: TextInputAction.search,
          onSubmitted: s.rememberSearch,
          decoration: InputDecoration(
            hintText: t.searchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: q.isNotEmpty
                ? IconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .clearButtonTooltip,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => _query.clear(),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        if (q.isEmpty && s.recentSearches.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  t.recentSearches,
                  style: const TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => s.forgetSearch(null),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.inkSoft,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(t.clearAll),
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final r in s.recentSearches)
                InputChip(
                  label: Text(r),
                  onPressed: () => _query.value = TextEditingValue(
                    text: r,
                    selection: TextSelection.collapsed(offset: r.length),
                  ),
                  onDeleted: () => s.forgetSearch(r),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        if (q.isEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in [if (showRecent) null, ...cats])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(c ?? t.recentFoodsChip),
                      selected: category == c,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        if (foods.isEmpty && !remotePending && _remoteShown(q).isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              q.isNotEmpty ? t.noResults(q) : t.noRecentFoods,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft),
            ),
          ),
        // Keyed without the query: rows still matching after a keystroke
        // stay put instead of all fading in again.
        for (final (i, f) in foods.indexed)
          FadeSlideIn(
            key: ValueKey('${f.id}-$category'),
            delay: stagger(i),
            dy: 8,
            child: _FoodRow(
              food: f,
              onTap: () => _go(_View.detail, food: f),
              picked: _picked.containsKey(f.id),
              onQuickAdd: () => _toggle(f),
            ),
          ),
        if (found.length > foods.length)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              t.browseMore('${found.length}'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
          ),
        if (q.isNotEmpty && s.remoteSearch != null) ..._remoteSection(t, q),
        const SizedBox(height: 6),
        SoftCard(
          color: AppColors.lilacSoft,
          padding: const EdgeInsets.all(14),
          onTap: () => _go(_View.create),
          child: Row(
            children: [
              const Icon(Icons.add_circle_rounded, color: AppColors.lilac),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.createFood,
                      style: const TextStyle(
                        fontFamily: headingFont,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      t.createFoodDesc,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.lilac),
            ],
          ),
        ),
      ],
    );
  }

  List<Food> _remoteShown(String q) =>
      _remoteQuery == q && !_remoteLoading ? _remote : const [];

  List<Widget> _remoteSection(L t, String q) {
    final current = _remoteQuery == q;
    Widget note(String text, {Widget? leading}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ?leading,
          if (leading != null) const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
          ),
        ],
      ),
    );
    if (!current || _remoteLoading) {
      return [
        note(
          t.remoteSearching,
          leading: const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ];
    }
    if (_remoteFailed) return [note(t.remoteSearchFailed)];
    if (_remote.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
        child: Text(
          t.remoteResults('${_remote.length}'),
          style: const TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: AppColors.inkSoft,
          ),
        ),
      ),
      for (final (i, f) in _remote.indexed)
        FadeSlideIn(
          key: ValueKey('remote-${f.id}'),
          delay: stagger(i),
          dy: 8,
          child: _FoodRow(
            food: f,
            onTap: () => _go(_View.detail, food: f),
            picked: _picked.containsKey(f.id),
            onQuickAdd: () => _toggle(f),
          ),
        ),
    ];
  }
}

class _FoodRow extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;

  /// Added while this sheet is open: shows a check that takes it back out.
  final bool picked;
  const _FoodRow({
    required this.food,
    required this.onTap,
    required this.onQuickAdd,
    this.picked = false,
  });

  @override
  Widget build(BuildContext context) {
    final u = food.units.first;
    final n = food.forPortion(u, 1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        color: picked ? AppColors.peachSoft : AppColors.card,
        padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: headingFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                    ),
                  ),
                  Text(
                    food.custom
                        ? '${food.category} · ${u.label}'
                        : '${food.category} · ${u.label} (${u.grams.round()}g)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              food.kcalEstimated
                  ? '~${fmt0(n.kcal)} kcal'
                  : '${fmt0(n.kcal)} kcal',
              style: const TextStyle(
                fontFamily: headingFont,
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              onPressed: onQuickAdd,
              icon: AnimatedSwitcher(
                duration: Motion.medium,
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: Icon(
                  picked
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_rounded,
                  key: ValueKey(picked),
                  color: AppColors.peach,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodDetail extends StatefulWidget {
  final Food food;
  final MealSlot slot;
  final VoidCallback onBack;
  final Future<void> Function(FoodUnit unit, double qty) onAdd;

  /// Already added while this sheet is open: the amount can be changed
  /// (starting from [initialAmount]) or the food taken back out.
  final bool picked;
  final (FoodUnit, double)? initialAmount;
  final Future<void> Function(FoodUnit unit, double qty) onChange;
  final Future<void> Function() onRemove;
  const _FoodDetail({
    super.key,
    required this.food,
    required this.slot,
    required this.onBack,
    required this.onAdd,
    required this.picked,
    this.initialAmount,
    required this.onChange,
    required this.onRemove,
  });

  @override
  State<_FoodDetail> createState() => _FoodDetailState();
}

class _FoodDetailState extends State<_FoodDetail> {
  late FoodUnit _unit = widget.initialAmount?.$1 ?? widget.food.units.first;
  late var _qty = widget.initialAmount?.$2 ?? 1.0;
  late final _qtyCtrl = TextEditingController(text: _fmtQty(_qty));
  var _busy = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  double get _step => _unit.isGram ? 10 : 0.5;

  String _fmtQty(double q) =>
      q == q.roundToDouble() ? q.round().toString() : q.toStringAsFixed(1);

  void _setQty(double q) {
    setState(() => _qty = q.clamp(0, _unit.isGram ? 5000 : 50).toDouble());
    _qtyCtrl.text = _fmtQty(_qty);
  }

  void _setUnit(FoodUnit u) {
    if (u == _unit) return;
    // Keep the same amount of food when switching units.
    final grams = _unit.grams * _qty;
    setState(() => _unit = u);
    final q = u.isGram
        ? grams.roundToDouble()
        : (grams / u.grams * 2).round() / 2;
    _setQty(q == 0 ? (u.isGram ? 100 : 1) : q);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final f = widget.food;
    final n = f.forPortion(_unit, _qty);
    Widget macro(String label, double g, bool estimated, Color c, Color soft) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: c,
                  ),
                ),
                CountUp(
                  value: g,
                  duration: Motion.medium,
                  format: (v) => estimated ? '~${fmt1(v)}g' : '${fmt1(v)}g',
                  style: TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: estimated ? AppColors.inkSoft : null,
                  ),
                ),
                if (estimated) // not published by the source
                  Text(
                    t.estimated,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.inkSoft,
                    ),
                  ),
              ],
            ),
          ),
        );
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        6,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                f.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Pill(
              text: f.category,
              color: AppColors.inkSoft,
              soft: AppColors.line,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            children: [
              CountUp(
                value: n.kcal,
                duration: Motion.medium,
                format: (v) =>
                    f.kcalEstimated ? '~${fmt0(v)} kcal' : '${fmt0(v)} kcal',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              if (!f.custom)
                Text(
                  f.kcalEstimated
                      ? '${fmt0(_unit.grams * _qty)}g · ${t.estimated}'
                      : '${fmt0(_unit.grams * _qty)}g',
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  macro(
                    t.protein,
                    n.proteinG,
                    f.unknown.contains('p'),
                    AppColors.mint,
                    AppColors.mintSoft,
                  ),
                  const SizedBox(width: 6),
                  macro(
                    t.carbs,
                    n.carbsG,
                    f.unknown.contains('c'),
                    const Color(0xFFD49B1F),
                    AppColors.butterSoft,
                  ),
                  const SizedBox(width: 6),
                  macro(
                    t.fat,
                    n.fatG,
                    f.unknown.contains('f'),
                    AppColors.lilac,
                    AppColors.lilacSoft,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  Text(
                    n.sugarG == null
                        ? t.sugarNone
                        : t.sugarPer(fmt1(n.sugarG!)),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.sugar,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    n.satFatG == null
                        ? t.satFatNone
                        : t.satFatPer(fmt1(n.satFatG!)),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.satFat,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t.unitLabel,
          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final u in f.allUnits)
              ChoiceChip(
                label: Text(
                  u.isGram || f.custom
                      ? u.label
                      : '${u.label} (${u.grams.round()}g)',
                ),
                selected: u == _unit,
                showCheckmark: false,
                onSelected: (_) => _setUnit(u),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          t.quantity,
          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: _qty > _step ? () => _setQty(_qty - _step) : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _qtyCtrl,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: InputDecoration(
                  suffixText: _unit.isGram ? 'g' : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) =>
                    setState(() => _qty = double.tryParse(v) ?? 0),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => _setQty(_qty + _step),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          f.hasEstimatedMacros
              ? '${t.foodMacrosEstimatedNote} ${t.foodRefNote}'
              : t.foodRefNote,
          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 14),
        if (widget.picked)
          Row(
            children: [
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        await widget.onRemove();
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.inkSoft,
                ),
                child: Text(t.removeShort),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _qty > 0 && !_busy
                      ? () async {
                          setState(() => _busy = true);
                          await widget.onChange(_unit, _qty);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: slotColors(widget.slot).$1,
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(t.updateInSlot(slotLabel(t, widget.slot))),
                ),
              ),
            ],
          )
        else
          FilledButton.icon(
            onPressed: _qty > 0 && !_busy
                ? () async {
                    setState(() => _busy = true);
                    await widget.onAdd(_unit, _qty);
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: slotColors(widget.slot).$1,
            ),
            icon: Icon(slotIcon(widget.slot)),
            label: Text(t.addToSlot(slotLabel(t, widget.slot))),
          ),
      ],
    );
  }
}

class _CustomFoodForm extends StatefulWidget {
  final String initialName;
  final VoidCallback onBack;
  final ValueChanged<Food> onCreated;
  const _CustomFoodForm({
    required this.initialName,
    required this.onBack,
    required this.onCreated,
  });

  @override
  State<_CustomFoodForm> createState() => _CustomFoodFormState();
}

class _CustomFoodFormState extends State<_CustomFoodForm> {
  late final _name = TextEditingController(text: widget.initialName);
  final _unit = TextEditingController(text: '1인분');
  final _grams = TextEditingController();
  final _kcal = TextEditingController();
  final _p = TextEditingController();
  final _c = TextEditingController();
  final _f = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _unit, _kcal]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _unit, _grams, _kcal, _p, _c, _f]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _v(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _unit.text.trim().isNotEmpty &&
      (_v(_kcal) ?? 0) > 0;

  Future<void> _save() async {
    final t = L.of(context);
    final grams = _v(_grams);
    final food = await AppScope.read(context).addCustomFood(
      name: _name.text.trim(),
      unitLabel: _unit.text.trim(),
      grams: grams != null && grams > 0 ? grams : null,
      kcal: _v(_kcal)!,
      proteinG: _v(_p) ?? 0,
      carbsG: _v(_c) ?? 0,
      fatG: _v(_f) ?? 0,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t.customSaved(josa(t.localeName, "'${food.name}'", '을', '를')),
        ),
      ),
    );
    widget.onCreated(food);
  }

  Widget _num(TextEditingController c, String label) => TextField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    decoration: InputDecoration(labelText: label),
  );

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        6,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Text(t.createFood, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          decoration: InputDecoration(labelText: t.foodName),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _unit,
                decoration: InputDecoration(labelText: t.servingLabel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _num(_grams, t.servingGrams)),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          t.perServing,
          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 8),
        _num(_kcal, t.kcalField),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _num(_p, t.proteinField)),
            const SizedBox(width: 8),
            Expanded(child: _num(_c, t.carbsField)),
            const SizedBox(width: 8),
            Expanded(child: _num(_f, t.fatField)),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton(onPressed: _valid ? _save : null, child: Text(t.save)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Text estimate / manual entry / edit
// ---------------------------------------------------------------------------

class _MealForm extends StatefulWidget {
  final bool withText;
  final DateTime? date;
  final MealSlot slot;
  final ValueChanged<String> onAdded;

  /// When set, the form edits this meal instead of adding a new one.
  final Meal? editing;
  const _MealForm({
    required this.withText,
    this.date,
    required this.slot,
    required this.onAdded,
    this.editing,
  });

  @override
  State<_MealForm> createState() => _MealFormState();
}

class _MealFormState extends State<_MealForm>
    with AutomaticKeepAliveClientMixin {
  final _text = TextEditingController();
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _p = TextEditingController();
  final _c = TextEditingController();
  final _f = TextEditingController();
  var _saveTemplate = false;
  Estimate? _estimate;
  var _edited = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final m = widget.editing;
    if (m != null) {
      _name.text = m.name;
      _kcal.text = m.kcal.round().toString();
      _p.text = m.proteinG.round().toString();
      _c.text = m.carbsG.round().toString();
      _f.text = m.fatG.round().toString();
    }
    for (final c in [_text, _name, _kcal, _p, _c, _f]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_text, _name, _kcal, _p, _c, _f]) {
      c.dispose();
    }
    super.dispose();
  }

  double _v(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  void _runEstimate() {
    FocusScope.of(context).unfocus();
    final e = estimateFromText(
      _text.text,
      foods: AppScope.read(context).allFoods,
    );
    setState(() {
      _estimate = e;
      _edited = false;
      _name.text = _text.text.trim();
      _kcal.text = e.kcal.round().toString();
      _p.text = e.proteinG.round().toString();
      _c.text = e.carbsG.round().toString();
      _f.text = e.fatG.round().toString();
    });
  }

  bool get _valid => _name.text.trim().isNotEmpty && _v(_kcal) > 0;

  Future<void> _add() async {
    final s = AppScope.read(context);
    final t = L.of(context);
    final name = _name.text.trim();
    final editing = widget.editing;
    if (editing != null) {
      final changed =
          name != editing.name ||
          _v(_kcal).round() != editing.kcal.round() ||
          _v(_p).round() != editing.proteinG.round() ||
          _v(_c).round() != editing.carbsG.round() ||
          _v(_f).round() != editing.fatG.round();
      // 당류/포화지방 follow the new kcal (they can't be edited here), so
      // halving a meal halves them too.
      final k = editing.kcal > 0 ? _v(_kcal) / editing.kcal : 1.0;
      await s.updateMeal(
        editing
            .copyWith(
              name: name,
              kcal: _v(_kcal),
              proteinG: _v(_p),
              carbsG: _v(_c),
              fatG: _v(_f),
              edited: editing.edited || changed,
              // A hand-edited amount no longer matches the stored portion.
              portion: changed ? () => null : null,
            )
            .withNutrients(
              editing.sugarG == null ? null : editing.sugarG! * k,
              editing.satFatG == null ? null : editing.satFatG! * k,
            ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.mealUpdated)));
      return;
    }
    await s.addMeal(
      date: widget.date,
      slot: widget.slot,
      name: name,
      kcal: _v(_kcal),
      proteinG: _v(_p),
      carbsG: _v(_c),
      fatG: _v(_f),
      source: widget.withText && _estimate != null
          ? MealSource.text
          : MealSource.manual,
      edited: _edited,
    );
    if (_saveTemplate) {
      await s.saveMealTemplate(
        name: name,
        kcal: _v(_kcal),
        proteinG: _v(_p),
        carbsG: _v(_c),
        fatG: _v(_f),
      );
    }
    if (!mounted) return;
    widget.onAdded(name);
  }

  Widget _num(TextEditingController c, String label) => TextField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    onChanged: (_) => _edited = true,
    decoration: InputDecoration(labelText: label),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = L.of(context);
    final e = _estimate;
    final showForm = !widget.withText || e != null;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      children: [
        if (widget.editing != null) ...[
          if (widget.editing!.portion != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.editing!.portion!,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ],
          const SizedBox(height: 4),
        ],
        if (widget.withText) ...[
          TextField(
            controller: _text,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(hintText: t.textHint),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _text.text.trim().isEmpty ? null : _runEstimate,
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.peach,
            ),
            label: Text(t.estimate),
          ),
        ],
        if (e != null) ...[
          const SizedBox(height: 14),
          FadeSlideIn(
            key: ValueKey(e),
            child: SoftCard(
              padding: const EdgeInsets.all(14),
              color: AppColors.mintSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final i in e.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            i.matched
                                ? Icons.check_circle_rounded
                                : Icons.help_rounded,
                            size: 16,
                            color: i.matched
                                ? AppColors.mint
                                : AppColors.inkSoft,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              i.matched && i.food!.name != i.name
                                  ? '${i.name} → ${i.food!.name}'
                                  : i.name,
                            ),
                          ),
                          Text(
                            '${fmt0(i.kcal)} kcal',
                            style: const TextStyle(
                              fontFamily: headingFont,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    t.estimateNote,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  if (e.hasUnmatched)
                    Text(
                      t.unmatchedNote(
                        e.items
                            .where((i) => !i.matched)
                            .map((i) => i.name)
                            .join(', '),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.peach,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (showForm) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: t.mealName),
          ),
          const SizedBox(height: 12),
          _num(_kcal, t.kcalField),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _num(_p, t.proteinField)),
              const SizedBox(width: 8),
              Expanded(child: _num(_c, t.carbsField)),
              const SizedBox(width: 8),
              Expanded(child: _num(_f, t.fatField)),
            ],
          ),
          const SizedBox(height: 6),
          if (widget.editing == null)
            CheckboxListTile(
              value: _saveTemplate,
              onChanged: (v) => setState(() => _saveTemplate = v ?? false),
              title: Text(
                t.saveAsMyMeal,
                style: const TextStyle(fontSize: 14.5),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.peach,
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _valid ? _add : null,
            style: widget.editing != null
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: slotColors(widget.slot).$1,
                  ),
            child: Text(
              widget.editing != null
                  ? t.save
                  : t.addToSlot(slotLabel(t, widget.slot)),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Saved + recent meals (one tap)
// ---------------------------------------------------------------------------

/// Tap a meal to add it, tap it again to take it back out.
class _SavedList extends StatefulWidget {
  final DateTime? date;
  final MealSlot slot;
  final ValueChanged<String> onAdded;
  final ValueChanged<String> onRemoved;
  const _SavedList({
    this.date,
    required this.slot,
    required this.onAdded,
    required this.onRemoved,
  });

  @override
  State<_SavedList> createState() => _SavedListState();
}

class _SavedListState extends State<_SavedList>
    with AutomaticKeepAliveClientMixin {
  /// Meals added from this list while the sheet is open: name -> meal id.
  final _picked = <String, String>{};
  final _busy = <String>{};

  @override
  bool get wantKeepAlive => true;

  Future<void> _toggle(
    String name,
    double kcal,
    double p,
    double c,
    double f,
  ) async {
    if (!_busy.add(name)) return; // ignore taps while saving
    final s = AppScope.read(context);
    try {
      final id = _picked[name];
      if (id != null) {
        setState(() => _picked.remove(name));
        await s.removeServing(id);
        widget.onRemoved(name);
        return;
      }
      final newId = await s.addMeal(
        date: widget.date,
        slot: widget.slot,
        name: name,
        kcal: kcal,
        proteinG: p,
        carbsG: c,
        fatG: f,
        source: MealSource.saved,
      );
      if (!mounted) return;
      setState(() => _picked[name] = newId);
      widget.onAdded(name);
    } finally {
      _busy.remove(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = L.of(context);
    final s = AppScope.of(context);
    final saved = s.savedMeals;
    final recent = s.recentMeals();
    if (saved.isEmpty && recent.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Mascot(size: 72, mood: MascotMood.thinking),
              const SizedBox(height: 12),
              Text(
                t.noSavedMeals,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkSoft, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }
    var i = 0;
    Widget row({
      required IconData icon,
      required Color color,
      required String name,
      required double kcal,
      required double p,
      required double c,
      required double f,
      VoidCallback? onRemove,
    }) {
      final picked = _picked.containsKey(name);
      return FadeSlideIn(
        delay: stagger(i++),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SoftCard(
            color: picked ? AppColors.peachSoft : AppColors.card,
            padding: EdgeInsets.fromLTRB(16, 10, onRemove == null ? 16 : 8, 10),
            onTap: () => _toggle(name, kcal, p, c, f),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: Motion.medium,
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: picked
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('picked'),
                          color: AppColors.peach,
                        )
                      : Icon(icon, key: const ValueKey('icon'), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        L.of(context).macroSummary(fmt0(p), fmt0(c), fmt0(f)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${fmt0(kcal)} kcal',
                  style: const TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    tooltip: L.of(context).delete,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.inkSoft,
                    ),
                    onPressed: onRemove,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (saved.isNotEmpty) ...[
          SectionTitle(t.savedMealsTitle),
          for (final m in saved)
            row(
              icon: Icons.bookmark_rounded,
              color: AppColors.peach,
              name: m.name,
              kcal: m.kcal,
              p: m.proteinG,
              c: m.carbsG,
              f: m.fatG,
              onRemove: () => s.deleteSavedMeal(m.id),
            ),
        ],
        if (recent.isNotEmpty) ...[
          SectionTitle(t.recentMeals),
          for (final m in recent)
            row(
              icon: Icons.history_rounded,
              color: AppColors.sky,
              name: m.name,
              kcal: m.kcal,
              p: m.proteinG,
              c: m.carbsG,
              f: m.fatG,
            ),
        ],
      ],
    );
  }
}
