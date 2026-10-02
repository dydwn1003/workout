import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'motion.dart';
import 'theme.dart';

/// Shows [builder] as a dialog that pops in (scale + fade) over a soft dim.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: dismissible,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: const Color(0x663B3340),
  transitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (ctx, _, _) => builder(ctx),
  transitionBuilder: (ctx, a, _, child) {
    final curved = CurvedAnimation(
      parent: a,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
    return FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.9, end: 1.0).animate(curved),
        child: child,
      ),
    );
  },
);

/// The app's dialog: a white rounded card with an optional icon in a soft
/// circle, a centered title and message, any [content], and two pill
/// buttons (a grey one to back out, a colored one to go ahead).
class AppDialog extends StatelessWidget {
  final IconData? icon;
  final String? title;
  final String? message;
  final Widget? content;

  /// The grey button; none when null.
  final String? cancelLabel;
  final String confirmLabel;

  /// Null disables the colored button (e.g. while an input is invalid).
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// Red instead of peach, for deleting and other things that can't be
  /// undone.
  final bool danger;

  const AppDialog({
    super.key,
    this.icon,
    this.title,
    this.message,
    this.content,
    this.cancelLabel,
    required this.confirmLabel,
    required this.onConfirm,
    this.onCancel,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = danger ? AppColors.over : AppColors.peach;
    final soft = danger ? const Color(0xFFFFE3E3) : AppColors.peachSoft;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) ...[
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: soft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: 28),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (title != null)
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 18.5,
                    height: 1.35,
                    color: AppColors.ink,
                  ),
                ),
              if (message != null) ...[
                if (title != null) const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: title == null ? 15.5 : 14.5,
                    height: 1.55,
                    color: title == null ? AppColors.ink : AppColors.inkSoft,
                  ),
                ),
              ],
              if (content != null) ...[const SizedBox(height: 16), content!],
              const SizedBox(height: 22),
              Row(
                children: [
                  if (cancelLabel != null) ...[
                    Expanded(
                      child: _PillButton(
                        label: cancelLabel!,
                        bg: AppColors.neutralSoft,
                        fg: AppColors.ink,
                        onTap: onCancel ?? () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: _PillButton(
                      label: confirmLabel,
                      bg: accent,
                      fg: Colors.white,
                      onTap: onConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;
  const _PillButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Squish(
      child: Material(
        color: on ? bg : bg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 50,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: headingFont,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: on ? fg : fg.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks a yes/no question with [AppDialog]. True when [confirm] is tapped.
Future<bool> showConfirm(
  BuildContext context, {
  String? title,
  String? message,
  required String confirm,
  String? cancel,
  bool danger = false,
  IconData? icon,
}) async {
  final ok = await showAppDialog<bool>(
    context,
    builder: (ctx) => AppDialog(
      icon: icon,
      title: title,
      message: message,
      cancelLabel: cancel ?? L.of(ctx).cancel,
      confirmLabel: confirm,
      danger: danger,
      onCancel: () => Navigator.pop(ctx, false),
      onConfirm: () => Navigator.pop(ctx, true),
    ),
  );
  return ok ?? false;
}

/// A calendar that slides up from the bottom: 오늘 as a shortcut, round
/// day cells, and a tap on a day picks it right away.
Future<DateTime?> showDateSheet(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
  String? title,
}) => showModalBottomSheet<DateTime>(
  context: context,
  isScrollControlled: true,
  builder: (ctx) {
    final t = L.of(ctx);
    final theme = Theme.of(ctx);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title ?? t.pickDate,
                    style: const TextStyle(
                      fontFamily: headingFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                ),
                // The latest pickable day: today wherever this is used.
                Squish(
                  child: Material(
                    color: AppColors.peachSoft,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(ctx, last),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        child: Text(
                          t.backToToday,
                          style: const TextStyle(
                            fontFamily: headingFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.peach,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Theme(
              data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  primary: AppColors.peach,
                  onPrimary: Colors.white,
                ),
                datePickerTheme: DatePickerThemeData(
                  dayShape: const WidgetStatePropertyAll(CircleBorder()),
                  todayBorder: const BorderSide(
                    color: AppColors.peach,
                    width: 1.5,
                  ),
                  todayForegroundColor: WidgetStateProperty.resolveWith(
                    (s) => s.contains(WidgetState.selected)
                        ? Colors.white
                        : AppColors.peach,
                  ),
                  dayStyle: const TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  weekdayStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.inkSoft,
                  ),
                  yearStyle: const TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              child: CalendarDatePicker(
                initialDate: initial,
                firstDate: first,
                lastDate: last,
                onDateChanged: (d) => Navigator.pop(ctx, d),
              ),
            ),
          ],
        ),
      ),
    );
  },
);

/// One choice in [showActionSheet].
class SheetAction<T> {
  final T value;
  final IconData? icon;
  final String label;

  /// Red, for deleting, blocking and the like.
  final bool danger;
  const SheetAction(this.value, this.label, {this.icon, this.danger = false});
}

/// A menu that slides up: the choices on a white rounded card (icons in
/// soft circles) and a grey 취소 pill under it. The chosen value, or null.
Future<T?> showActionSheet<T>(
  BuildContext context, {
  String? title,
  required List<SheetAction<T>> actions,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  builder: (ctx) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: headingFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, a) in actions.indexed) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 64, endIndent: 16),
                  _SheetTile(
                    action: a,
                    onTap: () => Navigator.pop(ctx, a.value),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _PillButton(
            label: L.of(ctx).cancel,
            bg: Colors.white,
            fg: AppColors.inkSoft,
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    ),
  ),
);

class _SheetTile<T> extends StatelessWidget {
  final SheetAction<T> action;
  final VoidCallback onTap;
  const _SheetTile({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = action.danger ? AppColors.over : AppColors.ink;
    final soft = action.danger
        ? const Color(0xFFFFE3E3)
        : AppColors.neutralSoft;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            if (action.icon != null) ...[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
                child: Icon(action.icon, size: 19, color: fg),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                action.label,
                style: TextStyle(
                  fontFamily: headingFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
