import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/update_check.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';

/// "알아서핏 어떠세요?": happy users go on to a store rating, unhappy ones
/// tell us why (supabase/push.sql, app_feedback) instead.
Future<void> showReviewSheet(BuildContext context) async {
  final s = AppScope.read(context);
  await s.reviewAsked();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    sheetAnimationStyle: Motion.sheet,
    builder: (_) => const _ReviewSheet(),
  );
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet();

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

enum _Step { ask, good, bad }

class _ReviewSheetState extends State<_ReviewSheet> {
  var _step = _Step.ask;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canRateInStore =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          (defaultTargetPlatform == TargetPlatform.iOS &&
              iosStoreUrl.isNotEmpty));

  Future<void> _rate() async {
    final review = InAppReview.instance;
    Navigator.pop(context);
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
        return;
      }
    } catch (_) {}
    await launchUrl(
      Uri.parse(
        defaultTargetPlatform == TargetPlatform.iOS
            ? iosStoreUrl
            : androidStoreUrl,
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final s = AppScope.read(context);
    final child = switch (_step) {
      _Step.ask => Column(
        key: const ValueKey('ask'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Mascot(size: 72, mood: MascotMood.happy),
          const SizedBox(height: 10),
          Text(
            t.reviewTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = _Step.bad),
                  child: Text(t.reviewBad),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await s.answerReview(good: true);
                    if (!_canRateInStore) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(t.reviewThanks)));
                      return;
                    }
                    setState(() => _step = _Step.good);
                  },
                  child: Text(t.reviewGood),
                ),
              ),
            ],
          ),
        ],
      ),
      _Step.good => Column(
        key: const ValueKey('good'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Mascot(size: 72, mood: MascotMood.cheer),
          const SizedBox(height: 10),
          Text(
            t.reviewThanks,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            t.reviewAskStore,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkSoft, height: 1.5),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _rate,
            icon: const Icon(Icons.star_rounded),
            label: Text(t.reviewRate),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.reviewLater),
          ),
        ],
      ),
      _Step.bad => Column(
        key: const ValueKey('bad'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.reviewBadTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            autofocus: true,
            maxLines: 4,
            maxLength: 2000,
            decoration: InputDecoration(hintText: t.reviewBadHint),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await s.answerReview(good: false, message: _text.text.trim());
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(t.reviewSent)));
            },
            child: Text(t.reviewSend),
          ),
        ],
      ),
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AnimatedSize(
        duration: Motion.medium,
        curve: Motion.ease,
        child: AnimatedSwitcher(duration: Motion.medium, child: child),
      ),
    );
  }
}
