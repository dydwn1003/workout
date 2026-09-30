import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/community.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/community_state.dart';
import '../../motion.dart';
import '../../theme.dart';
import 'community_common.dart';
import 'gym_board_screen.dart';

/// What happened to the post while it was open, for the board to follow.
class PostResult {
  /// The post as it is now; null when deleted.
  final Post? post;

  /// Set when its author was blocked: the board drops all their posts.
  final String? blockedAuthor;
  const PostResult(this.post, {this.blockedAuthor});
}

class PostScreen extends StatefulWidget {
  final Post post;
  const PostScreen({super.key, required this.post});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  late Post? _post = widget.post;
  String? _blocked;
  List<Comment>? _comments;
  var _failed = false;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  CommunityRepository get _repo => CommunityScope.read(context).repo;

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final list = await _repo.comments(widget.post.id);
      if (mounted) setState(() => _comments = list);
    } catch (e) {
      debugPrint('comments load failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  void _close() => Navigator.pop(
    context,
    PostResult(
      _post?.copyWith(commentCount: _comments?.length),
      blockedAuthor: _blocked,
    ),
  );

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    if (!await ensureCommunityMember(context) || !mounted) return;
    setState(() => _sending = true);
    try {
      final c = await _repo.addComment(widget.post.id, text);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      _input.clear();
      setState(() => _comments = [...?_comments, c]);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: Motion.medium,
            curve: Motion.ease,
          );
        }
      });
    } catch (e) {
      if (mounted) showCommunityError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final post = _post;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _close),
          title: Text(t.communityTitle),
        ),
        body: post == null
            ? const SizedBox()
            : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 24),
                        children: [
                          PostHeader(
                            post: post,
                            onChanged: (u) {
                              if (u == null) {
                                setState(() => _post = null);
                                _close();
                              } else {
                                setState(() => _post = u);
                              }
                            },
                            onBlocked: () {
                              _blocked = post.authorId;
                              _close();
                            },
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SelectableText(
                              post.body,
                              style: const TextStyle(
                                fontSize: 15.5,
                                height: 1.6,
                              ),
                            ),
                          ),
                          if (post.images.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: PhotoStrip(
                                urls: post.images,
                                height: post.images.length == 1 ? 260 : 150,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              LikeButton(
                                post: post,
                                onChanged: (u) =>
                                    setState(() => _post = u ?? _post),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: AppColors.line),
                          Text(
                            t.commentsN(
                              '${_comments?.length ?? post.commentCount}',
                            ),
                            style: const TextStyle(
                              fontFamily: headingFont,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_failed)
                            TextButton(onPressed: _load, child: Text(t.retry))
                          else if (_comments == null)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_comments!.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                t.noComments,
                                style: const TextStyle(
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            )
                          else
                            for (final c in _comments!)
                              FadeSlideIn(
                                key: ValueKey(c.id),
                                dy: 6,
                                child: _CommentTile(
                                  comment: c,
                                  onDeleted: () => setState(
                                    () => _comments!.removeWhere(
                                      (x) => x.id == c.id,
                                    ),
                                  ),
                                  onBlocked: () => setState(
                                    () => _comments!.removeWhere(
                                      (x) => x.authorId == c.authorId,
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  _inputBar(t),
                ],
              ),
      ),
    );
  }

  Widget _inputBar(L t) => Material(
    color: AppColors.card,
    elevation: 8,
    shadowColor: const Color(0x22000000),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                maxLength: CommunityLimits.commentLength,
                buildCounter: (
                  _, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                onTap: () => ensureCommunityMember(context),
                decoration: InputDecoration(
                  hintText: t.commentHint,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 4),
            ListenableBuilder(
              listenable: _input,
              builder: (context, _) => IconButton(
                onPressed: _sending || _input.text.trim().isEmpty
                    ? null
                    : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                color: AppColors.peach,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback onDeleted;
  final VoidCallback onBlocked;
  const _CommentTile({
    required this.comment,
    required this.onDeleted,
    required this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final c = CommunityScope.read(context);
    final mine = comment.authorId == c.repo.myId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NickAvatar(
            userId: comment.authorId,
            nickname: comment.nickname,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: comment.nickname,
                        style: const TextStyle(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: '  ${timeAgo(t, comment.createdAt)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comment.body,
                  style: const TextStyle(fontSize: 14, height: 1.45),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.more_horiz_rounded,
              size: 18,
              color: AppColors.inkSoft,
            ),
            onPressed: () => showContentMenu(
              context,
              mine: mine,
              type: 'comment',
              id: comment.id,
              authorId: comment.authorId,
              nickname: comment.nickname,
              onDelete: () async {
                await c.repo.deleteComment(comment);
                onDeleted();
              },
              onBlocked: onBlocked,
            ),
          ),
        ],
      ),
    );
  }
}
