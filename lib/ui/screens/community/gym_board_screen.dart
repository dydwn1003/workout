import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/community.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/community_state.dart';
import '../../motion.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'community_common.dart';
import 'community_sheets.dart';
import 'community_widgets.dart';
import 'compose_sheet.dart';
import 'post_screen.dart';

/// One gym's board: a colored header that folds away, tag filters, and the
/// newest posts, more as you scroll.
class GymBoardScreen extends StatefulWidget {
  final Gym gym;
  const GymBoardScreen({super.key, required this.gym});

  @override
  State<GymBoardScreen> createState() => _GymBoardScreenState();
}

class _GymBoardScreenState extends State<GymBoardScreen> {
  static const _page = 20;
  final _posts = <Post>[];
  PostTag? _tag;
  var _loading = true;
  var _failed = false;
  var _hasMore = true;
  var _loadingMore = false;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) _more();
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  CommunityRepository get _repo => CommunityScope.read(context).repo;

  Future<void> _load() async {
    final tag = _tag;
    setState(() {
      _loading = _posts.isEmpty;
      _failed = false;
    });
    try {
      final list = await _repo.posts(widget.gym.id, limit: _page, tag: tag);
      if (!mounted || tag != _tag) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(list);
        _hasMore = list.length == _page;
      });
    } catch (e) {
      debugPrint('board load failed: $e');
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setTag(PostTag? tag) {
    if (tag == _tag) return;
    setState(() {
      _tag = tag;
      _posts.clear();
      _loading = true;
    });
    _load();
  }

  Future<void> _more() async {
    if (_loadingMore || !_hasMore || _posts.isEmpty) return;
    _loadingMore = true;
    try {
      final list = await _repo.posts(
        widget.gym.id,
        before: _posts.last.createdAt,
        limit: _page,
        tag: _tag,
      );
      if (!mounted) return;
      setState(() {
        _posts.addAll(list);
        _hasMore = list.length == _page;
      });
    } catch (_) {
      // Tried again on the next scroll.
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> _write() async {
    if (!await ensureCommunityMember(context) || !mounted) return;
    final post = await showComposeSheet(context, gymId: widget.gym.id);
    if (post == null || !mounted) return;
    HapticFeedback.mediumImpact();
    final c = CommunityScope.read(context);
    if (!widget.gym.isTopic && !c.isMine(widget.gym.id) && !c.gymsFull) {
      try {
        await c.join(widget.gym); // writing here makes it one of my gyms
      } catch (_) {}
    }
    c.postedIn(widget.gym.id);
    setState(() {
      if (_tag == null || _tag == post.tag) _posts.insert(0, post);
    });
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: Motion.medium, curve: Motion.ease);
    }
  }

  Future<void> _toggleJoin() async {
    final c = CommunityScope.read(context);
    if (!await ensureCommunityMember(context) || !mounted) return;
    HapticFeedback.selectionClick();
    if (!c.isMine(widget.gym.id)) {
      await joinGym(context, widget.gym);
      return;
    }
    try {
      await c.leave(widget.gym.id);
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    }
  }

  void _replace(Post post, Post? updated) {
    final i = _posts.indexWhere((p) => p.id == post.id);
    if (i < 0) return;
    setState(() {
      if (updated == null) {
        _posts.removeAt(i);
      } else {
        _posts[i] = updated;
      }
    });
  }

  void _dropAuthor(String authorId) =>
      setState(() => _posts.removeWhere((p) => p.authorId == authorId));

  Future<void> _openPost(Post post) async {
    final result = await Navigator.of(context).push<PostResult>(
      MaterialPageRoute(builder: (_) => PostScreen(post: post)),
    );
    if (result == null || !mounted) return;
    if (result.blockedAuthor != null) {
      _dropAuthor(result.blockedAuthor!);
    } else {
      _replace(post, result.post);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final c = CommunityScope.of(context);
    final mine = c.isMine(widget.gym.id);
    final g = c.myGyms.firstWhere(
      (x) => x.id == widget.gym.id,
      orElse: () => widget.gym,
    );

    return Scaffold(
      floatingActionButton: WriteButton(onTap: _write, label: t.writePost),
      body: RefreshIndicator(
        onRefresh: _load,
        edgeOffset: 120,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: 210,
              backgroundColor: gymDeep(g.id),
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: Text(
                boardName(t, g),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: headingFont,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: t.shareBoard,
                  onPressed: () => shareBoard(context, g),
                  icon: const Icon(Icons.ios_share_rounded),
                ),
                if (!g.isTopic)
                  IconButton(
                    tooltip: mine ? t.leaveGym : t.joinGym,
                    onPressed: _toggleJoin,
                    icon: AnimatedSwitcher(
                      duration: Motion.fast,
                      transitionBuilder: (child, a) =>
                          ScaleTransition(scale: a, child: child),
                      child: Icon(
                        mine
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_add_outlined,
                        key: ValueKey(mine),
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _BoardHeader(
                  gym: g,
                  mine: mine,
                  onJoin: _toggleJoin,
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TagBarDelegate(
                child: TagFilterBar(selected: _tag, onChanged: _setTag),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_failed)
              SliverToBoxAdapter(
                child: Center(
                  child: TextButton(onPressed: _load, child: Text(t.retry)),
                ),
              )
            else if (_posts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                  child: Column(
                    children: [
                      const Mascot(size: 88, mood: MascotMood.sleepy),
                      const SizedBox(height: 12),
                      Text(
                        t.boardEmpty,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                sliver: SliverList.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, i) {
                    final p = _posts[i];
                    return FadeSlideIn(
                      key: ValueKey('${p.id}-${_tag?.name}'),
                      delay: stagger(i),
                      dy: 10,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PostCard(
                          post: p,
                          onTap: () => _openPost(p),
                          onChanged: (u) => _replace(p, u),
                          onBlocked: () => _dropAuthor(p.authorId),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BoardHeader extends StatelessWidget {
  final Gym gym;
  final bool mine;
  final VoidCallback onJoin;
  const _BoardHeader({
    required this.gym,
    required this.mine,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final (color, _) = gymColors(gym.id);
    return Container(
      decoration: BoxDecoration(gradient: gymGradient(gym.id)),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: gym.isTopic ? -30 : -40,
            child: gym.isTopic
                ? Icon(
                    topicStyle(gym.id).$1,
                    size: 170,
                    color: Colors.white.withValues(alpha: 0.14),
                  )
                : Text(
                    gym.name.characters.first,
                    style: TextStyle(
                      fontFamily: headingFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 180,
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (gym.isTopic)
                    Row(
                      children: [
                        const Icon(
                          Icons.public_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t.loungeBoardBadge,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    )
                  else if (gym.address.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            gym.shortAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!gym.isTopic) ...[
                        _StatBubble(
                          Icons.people_alt_rounded,
                          t.gymMembers('${gym.memberCount}'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _StatBubble(
                        Icons.article_rounded,
                        t.gymPosts('${gym.postCount}'),
                      ),
                      const Spacer(),
                      if (!gym.isTopic)
                        GestureDetector(
                          onTap: onJoin,
                          child: AnimatedContainer(
                            duration: Motion.fast,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: mine
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  mine
                                      ? Icons.check_rounded
                                      : Icons.bookmark_add_rounded,
                                  size: 16,
                                  color: mine ? Colors.white : color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  mine ? t.joinedGym : t.joinGym,
                                  style: TextStyle(
                                    fontFamily: headingFont,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: mine ? Colors.white : color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final IconData icon;
  final String text;
  const _StatBubble(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

class _TagBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _TagBarDelegate({required this.child});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      Container(color: AppColors.bg, alignment: Alignment.center, child: child);

  @override
  bool shouldRebuild(_TagBarDelegate old) => old.child != child;
}

/// The floating "글쓰기" pill with the brand gradient.
class WriteButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const WriteButton({super.key, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) => Squish(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.peach, Color(0xFFFFA98F)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.peach.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: headingFont,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
