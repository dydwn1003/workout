import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/community.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_state.dart';
import '../../../state/community_state.dart';
import '../../motion.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../sign_in_sheet.dart';
import 'community_common.dart';
import 'community_sheets.dart';
import 'community_widgets.dart';
import 'gym_board_screen.dart';
import 'lounge_view.dart';
import 'my_activity_screen.dart';
import 'notifications_screen.dart';
import 'post_screen.dart';

/// 커뮤니티 tab: 내 헬스장 (a hero card, my gyms as cards, their newest
/// posts, and a search over every gym) and 운동 라운지 (boards by sport for
/// everyone), with 친구 초대 on top.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  var _tab = 0; // 0: 내 헬스장, 1: 운동 라운지
  var _loungeOpened = false;
  final _query = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  String _q = '';
  List<Gym>? _results;
  var _searching = false;
  var _searchFailed = false;

  // My gyms' feed.
  PostTag? _tag;
  List<Post>? _feed;
  var _feedFailed = false;
  var _feedMore = true;
  var _feedLoadingMore = false;
  String? _feedKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CommunityScope.read(context).refresh();
      _openInvitedBoard();
    });
  }

  /// Opens the board an invite link pointed at (?gym=...).
  Future<void> _openInvitedBoard() async {
    final c = CommunityScope.read(context);
    final id = c.pendingBoard;
    if (id == null) return;
    c.pendingBoard = null;
    try {
      final found = await c.repo.boards([id]);
      if (!mounted || found.isEmpty) return;
      final g = found.first;
      if (g.isTopic) _setTab(1);
      await _openGym(g);
    } catch (e) {
      debugPrint('invite board failed: $e');
    }
  }

  void _setTab(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {
      _tab = i;
      if (i == 1) _loungeOpened = true;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // --- search ---------------------------------------------------------------

  void _onQuery(String v) {
    _debounce?.cancel();
    final q = v.trim();
    if (q.isEmpty) {
      setState(() {
        _q = '';
        _results = null;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String q) async {
    try {
      final r = await CommunityScope.read(context).repo.searchGyms(q);
      if (!mounted || _query.text.trim() != q) return;
      setState(() {
        _q = q;
        _results = r;
        _searching = false;
        _searchFailed = false;
      });
    } catch (e) {
      debugPrint('gym search failed: $e');
      if (!mounted) return;
      setState(() {
        _q = q;
        _results = const [];
        _searching = false;
        _searchFailed = true;
      });
    }
  }

  void _clearSearch() {
    _query.clear();
    _onQuery('');
    FocusScope.of(context).unfocus();
  }

  // --- feed -----------------------------------------------------------------

  /// Reloads the feed when my gyms or the tag changed.
  void _syncFeed(CommunityState c) {
    final ids = [for (final g in c.myGyms) g.id]..sort();
    final key = '${ids.join(',')}|${_tag?.name}';
    if (key == _feedKey) return;
    _feedKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFeed());
  }

  Future<void> _loadFeed() async {
    final c = CommunityScope.read(context);
    final ids = [for (final g in c.myGyms) g.id];
    if (ids.isEmpty) {
      setState(() => _feed = const []);
      return;
    }
    final key = _feedKey;
    setState(() => _feedFailed = false);
    try {
      final list = await c.repo.feed(ids, tag: _tag);
      if (!mounted || key != _feedKey) return;
      setState(() {
        _feed = list;
        _feedMore = list.length == 20;
      });
    } catch (e) {
      debugPrint('feed load failed: $e');
      if (mounted) setState(() => _feedFailed = true);
    }
  }

  Future<void> _moreFeed() async {
    final feed = _feed;
    if (_feedLoadingMore || !_feedMore || feed == null || feed.isEmpty) {
      return;
    }
    _feedLoadingMore = true;
    final c = CommunityScope.read(context);
    try {
      final list = await c.repo.feed(
        [for (final g in c.myGyms) g.id],
        tag: _tag,
        before: feed.last.createdAt,
      );
      if (!mounted) return;
      setState(() {
        _feed = [...feed, ...list];
        _feedMore = list.length == 20;
      });
    } catch (_) {
    } finally {
      _feedLoadingMore = false;
    }
  }

  Future<void> _refresh() async {
    final c = CommunityScope.read(context);
    await c.refresh(force: true);
    _feedKey = null;
    if (mounted) _syncFeed(c);
  }

  void _replace(Post post, Post? updated) {
    final feed = _feed;
    if (feed == null) return;
    setState(() {
      _feed = [
        for (final p in feed)
          if (p.id != post.id) p else ?updated,
      ];
    });
  }

  // --- navigation -----------------------------------------------------------

  Future<void> _openGym(Gym gym) async {
    FocusScope.of(context).unfocus();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => GymBoardScreen(gym: gym)));
    if (mounted) {
      _feedKey = null;
      _syncFeed(CommunityScope.read(context));
    }
  }

  Future<void> _openPost(Post post) async {
    final result = await Navigator.of(context).push<PostResult>(
      MaterialPageRoute(builder: (_) => PostScreen(post: post)),
    );
    if (result == null || !mounted) return;
    if (result.blockedAuthor != null) {
      setState(
        () => _feed = [
          for (final p in _feed ?? const <Post>[])
            if (p.authorId != result.blockedAuthor) p,
        ],
      );
    } else {
      _replace(post, result.post);
    }
  }

  Future<void> _addGym() async {
    if (!await ensureCommunityMember(context) || !mounted) return;
    final gym = await showModalBottomSheet<Gym>(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: Motion.sheet,
      builder: (_) => _AddGymSheet(initialName: _q),
    );
    if (gym == null || !mounted) return;
    await joinGym(context, gym);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(L.of(context).gymAdded)));
    _clearSearch();
    await _openGym(gym);
  }

  // --- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final c = CommunityScope.of(context);
    final app = AppScope.of(context);
    if (c.repo.myId != null && !c.loading && c.profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) c.refresh();
      });
    }
    _syncFeed(c);
    final searching = _query.text.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(t, c, app),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _myGymsTab(t, c, app, searching),
                  if (_loungeOpened) const LoungeView() else const SizedBox(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMe() async {
    if (!await ensureCommunityMember(context) || !mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MyActivityScreen()));
  }

  Widget _topBar(L t, CommunityState c, AppState app) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.navCommunity,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            _BellButton(
              count: c.badge,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (c.signedIn || app.auth != null) ...[
              _MeButton(profile: c.profile, onTap: _openMe),
              const SizedBox(width: 8),
            ],
            Squish(
              child: GestureDetector(
                onTap: () => showInviteSheet(context),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
                  decoration: BoxDecoration(
                    color: AppColors.peachSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 17,
                        color: AppColors.peach,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        t.inviteFriends,
                        style: const TextStyle(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.peach,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Segments(
          index: _tab,
          onChanged: _setTab,
          labels: [
            (
              Icons.bookmark_rounded,
              '${t.tabMyGyms} ${c.myGyms.length}/${CommunityLimits.myGyms}',
            ),
            (Icons.public_rounded, t.tabLounge),
          ],
        ),
      ],
    ),
  );

  Widget _myGymsTab(L t, CommunityState c, AppState app, bool searching) =>
      RefreshIndicator(
        onRefresh: _refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (!searching && n.metrics.extentAfter < 600) _moreFeed();
            return false;
          },
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(child: _header(t, c)),
              SliverToBoxAdapter(child: _searchField(t, searching)),
              if (searching)
                ..._resultSlivers(t, c)
              else ...[
                if (!c.signedIn && app.auth != null)
                  SliverToBoxAdapter(child: _signInCard(t, c)),
                SliverToBoxAdapter(child: _myGyms(t, c)),
                if (c.myGyms.isNotEmpty) ..._feedSlivers(t),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      );

  Widget _header(L t, CommunityState c) {
    final today = (_feed ?? const <Post>[])
        .where((p) => DateTime.now().difference(p.createdAt).inHours < 24)
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF8E7F), Color(0xFFFFB38A)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.peach.withValues(alpha: 0.35),
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
                      Text(
                        t.heroTitle,
                        style: const TextStyle(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          height: 1.3,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _HeroPill(
                            Icons.bookmark_rounded,
                            t.heroMyGyms('${c.myGyms.length}'),
                          ),
                          _HeroPill(
                            Icons.local_fire_department_rounded,
                            t.heroNewToday('$today'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Mascot(size: 76, mood: MascotMood.cheer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField(L t, bool searching) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12B98B6E),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _query,
        focusNode: _searchFocus,
        onChanged: _onQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: t.gymSearchHint,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.peach),
          suffixIcon: searching
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _clearSearch,
                )
              : null,
        ),
      ),
    ),
  );

  List<Widget> _resultSlivers(L t, CommunityState c) {
    final results = _results;
    if (_searching && results == null) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }
    return [
      if (results != null && results.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              t.searchResults('${results.length}'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ),
      if (results != null && results.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: MascotSays(
              text: _searchFailed ? t.communityError : t.gymSearchEmpty(_q),
              mood: MascotMood.thinking,
              size: 52,
            ),
          ),
        ),
      SliverList.builder(
        itemCount: results?.length ?? 0,
        itemBuilder: (context, i) {
          final g = results![i];
          return FadeSlideIn(
            key: ValueKey('gym-${g.id}'),
            delay: stagger(i),
            dy: 8,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: GymRow(
                gym: g,
                mine: c.isMine(g.id),
                onTap: () => _openGym(g),
              ),
            ),
          );
        },
      ),
      SliverToBoxAdapter(
        child: Center(
          child: TextButton.icon(
            onPressed: _addGym,
            icon: const Icon(Icons.add_location_alt_rounded),
            label: Text(t.addGym),
          ),
        ),
      ),
    ];
  }

  Widget _signInCard(L t, CommunityState c) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      child: Row(
        children: [
          const Mascot(size: 44, mood: MascotMood.happy),
          const SizedBox(width: 12),
          Expanded(
            child: Text(t.communitySignIn, style: const TextStyle(height: 1.4)),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () async {
              await showSignInSheet(context);
              if (mounted) await c.refresh(force: true);
            },
            child: Text(t.communitySignInCta),
          ),
        ],
      ),
    ),
  );

  Widget _myGyms(L t, CommunityState c) {
    if (c.loading && c.myGyms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (c.failed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SoftCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(child: Text(t.communityError)),
              TextButton(
                onPressed: () => c.refresh(force: true),
                child: Text(t.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (c.myGyms.isEmpty) return _startCard(t);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: SectionTitle(t.myGyms),
        ),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            children: [
              for (final (i, g) in c.myGyms.indexed)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FadeSlideIn(
                    key: ValueKey('card-${g.id}'),
                    delay: stagger(i),
                    dy: 10,
                    child: GymCard(gym: g, onTap: () => _openGym(g)),
                  ),
                ),
              if (!c.gymsFull)
                FindGymCard(onTap: () => _searchFocus.requestFocus()),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _startCard(L t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Mascot(size: 52, mood: MascotMood.happy),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.startTitle,
                  style: const TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final (i, (icon, text, color, soft)) in [
            (
              Icons.search_rounded,
              t.startStep1,
              AppColors.sky,
              AppColors.skySoft,
            ),
            (
              Icons.bookmark_add_rounded,
              t.startStep2,
              AppColors.peach,
              AppColors.peachSoft,
            ),
            (
              Icons.people_alt_rounded,
              t.startStep3,
              AppColors.mint,
              AppColors.mintSoft,
            ),
          ].indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: soft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontFamily: headingFont,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(text)),
                ],
              ),
            ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: () => _searchFocus.requestFocus(),
            icon: const Icon(Icons.search_rounded),
            label: Text(t.findGym),
          ),
        ],
      ),
    ),
  );

  List<Widget> _feedSlivers(L t) {
    final feed = _feed;
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: SectionTitle(t.myGymsNews),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TagFilterBar(
            selected: _tag,
            onChanged: (tag) => setState(() => _tag = tag),
          ),
        ),
      ),
      if (_feedFailed)
        SliverToBoxAdapter(
          child: Center(
            child: TextButton(onPressed: _loadFeed, child: Text(t.retry)),
          ),
        )
      else if (feed == null)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        )
      else if (feed.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: MascotSays(
              text: t.feedEmpty,
              mood: MascotMood.sleepy,
              size: 52,
            ),
          ),
        )
      else
        SliverList.builder(
          itemCount: feed.length,
          itemBuilder: (context, i) {
            final p = feed[i];
            return FadeSlideIn(
              key: ValueKey('feed-${p.id}-${_tag?.name}'),
              delay: stagger(i),
              dy: 10,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: PostCard(
                  post: p,
                  showGym: true,
                  onTap: () => _openPost(p),
                  onChanged: (u) => _replace(p, u),
                  onBlocked: () => setState(
                    () => _feed = [
                      for (final x in feed)
                        if (x.authorId != p.authorId) x,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
    ];
  }
}

/// 🔔 with the number of unread notifications and new 인기글.
class _BellButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _BellButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: L.of(context).notificationsTitle,
    child: Squish(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF0E6DD),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 21,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (count > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 17),
                    height: 17,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.peach,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.bg, width: 1.5),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        fontFamily: headingFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                        height: 1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// My photo (or a person icon before I have a profile): opens 내 활동.
class _MeButton extends StatelessWidget {
  final CommunityProfile? profile;
  final VoidCallback onTap;
  const _MeButton({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Tooltip(
      message: L.of(context).myActivity,
      child: Squish(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.peach, Color(0xFFFFB38A)],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: p == null
                  ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: AppColors.peach,
                      ),
                    )
                  : NickAvatar(
                      userId: p.userId,
                      nickname: p.nickname,
                      photoUrl: p.avatarUrl,
                      size: 30,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 내 헬스장 | 운동 라운지, with a sliding highlight.
class _Segments extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<(IconData, String)> labels;
  const _Segments({
    required this.index,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFF3ECE6),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Stack(
      children: [
        AnimatedAlign(
          duration: Motion.medium,
          curve: Motion.ease,
          alignment: index == 0 ? Alignment.centerLeft : Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 1 / labels.length,
            heightFactor: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A8B6E5A),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            for (final (i, (icon, label)) in labels.indexed)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 17,
                          color: i == index
                              ? (i == 0
                                    ? AppColors.peach
                                    : const Color(0xFF6A7FE0))
                              : AppColors.inkSoft,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: headingFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: i == index
                                ? AppColors.ink
                                : AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroPill(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(20),
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

class _AddGymSheet extends StatefulWidget {
  final String initialName;
  const _AddGymSheet({required this.initialName});

  @override
  State<_AddGymSheet> createState() => _AddGymSheetState();
}

class _AddGymSheetState extends State<_AddGymSheet> {
  late final _name = TextEditingController(text: widget.initialName);
  final _address = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final gym = await CommunityScope.read(context).repo
          .addGym(_name.text, _address.text);
      if (mounted) Navigator.pop(context, gym);
    } catch (e) {
      if (mounted) showCommunityError(context, e);
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
        20,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.peachSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.add_location_alt_rounded,
                  color: AppColors.peach,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                t.addGymTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 60,
            decoration: InputDecoration(labelText: t.gymName),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _address,
            maxLength: 200,
            decoration: InputDecoration(labelText: t.gymAddress),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: Listenable.merge([_name, _address]),
            builder: (context, _) => FilledButton(
              onPressed:
                  _busy ||
                      _name.text.trim().isEmpty ||
                      _address.text.trim().isEmpty
                  ? null
                  : _save,
              child: Text(t.save),
            ),
          ),
        ],
      ),
    );
  }
}
