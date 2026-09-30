import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/community.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/community_state.dart';
import '../../motion.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'community_common.dart';
import 'community_widgets.dart';

/// The web app, which invite links open (with `?gym=` and the board id).
const webAppUrl = String.fromEnvironment(
  'WEB_URL',
  defaultValue: 'https://dydwn1003.github.io/workout/',
);

String boardLink(String id) => '$webAppUrl?gym=${Uri.encodeQueryComponent(id)}';

/// The share sheet, or the clipboard where there's none (desktop browsers).
Future<void> shareText(BuildContext context, String text) async {
  try {
    final r = await SharePlus.instance.share(
      ShareParams(text: text, mailToFallbackEnabled: false),
    );
    if (r.status != ShareResultStatus.unavailable) return;
  } catch (e) {
    debugPrint('share failed: $e');
  }
  try {
    await Clipboard.setData(ClipboardData(text: text));
  } catch (e) {
    // No clipboard either: show the text to copy by hand.
    debugPrint('copy failed: $e');
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: SelectableText(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L.of(context).confirm),
          ),
        ],
      ),
    );
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(L.of(context).linkCopied)));
}

Future<void> shareBoard(BuildContext context, Gym gym) {
  final t = L.of(context);
  return shareText(
    context,
    t.inviteGymText(boardName(t, gym), boardLink(gym.id)),
  );
}

/// 친구 초대: the app, or one of my gyms' boards.
Future<void> showInviteSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: Motion.sheet,
      isScrollControlled: true,
      builder: (_) => const _InviteSheet(),
    );

class _InviteSheet extends StatelessWidget {
  const _InviteSheet();

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final c = CommunityScope.of(context);
    Future<void> share(Future<void> Function() f) async {
      Navigator.pop(context);
      await f();
    }

    final root = Navigator.of(context).context;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Mascot(size: 56, mood: MascotMood.cheer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.inviteTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.inviteBody,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InviteOption(
              icon: Icons.favorite_rounded,
              color: AppColors.peach,
              title: t.inviteApp,
              subtitle: t.inviteAppDesc,
              onTap: () =>
                  share(() => shareText(root, t.inviteAppText(webAppUrl))),
            ),
            for (final g in c.myGyms)
              _InviteOption(
                icon: Icons.fitness_center_rounded,
                color: gymColors(g.id).$1,
                title: t.inviteGym(g.name),
                subtitle: t.inviteGymDesc,
                onTap: () => share(() => shareBoard(root, g)),
              ),
          ],
        ),
      ),
    );
  }
}

class _InviteOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _InviteOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFF0E6DD)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Color.lerp(color, Colors.white, 0.82),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: headingFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.ios_share_rounded, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Adds [gym] to my gyms. With 3 there already, asks which one to swap
/// out. False when it wasn't added.
Future<bool> joinGym(BuildContext context, Gym gym) async {
  final c = CommunityScope.read(context);
  try {
    await c.join(gym);
    return true;
  } on CommunityException catch (e) {
    if (e.error != CommunityError.gymLimit) {
      if (context.mounted) showCommunityError(context, e);
      return false;
    }
  } catch (e) {
    if (context.mounted) showCommunityError(context, e);
    return false;
  }
  if (!context.mounted) return false;
  final out = await showModalBottomSheet<Gym>(
    context: context,
    sheetAnimationStyle: Motion.sheet,
    builder: (_) => _GymLimitSheet(adding: gym),
  );
  if (out == null || !context.mounted) return false;
  try {
    await c.leave(out.id);
    await c.join(gym);
    return true;
  } catch (e) {
    if (context.mounted) showCommunityError(context, e);
    return false;
  }
}

class _GymLimitSheet extends StatelessWidget {
  final Gym adding;
  const _GymLimitSheet({required this.adding});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final c = CommunityScope.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Mascot(size: 52, mood: MascotMood.thinking),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.gymLimitTitle('${CommunityLimits.myGyms}'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.gymLimitBody(adding.name),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final g in c.myGyms)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF0E6DD)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: gymGradient(g.id),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          g.name.characters.first,
                          style: const TextStyle(
                            fontFamily: headingFont,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: headingFont,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (g.address.isNotEmpty)
                              Text(
                                g.shortAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, g),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.peach,
                          side: const BorderSide(color: AppColors.peach),
                        ),
                        child: Text(t.swapGym),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
