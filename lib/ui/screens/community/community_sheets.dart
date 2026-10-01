import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/community.dart';
import '../../../data/photo_prep.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/community_state.dart';
import '../../motion.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'community_common.dart';
import 'community_widgets.dart';

/// The web app. Invite links go through its go.html, which sends phones
/// to their store (Play; App Store once the iPhone app is out) and
/// everything else to the web app (`?gym=` opens that board there).
const webAppUrl = String.fromEnvironment(
  'WEB_URL',
  defaultValue: 'https://dydwn1003.github.io/workout/',
);

const inviteUrl = '${webAppUrl}go.html';

String boardLink(String id) => '$inviteUrl?gym=${Uri.encodeQueryComponent(id)}';

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
                  share(() => shareText(root, t.inviteAppText(inviteUrl))),
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
                        t.gymLimitBody(
                          josa(t.localeName, adding.name, '을', '를'),
                        ),
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

/// A round profile photo that picks a new one on tap: [onChanged] gets
/// the prepared JPEG, or null with `removed` when the photo was taken off.
class AvatarPicker extends StatefulWidget {
  final String userId;
  final String nickname;
  final String? currentUrl;
  final double size;
  final void Function(Uint8List? photo, bool removed) onChanged;
  const AvatarPicker({
    super.key,
    required this.userId,
    required this.nickname,
    required this.currentUrl,
    required this.onChanged,
    this.size = 96,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  Uint8List? _photo;
  var _removed = false;
  var _busy = false;

  bool get _hasPhoto =>
      _photo != null || (!_removed && widget.currentUrl != null);

  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final f = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (f == null) return;
      final bytes = await prepareAvatar(await f.readAsBytes());
      if (!mounted) return;
      if (bytes == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(L.of(context).badImage)));
        return;
      }
      setState(() {
        _photo = bytes;
        _removed = false;
      });
      widget.onChanged(bytes, false);
    } catch (e) {
      debugPrint('avatar pick failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove() {
    setState(() {
      _photo = null;
      _removed = true;
    });
    widget.onChanged(null, true);
  }

  Future<void> _menu() async {
    if (!_hasPhoto) return _pick();
    final t = L.of(context);
    final remove = await showModalBottomSheet<bool>(
      context: context,
      sheetAnimationStyle: Motion.sheet,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(t.choosePhoto),
              onTap: () => Navigator.pop(context, false),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.peach,
              ),
              title: Text(t.removePhoto),
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
    if (remove == null || !mounted) return;
    remove ? _remove() : await _pick();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final photo = _photo;
    return Squish(
      child: GestureDetector(
        onTap: _menu,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x228B6E5A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: photo != null
                    ? ClipOval(
                        child: Image.memory(
                          photo,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                        ),
                      )
                    : NickAvatar(
                        userId: widget.userId,
                        nickname: widget.nickname,
                        photoUrl: _removed ? null : widget.currentUrl,
                        size: size - 6,
                      ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: size * 0.34,
                  height: size * 0.34,
                  decoration: BoxDecoration(
                    color: AppColors.peach,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: _busy
                      ? const Padding(
                          padding: EdgeInsets.all(7),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.photo_camera_rounded,
                          size: size * 0.18,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 프로필 편집: photo and nickname.
Future<void> showProfileSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: Motion.sheet,
      builder: (_) => const _ProfileSheet(),
    );

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet();

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  late final CommunityProfile _me = CommunityScope.read(context).profile!;
  late final _nick = TextEditingController(text: _me.nickname);
  Uint8List? _photo;
  var _removePhoto = false;
  var _busy = false;
  String? _error;

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
    final c = CommunityScope.read(context);
    try {
      await c.updateProfile(
        nickname: n == _me.nickname ? null : n,
        photo: _photo,
        removePhoto: _removePhoto,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t.profileSaved)));
    } catch (e) {
      if (mounted) setState(() => _error = communityErrorText(t, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return Padding(
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
          Text(
            t.editProfile,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            t.editProfileSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 20),
          Center(
            child: ListenableBuilder(
              listenable: _nick,
              builder: (context, _) => AvatarPicker(
                userId: _me.userId,
                nickname: _nick.text.trim().isEmpty
                    ? _me.nickname
                    : _nick.text.trim(),
                currentUrl: _me.avatarUrl,
                onChanged: (photo, removed) {
                  _photo = photo;
                  _removePhoto = removed;
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nick,
            maxLength: CommunityLimits.nicknameMax,
            style: const TextStyle(
              fontFamily: headingFont,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
            decoration: InputDecoration(
              labelText: t.nicknameLabel,
              errorText: _error,
              prefixIcon: const Icon(
                Icons.alternate_email_rounded,
                color: AppColors.peach,
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.save),
          ),
        ],
      ),
    );
  }
}
