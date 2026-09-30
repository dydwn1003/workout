import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/community.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/community_state.dart';
import '../../motion.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'community_common.dart';
import 'post_screen.dart';

/// One gym's board: newest posts first, more as you scroll.
class GymBoardScreen extends StatefulWidget {
  final Gym gym;
  const GymBoardScreen({super.key, required this.gym});

  @override
  State<GymBoardScreen> createState() => _GymBoardScreenState();
}

class _GymBoardScreenState extends State<GymBoardScreen> {
  static const _page = 20;
  final _posts = <Post>[];
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
    setState(() {
      _loading = _posts.isEmpty;
      _failed = false;
    });
    try {
      final list = await _repo.posts(widget.gym.id, limit: _page);
      if (!mounted) return;
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

  Future<void> _more() async {
    if (_loadingMore || !_hasMore || _posts.isEmpty) return;
    _loadingMore = true;
    try {
      final list = await _repo.posts(
        widget.gym.id,
        before: _posts.last.createdAt,
        limit: _page,
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
    HapticFeedback.lightImpact();
    final c = CommunityScope.read(context);
    if (!c.isMine(widget.gym.id)) {
      try {
        await c.join(widget.gym); // writing here makes it one of my gyms
      } catch (_) {}
    }
    c.postedIn(widget.gym.id);
    setState(() => _posts.insert(0, post));
    _scroll.animateTo(0, duration: Motion.medium, curve: Motion.ease);
  }

  Future<void> _toggleJoin() async {
    final c = CommunityScope.read(context);
    if (!await ensureCommunityMember(context) || !mounted) return;
    HapticFeedback.selectionClick();
    try {
      c.isMine(widget.gym.id)
          ? await c.leave(widget.gym.id)
          : await c.join(widget.gym);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gym.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: mine ? t.leaveGym : t.joinGym,
            onPressed: _toggleJoin,
            icon: AnimatedSwitcher(
              duration: Motion.fast,
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: Icon(
                mine ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                key: ValueKey(mine),
                color: mine ? AppColors.peach : null,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _write,
        icon: const Icon(Icons.edit_rounded),
        label: Text(t.writePost),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          itemCount: _posts.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) return _header(t, mine);
            final p = _posts[i - 1];
            return FadeSlideIn(
              key: ValueKey(p.id),
              delay: stagger(i - 1),
              dy: 8,
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
    );
  }

  Widget _header(L t, bool mine) {
    final g = widget.gym;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (g.address.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: AppColors.inkSoft,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    g.address,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!mine)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: _toggleJoin,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(t.joinGym),
            ),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_failed)
          SoftCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(child: Text(t.communityError)),
                TextButton(onPressed: _load, child: Text(t.retry)),
              ],
            ),
          )
        else if (_posts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                const Icon(
                  Icons.forum_outlined,
                  size: 40,
                  color: AppColors.peach,
                ),
                const SizedBox(height: 10),
                Text(
                  t.boardEmpty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A post in the board: author, time, text (shortened), photos, likes.
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final ValueChanged<Post?> onChanged;
  final VoidCallback onBlocked;
  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onChanged,
    required this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PostHeader(post: post, onChanged: onChanged, onBlocked: onBlocked),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              post.body,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14.5, height: 1.5),
            ),
          ),
          if (post.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PhotoStrip(urls: post.images),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              LikeButton(post: post, onChanged: onChanged),
              const SizedBox(width: 4),
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: AppColors.inkSoft,
              ),
              const SizedBox(width: 4),
              Text(
                t.commentsN('${post.commentCount}'),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Avatar, nickname, time and the ⋮ menu.
class PostHeader extends StatelessWidget {
  final Post post;
  final ValueChanged<Post?> onChanged;
  final VoidCallback onBlocked;
  const PostHeader({
    super.key,
    required this.post,
    required this.onChanged,
    required this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final c = CommunityScope.read(context);
    final mine = post.authorId == c.repo.myId;
    return Row(
      children: [
        NickAvatar(userId: post.authorId, nickname: post.nickname),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.nickname,
                style: const TextStyle(
                  fontFamily: headingFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                [
                  timeAgo(t, post.createdAt),
                  if (post.editedAt != null) t.edited,
                ].join(' · '),
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.inkSoft),
          onPressed: () => showContentMenu(
            context,
            mine: mine,
            type: 'post',
            id: post.id,
            authorId: post.authorId,
            nickname: post.nickname,
            onEdit: () async {
              final edited = await showComposeSheet(
                context,
                gymId: post.gymId,
                editing: post,
              );
              if (edited != null) onChanged(edited);
            },
            onDelete: () async {
              await c.repo.deletePost(post);
              onChanged(null);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(t.postDeleted)));
              }
            },
            onBlocked: onBlocked,
          ),
        ),
      ],
    );
  }
}

/// ♡ 3 — toggles right away, undone if the server says no.
class LikeButton extends StatelessWidget {
  final Post post;
  final ValueChanged<Post?> onChanged;
  const LikeButton({super.key, required this.post, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final liked = post.likedByMe;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: liked ? AppColors.peach : AppColors.inkSoft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 36),
      ),
      onPressed: () async {
        if (!await ensureCommunityMember(context) || !context.mounted) return;
        HapticFeedback.selectionClick();
        final next = post.copyWith(
          likedByMe: !liked,
          likeCount: post.likeCount + (liked ? -1 : 1),
        );
        onChanged(next);
        try {
          await CommunityScope.read(context).repo.setLike(post.id, !liked);
        } catch (e) {
          onChanged(post);
          if (context.mounted) showCommunityError(context, e);
        }
      },
      icon: AnimatedSwitcher(
        duration: Motion.fast,
        transitionBuilder: (child, a) =>
            ScaleTransition(scale: a, child: child),
        child: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(liked),
          size: 18,
        ),
      ),
      label: Text('${post.likeCount}', style: const TextStyle(fontSize: 13)),
    );
  }
}

/// Up to 4 photos in a row; tap one to see it full screen.
class PhotoStrip extends StatelessWidget {
  final List<String> urls;
  final double height;
  const PhotoStrip({super.key, required this.urls, this.height = 110});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (final (i, u) in urls.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () => showPhotoViewer(context, urls, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Hero(
                    tag: u,
                    child: Image.network(
                      u,
                      fit: BoxFit.cover,
                      height: height,
                      cacheWidth: 480,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.line,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> showPhotoViewer(BuildContext context, List<String> urls, int i) =>
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, a, _) => FadeTransition(
          opacity: a,
          child: _PhotoViewer(urls: urls, initial: i),
        ),
      ),
    );

class _PhotoViewer extends StatelessWidget {
  final List<String> urls;
  final int initial;
  const _PhotoViewer({required this.urls, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView(
        controller: PageController(initialPage: initial),
        children: [
          for (final u in urls)
            InteractiveViewer(
              child: Center(
                child: Hero(tag: u, child: Image.network(u)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Write a post (or edit one's text): returns the saved post.
Future<Post?> showComposeSheet(
  BuildContext context, {
  required String gymId,
  Post? editing,
}) => showModalBottomSheet<Post>(
  context: context,
  isScrollControlled: true,
  sheetAnimationStyle: Motion.sheet,
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.9,
    child: _ComposeSheet(gymId: gymId, editing: editing),
  ),
);

class _ComposeSheet extends StatefulWidget {
  final String gymId;
  final Post? editing;
  const _ComposeSheet({required this.gymId, this.editing});

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  late final _body = TextEditingController(text: widget.editing?.body);
  final _photos = <Uint8List>[];
  var _busy = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final t = L.of(context);
    final room = CommunityLimits.photos - _photos.length;
    if (room <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.photoLimit('${CommunityLimits.photos}'))),
      );
      return;
    }
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        limit: room > 1 ? room : null,
      );
      var rejected = false;
      final picked = <Uint8List>[];
      for (final f in files.take(room)) {
        final bytes = await f.readAsBytes();
        if (imageMimeType(bytes) == null ||
            bytes.length > CommunityLimits.photoBytes) {
          rejected = true;
        } else {
          picked.add(bytes);
        }
      }
      if (!mounted) return;
      setState(() => _photos.addAll(picked));
      if (rejected) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.badImage)));
      }
    } catch (e) {
      debugPrint('photo pick failed: $e');
    }
  }

  Future<void> _submit() async {
    final text = _body.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    final repo = CommunityScope.read(context).repo;
    try {
      final post = widget.editing == null
          ? await repo.writePost(widget.gymId, text, _photos)
          : await repo.editPost(widget.editing!, text);
      if (mounted) Navigator.pop(context, post);
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final editing = widget.editing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        12 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  editing ? t.editPost : t.writePost,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListenableBuilder(
                listenable: _body,
                builder: (context, _) => FilledButton(
                  onPressed: _busy || _body.text.trim().isEmpty
                      ? null
                      : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(editing ? t.save : t.postSubmit),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _body,
              autofocus: true,
              maxLines: null,
              expands: true,
              maxLength: CommunityLimits.postLength,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(hintText: t.postHint),
            ),
          ),
          if (!editing) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _AddPhotoButton(
                    count: _photos.length,
                    onTap: _busy ? null : _pick,
                  ),
                  for (final (i, b) in _photos.indexed)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              b,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              cacheWidth: 216,
                            ),
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: GestureDetector(
                              onTap: _busy
                                  ? null
                                  : () => setState(() => _photos.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  const _AddPhotoButton({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_a_photo_outlined, color: AppColors.inkSoft),
          const SizedBox(height: 2),
          Text(
            '$count/${CommunityLimits.photos}',
            style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    ),
  );
}
