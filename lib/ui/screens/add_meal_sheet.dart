import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/entities.dart';
import '../../data/food_estimator.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';

Future<void> showAddMealSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) =>
      const FractionallySizedBox(heightFactor: 0.9, child: AddMealSheet()),
);

class AddMealSheet extends StatefulWidget {
  const AddMealSheet({super.key});

  @override
  State<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<AddMealSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    final hasSaved = AppScope.read(context).savedMeals.isNotEmpty;
    _tabs = TabController(
      length: 4,
      vsync: this,
      initialIndex: hasSaved ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            t.addMeal,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _tabs,
          labelStyle: const TextStyle(fontFamily: headingFont, fontSize: 15),
          labelColor: AppColors.ink,
          unselectedLabelColor: AppColors.inkSoft,
          indicatorColor: AppColors.peach,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.line,
          tabs: [
            Tab(text: t.tabText),
            Tab(text: t.tabSaved),
            Tab(text: t.tabManual),
            Tab(text: t.tabPhoto),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _MealForm(withText: true),
              _SavedList(),
              _MealForm(withText: false),
              _PhotoSoon(),
            ],
          ),
        ),
      ],
    );
  }
}

class _MealForm extends StatefulWidget {
  final bool withText;
  const _MealForm({required this.withText});

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
    final e = estimateFromText(_text.text);
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
    await s.addMeal(
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
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t.added(name))));
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
          SoftCard(
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
                          color: i.matched ? AppColors.mint : AppColors.inkSoft,
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(i.name)),
                        Text(
                          '${fmt0(i.kcal)} kcal',
                          style: const TextStyle(fontFamily: headingFont),
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
          CheckboxListTile(
            value: _saveTemplate,
            onChanged: (v) => setState(() => _saveTemplate = v ?? false),
            title: Text(t.saveAsMyMeal, style: const TextStyle(fontSize: 14.5)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.peach,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _valid ? _add : null,
            child: Text(t.addToToday),
          ),
        ],
      ],
    );
  }
}

class _SavedList extends StatelessWidget {
  const _SavedList();

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.of(context);
    final saved = s.savedMeals;
    if (saved.isEmpty) {
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: saved.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final m = saved[i];
        return SoftCard(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          onTap: () async {
            await s.addMeal(
              name: m.name,
              kcal: m.kcal,
              proteinG: m.proteinG,
              carbsG: m.carbsG,
              fatG: m.fatG,
              source: MealSource.saved,
            );
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(t.added(m.name))));
          },
          child: Row(
            children: [
              const Icon(Icons.bookmark_rounded, color: AppColors.peach),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: const TextStyle(
                        fontFamily: headingFont,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'P ${fmt0(m.proteinG)} · C ${fmt0(m.carbsG)} · F ${fmt0(m.fatG)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${fmt0(m.kcal)} kcal',
                style: const TextStyle(fontFamily: headingFont),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.inkSoft,
                ),
                onPressed: () => s.deleteSavedMeal(m.id),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PhotoSoon extends StatelessWidget {
  const _PhotoSoon();

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.peachSoft,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.photo_camera_rounded,
                size: 44,
                color: AppColors.peach,
              ),
            ),
            const SizedBox(height: 16),
            Text(t.photoSoon, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              t.photoSoonDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
