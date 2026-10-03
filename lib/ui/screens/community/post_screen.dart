import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../data/community.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/community_state.dart';
import '../../motion.dart';
import '../../theme.dart';
import 'community_common.dart';
import 'community_widgets.dart';

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

  /// A comment to scroll to and flash (opened from 내 활동).
  final String? focusCommentId;
  const PostScreen({super.key, required this.post, this.focusCommentId});

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
  var _photo = 0;
  final _inputFocus = FocusNode();

  /// The comment being answered; null writes a top-level comment.
  Comment? _replyTo;

  final _focusKey = GlobalKey();
  String? _flash;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  CommunityRepository get _repo => CommunityScope.read(context).repo;

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final list = await _repo.comments(widget.post.id);
      if (!mounted) return;
      final first = _comments == null;
      setState(() => _comments = list);
      final focus = widget.focusCommentId;
      if (first && focus != null && list.any((c) => c.id == focus)) {
        _showFocused(focus);
      }
    } catch (e) {
      debugPrint('comments load failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  /// 답글 달기: "@닉네임 " goes in front of what's typed (replacing an
  /// earlier @someone), so the reply says who it answers.
  void _startReply(Comment c) {
    final rest = _input.text.replaceFirst(_mentionPrefix, '');
    final text = '@${c.nickname} $rest';
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _replyTo = c);
    _inputFocus.requestFocus();
  }

  void _cancelReply() {
    _input.text = _input.text.replaceFirst(_mentionPrefix, '');
    setState(() => _replyTo = null);
  }

  void _swapComment(Comment c) => setState(
    () => _comments = [
      for (final x in _comments ?? const <Comment>[])
        if (x.id == c.id) c else x,
    ],
  );

  /// Heart on a comment: shown at once, undone if the server says no.
  Future<void> _likeComment(Comment c) async {
    if (!await ensureCommunityMember(context) || !mounted) return;
    HapticFeedback.selectionClick();
    final on = !c.likedByMe;
    _swapComment(
      c.copyWith(likedByMe: on, likeCount: c.likeCount + (on ? 1 : -1)),
    );
    try {
      await _repo.setCommentLike(c.id, on);
    } catch (e) {
      if (!mounted) return;
      _swapComment(c);
      showCommunityError(context, e);
    }
  }

  /// Scrolls to the comment and flashes it for a moment.
  void _showFocused(String id) {
    setState(() => _flash = id);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctx = _focusKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.3,
          duration: Motion.medium,
          curve: Motion.ease,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 1800));
      if (mounted) setState(() => _flash = null);
    });
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
    final replyTo = _replyTo;
    try {
      final c = await _repo.addComment(
        widget.post.id,
        text,
        parentId: replyTo == null ? null : (replyTo.parentId ?? replyTo.id),
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      _input.clear();
      setState(() {
        _comments = [...?_comments, c];
        _replyTo = null;
      });
      if (replyTo != null) return; // stays where the thread is
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
          title: Text(
            (post == null ? null : postBoardName(t, post)) ?? t.communityTitle,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (post != null)
              PostMenuButton(
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
            const SizedBox(width: 4),
          ],
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
                        // Every comment built, so one can be scrolled to.
                        scrollCacheExtent: const ScrollCacheExtent.pixels(
                          100000,
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          _postCard(t, post),
                          const SizedBox(height: 20),
                          _commentsHeader(t, post),
                          const SizedBox(height: 10),
                          ..._commentList(t, post),
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

  Widget _postCard(L t, Post post) => Container(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14B98B6E),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            NickAvatar(
              userId: post.authorId,
              nickname: post.nickname,
              photoUrl: post.avatarUrl,
              size: 42,
            ),
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
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      timeAgo(t, post.createdAt),
                      if (post.editedAt != null) t.edited,
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            TagLabel(post.tag),
            if (post.likeCount >= CommunityLimits.hotLikes) ...[
              const SizedBox(width: 10),
              const HotLabel(),
            ],
          ],
        ),
        const SizedBox(height: 6),
        SelectableText(
          post.body,
          style: const TextStyle(fontSize: 16, height: 1.65),
        ),
        if (post.images.isNotEmpty) ...[
          const SizedBox(height: 14),
          _carousel(post.images),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            LikePill(
              post: post,
              large: true,
              onChanged: (u) => setState(() => _post = u ?? _post),
            ),
            const SizedBox(width: 8),
            CountPill(
              icon: CupertinoIcons.chat_bubble,
              count: _comments?.length ?? post.commentCount,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _carousel(List<String> urls) => Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _photo = i),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => showPhotoViewer(context, urls, i),
              child: Hero(
                tag: '${urls[i]}#$i',
                child: Image.network(
                  urls[i],
                  fit: BoxFit.cover,
                  cacheWidth: 1080,
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
      ),
      if (urls.length > 1) ...[
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < urls.length; i++)
              AnimatedContainer(
                duration: Motion.fast,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _photo ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _photo ? AppColors.peach : AppColors.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    ],
  );

  Widget _commentsHeader(L t, Post post) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        const Icon(
          CupertinoIcons.chat_bubble_2_fill,
          size: 18,
          color: AppColors.peach,
        ),
        const SizedBox(width: 6),
        Text(
          t.commentsN('${_comments?.length ?? post.commentCount}'),
          style: const TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );

  List<Widget> _commentList(L t, Post post) {
    final comments = _comments;
    if (_failed) {
      return [
        Center(
          child: TextButton(onPressed: _load, child: Text(t.retry)),
        ),
      ];
    }
    if (comments == null) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (comments.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line, width: 1.5),
          ),
          child: Column(
            children: [
              const Icon(CupertinoIcons.chat_bubble, color: AppColors.inkSoft),
              const SizedBox(height: 6),
              Text(
                t.noComments,
                style: const TextStyle(color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ];
    }
    // Top-level comments in order, each followed by its replies.
    final ids = {for (final c in comments) c.id};
    final top = [
      for (final c in comments)
        if (c.parentId == null || !ids.contains(c.parentId)) c,
    ];
    Widget bubble(Comment c, {required bool reply}) => FadeSlideIn(
      key: ValueKey(c.id),
      dy: 6,
      child: _CommentBubble(
        key: c.id == widget.focusCommentId ? _focusKey : null,
        comment: c,
        highlighted: c.id == _flash,
        isReply: reply,
        byAuthor: c.authorId == post.authorId,
        onReply: () => _startReply(c),
        onLike: () => _likeComment(c),
        onDeleted: () => setState(
          () =>
              _comments!.removeWhere((x) => x.id == c.id || x.parentId == c.id),
        ),
        onBlocked: () => setState(
          () => _comments!.removeWhere((x) => x.authorId == c.authorId),
        ),
      ),
    );
    return [
      for (final c in top) ...[
        bubble(c, reply: false),
        for (final r in comments)
          if (r.parentId == c.id) bubble(r, reply: true),
      ],
    ];
  }

  Widget _inputBar(L t) {
    final c = CommunityScope.of(context);
    final me = c.profile;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSize(
                duration: Motion.fast,
                curve: Motion.ease,
                child: _replyTo == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.subdirectory_arrow_right_rounded,
                              size: 18,
                              color: AppColors.peach,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                t.replyingTo(_replyTo!.nickname),
                                style: const TextStyle(
                                  fontFamily: headingFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.peach,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _cancelReply,
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (me != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: NickAvatar(
                        userId: me.userId,
                        nickname: me.nickname,
                        photoUrl: me.avatarUrl,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F1EC),
                        borderRadius: BorderRadius.circular(22),
                      ),
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
                        focusNode: _inputFocus,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        onTap: () => ensureCommunityMember(context),
                        decoration: InputDecoration(
                          hintText: _replyTo == null
                              ? t.commentHint
                              : t.replyHint,
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ListenableBuilder(
                    listenable: _input,
                    builder: (context, _) {
                      final ready = !_sending && _input.text.trim().isNotEmpty;
                      return Semantics(
                        button: true,
                        enabled: ready,
                        label: t.reviewSend,
                        child: GestureDetector(
                          onTap: ready ? _send : null,
                          child: AnimatedContainer(
                            duration: Motion.fast,
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: ready
                                  ? const LinearGradient(
                                      colors: [
                                        AppColors.peach,
                                        Color(0xFFFFA98F),
                                      ],
                                    )
                                  : null,
                              color: ready ? null : AppColors.line,
                              shape: BoxShape.circle,
                            ),
                            child: _sending
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.arrow_upward_rounded,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final Comment comment;
  final bool byAuthor;
  final bool isReply;
  final bool highlighted;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final VoidCallback onDeleted;
  final VoidCallback onBlocked;
  const _CommentBubble({
    super.key,
    this.highlighted = false,
    required this.onLike,
    required this.comment,
    required this.byAuthor,
    required this.isReply,
    required this.onReply,
    required this.onDeleted,
    required this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final c = CommunityScope.read(context);
    final mine = comment.authorId == c.repo.myId;
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40 : 0, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NickAvatar(
            userId: comment.authorId,
            nickname: comment.nickname,
            photoUrl: comment.avatarUrl,
            size: isReply ? 26 : 32,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: Motion.medium,
              padding: const EdgeInsets.fromLTRB(14, 10, 4, 12),
              decoration: BoxDecoration(
                color: highlighted
                    ? AppColors.butterSoft
                    : mine
                    ? const Color(0xFFFFF5F1)
                    : Colors.white,
                border: Border.all(
                  color: highlighted
                      ? const Color(0xFFF5B400)
                      : Colors.transparent,
                  width: 1.5,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          comment.nickname,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: headingFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (byAuthor) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.peach,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            t.authorBadge,
                            style: const TextStyle(
                              fontFamily: headingFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        timeAgo(t, comment.createdAt),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 28,
                        height: 22,
                        child: IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .moreButtonTooltip,
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          icon: const Icon(
                            Icons.more_horiz_rounded,
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _MentionText(comment.body),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onReply,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 2),
                          child: Text(
                            t.replyAction,
                            style: const TextStyle(
                              fontFamily: headingFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      _CommentLike(
                        liked: comment.likedByMe,
                        count: comment.likeCount,
                        onTap: onLike,
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

/// ♥ and count under a comment.
class _CommentLike extends StatelessWidget {
  final bool liked;
  final int count;
  final VoidCallback onTap;
  const _CommentLike({
    required this.liked,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: L.of(context).likeLabel('$count'),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: Motion.fast,
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(liked),
                size: 15,
                color: liked ? AppColors.peach : AppColors.inkSoft,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 3),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: headingFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: liked ? AppColors.peach : AppColors.inkSoft,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// "@닉네임 " at the start of a reply.
final _mentionPrefix = RegExp(r'^@[0-9A-Za-z가-힣_]{1,12}\s');

/// A comment's text with its leading @mention in the brand color.
class _MentionText extends StatelessWidget {
  final String body;
  const _MentionText(this.body);

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 15, height: 1.5, color: AppColors.ink);
    final m = _mentionPrefix.firstMatch(body);
    if (m == null) return Text(body, style: style);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(
            text: m.group(0),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.peach,
            ),
          ),
          TextSpan(text: body.substring(m.end)),
        ],
      ),
    );
  }
}
