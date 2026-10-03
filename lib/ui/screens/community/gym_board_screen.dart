import 'dart:async';

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

  /// 인기순: the month's most liked (one page) instead of the newest.
  var _popular = false;

  /// Board search: open, and what's typed (applied after a short pause).
  var _searchOpen = false;
  var _query = '';
  final _queryCtrl = TextEditingController();
  Timer? _queryDebounce;
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
    _queryDebounce?.cancel();
    _queryCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  CommunityRepository get _repo => CommunityScope.read(context).repo;

  Future<void> _load() async {
    final (tag, popular, query) = (_tag, _popular, _query);
    setState(() {
      _loading = _posts.isEmpty;
      _failed = false;
    });
    try {
      final q = query.trim().toLowerCase();
      final list = popular
          ? [
              for (final p in await _repo.hot(
                [widget.gym.id],
                days: 30,
                limit: 40,
              ))
                if ((tag == null || p.tag == tag) &&
                    (q.isEmpty || p.body.toLowerCase().contains(q)))
                  p,
            ]
          : await _repo.posts(
              widget.gym.id,
              limit: _page,
              tag: tag,
              query: q.isEmpty ? null : query,
            );
      if (!mounted || tag != _tag || popular != _popular || query != _query) {
        return;
      }
      setState(() {
        _posts
          ..clear()
          ..addAll(list);
        _hasMore = !popular && list.length == _page;
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

  void _setPopular(bool on) {
    if (on == _popular) return;
    HapticFeedback.selectionClick();
    setState(() {
      _popular = on;
      _posts.clear();
      _loading = true;
    });
    _load();
  }

  void _onQuery(String v) {
    _queryDebounce?.cancel();
    _queryDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || v == _query) return;
      setState(() {
        _query = v;
        _posts.clear();
        _loading = true;
      });
      _load();
    });
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen && _query.isNotEmpty) {
      _queryCtrl.clear();
      _onQuery('');
    }
  }

  Future<void> _more() async {
    if (_loadingMore || !_hasMore || _popular || _posts.isEmpty) return;
    _loadingMore = true;
    try {
      final list = await _repo.posts(
        widget.gym.id,
        before: _posts.last.createdAt,
        limit: _page,
        tag: _tag,
        query: _query.trim().isEmpty ? null : _query,
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

  /// Board search (when open) and 최신순 · 인기순.
  Widget _toolsRow(L t) {
    Widget sort(String label, bool on, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (on) ...[
              const Icon(Icons.check_rounded, size: 15, color: AppColors.ink),
              const SizedBox(width: 2),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: headingFont,
                fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: on ? AppColors.ink : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 10, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: Motion.fast,
            curve: Motion.ease,
            child: !_searchOpen
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 6),
                    child: TextField(
                      controller: _queryCtrl,
                      autofocus: true,
                      onChanged: _onQuery,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: t.searchPostsHint,
                        isDense: true,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.inkSoft,
                        ),
                        suffixIcon: IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: _toggleSearch,
                        ),
                      ),
                    ),
                  ),
          ),
          Row(
            children: [
              if (_query.trim().isNotEmpty && !_loading)
                Text(
                  t.searchPostsCount('${_posts.length}${_hasMore ? '+' : ''}'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              const Spacer(),
              sort(t.sortNewest, !_popular, () => _setPopular(false)),
              const Text('·', style: TextStyle(color: AppColors.inkSoft)),
              sort(t.sortPopular, _popular, () => _setPopular(true)),
            ],
          ),
        ],
      ),
    );
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
    final t = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await c.leave(widget.gym.id);
      // One tap took it out: one tap puts it back.
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              t.leftGym(josa(t.localeName, widget.gym.name, '을', '를')),
            ),
            action: SnackBarAction(
              label: t.undo,
              onPressed: () => c.join(widget.gym).catchError((_) {}),
            ),
          ),
        );
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
              expandedHeight: 132,
              backgroundColor: Color.lerp(
                gymColors(g.id).$1,
                AppColors.bg,
                0.86,
              ),
              foregroundColor: AppColors.ink,
              surfaceTintColor: Colors.transparent,
              title: Text(
                boardName(t, g),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: headingFont,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  fontSize: 18,
                ),
              ),
              actions: [
                if (g.isTopic)
                  IconButton(
                    tooltip: t.favoriteAdd,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      final on = !c.isFavorite(g.id);
                      c.toggleFavorite(g.id);
                      if (on) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(t.favoriteAdded)),
                          );
                      }
                    },
                    icon: AnimatedSwitcher(
                      duration: Motion.fast,
                      transitionBuilder: (child, a) =>
                          ScaleTransition(scale: a, child: child),
                      child: Icon(
                        c.isFavorite(g.id)
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        key: ValueKey(c.isFavorite(g.id)),
                        color: c.isFavorite(g.id)
                            ? const Color(0xFFF5B400)
                            : AppColors.ink,
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: t.searchPosts,
                  onPressed: _toggleSearch,
                  icon: Icon(
                    _searchOpen
                        ? Icons.search_off_rounded
                        : Icons.search_rounded,
                  ),
                ),
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
                        color: AppColors.ink,
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
            SliverToBoxAdapter(child: _toolsRow(t)),
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
                        _query.trim().isNotEmpty
                            ? t.searchPostsEmpty(
                                josa(
                                  t.localeName,
                                  "'${_query.trim()}'",
                                  '이',
                                  '가',
                                ),
                              )
                            : _popular
                            ? t.popularEmpty
                            : t.boardEmpty,
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
    const soft = TextStyle(fontSize: 13, color: AppColors.inkSoft);
    final meta = [
      if (gym.isTopic)
        t.loungeBoardBadge
      else if (gym.address.isNotEmpty)
        gym.shortAddress,
      if (!gym.isTopic) t.gymMembers('${gym.memberCount}'),
      t.gymPosts('${gym.postCount}'),
    ].join(' · ');
    final (color, _) = gymColors(gym.id);
    return ColoredBox(
      color: Color.lerp(color, AppColors.bg, 0.86)!,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 58, 16, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  gym.isTopic
                      ? topicStyle(gym.id).$1
                      : Icons.fitness_center_rounded,
                  size: 21,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  meta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: soft,
                ),
              ),
              if (!gym.isTopic) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onJoin,
                  child: AnimatedContainer(
                    duration: Motion.fast,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: mine ? Colors.white : color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      mine ? t.joinedGym : t.joinGym,
                      style: TextStyle(
                        fontFamily: headingFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: mine ? color : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFA36C), AppColors.peach, Color(0xFFFF7A8A)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.peach.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
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
