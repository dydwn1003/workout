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

/// A gym's own color pair, stable per gym (a 라운지 board's own color).
(Color, Color) gymColors(String id) {
  if (isTopicId(id)) {
    final c = topicStyle(id).$2;
    return (c, Color.lerp(c, Colors.white, 0.85)!);
  }
  return _palette[id.codeUnits.fold(0, (a, b) => a * 31 + b) % _palette.length];
}

/// Icon and color of a 운동 라운지 board.
(IconData, Color) topicStyle(String id) => switch (id) {
  't-health' => (Icons.fitness_center_rounded, const Color(0xFFFF7A6B)),
  't-crossfit' => (Icons.sports_gymnastics_rounded, const Color(0xFFF28B30)),
  't-running' => (Icons.directions_run_rounded, const Color(0xFF4A9BE8)),
  't-yoga' => (Icons.self_improvement_rounded, const Color(0xFF9A7BE0)),
  't-pilates' => (Icons.accessibility_new_rounded, const Color(0xFFE56FA8)),
  't-diet' => (Icons.restaurant_rounded, const Color(0xFF34B37F)),
  't-home' => (Icons.home_rounded, const Color(0xFFE0A21B)),
  't-swimming' => (Icons.pool_rounded, const Color(0xFF26A9BF)),
  't-climbing' => (Icons.terrain_rounded, const Color(0xFFB9825A)),
  't-cycling' => (Icons.directions_bike_rounded, const Color(0xFF62AE42)),
  't-combat' => (Icons.sports_mma_rounded, const Color(0xFFE0524B)),
  _ => (Icons.forum_rounded, const Color(0xFF8A7F95)),
};

/// A 라운지 board's name in the app's language; null for gyms.
String? topicName(L t, String id) => switch (id) {
  't-health' => t.topicHealth,
  't-crossfit' => t.topicCrossfit,
  't-running' => t.topicRunning,
  't-yoga' => t.topicYoga,
  't-pilates' => t.topicPilates,
  't-diet' => t.topicDiet,
  't-home' => t.topicHome,
  't-swimming' => t.topicSwimming,
  't-climbing' => t.topicClimbing,
  't-cycling' => t.topicCycling,
  't-combat' => t.topicCombat,
  't-free' => t.topicFree,
  _ => null,
};

/// The board's name to show: a 라운지 board's in the app's language.
String boardName(L t, Gym g) => topicName(t, g.id) ?? g.name;

/// Where a post is from, for feeds mixing boards.
String? postBoardName(L t, Post p) => topicName(t, p.gymId) ?? p.gymName;

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

/// A post's kind as a small round colored chip (feed cards).
class TagLabel extends StatelessWidget {
  final PostTag tag;
  const TagLabel(this.tag, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, icon, fg, soft) = tagStyle(L.of(context), tag);
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
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

/// 🔥 인기, next to [TagLabel].
class HotLabel extends StatelessWidget {
  const HotLabel({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE4DA),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          size: 12,
          color: Color(0xFFF2643A),
        ),
        const SizedBox(width: 2),
        Text(
          L.of(context).hotBadge,
          style: const TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w800,
            fontSize: 11.5,
            color: Color(0xFFF2643A),
          ),
        ),
      ],
    ),
  );
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
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(tag);
          },
          child: AnimatedContainer(
            duration: Motion.fast,
            curve: Motion.ease,
            padding: const EdgeInsets.fromLTRB(10, 7, 13, 7),
            decoration: BoxDecoration(
              color: on ? fg : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: on ? fg : AppColors.line, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: on ? Colors.white : fg),
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

/// A gym in the "내 헬스장" row: a white card with the gym's color mark,
/// its name and how lively it is.
class GymCard extends StatelessWidget {
  final Gym gym;
  final VoidCallback onTap;
  const GymCard({super.key, required this.gym, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final (c, soft) = gymColors(gym.id);
    final last = gym.lastPostAt;
    final fresh = last != null && DateTime.now().difference(last).inHours < 24;
    return Squish(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 172,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0DB98B6E),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: soft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: c,
                      size: 19,
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
                        color: AppColors.peachSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        t.newBadge,
                        style: const TextStyle(
                          fontFamily: headingFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: AppColors.peach,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                gym.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: headingFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  t.gymMembers('${gym.memberCount}'),
                  t.gymPosts('${gym.postCount}'),
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
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
        width: 112,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line, width: 1.5),
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
      if (showGym) ?postBoardName(t, post),
      timeAgo(t, post.createdAt),
    ].join(' · ');
    final hot = post.likeCount >= CommunityLimits.hotLikes;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0DB98B6E),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 6, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    NickAvatar(
                      userId: post.authorId,
                      nickname: post.nickname,
                      photoUrl: post.avatarUrl,
                      size: 36,
                    ),
                    const SizedBox(width: 10),
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
                              fontSize: 14,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 1),
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
                    SizedBox(
                      width: 36,
                      child: PostMenuButton(
                        post: post,
                        onChanged: onChanged,
                        onBlocked: onBlocked,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          TagLabel(post.tag),
                          if (hot) ...[
                            const SizedBox(width: 5),
                            const HotLabel(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.ink,
                        ),
                      ),
                      if (post.images.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        PhotoThumbs(urls: post.images),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
      tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
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
  final bool plain;
  const CountPill({
    super.key,
    required this.icon,
    required this.count,
    this.color = AppColors.inkSoft,
    this.bg = const Color(0xFFF7F1EC),
    this.plain = false,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: Motion.fast,
    padding: plain
        ? const EdgeInsets.symmetric(horizontal: 2, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: plain ? Colors.transparent : bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: plain ? 17 : 15, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w800,
            fontSize: plain ? 13.5 : 12.5,
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

  /// Just the heart and number (feed cards); the pill when false.
  final bool plain;
  const LikePill({
    super.key,
    required this.post,
    required this.onChanged,
    this.large = false,
    this.plain = false,
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
    return Semantics(
      button: true,
      label: L.of(context).likeLabel('${widget.post.likeCount}'),
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: widget.plain
              ? const EdgeInsets.symmetric(horizontal: 2, vertical: 6)
              : EdgeInsets.symmetric(
                  horizontal: big ? 16 : 9,
                  vertical: big ? 9 : 4,
                ),
          decoration: BoxDecoration(
            color: widget.plain
                ? Colors.transparent
                : liked
                ? AppColors.peachSoft
                : const Color(0xFFF7F1EC),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: TweenSequence(
                  [
                    TweenSequenceItem(
                      tween: Tween(begin: 1.0, end: 1.4),
                      weight: 40,
                    ),
                    TweenSequenceItem(
                      tween: Tween(begin: 1.4, end: 1.0),
                      weight: 60,
                    ),
                  ],
                ).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOut)),
                child: Icon(
                  liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: big ? 20 : (widget.plain ? 18 : 15),
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
                    fontSize: big ? 15 : (widget.plain ? 13.5 : 12.5),
                    color: liked ? AppColors.peach : AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
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

/// The 커뮤니티 tab icon: two chatting bubbles with a little heart, drawn
/// so it can be rounder and friendlier than the stock icons. Outlined
/// normally, filled (heart cut out) when [selected].
class CommunityIcon extends StatelessWidget {
  final bool selected;
  final double size;
  const CommunityIcon({super.key, this.selected = false, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? AppColors.ink;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _CommunityIconPainter(color: color, selected: selected),
      ),
    );
  }
}

class _CommunityIconPainter extends CustomPainter {
  final Color color;
  final bool selected;
  _CommunityIconPainter({required this.color, required this.selected});

  /// A rounded bubble and its little tail as one shape (in a 24×24 box),
  /// [grow] wider all round for the gap around the front bubble.
  Path _bubble(Rect r, double radius, List<Offset> tail, {double grow = 0}) {
    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          r.inflate(grow),
          Radius.circular(radius + grow),
        ),
      );
    final t = Path()..addPolygon(tail, true);
    return Path.combine(PathOperation.union, body, t);
  }

  Path _heart(Offset c, double w) {
    final h = w * 0.9;
    final top = c.dy - h * 0.35;
    return Path()
      ..moveTo(c.dx, c.dy + h * 0.5)
      ..cubicTo(
        c.dx - w * 0.9,
        c.dy - h * 0.05,
        c.dx - w * 0.45,
        top - h * 0.55,
        c.dx,
        top,
      )
      ..cubicTo(
        c.dx + w * 0.45,
        top - h * 0.55,
        c.dx + w * 0.9,
        c.dy - h * 0.05,
        c.dx,
        c.dy + h * 0.5,
      )
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;

    // My bubble in front, and the friend's behind it on the right, drawn
    // only where mine (with a little gap) doesn't cover it.
    const frontRect = Rect.fromLTWH(2, 7, 15.5, 12.5);
    const frontTail = [Offset(5, 17.5), Offset(3, 22.2), Offset(10.5, 19)];
    final front = _bubble(frontRect, 6.25, frontTail);
    final back = _bubble(const Rect.fromLTWH(11, 2.5, 11, 9.5), 4.75, const [
      Offset(17.5, 10),
      Offset(21.8, 14.2),
      Offset(21, 8.5),
    ]);
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(const Rect.fromLTWH(-2, -2, 28, 28)),
        _bubble(frontRect, 6.25, frontTail, grow: 1.6),
      ),
    );
    canvas.drawPath(
      back,
      selected ? (Paint()..color = color.withValues(alpha: 0.45)) : stroke,
    );
    canvas.restore();

    if (selected) {
      canvas.drawPath(front, fill);
      canvas.drawPath(
        _heart(const Offset(9.5, 12.8), 6),
        Paint()..color = Colors.white,
      );
    } else {
      canvas.drawPath(front, stroke);
      canvas.drawPath(_heart(const Offset(9.5, 12.8), 5.2), fill);
    }
  }

  @override
  bool shouldRepaint(_CommunityIconPainter old) =>
      old.color != color || old.selected != selected;
}
