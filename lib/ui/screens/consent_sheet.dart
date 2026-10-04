import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import 'settings_screen.dart' show privacyPolicyUrl, termsUrl;

/// The agreements before starting: 전체 동의, the required ones (age,
/// terms, privacy, health data) and reminders as an option. True when
/// agreed; reminders are turned on (with the system's permission prompt)
/// when picked.
Future<bool> showConsentSheet(BuildContext context, {String? note}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    sheetAnimationStyle: Motion.sheet,
    builder: (_) => _ConsentSheet(note: note),
  );
  return ok ?? false;
}

class _ConsentSheet extends StatefulWidget {
  final String? note;
  const _ConsentSheet({this.note});

  @override
  State<_ConsentSheet> createState() => _ConsentSheetState();
}

class _ConsentSheetState extends State<_ConsentSheet> {
  var _age = false;
  var _terms = false;
  var _privacy = false;
  var _health = false;
  var _notify = false;
  var _busy = false;

  bool get _required => _age && _terms && _privacy && _health;
  bool _all(bool reminders) => _required && (!reminders || _notify);

  void _setAll(bool v, bool reminders) => setState(() {
    _age = _terms = _privacy = _health = v;
    if (reminders) _notify = v;
  });

  Future<void> _agree() async {
    final s = AppScope.read(context);
    setState(() => _busy = true);
    if (_notify && s.remindersSupported) await s.setReminders(true);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final reminders = AppScope.of(context).remindersSupported;
    final all = _all(reminders);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.consentTitle,
              style: const TextStyle(
                fontFamily: headingFont,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            if (widget.note != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.note!,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // 전체 동의
            Material(
              color: all ? AppColors.peachSoft : Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _setAll(!all, reminders),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      _Check(on: all, big: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.consentAll,
                          style: const TextStyle(
                            fontFamily: headingFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _Item(
              on: _age,
              required: true,
              label: t.consentAge,
              onTap: () => setState(() => _age = !_age),
            ),
            _Item(
              on: _terms,
              required: true,
              label: t.consentTerms,
              link: termsUrl,
              onTap: () => setState(() => _terms = !_terms),
            ),
            _Item(
              on: _privacy,
              required: true,
              label: t.consentPrivacy,
              link: privacyPolicyUrl,
              onTap: () => setState(() => _privacy = !_privacy),
            ),
            _Item(
              on: _health,
              required: true,
              label: t.consentHealth,
              onTap: () => setState(() => _health = !_health),
            ),
            if (reminders)
              _Item(
                on: _notify,
                required: false,
                label: t.consentNotify,
                onTap: () => setState(() => _notify = !_notify),
              ),
            const SizedBox(height: 6),
            Text(
              t.disclaimer,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _required && !_busy ? _agree : null,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(t.consentAgree),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final bool on;
  final bool required;
  final String label;
  final String? link;
  final VoidCallback onTap;
  const _Item({
    required this.on,
    required this.required,
    required this.label,
    required this.onTap,
    this.link,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            _Check(on: on),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: required ? AppColors.peachSoft : AppColors.neutralSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                required ? t.consentRequired : t.consentOptional,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: required ? AppColors.peach : AppColors.inkSoft,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14.5, height: 1.35),
              ),
            ),
            if (link != null)
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.inkSoft,
                ),
                onPressed: () => launchUrl(
                  Uri.parse(link!),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  t.consentView,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A round check: peach and filled when on.
class _Check extends StatelessWidget {
  final bool on;
  final bool big;
  const _Check({required this.on, this.big = false});

  @override
  Widget build(BuildContext context) {
    final size = big ? 26.0 : 22.0;
    return AnimatedContainer(
      duration: Motion.fast,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? AppColors.peach : Colors.white,
        border: Border.all(
          color: on ? AppColors.peach : AppColors.line,
          width: 2,
        ),
      ),
      child: on
          ? Icon(Icons.check_rounded, size: size - 8, color: Colors.white)
          : null,
    );
  }
}
