import 'package:flutter/material.dart';

import '../../core/coach_engine/coach_engine.dart';
import '../../l10n/app_localizations.dart';
import '../motion.dart';
import '../theme.dart';
import 'labels.dart';

/// One feedback line with a tone-colored icon.
class WorkoutTipRow extends StatelessWidget {
  final WorkoutTip tip;
  final int index;
  const WorkoutTipRow({super.key, required this.tip, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final (icon, color, soft) = switch (tip.tone) {
      TipTone.positive => (
        Icons.celebration_rounded,
        AppColors.mint,
        AppColors.mintSoft,
      ),
      TipTone.neutral => (
        Icons.insights_rounded,
        AppColors.sky,
        AppColors.skySoft,
      ),
      TipTone.nudge => (
        Icons.lightbulb_rounded,
        AppColors.peach,
        AppColors.peachSoft,
      ),
    };
    return FadeSlideIn(
      delay: stagger(index + 2),
      dy: 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                tipText(L.of(context), tip),
                style: const TextStyle(fontSize: 13.5, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
