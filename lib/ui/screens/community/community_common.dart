import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/community.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_state.dart';
import '../../../state/community_state.dart';
import '../../motion.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../settings_screen.dart' show termsUrl;
import '../sign_in_sheet.dart';
import 'community_sheets.dart';

/// "방금", "5분 전", "3시간 전", "2일 전", then the date.
String timeAgo(L t, DateTime at, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(at);
  if (d.inMinutes < 1) return t.justNow;
  if (d.inHours < 1) return t.minutesAgo('${d.inMinutes}');
  if (d.inDays < 1) return t.hoursAgo('${d.inHours}');
  if (d.inDays < 7) return t.daysAgo('${d.inDays}');
  return '${at.year % 100}.${at.month}.${at.day}';
}

String communityErrorText(L t, Object e) => switch (e) {
  CommunityException(error: CommunityError.nicknameTaken) => t.nicknameTaken,
  CommunityException(error: CommunityError.rateLimited) => t.rateLimited,
  CommunityException(error: CommunityError.blockedWords) => t.blockedWordsError,
  CommunityException(error: CommunityError.badImage) => t.badImage,
  CommunityException(error: CommunityError.gymLimit) => t.gymLimitError,
  CommunityException(error: CommunityError.banned) => t.bannedError,
  _ => t.communityError,
};

void showCommunityError(BuildContext context, Object e) {
  debugPrint('community: $e');
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(communityErrorText(L.of(context), e))),
    );
}

const _avatarColors = [
  (AppColors.peach, AppColors.peachSoft),
  (AppColors.mint, AppColors.mintSoft),
  (AppColors.sky, AppColors.skySoft),
  (AppColors.lilac, AppColors.lilacSoft),
  (AppColors.butter, AppColors.butterSoft),
];

/// The profile photo, or a circle with the nickname's first letter
/// colored by the author.
class NickAvatar extends StatelessWidget {
  final String userId;
  final String nickname;
  final String? photoUrl;
  final double size;
  const NickAvatar({
    super.key,
    required this.userId,
    required this.nickname,
    this.photoUrl,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    if (url != null) {
      final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: px,
          errorBuilder: (_, _, _) => _letter(),
        ),
      );
    }
    return _letter();
  }

  Widget _letter() {
    final (fg, bg) =
        _avatarColors[userId.codeUnits.fold(0, (a, b) => a + b) %
            _avatarColors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        nickname.isEmpty ? '?' : nickname.characters.first,
        style: TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
          color: fg,
        ),
      ),
    );
  }
}

/// Makes sure I'm signed in and have a nickname (agreeing to the rules)
/// before writing; false when the person backs out.
Future<bool> ensureCommunityMember(BuildContext context) async {
  final c = CommunityScope.read(context);
  if (!c.signedIn) {
    final app = AppScope.read(context);
    if (app.auth == null) return false;
    await showSignInSheet(context);
    if (!context.mounted || !c.signedIn) return false;
    await c.refresh(force: true);
    if (!context.mounted) return false;
  }
  if (c.profile != null) return true;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    sheetAnimationStyle: Motion.sheet,
    builder: (_) => const _SetupSheet(),
  );
  return ok ?? false;
}

class _SetupSheet extends StatefulWidget {
  const _SetupSheet();
  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  final _nick = TextEditingController();
  String? _error;
  var _busy = false;
  Uint8List? _photo;

  @override
  void dispose() {
    _nick.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = L.of(context);
    final n = _nick.text.trim();
    if (!validNickname(n)) {
      setState(
        () => _error = containsBlockedWords(n)
            ? t.blockedWordsError
            : t.nicknameInvalid,
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final c = CommunityScope.read(context);
      await c.createProfile(n);
      final photo = _photo;
      if (photo != null) {
        try {
          await c.updateProfile(photo: photo);
        } catch (e) {
          debugPrint('avatar upload failed: $e'); // can be set later
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = communityErrorText(t, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final rules = t.rulesBody
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'^[·•]\s*'), ''))
        .toList();
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
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
                        t.setupTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.setupSubtitle,
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
            Center(
              child: ListenableBuilder(
                listenable: _nick,
                builder: (context, _) => AvatarPicker(
                  userId: CommunityScope.read(context).repo.myId ?? '',
                  nickname: _nick.text.trim(),
                  currentUrl: null,
                  size: 84,
                  onChanged: (photo, _) => _photo = photo,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nick,
              autofocus: true,
              maxLength: CommunityLimits.nicknameMax,
              style: const TextStyle(
                fontFamily: headingFont,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
              decoration: InputDecoration(
                hintText: t.nicknameHint,
                errorText: _error,
                prefixIcon: const Icon(
                  Icons.alternate_email_rounded,
                  color: AppColors.peach,
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        size: 18,
                        color: AppColors.mint,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t.rulesTitle,
                        style: const TextStyle(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final r in rules)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 15,
                              color: AppColors.mint,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => launchUrl(
                        Uri.parse(termsUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(t.readTerms),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.agreeRules),
            ),
          ],
        ),
      ),
    );
  }
}

/// ⋮ menu on a post or comment: edit/delete for mine, report/block for
/// others'.
Future<void> showContentMenu(
  BuildContext context, {
  required bool mine,
  required String type, // 'post' | 'comment'
  required String id,
  required String authorId,
  required String nickname,
  VoidCallback? onEdit,
  required Future<void> Function() onDelete,
  required VoidCallback onBlocked,
}) async {
  final t = L.of(context);
  final choice = await showModalBottomSheet<String>(
    context: context,
    sheetAnimationStyle: Motion.sheet,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          if (mine) ...[
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(t.editPost),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.over,
              ),
              title: Text(
                t.delete,
                style: const TextStyle(color: AppColors.over),
              ),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(t.report),
              onTap: () => Navigator.pop(ctx, 'report'),
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: AppColors.over),
              title: Text(
                t.blockUser,
                style: const TextStyle(color: AppColors.over),
              ),
              onTap: () => Navigator.pop(ctx, 'block'),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  final c = CommunityScope.read(context);
  switch (choice) {
    case 'edit':
      onEdit?.call();
    case 'delete':
      final ok = await _confirm(
        context,
        type == 'post' ? t.deletePostConfirm : t.deleteCommentConfirm,
        t.delete,
      );
      if (!ok || !context.mounted) return;
      try {
        await onDelete();
      } catch (e) {
        if (context.mounted) showCommunityError(context, e);
      }
    case 'report':
      if (!await ensureCommunityMember(context) || !context.mounted) return;
      final reason = await showModalBottomSheet<ReportReason>(
        context: context,
        sheetAnimationStyle: Motion.sheet,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Text(
                  t.reportContentTitle,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              for (final (r, label) in [
                (ReportReason.spam, t.reasonSpam),
                (ReportReason.abuse, t.reasonAbuse),
                (ReportReason.sexual, t.reasonSexual),
                (ReportReason.privacy, t.reasonPrivacy),
                (ReportReason.other, t.reasonOther),
              ])
                ListTile(
                  title: Text(label),
                  onTap: () => Navigator.pop(ctx, r),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (reason == null || !context.mounted) return;
      try {
        await c.repo.report(type, id, reason);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(t.reported)));
        }
      } catch (e) {
        if (context.mounted) showCommunityError(context, e);
      }
    case 'block':
      if (!await ensureCommunityMember(context) || !context.mounted) return;
      final ok = await _confirm(
        context,
        t.blockConfirm(nickname),
        t.blockAction,
      );
      if (!ok || !context.mounted) return;
      try {
        await c.repo.block(authorId);
        onBlocked();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(t.blocked)));
        }
      } catch (e) {
        if (context.mounted) showCommunityError(context, e);
      }
  }
}

Future<bool> _confirm(BuildContext context, String msg, String action) async {
  final t = L.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(msg, style: const TextStyle(height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.over),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}
