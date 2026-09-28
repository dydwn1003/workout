import 'package:flutter/material.dart';

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

  static const _presets = [20, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    if (widget.initialType == WorkoutType.cardio) _minutes = 30;
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
                  onPressed: _minutes > 5
                      ? () => setState(() => _minutes -= 5)
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                SizedBox(
                  width: 120,
                  child: CountUp(
                    value: _minutes.toDouble(),
                    duration: Motion.medium,
                    format: (v) => t.minutesN('${v.round()}'),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _minutes < 300
                      ? () => setState(() => _minutes += 5)
                      : null,
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
                  onSelected: (_) => setState(() => _minutes = m),
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
          FilledButton(onPressed: _save, child: Text(t.save)),
        ],
      ),
    );
  }
}
