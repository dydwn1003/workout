import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/community.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/community_state.dart';
import '../../motion.dart';
import '../../theme.dart';
import 'community_common.dart';
import 'compose_sheet.dart';

/// Shared pieces of the community screens: tags, gym cards, post cards,
/// photo grids, like/comment pills.

const _palette = [
  (AppColors.peach, AppColors.peachSoft),
  (AppColors.mint, AppColors.mintSoft),
  (AppColors.sky, AppColors.skySoft),
  (AppColors.lilac, AppColors.lilacSoft),
  (AppColors.butter, AppColors.butterSoft),
];

/// A gym's own color pair, stable per gym.
(Color, Color) gymColors(String id) =>
    _palette[id.codeUnits.fold(0, (a, b) => a * 31 + b) % _palette.length];

/// A gym's color, a little deeper so white text on it reads well.
Color gymDeep(String id) =>
    Color.lerp(gymColors(id).$1, const Color(0xFF3B3340), 0.3)!;

LinearGradient gymGradient(String id) {
  final (c, _) = gymColors(id);
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gymDeep(id), Color.lerp(c, const Color(0xFF3B3340), 0.08)!],
  );
}

/// Label, icon and colors of a tag.
(String, IconData, Color, Color) tagStyle(L t, PostTag tag) => switch (tag) {
  PostTag.mate => (
    t.tagMate,
    Icons.people_alt_rounded,
    AppColors.mint,
    AppColors.mintSoft,
  ),
  PostTag.question => (
    t.tagQuestion,
    Icons.help_rounded,
    AppColors.sky,
    AppColors.skySoft,
  ),
  PostTag.info => (
    t.tagInfo,
    Icons.lightbulb_rounded,
    const Color(0xFFE0A21B),
    AppColors.butterSoft,
  ),
  PostTag.review => (
    t.tagReview,
    Icons.star_rounded,
    AppColors.lilac,
    AppColors.lilacSoft,
  ),
  PostTag.free => (
    t.tagFree,
    Icons.chat_bubble_rounded,
    AppColors.peach,
    AppColors.peachSoft,
  ),
};

class TagChip extends StatelessWidget {
  final PostTag tag;
  const TagChip(this.tag, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, icon, fg, bg) = tagStyle(L.of(context), tag);
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: headingFont,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// 전체 · 운동메이트 · 질문 · 정보 · 후기 · 잡담, scrolling sideways.
class TagFilterBar extends StatelessWidget {
  final PostTag? selected;
  final ValueChanged<PostTag?> onChanged;
  final EdgeInsetsGeometry padding;
  const TagFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  static const order = [
    PostTag.mate,
    PostTag.question,
    PostTag.info,
    PostTag.review,
    PostTag.free,
  ];

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    Widget chip(PostTag? tag) {
      final on = selected == tag;
      final (label, icon, fg, _) = tag == null
          ? (t.tagAll, Icons.apps_rounded, AppColors.ink, AppColors.line)
          : tagStyle(t, tag);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(tag);
          },
          child: AnimatedContainer(
            duration: Motion.fast,
            curve: Motion.ease,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: on ? (tag == null ? AppColors.ink : fg) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: on ? Colors.transparent : AppColors.line,
                width: 1.4,
              ),
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: (tag == null ? AppColors.ink : fg).withValues(
                          alpha: 0.25,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: on ? Colors.white : fg),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: on ? Colors.white : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(children: [chip(null), for (final tg in order) chip(tg)]),
    );
  }
}

/// A gym in the "내 헬스장" carousel: its color, name, area and activity.
class GymCard extends StatelessWidget {
  final Gym gym;
  final VoidCallback onTap;
  const GymCard({super.key, required this.gym, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final (c, _) = gymColors(gym.id);
    final last = gym.lastPostAt;
    final fresh = last != null && DateTime.now().difference(last).inHours < 24;
    return Squish(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 196,
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            gradient: gymGradient(gym.id),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: c.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -14,
                top: -22,
                child: Text(
                  gym.name.characters.first,
                  style: TextStyle(
                    fontFamily: headingFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 96,
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.fitness_center_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const Spacer(),
                      if (fresh)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            t.newBadge,
                            style: TextStyle(
                              fontFamily: headingFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: c,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    gym.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: headingFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.25,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Color(0x33000000), blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      t.gymMembers('${gym.memberCount}'),
                      t.gymPosts('${gym.postCount}'),
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
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

/// The last card of the carousel: go find (another) gym.
class FindGymCard extends StatelessWidget {
  final VoidCallback onTap;
  const FindGymCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => Squish(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.peachSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.peach),
            ),
            const SizedBox(height: 8),
            Text(
              L.of(context).findGym,
              style: const TextStyle(
                fontFamily: headingFont,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A gym in search results.
class GymRow extends StatelessWidget {
  final Gym gym;
  final bool mine;
  final VoidCallback onTap;
  const GymRow({
    super.key,
    required this.gym,
    required this.onTap,
    this.mine = false,
  });

  @override
  Widget build(BuildContext context) {
    final (c, soft) = gymColors(gym.id);
    return Squish(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    gym.name.characters.first,
                    style: TextStyle(
                      fontFamily: headingFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: c,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              gym.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: headingFont,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (mine) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.bookmark_rounded,
                              size: 16,
                              color: AppColors.peach,
                            ),
                          ],
                        ],
                      ),
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
                  ),
                ),
                if (gym.memberCount > 0 || gym.postCount > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _MiniStat(Icons.people_alt_rounded, gym.memberCount),
                      const SizedBox(height: 2),
                      _MiniStat(Icons.article_rounded, gym.postCount),
                    ],
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.inkSoft,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final int n;
  const _MiniStat(this.icon, this.n);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: AppColors.inkSoft),
      const SizedBox(width: 3),
      Text(
        '$n',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.inkSoft,
        ),
      ),
    ],
  );
}

/// A post in a board or feed, kept compact: author and time, tag, three
/// lines of text, photo thumbnails, likes and comments.
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final ValueChanged<Post?> onChanged;
  final VoidCallback onBlocked;

  /// Show which gym it's from (feeds mixing gyms).
  final bool showGym;
  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onChanged,
    required this.onBlocked,
    this.showGym = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final meta = [
      if (showGym && post.gymName != null) post.gymName!,
      timeAgo(t, post.createdAt),
    ].join(' · ');
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFF0E6DD)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  NickAvatar(
                    userId: post.authorId,
                    nickname: post.nickname,
                    size: 30,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: headingFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          meta,
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
                  TagChip(post.tag),
                  SizedBox(
                    width: 34,
                    child: PostMenuButton(
                      post: post,
                      onChanged: onChanged,
                      onBlocked: onBlocked,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  post.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: 8),
                PhotoThumbs(urls: post.images),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  LikePill(post: post, onChanged: onChanged),
                  const SizedBox(width: 6),
                  CountPill(
                    icon: Icons.chat_bubble_outline_rounded,
                    count: post.commentCount,
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

/// Up to three small squares in a card; "+2" on the last when there are
/// more. Tapping opens the photo.
class PhotoThumbs extends StatelessWidget {
  final List<String> urls;
  const PhotoThumbs({super.key, required this.urls});

  @override
  Widget build(BuildContext context) {
    const size = 76.0;
    final shown = urls.length > 3 ? 3 : urls.length;
    return SizedBox(
      height: size,
      child: Row(
        children: [
          for (var i = 0; i < shown; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            GestureDetector(
              onTap: () => showPhotoViewer(context, urls, i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Hero(
                      tag: '${urls[i]}#$i',
                      child: Image.network(
                        urls[i],
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        cacheWidth: 240,
                        errorBuilder: (_, _, _) => Container(
                          width: size,
                          height: size,
                          color: AppColors.line,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                    if (i == 2 && urls.length > 3)
                      Container(
                        width: size,
                        height: size,
                        color: Colors.black45,
                        alignment: Alignment.center,
                        child: Text(
                          '+${urls.length - 3}',
                          style: const TextStyle(
                            fontFamily: headingFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ⋮ on a post: edit/delete for mine, report/block for others'.
class PostMenuButton extends StatelessWidget {
  final Post post;
  final ValueChanged<Post?> onChanged;
  final VoidCallback onBlocked;
  const PostMenuButton({
    super.key,
    required this.post,
    required this.onChanged,
    required this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final c = CommunityScope.read(context);
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: AppColors.inkSoft,
      ),
      onPressed: () => showContentMenu(
        context,
        mine: post.authorId == c.repo.myId,
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
    );
  }
}

class CountPill extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final Color bg;
  const CountPill({
    super.key,
    required this.icon,
    required this.count,
    this.color = AppColors.inkSoft,
    this.bg = const Color(0xFFF7F1EC),
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: Motion.fast,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: color,
          ),
        ),
      ],
    ),
  );
}

/// ♥ 3: toggles right away with a little pop, undone if the server says no.
class LikePill extends StatefulWidget {
  final Post post;
  final ValueChanged<Post?> onChanged;
  final bool large;
  const LikePill({
    super.key,
    required this.post,
    required this.onChanged,
    this.large = false,
  });

  @override
  State<LikePill> createState() => _LikePillState();
}

class _LikePillState extends State<LikePill>
    with SingleTickerProviderStateMixin {
  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final post = widget.post;
    if (!await ensureCommunityMember(context) || !mounted) return;
    final liked = post.likedByMe;
    HapticFeedback.lightImpact();
    if (!liked) _pop.forward(from: 0);
    widget.onChanged(
      post.copyWith(
        likedByMe: !liked,
        likeCount: post.likeCount + (liked ? -1 : 1),
      ),
    );
    try {
      await CommunityScope.read(context).repo.setLike(post.id, !liked);
    } catch (e) {
      widget.onChanged(post);
      if (mounted) showCommunityError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liked = widget.post.likedByMe;
    final big = widget.large;
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: EdgeInsets.symmetric(
          horizontal: big ? 16 : 9,
          vertical: big ? 9 : 4,
        ),
        decoration: BoxDecoration(
          color: liked ? AppColors.peachSoft : const Color(0xFFF7F1EC),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: TweenSequence([
                TweenSequenceItem(
                  tween: Tween(begin: 1.0, end: 1.4),
                  weight: 40,
                ),
                TweenSequenceItem(
                  tween: Tween(begin: 1.4, end: 1.0),
                  weight: 60,
                ),
              ]).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOut)),
              child: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: big ? 20 : 15,
                color: liked ? AppColors.peach : AppColors.inkSoft,
              ),
            ),
            SizedBox(width: big ? 6 : 4),
            AnimatedSwitcher(
              duration: Motion.fast,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: Text(
                '${widget.post.likeCount}',
                key: ValueKey(widget.post.likeCount),
                style: TextStyle(
                  fontFamily: headingFont,
                  fontWeight: FontWeight.w800,
                  fontSize: big ? 15 : 12.5,
                  color: liked ? AppColors.peach : AppColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 1 photo wide, 2 side by side, 3 as one big and two small, 4 in a grid.
class PhotoGrid extends StatelessWidget {
  final List<String> urls;
  const PhotoGrid({super.key, required this.urls});

  @override
  Widget build(BuildContext context) {
    Widget tile(int i, {double? height}) => GestureDetector(
      onTap: () => showPhotoViewer(context, urls, i),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Hero(
          tag: '${urls[i]}#$i',
          child: Image.network(
            urls[i],
            fit: BoxFit.cover,
            width: double.infinity,
            height: height,
            cacheWidth: 720,
            errorBuilder: (_, _, _) => Container(
              height: height,
              color: AppColors.line,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ),
      ),
    );
    const gap = 6.0;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        switch (urls.length) {
          case 1:
            return tile(0, height: w * 0.62);
          case 2:
            return Row(
              children: [
                Expanded(child: tile(0, height: w * 0.5)),
                const SizedBox(width: gap),
                Expanded(child: tile(1, height: w * 0.5)),
              ],
            );
          case 3:
            final h = w * 0.62;
            return SizedBox(
              height: h,
              child: Row(
                children: [
                  Expanded(flex: 3, child: tile(0, height: h)),
                  const SizedBox(width: gap),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(child: tile(1)),
                        const SizedBox(height: gap),
                        Expanded(child: tile(2)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          default:
            final h = (w - gap) / 2 * 0.72;
            return Column(
              children: [
                for (final r in [0, 2]) ...[
                  if (r > 0) const SizedBox(height: gap),
                  Row(
                    children: [
                      Expanded(child: tile(r, height: h)),
                      const SizedBox(width: gap),
                      Expanded(child: tile(r + 1, height: h)),
                    ],
                  ),
                ],
              ],
            );
        }
      },
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

class _PhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initial;
  const _PhotoViewer({required this.urls, required this.initial});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late int _i = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.urls.length > 1
            ? Text(
                '${_i + 1} / ${widget.urls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              )
            : null,
      ),
      body: PageView(
        controller: PageController(initialPage: widget.initial),
        onPageChanged: (i) => setState(() => _i = i),
        children: [
          for (final (i, u) in widget.urls.indexed)
            InteractiveViewer(
              child: Center(
                child: Hero(tag: '$u#$i', child: Image.network(u)),
              ),
            ),
        ],
      ),
    );
  }
}
