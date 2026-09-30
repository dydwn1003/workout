import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/community.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_state.dart';
import '../../../state/community_state.dart';
import '../../motion.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../sign_in_sheet.dart';
import 'community_common.dart';
import 'gym_board_screen.dart';

/// 커뮤니티 tab: my gyms, and a search over every gym to find the others.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  String _q = '';
  List<Gym>? _results;
  var _searching = false;
  var _searchFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) CommunityScope.read(context).refresh();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

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

  Future<void> _open(Gym gym) async {
    FocusScope.of(context).unfocus();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => GymBoardScreen(gym: gym)));
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
    final c = CommunityScope.read(context);
    try {
      await c.join(gym);
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(L.of(context).gymAdded)));
    _query.clear();
    _onQuery('');
    await _open(gym);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final c = CommunityScope.of(context);
    final app = AppScope.of(context);
    // Signed in or out elsewhere (settings): reload who I am.
    if (c.repo.myId != null && !c.loading && c.profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) c.refresh();
      });
    }
    final searching = _query.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(t.communityTitle)),
      body: RefreshIndicator(
        onRefresh: () => c.refresh(force: true),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
              child: Text(
                t.communityIntro,
                style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
              ),
            ),
            TextField(
              controller: _query,
              onChanged: _onQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: t.gymSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searching
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _query.clear();
                          _onQuery('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: Motion.fast,
              child: searching
                  ? _resultsView(t)
                  : _myGymsView(t, c, app.auth != null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultsView(L t) {
    final results = _results;
    return Column(
      key: const ValueKey('results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_searching && results == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          if (results != null && results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                _searchFailed ? t.communityError : t.gymSearchEmpty(_q),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkSoft),
              ),
            ),
          for (final (i, g) in (results ?? const <Gym>[]).indexed)
            FadeSlideIn(
              key: ValueKey('gym-${g.id}'),
              delay: stagger(i),
              dy: 8,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GymTile(gym: g, onTap: () => _open(g)),
              ),
            ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _addGym,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(t.addGym),
          ),
        ],
      ],
    );
  }

  Widget _myGymsView(L t, CommunityState c, bool canSignIn) {
    return Column(
      key: const ValueKey('mine'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!c.signedIn && canSignIn) ...[
          SoftCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(
                  Icons.forum_outlined,
                  color: AppColors.peach,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.communitySignIn,
                    style: const TextStyle(height: 1.4),
                  ),
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
          const SizedBox(height: 12),
        ],
        SectionTitle(t.myGyms),
        if (c.loading && c.myGyms.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (c.failed)
          SoftCard(
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
          )
        else if (c.myGyms.isEmpty)
          SoftCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.peachSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.peach,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.myGymsEmpty,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (final (i, g) in c.myGyms.indexed)
            FadeSlideIn(
              key: ValueKey('my-${g.id}'),
              delay: stagger(i),
              dy: 8,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GymTile(gym: g, mine: true, onTap: () => _open(g)),
              ),
            ),
      ],
    );
  }
}

/// A gym in a list: name, area, members and posts.
class GymTile extends StatelessWidget {
  final Gym gym;
  final bool mine;
  final VoidCallback onTap;
  const GymTile({
    super.key,
    required this.gym,
    required this.onTap,
    this.mine = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final last = gym.lastPostAt;
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: mine ? AppColors.peach : AppColors.peachSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              color: mine ? Colors.white : AppColors.peach,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gym.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                if (gym.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    gym.shortAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  [
                    t.gymMembers('${gym.memberCount}'),
                    t.gymPosts('${gym.postCount}'),
                    if (last != null) timeAgo(t, last),
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
        ],
      ),
    );
  }
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
          Text(t.addGymTitle, style: Theme.of(context).textTheme.titleLarge),
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
