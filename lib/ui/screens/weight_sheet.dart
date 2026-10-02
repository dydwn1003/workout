import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/entities.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';
import 'trend_sections.dart' show BodyCompGuide;

Future<void> showWeightSheet(BuildContext context, {DateTime? date}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: Motion.sheet,
      builder: (_) => WeightSheet(date: date),
    );

class WeightSheet extends StatefulWidget {
  final DateTime? date;
  const WeightSheet({super.key, this.date});

  @override
  State<WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends State<WeightSheet> {
  late double _kg;
  final _bf = TextEditingController();
  final _smm = TextEditingController();
  var _showComp = false;

  // Body fat % and 골격근량 (kg) it takes, inclusive.
  static const _bfRange = (3, 70);
  static const _smmRange = (5, 100);

  double? _read(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));

  /// Typed but out of range (blank is fine: both are optional).
  bool _bad(TextEditingController c, (int, int) r) {
    if (c.text.trim().isEmpty) return false;
    final v = _read(c);
    return v == null || v < r.$1 || v > r.$2;
  }

  String? _error(TextEditingController c, (int, int) r) =>
      _bad(c, r) ? L.of(context).numberRange('${r.$1}', '${r.$2}') : null;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    final today = s.weightOn(widget.date ?? s.today);
    _kg = today?.kg ?? s.latestWeight?.kg ?? 70;
    if (today?.bodyFatPct != null) {
      _bf.text = today!.bodyFatPct!.toString();
      _showComp = true;
    }
    if (today?.skeletalMuscleKg != null) {
      _smm.text = today!.skeletalMuscleKg!.toString();
      _showComp = true;
    }
    for (final c in [_bf, _smm]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _bf.dispose();
    _smm.dispose();
    super.dispose();
  }

  void _bump(double d) => setState(
    () => _kg = double.parse((_kg + d).clamp(25, 300).toStringAsFixed(1)),
  );

  Future<void> _editDirect() async {
    final c = TextEditingController(text: fmt1(_kg));
    final v = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, redraw) {
          final v = _read(c);
          final ok = v != null && v >= 25 && v <= 300;
          return AlertDialog(
            title: Text(L.of(ctx).weightKg),
            content: TextField(
              controller: c,
              autofocus: true,
              onChanged: (_) => redraw(() {}),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                errorText: ok ? null : L.of(ctx).numberRange('25', '300'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(L.of(ctx).cancel),
              ),
              TextButton(
                onPressed: ok ? () => Navigator.pop(ctx, v) : null,
                child: Text(L.of(ctx).confirm),
              ),
            ],
          );
        },
      ),
    );
    if (v != null) setState(() => _kg = double.parse(v.toStringAsFixed(1)));
  }

  Future<void> _save() async {
    final s = AppScope.read(context);
    final t = L.of(context);
    if (_bad(_bf, _bfRange) || _bad(_smm, _smmRange)) return;
    final bf = _read(_bf);
    final smm = _read(_smm);
    await s.upsertWeight(
      WeightEntry(
        date: dateKey(widget.date ?? s.today),
        kg: _kg,
        bodyFatPct: bf,
        skeletalMuscleKg: smm,
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t.weightSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    Widget bump(String label, double d) => Expanded(
      child: OutlinedButton(
        onPressed: () => _bump(d),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: EdgeInsets.zero,
        ),
        child: Text(label),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.weightTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _editDirect,
              child: Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: fmt1(_kg),
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const TextSpan(
                        text: ' kg',
                        style: TextStyle(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                bump('-1', -1),
                const SizedBox(width: 8),
                bump('-0.1', -0.1),
                const SizedBox(width: 8),
                bump('+0.1', 0.1),
                const SizedBox(width: 8),
                bump('+1', 1),
              ],
            ),
            const SizedBox(height: 12),
            if (!_showComp)
              TextButton.icon(
                onPressed: () => setState(() => _showComp = true),
                icon: const Icon(Icons.add_rounded),
                label: Text(t.moreBodyComp),
              )
            else ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bf,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                        labelText: t.bodyFatField,
                        errorText: _error(_bf, _bfRange),
                        errorMaxLines: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _smm,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                        labelText: t.smmField,
                        errorText: _error(_smm, _smmRange),
                        errorMaxLines: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // How often to measure, and when the next one counts.
              const BodyCompGuide(compact: true),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _bad(_bf, _bfRange) || _bad(_smm, _smmRange)
                  ? null
                  : _save,
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }
}
