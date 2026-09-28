import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/entities.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets.dart';

Future<void> showWeightSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => const WeightSheet(),
);

class WeightSheet extends StatefulWidget {
  const WeightSheet({super.key});

  @override
  State<WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends State<WeightSheet> {
  late double _kg;
  final _bf = TextEditingController();
  final _smm = TextEditingController();
  var _showComp = false;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    final today = s.weightOn(s.today);
    _kg = today?.kg ?? s.latestWeight?.kg ?? 70;
    if (today?.bodyFatPct != null) {
      _bf.text = today!.bodyFatPct!.toString();
      _showComp = true;
    }
    if (today?.skeletalMuscleKg != null) {
      _smm.text = today!.skeletalMuscleKg!.toString();
      _showComp = true;
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
      builder: (ctx) => AlertDialog(
        title: Text(L.of(ctx).weightKg),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(L.of(ctx).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              ctx,
              double.tryParse(c.text.replaceAll(',', '.')),
            ),
            child: Text(L.of(ctx).confirm),
          ),
        ],
      ),
    );
    if (v != null && v > 25 && v < 300) setState(() => _kg = v);
  }

  Future<void> _save() async {
    final s = AppScope.read(context);
    final t = L.of(context);
    final bf = double.tryParse(_bf.text.replaceAll(',', '.'));
    final smm = double.tryParse(_smm.text.replaceAll(',', '.'));
    await s.upsertWeight(
      WeightEntry(
        date: dateKey(s.today),
        kg: _kg,
        bodyFatPct: bf != null && bf > 2 && bf < 70 ? bf : null,
        skeletalMuscleKg: smm != null && smm > 5 && smm < 100 ? smm : null,
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
                      decoration: InputDecoration(labelText: t.bodyFatField),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _smm,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(labelText: t.smmField),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                t.bodyCompHint,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.skySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.sky,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.healthSync,
                      style: const TextStyle(fontFamily: headingFont),
                    ),
                  ),
                  Text(
                    t.healthSyncSoon,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: _save, child: Text(t.save)),
          ],
        ),
      ),
    );
  }
}
