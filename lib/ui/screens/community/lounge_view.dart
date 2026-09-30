import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/community.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/community_state.dart';
import '../../motion.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'community_common.dart';
import 'community_widgets.dart';
import 'compose_sheet.dart';
import 'gym_board_screen.dart';
import 'post_screen.dart';

/// 운동 라운지: boards by sport that every member shares, this week's hot
/// posts, and the newest posts across them.
class LoungeView extends StatefulWidget {
  const LoungeView({super.key});

  @override
  State<LoungeView> createState() => _LoungeViewState();
}

class _LoungeViewState extends State<LoungeView> {
  static const _page = 20;
  List<Gym>? _boards;
  List<Post>? _hot;
  List<Post>? _latest;
  String? _topic; // null: every board
  var _failed = false;
  var _hasMore = true;
  var _loadingMore = false;

  CommunityRepository get _repo => CommunityScope.read(context).repo;
  List<String> get _shown => CommunityScope.read(context).loungeBoards;
  List<String> get _ids => _topic == null ? _shown : [_topic!];
  String? _shownKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  /// Reloads when the boards shown change (favorites only on/off, stars).
  void _syncShown(CommunityState c) {
    final key = c.loungeBoards.join(',');
    if (_shownKey == null) {
      _shownKey = key;
      return;
    }
    if (key == _shownKey) return;
    _shownKey = key;
    if (_topic != null && !c.loungeBoards.contains(_topic)) _topic = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    final shown = _shown;
    try {
      final r = await Future.wait([
        _repo.boards(topicIds),
        _repo.hot(shown, limit: 3),
        _repo.feed(_ids, limit: _page),
      ]);
      if (!mounted || shown.join(',') != _shown.join(',')) return;
      final boards = r[0] as List<Gym>;
      setState(() {
        // Boards the server doesn't have yet still show (0 posts).
        _boards = [
          for (final id in topicIds)
            boards.where((g) => g.id == id).firstOrNull ??
                Gym(id: id, name: id),
        ];
        _hot = r[1] as List<Post>;
        _latest = r[2] as List<Post>;
        _hasMore = _latest!.length == _page;
      });
    } catch (e) {
      debugPrint('lounge load failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _setTopic(String? id) async {
    if (id == _topic) return;
    HapticFeedback.selectionClick();
    setState(() {
      _topic = id;
      _latest = null;
    });
    try {
      final list = await _repo.feed(_ids, limit: _page);
      if (!mounted || id != _topic) return;
      setState(() {
        _latest = list;
        _hasMore = list.length == _page;
      });
    } catch (e) {
      if (mounted) setState(() => _latest = const []);
    }
  }

  Future<void> _more() async {
    final latest = _latest;
    if (_loadingMore || !_hasMore || latest == null || latest.isEmpty) return;
    _loadingMore = true;
    final topic = _topic;
    try {
      final list = await _repo.feed(
        _ids,
        before: latest.last.createdAt,
        limit: _page,
      );
      if (!mounted || topic != _topic) return;
      setState(() {
        _latest = [...latest, ...list];
        _hasMore = list.length == _page;
      });
    } catch (_) {
    } finally {
      _loadingMore = false;
    }
  }

  void _replace(Post post, Post? updated) {
    List<Post>? swap(List<Post>? l) => l == null
        ? null
        : [
            for (final p in l)
              if (p.id != post.id) p else ?updated,
          ];
    setState(() {
      _latest = swap(_latest);
      _hot = swap(_hot);
    });
  }

  void _dropAuthor(String id) => setState(() {
    _latest = [...?_latest?.where((p) => p.authorId != id)];
    _hot = [...?_hot?.where((p) => p.authorId != id)];
  });

  Future<void> _openBoard(Gym g) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => GymBoardScreen(gym: g)));
    if (mounted) _load();
  }

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

  Future<void> _write() async {
    if (!await ensureCommunityMember(context) || !mounted) return;
    final id =
        _topic ??
        await showModalBottomSheet<String>(
          context: context,
          sheetAnimationStyle: Motion.sheet,
          builder: (_) => const _TopicPicker(),
        );
    if (id == null || !mounted) return;
    final post = await showComposeSheet(context, gymId: id);
    if (post == null || !mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _latest = [post, ...?_latest]);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    _syncShown(CommunityScope.of(context));
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 600) _more();
              return false;
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _banner(t)),
                if (_failed)
                  SliverToBoxAdapter(
                    child: Center(
                      child: TextButton(onPressed: _load, child: Text(t.retry)),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(child: _categories(t)),
                  SliverToBoxAdapter(child: _hotSection(t)),
                  ..._latestSlivers(t),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: WriteButton(onTap: _write, label: t.writePost),
        ),
      ],
    );
  }

  Widget _banner(L t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C6BD6), Color(0xFF5C9BE6)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A84E0).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.public_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t.loungeTitle,
                      style: const TextStyle(
                        fontFamily: headingFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  t.loungeSubtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          const Mascot(size: 64, mood: MascotMood.happy),
        ],
      ),
    ),
  );

  Widget _categories(L t) {
    final boards = _boards;
    final c = CommunityScope.of(context);
    final favOnly = c.loungeFavoritesOnly;
    // Favorites first; only them when asked (and there are some).
    final ids = favOnly && c.favoriteTopics.isNotEmpty
        ? c.loungeBoards
        : [
            ...topicIds.where(c.isFavorite),
            ...topicIds.where((id) => !c.isFavorite(id)),
          ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            t.loungeCategories,
            trailing: _FavOnlySwitch(
              on: favOnly,
              label: t.favoritesOnly,
              onTap: () {
                HapticFeedback.selectionClick();
                c.setLoungeFavoritesOnly(!favOnly);
              },
            ),
          ),
          if (favOnly && c.favoriteTopics.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                t.favoritesHint,
                style: const TextStyle(color: AppColors.inkSoft),
              ),
            ),
          LayoutBuilder(
            builder: (context, box) {
              const gap = 8.0;
              final w = (box.maxWidth - 8 - gap * 3) / 4;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final (i, id) in ids.indexed)
                      FadeSlideIn(
                        key: ValueKey('topic-$id'),
                        delay: stagger(i),
                        dy: 8,
                        child: SizedBox(
                          width: w,
                          child: _TopicTile(
                            id: id,
                            favorite: c.isFavorite(id),
                            onFavorite: () {
                              HapticFeedback.selectionClick();
                              c.toggleFavorite(id);
                            },
                            posts: boards == null
                                ? null
                                : boards
                                          .where((g) => g.id == id)
                                          .firstOrNull
                                          ?.postCount ??
                                      0,
                            onTap: () => _openBoard(
                              boards?.where((g) => g.id == id).firstOrNull ??
                                  Gym(id: id, name: topicName(t, id) ?? id),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _hotSection(L t) {
    final hot = _hot;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(t.loungeHot),
          if (hot == null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (hot.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                t.loungeHotEmpty,
                style: const TextStyle(color: AppColors.inkSoft),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF0E6DD)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, p) in hot.indexed) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          indent: 14,
                          endIndent: 14,
                          color: Color(0xFFF3ECE6),
                        ),
                      _HotRow(rank: i + 1, post: p, onTap: () => _openPost(p)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _latestSlivers(L t) {
    final latest = _latest;
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SectionTitle(t.loungeLatest),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _TopicChip(
                label: t.allBoards,
                icon: Icons.apps_rounded,
                color: AppColors.ink,
                selected: _topic == null,
                onTap: () => _setTopic(null),
              ),
              for (final id in CommunityScope.of(context).loungeBoards)
                _TopicChip(
                  label: topicName(t, id)!,
                  icon: topicStyle(id).$1,
                  color: topicStyle(id).$2,
                  selected: _topic == id,
                  onTap: () => _setTopic(id),
                ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 14)),
      if (latest == null)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        )
      else if (latest.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: MascotSays(
              text: t.loungeEmpty,
              mood: MascotMood.sleepy,
              size: 52,
            ),
          ),
        )
      else
        SliverList.builder(
          itemCount: latest.length,
          itemBuilder: (context, i) {
            final p = latest[i];
            return FadeSlideIn(
              key: ValueKey('lounge-${p.id}-$_topic'),
              delay: stagger(i),
              dy: 10,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: PostCard(
                  post: p,
                  showGym: _topic == null,
                  onTap: () => _openPost(p),
                  onChanged: (u) => _replace(p, u),
                  onBlocked: () => _dropAuthor(p.authorId),
                ),
              ),
            );
          },
        ),
    ];
  }
}

class _TopicTile extends StatelessWidget {
  final String id;
  final int? posts;
  final VoidCallback onTap;
  final bool favorite;

  /// Null hides the star (the board picker).
  final VoidCallback? onFavorite;
  const _TopicTile({
    required this.id,
    required this.posts,
    required this.onTap,
    this.favorite = false,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final (icon, color) = topicStyle(id);
    return Stack(
      children: [
        Squish(
          child: SizedBox(
            width: double.infinity,
            child: Material(
              color: favorite
                  ? Color.lerp(color, Colors.white, 0.9)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: favorite
                      ? color.withValues(alpha: 0.45)
                      : const Color(0xFFF0E6DD),
                  width: favorite ? 1.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(color, Colors.white, 0.25)!,
                              color,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        topicName(t, id)!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: AppColors.ink,
                        ),
                      ),
                      if (posts != null)
                        Text(
                          t.gymPosts('$posts'),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onFavorite != null)
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onFavorite,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: AnimatedSwitcher(
                  duration: Motion.fast,
                  transitionBuilder: (child, a) =>
                      ScaleTransition(scale: a, child: child),
                  child: Icon(
                    favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    key: ValueKey(favorite),
                    size: 20,
                    color: favorite
                        ? const Color(0xFFF5B400)
                        : AppColors.inkSoft.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TopicChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.ease,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : const Color(0xFFF0E6DD),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: headingFont,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HotRow extends StatelessWidget {
  final int rank;
  final Post post;
  final VoidCallback onTap;
  const _HotRow({required this.rank, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final (icon, color) = topicStyle(post.gymId);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontFamily: headingFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: rank == 1 ? AppColors.peach : AppColors.inkSoft,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 13, color: color),
                      const SizedBox(width: 3),
                      Text(
                        postBoardName(t, post) ?? '',
                        style: TextStyle(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
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

/// ★ 즐겨찾기만: shows only my starred boards.
class _FavOnlySwitch extends StatelessWidget {
  final bool on;
  final String label;
  final VoidCallback onTap;
  const _FavOnlySwitch({
    required this.on,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: Motion.fast,
      curve: Motion.ease,
      padding: const EdgeInsets.fromLTRB(9, 6, 11, 6),
      decoration: BoxDecoration(
        color: on ? const Color(0xFFF5B400) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: on ? const Color(0xFFF5B400) : const Color(0xFFF0E6DD),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            on ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16,
            color: on ? Colors.white : const Color(0xFFF5B400),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: headingFont,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: on ? Colors.white : AppColors.ink,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Which 라운지 board a new post goes to.
class _TopicPicker extends StatelessWidget {
  const _TopicPicker();

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.chooseTopic, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, box) {
                final w = (box.maxWidth - 8 * 3) / 4;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in topicIds)
                      SizedBox(
                        width: w,
                        child: _TopicTile(
                          id: id,
                          posts: null,
                          onTap: () => Navigator.pop(context, id),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
