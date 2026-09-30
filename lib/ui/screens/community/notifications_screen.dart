import 'package:flutter/material.dart';

import '../../../data/community.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/community_state.dart';
import '../../motion.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'community_common.dart';
import 'community_widgets.dart';
import 'post_screen.dart';

/// 알림: 인기글 on my boards, then likes, comments and replies on my posts
/// and comments. Opening it marks everything as seen; a tap opens the post
/// (at the comment, for comments and replies).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _page = 30;
  List<CommunityNotification>? _items;
  late final List<Post> _hot;
  late final Set<String> _newHot;
  var _failed = false;
  var _more = true;
  var _loadingMore = false;

  @override
  void initState() {
    super.initState();
    final c = CommunityScope.read(context);
    _hot = c.hotPosts;
    _newHot = {for (final p in c.newHotPosts) p.id};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final c = CommunityScope.read(context);
    setState(() => _failed = false);
    try {
      final list = c.signedIn
          ? await c.repo.notifications(limit: _page)
          : const <CommunityNotification>[];
      if (!mounted) return;
      setState(() {
        _items = list;
        _more = list.length == _page;
      });
      // Shown with their unread dots this time, read from now on.
      await c.markAllSeen();
    } catch (e) {
      debugPrint('notifications failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _loadMore() async {
    final items = _items;
    if (_loadingMore || !_more || items == null || items.isEmpty) return;
    _loadingMore = true;
    try {
      final list = await CommunityScope.read(context).repo
          .notifications(before: items.last.createdAt, limit: _page);
      if (!mounted) return;
      setState(() {
        _items = [...items, ...list];
        _more = list.length == _page;
      });
    } catch (_) {
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> _open(String postId, {String? commentId}) async {
    try {
      final post = await CommunityScope.read(context).repo.post(postId);
      if (!mounted) return;
      if (post == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(L.of(context).postGone)));
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PostScreen(post: post, focusCommentId: commentId),
        ),
      );
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final c = CommunityScope.of(context);
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: Text(t.notificationsTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          await c.refreshNotifications();
          await _load();
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 500) _loadMore();
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              if (_hot.isNotEmpty) ...[
                _SectionLabel(
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.peach,
                  text: t.hotNow,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF0E6DD)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (i, p) in _hot.indexed) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: Color(0xFFF3ECE6),
                          ),
                        _HotItem(
                          post: p,
                          isNew: _newHot.contains(p.id),
                          onTap: () => _open(p.id),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (!c.signedIn)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: MascotSays(
                    text: t.notificationsSignIn,
                    mood: MascotMood.happy,
                    size: 52,
                  ),
                )
              else if (_failed)
                Center(
                  child: TextButton(onPressed: _load, child: Text(t.retry)),
                )
              else if (items == null)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: MascotSays(
                    text: t.notificationsEmpty,
                    mood: MascotMood.sleepy,
                    size: 52,
                  ),
                )
              else
                for (final (i, n) in items.indexed)
                  FadeSlideIn(
                    key: ValueKey(n.id),
                    delay: stagger(i),
                    dy: 6,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _NotificationTile(
                        item: n,
                        onTap: n.postId == null
                            ? null
                            : () => _open(
                                n.postId!,
                                commentId: switch (n.kind) {
                                  NotificationKind.comment ||
                                  NotificationKind.reply ||
                                  NotificationKind.commentLike => n.commentId,
                                  _ => null,
                                },
                              ),
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

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _SectionLabel({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
    child: Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class _HotItem extends StatelessWidget {
  final Post post;
  final bool isNew;
  final VoidCallback onTap;
  const _HotItem({
    required this.post,
    required this.isNew,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final (color, _) = gymColors(post.gymId);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          postBoardName(t, post) ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: headingFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: color,
                          ),
                        ),
                      ),
                      if (isNew) ...[const SizedBox(width: 6), const _Dot()],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    post.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.favorite_rounded,
              size: 15,
              color: AppColors.peach,
            ),
            const SizedBox(width: 3),
            Text(
              '${post.likeCount}',
              style: const TextStyle(
                fontFamily: headingFont,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: const BoxDecoration(
      color: AppColors.peach,
      shape: BoxShape.circle,
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  final CommunityNotification item;
  final VoidCallback? onTap;
  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final n = item;
    final name = n.actorNickname ?? t.someone;
    final who = n.count > 1
        ? t.andOthers(name, '${n.count - 1}')
        : t.nameSuffix(name);
    final (title, icon, color) = switch (n.kind) {
      NotificationKind.postLike => (
        t.notifPostLike(who),
        Icons.favorite_rounded,
        AppColors.peach,
      ),
      NotificationKind.comment => (
        t.notifComment(who),
        Icons.chat_bubble_rounded,
        AppColors.sky,
      ),
      NotificationKind.reply => (
        t.notifReply(who),
        Icons.subdirectory_arrow_right_rounded,
        AppColors.mint,
      ),
      NotificationKind.commentLike => (
        t.notifCommentLike(who),
        Icons.favorite_rounded,
        AppColors.lilac,
      ),
      NotificationKind.hot => (
        t.notifHot,
        Icons.local_fire_department_rounded,
        const Color(0xFFF28B30),
      ),
    };
    final quote = switch (n.kind) {
      NotificationKind.comment ||
      NotificationKind.reply ||
      NotificationKind.commentLike => n.commentBody,
      _ => null,
    };
    return Material(
      color: n.read ? Colors.white : const Color(0xFFFFF1EC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: n.read
              ? const Color(0xFFF0E6DD)
              : AppColors.peach.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (n.kind == NotificationKind.hot || n.actorId == null)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Color.lerp(color, Colors.white, 0.82),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
                      )
                    else ...[
                      NickAvatar(
                        userId: n.actorId!,
                        nickname: name,
                        photoUrl: n.actorAvatar,
                        size: 38,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(icon, size: 11, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        height: 1.35,
                        color: AppColors.ink,
                      ),
                    ),
                    if (quote != null && quote.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '“$quote”',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (n.postBody.isNotEmpty) n.postBody,
                        timeAgo(t, n.createdAt),
                      ].join(' · '),
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
              if (!n.read) ...[
                const SizedBox(width: 6),
                const Padding(padding: EdgeInsets.only(top: 6), child: _Dot()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
