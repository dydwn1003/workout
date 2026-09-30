import 'package:flutter/material.dart';

import '../../../data/community.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/community_state.dart';
import '../../motion.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'community_common.dart';
import 'community_sheets.dart';
import 'community_widgets.dart';
import 'post_screen.dart';

/// 내 활동: my profile, the posts I wrote and the comments I left; each
/// opens its post (a comment scrolls to itself there).
class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  static const _page = 20;
  List<Post>? _posts;
  List<MyComment>? _comments;
  var _postsMore = true;
  var _commentsMore = true;
  var _loadingMore = false;
  var _failed = false;

  CommunityRepository get _repo => CommunityScope.read(context).repo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final r = await Future.wait([
        _repo.myPosts(limit: _page),
        _repo.myComments(limit: _page),
      ]);
      if (!mounted) return;
      setState(() {
        _posts = r[0] as List<Post>;
        _comments = r[1] as List<MyComment>;
        _postsMore = _posts!.length == _page;
        _commentsMore = _comments!.length == _page;
      });
    } catch (e) {
      debugPrint('my activity failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _morePosts() async {
    final posts = _posts;
    if (_loadingMore || !_postsMore || posts == null || posts.isEmpty) return;
    _loadingMore = true;
    try {
      final list = await _repo.myPosts(
        before: posts.last.createdAt,
        limit: _page,
      );
      if (!mounted) return;
      setState(() {
        _posts = [...posts, ...list];
        _postsMore = list.length == _page;
      });
    } catch (_) {
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> _moreComments() async {
    final list0 = _comments;
    if (_loadingMore || !_commentsMore || list0 == null || list0.isEmpty) {
      return;
    }
    _loadingMore = true;
    try {
      final list = await _repo.myComments(
        before: list0.last.comment.createdAt,
        limit: _page,
      );
      if (!mounted) return;
      setState(() {
        _comments = [...list0, ...list];
        _commentsMore = list.length == _page;
      });
    } catch (_) {
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> _openPost(Post post, {String? commentId}) async {
    final result = await Navigator.of(context).push<PostResult>(
      MaterialPageRoute(
        builder: (_) => PostScreen(post: post, focusCommentId: commentId),
      ),
    );
    if (!mounted || result == null) return;
    if (commentId == null) {
      setState(
        () => _posts = [
          for (final p in _posts ?? const <Post>[])
            if (p.id != post.id) p else ?result.post,
        ],
      );
    } else {
      _load(); // my comment may have been deleted there
    }
  }

  Future<void> _openComment(MyComment m) async {
    try {
      final post = await _repo.post(m.comment.postId);
      if (!mounted) return;
      if (post == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(L.of(context).postGone)));
        return;
      }
      await _openPost(post, commentId: m.comment.id);
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final c = CommunityScope.of(context);
    final me = c.profile;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: Text(t.myActivity)),
        body: Column(
          children: [
            if (me != null) _profileCard(t, me),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3ECE6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A8B6E5A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppColors.ink,
                unselectedLabelColor: AppColors.inkSoft,
                labelStyle: const TextStyle(
                  fontFamily: headingFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    height: 38,
                    text: _posts == null
                        ? t.myPostsTab
                        : '${t.myPostsTab} ${_posts!.length}'
                              '${_postsMore ? '+' : ''}',
                  ),
                  Tab(
                    height: 38,
                    text: _comments == null
                        ? t.myCommentsTab
                        : '${t.myCommentsTab} ${_comments!.length}'
                              '${_commentsMore ? '+' : ''}',
                  ),
                ],
              ),
            ),
            Expanded(
              child: _failed
                  ? Center(
                      child: TextButton(onPressed: _load, child: Text(t.retry)),
                    )
                  : TabBarView(children: [_postsTab(t), _commentsTab(t)]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(L t, CommunityProfile me) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          NickAvatar(
            userId: me.userId,
            nickname: me.nickname,
            photoUrl: me.avatarUrl,
            size: 56,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              me.nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: headingFont,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await showProfileSheet(context);
              if (mounted) _load(); // my posts show the new name and photo
            },
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: Text(t.editProfile),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: AppColors.peach,
              side: const BorderSide(color: AppColors.peach),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _empty(String text) => ListView(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
        child: Column(
          children: [
            const Mascot(size: 80, mood: MascotMood.sleepy),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _postsTab(L t) {
    final posts = _posts;
    if (posts == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: posts.isEmpty
          ? _empty(t.myPostsEmpty)
          : NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.extentAfter < 500) _morePosts();
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: posts.length,
                itemBuilder: (context, i) {
                  final p = posts[i];
                  return FadeSlideIn(
                    key: ValueKey('mine-${p.id}'),
                    delay: stagger(i),
                    dy: 8,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PostCard(
                        post: p,
                        showGym: true,
                        onTap: () => _openPost(p),
                        onChanged: (u) => setState(
                          () => _posts = [
                            for (final x in posts)
                              if (x.id != p.id) x else ?u,
                          ],
                        ),
                        onBlocked: () {},
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _commentsTab(L t) {
    final list = _comments;
    if (list == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: list.isEmpty
          ? _empty(t.myCommentsEmpty)
          : NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.extentAfter < 500) _moreComments();
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final m = list[i];
                  return FadeSlideIn(
                    key: ValueKey('mc-${m.comment.id}'),
                    delay: stagger(i),
                    dy: 8,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MyCommentRow(
                        item: m,
                        onTap: () => _openComment(m),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _MyCommentRow extends StatelessWidget {
  final MyComment item;
  final VoidCallback onTap;
  const _MyCommentRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final board = topicName(t, item.gymId) ?? item.gymName ?? '';
    final (color, _) = gymColors(item.gymId);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFF0E6DD)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isTopicId(item.gymId)
                              ? topicStyle(item.gymId).$1
                              : Icons.fitness_center_rounded,
                          size: 13,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$board · ${timeAgo(t, item.comment.createdAt)}',
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
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.comment.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F1EC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${t.onPost} · ${item.postBody}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}
