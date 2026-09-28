import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/entities.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';

Future<void> showWorkoutSheet(
  BuildContext context, {
  DateTime? date,
  WorkoutType type = WorkoutType.strength,
}) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  sheetAnimationStyle: Motion.sheet,
  builder: (_) => WorkoutSheet(date: date, initialType: type),
);

String workoutLabel(L t, WorkoutType type) =>
    type == WorkoutType.strength ? t.strength : t.cardio;

class WorkoutSheet extends StatefulWidget {
  final DateTime? date;
  final WorkoutType initialType;
  const WorkoutSheet({super.key, this.date, required this.initialType});

  @override
  State<WorkoutSheet> createState() => _WorkoutSheetState();
}

class _WorkoutSheetState extends State<WorkoutSheet> {
  late WorkoutType _type = widget.initialType;
  var _minutes = 60;
  final _ctrl = TextEditingController();

  static const _presets = [20, 30, 45, 60, 90];
  static const _max = 600;

  @override
  void initState() {
    super.initState();
    if (widget.initialType == WorkoutType.cardio) _minutes = 30;
    _ctrl.text = '$_minutes';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Sets minutes from buttons/presets and mirrors them into the field.
  void _set(int m) {
    setState(() => _minutes = m.clamp(1, _max));
    _ctrl.text = '$_minutes';
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
  }

  Future<void> _save() async {
    final t = L.of(context);
    await AppScope.read(context).addWorkout(_type, _minutes, date: widget.date);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.workoutAdded(workoutLabel(t, _type), '$_minutes')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    Widget typeTile(WorkoutType type, IconData icon, Color c, Color soft) =>
        Expanded(
          child: ChoiceTile(
            icon: icon,
            color: c,
            soft: soft,
            title: workoutLabel(t, type),
            selected: _type == type,
            onTap: () => setState(() => _type = type),
          ),
        );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.logWorkout, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              typeTile(
                WorkoutType.strength,
                Icons.fitness_center_rounded,
                AppColors.mint,
                AppColors.mintSoft,
              ),
              const SizedBox(width: 10),
              typeTile(
                WorkoutType.cardio,
                Icons.directions_run_rounded,
                AppColors.sky,
                AppColors.skySoft,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            t.workoutMinutes,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filledTonal(
                  onPressed: _minutes > 1 ? () => _set(_minutes - 1) : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: _ctrl,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: Theme.of(context).textTheme.displaySmall,
                    decoration: InputDecoration(
                      suffixText: t.minutesField,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (v) => setState(
                      () => _minutes = (int.tryParse(v) ?? 0).clamp(0, _max),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _minutes < _max ? () => _set(_minutes + 1) : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _presets)
                ChoiceChip(
                  label: Text(t.minutesN('$m')),
                  selected: _minutes == m,
                  showCheckmark: false,
                  onSelected: (_) => _set(m),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            t.workoutNoCalories,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _minutes > 0 ? _save : null,
            child: Text(t.save),
          ),
        ],
      ),
    );
  }
}
