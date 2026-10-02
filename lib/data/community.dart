import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 헬스장 커뮤니티: a board per gym (supabase/community.sql).

class Gym {
  final String id;
  final String name;
  final String address;
  final int memberCount;
  final int postCount;
  final DateTime? lastPostAt;

  /// Added by a user rather than from the 체력단련장업 open data.
  final bool userAdded;

  const Gym({
    required this.id,
    required this.name,
    this.address = '',
    this.memberCount = 0,
    this.postCount = 0,
    this.lastPostAt,
    this.userAdded = false,
  });

  factory Gym.fromJson(Map<String, dynamic> j) => Gym(
    id: j['id'] as String,
    name: j['name'] as String,
    address: j['address'] as String? ?? '',
    memberCount: (j['member_count'] as num?)?.toInt() ?? 0,
    postCount: (j['post_count'] as num?)?.toInt() ?? 0,
    lastPostAt: _time(j['last_post_at']),
    userAdded: j['source'] == 'user',
  );

  Gym copyWith({int? memberCount, int? postCount, DateTime? lastPostAt}) => Gym(
    id: id,
    name: name,
    address: address,
    memberCount: memberCount ?? this.memberCount,
    postCount: postCount ?? this.postCount,
    lastPostAt: lastPostAt ?? this.lastPostAt,
    userAdded: userAdded,
  );

  /// A 운동 라운지 board (by sport, for everyone) rather than a gym.
  bool get isTopic => isTopicId(id);

  /// "서울특별시 강남구 테헤란로 1 (역삼동)" -> "강남구 테헤란로 1".
  String get shortAddress {
    final parts = address.split(' ');
    if (parts.length <= 2) return address;
    return parts.skip(1).take(3).join(' ');
  }
}

/// The 운동 라운지 boards (supabase/community.sql), in display order.
const topicIds = [
  't-health',
  't-crossfit',
  't-running',
  't-yoga',
  't-pilates',
  't-diet',
  't-home',
  't-swimming',
  't-climbing',
  't-cycling',
  't-combat',
  't-free',
];

bool isTopicId(String id) => id.startsWith('t-');

class CommunityProfile {
  final String userId;
  final String nickname;

  /// Public URL of the profile photo; null shows the first letter.
  final String? avatarUrl;
  const CommunityProfile(this.userId, this.nickname, {this.avatarUrl});
}

/// What a post is about; boards filter by it.
enum PostTag {
  free, // 잡담
  mate, // 운동메이트
  question, // 질문
  info, // 정보
  review; // 후기

  static PostTag parse(Object? v) =>
      values.firstWhere((t) => t.name == v, orElse: () => free);
}

class Post {
  final String id;
  final String gymId;

  /// The gym's name, filled in feeds that mix several gyms.
  final String? gymName;
  final PostTag tag;
  final String authorId;
  final String nickname;

  /// The author's profile photo.
  final String? avatarUrl;
  final String body;

  /// Public URLs of the photos (up to 4).
  final List<String> images;

  /// Storage paths of the photos, to delete them with the post.
  final List<String> imagePaths;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool likedByMe;

  const Post({
    required this.id,
    required this.gymId,
    this.gymName,
    this.tag = PostTag.free,
    required this.authorId,
    required this.nickname,
    this.avatarUrl,
    required this.body,
    this.images = const [],
    this.imagePaths = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    this.editedAt,
    this.likedByMe = false,
  });

  Post copyWith({
    String? nickname,
    String? avatarUrl,
    String? body,
    PostTag? tag,
    String? gymName,
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
    DateTime? editedAt,
  }) => Post(
    id: id,
    gymId: gymId,
    gymName: gymName ?? this.gymName,
    tag: tag ?? this.tag,
    authorId: authorId,
    nickname: nickname ?? this.nickname,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    body: body ?? this.body,
    images: images,
    imagePaths: imagePaths,
    likeCount: likeCount ?? this.likeCount,
    commentCount: commentCount ?? this.commentCount,
    createdAt: createdAt,
    editedAt: editedAt ?? this.editedAt,
    likedByMe: likedByMe ?? this.likedByMe,
  );
}

class Comment {
  final String id;
  final String postId;

  /// The comment this replies to (always a top-level one); null for
  /// top-level comments.
  final String? parentId;
  final String authorId;
  final String nickname;
  final String? avatarUrl;
  final String body;
  final DateTime createdAt;
  final int likeCount;
  final bool likedByMe;

  const Comment({
    required this.id,
    required this.postId,
    this.parentId,
    required this.authorId,
    required this.nickname,
    this.avatarUrl,
    required this.body,
    required this.createdAt,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  Comment copyWith({
    String? nickname,
    String? avatarUrl,
    int? likeCount,
    bool? likedByMe,
  }) => Comment(
    id: id,
    postId: postId,
    parentId: parentId,
    authorId: authorId,
    nickname: nickname ?? this.nickname,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    body: body,
    createdAt: createdAt,
    likeCount: likeCount ?? this.likeCount,
    likedByMe: likedByMe ?? this.likedByMe,
  );
}

enum NotificationKind {
  postLike, // 내 글 좋아요
  comment, // 내 글에 댓글
  reply, // 내 댓글에 답글
  commentLike, // 내 댓글 좋아요
  hot; // 내 글이 인기글

  static NotificationKind? parse(Object? v) => switch (v) {
    'post_like' => postLike,
    'comment' => comment,
    'reply' => reply,
    'comment_like' => commentLike,
    'hot' => hot,
    _ => null,
  };
}

/// Something that happened to my posts or comments (알림).
class CommunityNotification {
  final String id;
  final NotificationKind kind;

  /// Who did it (the latest one for grouped likes); null for 인기글 or
  /// someone without a nickname.
  final String? actorId;
  final String? actorNickname;
  final String? actorAvatar;

  /// Likes grouped into this one: "OO님 외 N명".
  final int count;
  final String? postId;
  final String? commentId;

  /// A bit of the post / comment it's about.
  final String postBody;
  final String? commentBody;
  final String? gymId;
  final bool read;
  final DateTime createdAt;

  const CommunityNotification({
    required this.id,
    required this.kind,
    this.actorId,
    this.actorNickname,
    this.actorAvatar,
    this.count = 1,
    this.postId,
    this.commentId,
    this.postBody = '',
    this.commentBody,
    this.gymId,
    this.read = false,
    required this.createdAt,
  });

  CommunityNotification markRead() => CommunityNotification(
    id: id,
    kind: kind,
    actorId: actorId,
    actorNickname: actorNickname,
    actorAvatar: actorAvatar,
    count: count,
    postId: postId,
    commentId: commentId,
    postBody: postBody,
    commentBody: commentBody,
    gymId: gymId,
    read: true,
    createdAt: createdAt,
  );
}

/// A comment I wrote, with the post it's on (내 활동).
class MyComment {
  final Comment comment;
  final String postBody;
  final String gymId;
  final String? gymName;
  const MyComment({
    required this.comment,
    required this.postBody,
    required this.gymId,
    this.gymName,
  });
}

enum ReportReason { spam, abuse, sexual, privacy, other }

/// Why a community write failed, for the message shown.
enum CommunityError {
  nicknameTaken,
  rateLimited,
  blockedWords,
  badImage,
  network,

  /// Already 3 gyms in 내 헬스장.
  gymLimit,

  /// The operator stopped this account from posting (community_bans).
  banned,
}

class CommunityException implements Exception {
  final CommunityError error;
  const CommunityException(this.error);
  @override
  String toString() => 'CommunityException($error)';
}

/// Limits shared with supabase/community.sql.
class CommunityLimits {
  static const postLength = 2000;
  static const commentLength = 500;
  static const photos = 4;
  static const nicknameMin = 2;
  static const nicknameMax = 12;
  static const photoBytes = 5 * 1024 * 1024;
  static const myGyms = 3;

  /// Likes that make a post 인기글 (community_hot_likes() on the server).
  static const hotLikes = 5;
}

/// Image type from the file's first bytes; null when not JPEG/PNG/WebP
/// (HEIC, GIF...), which the storage bucket doesn't accept.
String? imageMimeType(Uint8List b) {
  if (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (b.length > 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47) {
    return 'image/png';
  }
  if (b.length > 12 &&
      String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}

/// Words never allowed in posts, comments or nicknames. Spaces and
/// punctuation between letters are ignored ("시 발" too); reports catch the
/// rest. Only words that don't turn up inside everyday ones (not 보지 as in
/// "보지 마세요", 시바 as in 시바견).
const _blockedWords = [
  '시발',
  '씨발',
  '씨바',
  'ㅅㅂ',
  'ㅆㅂ',
  '병신',
  'ㅂㅅ',
  '좆',
  '존나',
  '개새끼',
  '썅',
  '느금',
  '엠창',
  '염병',
  '지랄',
  '섹스',
  '야동',
  '조건만남',
  '성매매',
  'fuck',
  'shit',
];

bool containsBlockedWords(String text) {
  final t = text.toLowerCase().replaceAll(RegExp(r'[\s\.\,\-_\*~!?1]'), '');
  return _blockedWords.any(t.contains);
}

bool validNickname(String s) {
  final n = s.trim();
  return n.length >= CommunityLimits.nicknameMin &&
      n.length <= CommunityLimits.nicknameMax &&
      RegExp(r'^[0-9A-Za-z가-힣_]+$').hasMatch(n) &&
      !containsBlockedWords(n);
}

abstract class CommunityRepository {
  /// Signed-in user, or null (reading only).
  String? get myId;

  Future<CommunityProfile?> myProfile();

  /// Throws [CommunityException] (nicknameTaken, blockedWords).
  Future<CommunityProfile> createProfile(String nickname);

  /// Changes my nickname and/or photo ([photo] is a prepared JPEG;
  /// [removePhoto] goes back to the first letter). Throws like
  /// [createProfile].
  Future<CommunityProfile> updateProfile({
    String? nickname,
    Uint8List? photo,
    bool removePhoto = false,
  });

  Future<List<Gym>> searchGyms(String query);
  Future<List<Gym>> myGyms();
  Future<void> join(String gymId);
  Future<void> leave(String gymId);
  Future<Gym> addGym(String name, String address);

  /// These boards with their counts (라운지 boards, a gym from an invite);
  /// unknown ids are left out.
  Future<List<Gym>> boards(List<String> ids);

  /// Newest first; [before] pages back from the oldest one shown, [tag]
  /// keeps one kind.
  /// [query] keeps only posts whose text contains it (board search).
  Future<List<Post>> posts(
    String gymId, {
    DateTime? before,
    int limit = 20,
    PostTag? tag,
    String? query,
  });

  /// Newest posts of several gyms (my gyms' news), with their gym names.
  Future<List<Post>> feed(
    List<String> gymIds, {
    DateTime? before,
    int limit = 20,
    PostTag? tag,
    String? query,
  });

  /// The most liked posts of the last [days] days in these boards.
  Future<List<Post>> hot(List<String> gymIds, {int days = 7, int limit = 5});

  Future<Post> writePost(
    String gymId,
    String body,
    List<Uint8List> photos, {
    PostTag tag = PostTag.free,
  });
  Future<Post> editPost(Post post, String body, {PostTag? tag});
  Future<void> deletePost(Post post);

  /// One post (opened from 내 활동); null when gone or hidden.
  Future<Post?> post(String id);

  /// My posts and comments, newest first.
  Future<List<Post>> myPosts({DateTime? before, int limit = 20});
  Future<List<MyComment>> myComments({DateTime? before, int limit = 20});

  Future<List<Comment>> comments(String postId);

  /// [parentId] replies to that comment (replies to a reply go under its
  /// top-level comment).
  Future<Comment> addComment(String postId, String body, {String? parentId});
  Future<void> deleteComment(Comment comment);

  Future<void> setLike(String postId, bool liked);
  Future<void> setCommentLike(String commentId, bool liked);

  /// 알림: newest first, and how many aren't read yet.
  Future<List<CommunityNotification>> notifications({
    DateTime? before,
    int limit = 30,
  });
  Future<int> unreadNotifications();
  Future<void> markNotificationsRead();
  Future<void> report(String type, String id, ReportReason reason);
  Future<void> block(String userId);

  /// Deletes the signed-in user's photos (before deleting the account:
  /// rows go by cascade, storage files don't).
  Future<void> deleteMyPhotos();
}

// ---------------------------------------------------------------------------
// Supabase
// ---------------------------------------------------------------------------

class SupabaseCommunity implements CommunityRepository {
  final SupabaseClient client;
  SupabaseCommunity(this.client);

  static const _bucket = 'community';
  static const _postColumns =
      '*, profile:community_profiles!posts_author_fkey(nickname, avatar), '
      'gym:gyms(name)';

  @override
  String? get myId => client.auth.currentUser?.id;

  String _url(String path) => client.storage.from(_bucket).getPublicUrl(path);

  String? _avatar(Object? path) =>
      path is String && path.isNotEmpty ? _url(path) : null;

  static const _commentColumns =
      '*, profile:community_profiles!comments_author_fkey(nickname, avatar)';

  Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on StorageException catch (e) {
      debugPrint('photo upload failed: ${e.statusCode} ${e.message}');
      if (e.statusCode == '413' ||
          e.statusCode == '415' ||
          e.message.contains('mime')) {
        throw const CommunityException(CommunityError.badImage);
      }
      rethrow;
    } on PostgrestException catch (e) {
      if (e.message.contains('rate_limit')) {
        throw const CommunityException(CommunityError.rateLimited);
      }
      if (e.message.contains('gym_limit')) {
        throw const CommunityException(CommunityError.gymLimit);
      }
      if (e.message.contains('banned')) {
        throw const CommunityException(CommunityError.banned);
      }
      if (e.code == '23505') {
        throw const CommunityException(CommunityError.nicknameTaken);
      }
      rethrow;
    }
  }

  Post _post(Map<String, dynamic> j, Set<String> liked) {
    final paths = [for (final p in (j['images'] as List? ?? const [])) '$p'];
    return Post(
      id: j['id'] as String,
      gymId: j['gym_id'] as String,
      gymName: (j['gym'] as Map?)?['name'] as String?,
      tag: PostTag.parse(j['tag']),
      authorId: j['author'] as String,
      nickname: (j['profile'] as Map?)?['nickname'] as String? ?? '',
      avatarUrl: _avatar((j['profile'] as Map?)?['avatar']),
      body: j['body'] as String,
      images: [for (final p in paths) _url(p)],
      imagePaths: paths,
      likeCount: (j['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (j['comment_count'] as num?)?.toInt() ?? 0,
      createdAt: _time(j['created_at'])!,
      editedAt: _time(j['edited_at']),
      likedByMe: liked.contains(j['id']),
    );
  }

  Future<Set<String>> _liked(List<String> postIds) async {
    final me = myId;
    if (me == null || postIds.isEmpty) return {};
    final rows = await client
        .from('post_likes')
        .select('post_id')
        .eq('user_id', me)
        .inFilter('post_id', postIds);
    return {for (final r in rows) r['post_id'] as String};
  }

  @override
  Future<CommunityProfile?> myProfile() async {
    final me = myId;
    if (me == null) return null;
    final row = await client
        .from('community_profiles')
        .select('user_id, nickname, avatar')
        .eq('user_id', me)
        .maybeSingle();
    return row == null
        ? null
        : CommunityProfile(
            me,
            row['nickname'] as String,
            avatarUrl: _avatar(row['avatar']),
          );
  }

  @override
  Future<CommunityProfile> createProfile(String nickname) => _guard(() async {
    final n = nickname.trim();
    if (containsBlockedWords(n)) {
      throw const CommunityException(CommunityError.blockedWords);
    }
    await client.from('community_profiles').upsert({
      'user_id': myId,
      'nickname': n,
    });
    return CommunityProfile(myId!, n);
  });

  @override
  Future<CommunityProfile> updateProfile({
    String? nickname,
    Uint8List? photo,
    bool removePhoto = false,
  }) => _guard(() async {
    final me = myId!;
    final n = nickname?.trim();
    if (n != null && containsBlockedWords(n)) {
      throw const CommunityException(CommunityError.blockedWords);
    }
    final old = await client
        .from('community_profiles')
        .select('avatar')
        .eq('user_id', me)
        .maybeSingle();
    final oldPath = old?['avatar'] as String?;
    String? path;
    if (photo != null) {
      if (imageMimeType(photo) != 'image/jpeg' ||
          photo.length > CommunityLimits.photoBytes) {
        throw const CommunityException(CommunityError.badImage);
      }
      path = '$me/avatar-${_uuid()}.jpg';
      await client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            photo,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
    }
    final row = await client
        .from('community_profiles')
        .update({
          'nickname': ?n,
          'avatar': ?path,
          if (removePhoto && path == null) 'avatar': null,
        })
        .eq('user_id', me)
        .select('nickname, avatar')
        .single();
    // The replaced photo isn't needed anymore.
    if (oldPath != null && (path != null || removePhoto)) {
      try {
        await client.storage.from(_bucket).remove([oldPath]);
      } catch (_) {}
    }
    return CommunityProfile(
      me,
      row['nickname'] as String,
      avatarUrl: _avatar(row['avatar']),
    );
  });

  @override
  Future<List<Gym>> searchGyms(String query) async {
    final rows = await client.rpc(
      'search_gyms',
      params: {'q': query, 'lim': 30},
    );
    return [for (final r in rows as List) Gym.fromJson(r)];
  }

  @override
  Future<List<Gym>> myGyms() async {
    final me = myId;
    if (me == null) return const [];
    final rows = await client
        .from('gym_members')
        .select('created_at, gym:gyms(*)')
        .eq('user_id', me)
        .order('created_at');
    return [
      for (final r in rows)
        if (r['gym'] != null) Gym.fromJson(r['gym'] as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> join(String gymId) => _guard(() async {
    await client.from('gym_members').upsert({'gym_id': gymId, 'user_id': myId});
  });

  @override
  Future<List<Gym>> boards(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await client.from('gyms').select().inFilter('id', ids);
    final byId = {for (final r in rows) r['id'] as String: Gym.fromJson(r)};
    return [for (final id in ids) ?byId[id]];
  }

  @override
  Future<void> leave(String gymId) async {
    await client
        .from('gym_members')
        .delete()
        .eq('gym_id', gymId)
        .eq('user_id', myId!);
  }

  @override
  Future<Gym> addGym(String name, String address) => _guard(() async {
    if (containsBlockedWords(name)) {
      throw const CommunityException(CommunityError.blockedWords);
    }
    final parts = address.trim().split(RegExp(r'\s+'));
    final row = await client
        .from('gyms')
        .insert({
          'id': 'u-${_uuid()}',
          'name': name.trim(),
          'address': address.trim(),
          'sido': parts.isNotEmpty ? parts[0] : '',
          'sigungu': parts.length > 1 ? parts[1] : '',
          'source': 'user',
          'created_by': myId,
        })
        .select()
        .single();
    return Gym.fromJson(row);
  });

  @override
  Future<List<Post>> posts(
    String gymId, {
    DateTime? before,
    int limit = 20,
    PostTag? tag,
    String? query,
  }) => feed([gymId], before: before, limit: limit, tag: tag, query: query);

  @override
  Future<List<Post>> feed(
    List<String> gymIds, {
    DateTime? before,
    int limit = 20,
    PostTag? tag,
    String? query,
  }) async {
    if (gymIds.isEmpty) return const [];
    var q = client
        .from('posts')
        .select(_postColumns)
        .inFilter('gym_id', gymIds);
    if (tag != null) q = q.eq('tag', tag.name);
    final words = query?.trim() ?? '';
    if (words.isNotEmpty) {
      // % and _ are wildcards in LIKE: searched for as they are.
      final escaped = words.replaceAllMapped(
        RegExp(r'[%_\\]'),
        (m) => '\\${m[0]}',
      );
      q = q.ilike('body', '%$escaped%');
    }
    if (before != null) {
      q = q.lt('created_at', before.toUtc().toIso8601String());
    }
    final rows = await q.order('created_at', ascending: false).limit(limit);
    final liked = await _liked([for (final r in rows) r['id'] as String]);
    return [for (final r in rows) _post(r, liked)];
  }

  @override
  Future<List<Post>> hot(
    List<String> gymIds, {
    int days = 7,
    int limit = 5,
  }) async {
    if (gymIds.isEmpty) return const [];
    final since = DateTime.now().subtract(Duration(days: days));
    final rows = await client
        .from('posts')
        .select(_postColumns)
        .inFilter('gym_id', gymIds)
        .gte('created_at', since.toUtc().toIso8601String())
        .gt('like_count', 0)
        .order('like_count', ascending: false)
        .order('comment_count', ascending: false)
        .limit(limit);
    final liked = await _liked([for (final r in rows) r['id'] as String]);
    return [for (final r in rows) _post(r, liked)];
  }

  @override
  Future<Post> writePost(
    String gymId,
    String body,
    List<Uint8List> photos, {
    PostTag tag = PostTag.free,
  }) => _guard(() async {
    if (containsBlockedWords(body)) {
      throw const CommunityException(CommunityError.blockedWords);
    }
    final me = myId!;
    final paths = <String>[];
    for (final bytes in photos.take(CommunityLimits.photos)) {
      final type = imageMimeType(bytes);
      if (type == null || bytes.length > CommunityLimits.photoBytes) {
        throw const CommunityException(CommunityError.badImage);
      }
      final ext = type.split('/').last.replaceAll('jpeg', 'jpg');
      final path = '$me/${_uuid()}.$ext';
      await client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: type),
          );
      paths.add(path);
    }
    try {
      final row = await client
          .from('posts')
          .insert({
            'gym_id': gymId,
            'body': body.trim(),
            'images': paths,
            'tag': tag.name,
          })
          .select(_postColumns)
          .single();
      return _post(row, const {});
    } catch (_) {
      if (paths.isNotEmpty) {
        await client.storage.from(_bucket).remove(paths);
      }
      rethrow;
    }
  });

  @override
  Future<Post> editPost(Post post, String body, {PostTag? tag}) =>
      _guard(() async {
        if (containsBlockedWords(body)) {
          throw const CommunityException(CommunityError.blockedWords);
        }
        await client
            .from('posts')
            .update({'body': body.trim(), 'tag': (tag ?? post.tag).name})
            .eq('id', post.id);
        return post.copyWith(
          body: body.trim(),
          tag: tag,
          editedAt: DateTime.now(),
        );
      });

  @override
  Future<Post?> post(String id) async {
    final row = await client
        .from('posts')
        .select(_postColumns)
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return _post(row, await _liked([id]));
  }

  @override
  Future<List<Post>> myPosts({DateTime? before, int limit = 20}) async {
    final me = myId;
    if (me == null) return const [];
    var q = client.from('posts').select(_postColumns).eq('author', me);
    if (before != null) {
      q = q.lt('created_at', before.toUtc().toIso8601String());
    }
    final rows = await q.order('created_at', ascending: false).limit(limit);
    final liked = await _liked([for (final r in rows) r['id'] as String]);
    return [for (final r in rows) _post(r, liked)];
  }

  @override
  Future<List<MyComment>> myComments({DateTime? before, int limit = 20}) async {
    final me = myId;
    if (me == null) return const [];
    var q = client
        .from('comments')
        .select('$_commentColumns, post:posts(body, gym_id, gym:gyms(name))')
        .eq('author', me);
    if (before != null) {
      q = q.lt('created_at', before.toUtc().toIso8601String());
    }
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return [
      for (final r in rows)
        if (r['post'] case final Map<String, dynamic> p)
          MyComment(
            comment: _comment(r),
            postBody: p['body'] as String? ?? '',
            gymId: p['gym_id'] as String? ?? '',
            gymName: (p['gym'] as Map?)?['name'] as String?,
          ),
    ];
  }

  @override
  Future<void> deletePost(Post post) async {
    await client.from('posts').delete().eq('id', post.id);
    if (post.imagePaths.isNotEmpty) {
      await client.storage.from(_bucket).remove(post.imagePaths);
    }
  }

  @override
  Future<List<Comment>> comments(String postId) async {
    final rows = await client
        .from('comments')
        .select(_commentColumns)
        .eq('post_id', postId)
        .order('created_at')
        .limit(300);
    final liked = await _likedComments([
      for (final r in rows) r['id'] as String,
    ]);
    return [for (final r in rows) _comment(r, liked)];
  }

  Future<Set<String>> _likedComments(List<String> ids) async {
    final me = myId;
    if (me == null || ids.isEmpty) return {};
    final rows = await client
        .from('comment_likes')
        .select('comment_id')
        .eq('user_id', me)
        .inFilter('comment_id', ids);
    return {for (final r in rows) r['comment_id'] as String};
  }

  Comment _comment(Map<String, dynamic> r, [Set<String> liked = const {}]) =>
      Comment(
        id: r['id'] as String,
        postId: r['post_id'] as String,
        parentId: r['parent_id'] as String?,
        authorId: r['author'] as String,
        nickname: (r['profile'] as Map?)?['nickname'] as String? ?? '',
        avatarUrl: _avatar((r['profile'] as Map?)?['avatar']),
        body: r['body'] as String,
        createdAt: _time(r['created_at'])!,
        likeCount: (r['like_count'] as num?)?.toInt() ?? 0,
        likedByMe: liked.contains(r['id']),
      );

  @override
  Future<Comment> addComment(String postId, String body, {String? parentId}) =>
      _guard(() async {
        if (containsBlockedWords(body)) {
          throw const CommunityException(CommunityError.blockedWords);
        }
        final row = await client
            .from('comments')
            .insert({
              'post_id': postId,
              'body': body.trim(),
              'parent_id': ?parentId,
            })
            .select(_commentColumns)
            .single();
        return _comment(row);
      });

  @override
  Future<void> deleteComment(Comment comment) async {
    await client.from('comments').delete().eq('id', comment.id);
  }

  @override
  Future<void> setLike(String postId, bool liked) async {
    if (liked) {
      await client.from('post_likes').upsert({
        'post_id': postId,
        'user_id': myId,
      });
    } else {
      await client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', myId!);
    }
  }

  @override
  Future<void> setCommentLike(String commentId, bool liked) async {
    if (liked) {
      await client.from('comment_likes').upsert({
        'comment_id': commentId,
        'user_id': myId,
      });
    } else {
      await client
          .from('comment_likes')
          .delete()
          .eq('comment_id', commentId)
          .eq('user_id', myId!);
    }
  }

  @override
  Future<List<CommunityNotification>> notifications({
    DateTime? before,
    int limit = 30,
  }) async {
    final me = myId;
    if (me == null) return const [];
    var q = client
        .from('notifications')
        .select(
          '*, actor_profile:community_profiles!notifications_actor_fkey'
          '(nickname, avatar), post:posts(body, gym_id), '
          'comment:comments(body)',
        )
        .eq('user_id', me);
    if (before != null) {
      q = q.lt('created_at', before.toUtc().toIso8601String());
    }
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return [
      for (final r in rows)
        if (NotificationKind.parse(r['kind']) case final kind?)
          CommunityNotification(
            id: r['id'] as String,
            kind: kind,
            actorId: r['actor'] as String?,
            actorNickname: (r['actor_profile'] as Map?)?['nickname'] as String?,
            actorAvatar: _avatar((r['actor_profile'] as Map?)?['avatar']),
            count: (r['count'] as num?)?.toInt() ?? 1,
            postId: r['post_id'] as String?,
            commentId: r['comment_id'] as String?,
            postBody: (r['post'] as Map?)?['body'] as String? ?? '',
            commentBody: (r['comment'] as Map?)?['body'] as String?,
            gymId: (r['post'] as Map?)?['gym_id'] as String?,
            read: r['read_at'] != null,
            createdAt: _time(r['created_at'])!,
          ),
    ];
  }

  @override
  Future<int> unreadNotifications() async {
    final me = myId;
    if (me == null) return 0;
    return client
        .from('notifications')
        .count(CountOption.exact)
        .eq('user_id', me)
        .isFilter('read_at', null);
  }

  @override
  Future<void> markNotificationsRead() async {
    final me = myId;
    if (me == null) return;
    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', me)
        .isFilter('read_at', null);
  }

  @override
  Future<void> report(String type, String id, ReportReason reason) async {
    try {
      await client.from('reports').insert({
        'target_type': type,
        'target_id': id,
        'reason': reason.name,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow; // already reported: fine
    }
  }

  @override
  Future<void> block(String userId) async {
    await client.from('user_blocks').upsert({
      'blocker': myId,
      'blocked': userId,
    });
  }

  @override
  Future<void> deleteMyPhotos() async {
    final me = myId;
    if (me == null) return;
    final bucket = client.storage.from(_bucket);
    while (true) {
      final files = await bucket.list(path: me);
      if (files.isEmpty) return;
      await bucket.remove([for (final f in files) '$me/${f.name}']);
      if (files.length < 100) return;
    }
  }
}

DateTime? _time(Object? v) =>
    v == null ? null : DateTime.tryParse(v as String)?.toLocal();

final _rng = math.Random.secure();

String _uuid() {
  final b = List<int>.generate(16, (_) => _rng.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  final s = [for (var i = 0; i < 16; i++) h(i)].join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-'
      '${s.substring(16, 20)}-${s.substring(20)}';
}

// ---------------------------------------------------------------------------
// In memory (tests, and a demo build without a server)
// ---------------------------------------------------------------------------

class MemoryCommunity implements CommunityRepository {
  @override
  String? myId;
  final DateTime Function() clock;

  final Map<String, Gym> gyms = {};
  final Map<String, String> nicknames = {}; // userId -> nickname
  final Map<String, String> avatars = {}; // userId -> photo URL
  final Map<String, Set<String>> members = {}; // userId -> gym ids
  final List<Post> _posts = [];
  final List<Comment> _comments = [];
  final Map<String, Set<String>> _likes = {}; // postId -> user ids
  final Map<String, Set<String>> _commentLikes = {}; // commentId -> user ids
  final List<_Note> _notes = [];
  final Set<(String, String)> blocks = {};
  final List<(String, String, ReportReason)> reports = [];
  var _seq = 0;

  MemoryCommunity({this.myId, DateTime Function()? clock})
    : clock = clock ?? DateTime.now {
    for (final (id, name) in _topicNames) {
      gyms[id] = Gym(id: id, name: name);
    }
  }

  static const _topicNames = [
    ('t-health', '헬스'),
    ('t-crossfit', '크로스핏'),
    ('t-running', '러닝'),
    ('t-yoga', '요가'),
    ('t-pilates', '필라테스'),
    ('t-diet', '다이어트·식단'),
    ('t-home', '홈트'),
    ('t-swimming', '수영'),
    ('t-climbing', '클라이밍'),
    ('t-cycling', '자전거'),
    ('t-combat', '복싱·격투기'),
    ('t-free', '자유수다'),
  ];

  String _id() => 'm${++_seq}';

  bool _visible(String author) => !blocks.contains((myId ?? '', author));

  Post _withLikes(Post p) => p.copyWith(
    nickname: nicknames[p.authorId],
    avatarUrl: avatars[p.authorId],
    likeCount: _likes[p.id]?.length ?? 0,
    likedByMe: _likes[p.id]?.contains(myId) ?? false,
    commentCount: _comments.where((c) => c.postId == p.id).length,
  );

  Gym _gym(String id) {
    final g = gyms[id]!;
    final ps = _posts.where((p) => p.gymId == id);
    return g.copyWith(
      memberCount: members.values.where((s) => s.contains(id)).length,
      postCount: ps.length,
      lastPostAt: ps.isEmpty ? null : ps.last.createdAt,
    );
  }

  @override
  Future<CommunityProfile?> myProfile() async {
    final n = nicknames[myId];
    return n == null
        ? null
        : CommunityProfile(myId!, n, avatarUrl: avatars[myId]);
  }

  @override
  Future<CommunityProfile> createProfile(String nickname) async {
    final n = nickname.trim();
    if (containsBlockedWords(n)) {
      throw const CommunityException(CommunityError.blockedWords);
    }
    if (nicknames.entries.any(
      (e) => e.key != myId && e.value.toLowerCase() == n.toLowerCase(),
    )) {
      throw const CommunityException(CommunityError.nicknameTaken);
    }
    nicknames[myId!] = n;
    return CommunityProfile(myId!, n, avatarUrl: avatars[myId]);
  }

  @override
  Future<CommunityProfile> updateProfile({
    String? nickname,
    Uint8List? photo,
    bool removePhoto = false,
  }) async {
    if (nickname != null) await createProfile(nickname);
    if (photo != null) {
      if (imageMimeType(photo) == null) {
        throw const CommunityException(CommunityError.badImage);
      }
      avatars[myId!] = 'data:image/jpeg;base64,${base64Encode(photo)}';
    } else if (removePhoto) {
      avatars.remove(myId);
    }
    return (await myProfile())!;
  }

  @override
  Future<List<Gym>> searchGyms(String query) async {
    final words = query.toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    final hits = [
      for (final g in gyms.values)
        if (!g.isTopic &&
            words.every(
              (w) => (g.name + g.address)
                  .toLowerCase()
                  .replaceAll(' ', '')
                  .contains(w),
            ))
          _gym(g.id),
    ]..sort((a, b) => b.memberCount.compareTo(a.memberCount));
    return hits.take(30).toList();
  }

  @override
  Future<List<Gym>> myGyms() async => [
    for (final id in members[myId] ?? <String>{}) _gym(id),
  ];

  @override
  Future<void> join(String gymId) async {
    final mine = members[myId!] ??= <String>{};
    if (isTopicId(gymId)) throw StateError('topic_board');
    if (!mine.contains(gymId) && mine.length >= CommunityLimits.myGyms) {
      throw const CommunityException(CommunityError.gymLimit);
    }
    mine.add(gymId);
  }

  @override
  Future<List<Gym>> boards(List<String> ids) async => [
    for (final id in ids)
      if (gyms.containsKey(id)) _gym(id),
  ];

  @override
  Future<void> leave(String gymId) async => members[myId]?.remove(gymId);

  @override
  Future<Gym> addGym(String name, String address) async {
    if (containsBlockedWords(name)) {
      throw const CommunityException(CommunityError.blockedWords);
    }
    final g = Gym(
      id: 'u-${_id()}',
      name: name.trim(),
      address: address.trim(),
      userAdded: true,
    );
    gyms[g.id] = g;
    return g;
  }

  @override
  Future<List<Post>> posts(
    String gymId, {
    DateTime? before,
    int limit = 20,
    PostTag? tag,
    String? query,
  }) => feed([gymId], before: before, limit: limit, tag: tag, query: query);

  @override
  Future<List<Post>> feed(
    List<String> gymIds, {
    DateTime? before,
    int limit = 20,
    PostTag? tag,
    String? query,
  }) async {
    final list = [
      for (final p in _posts.reversed)
        if (gymIds.contains(p.gymId) &&
            (tag == null || p.tag == tag) &&
            (query == null ||
                p.body.toLowerCase().contains(query.trim().toLowerCase())) &&
            _visible(p.authorId) &&
            (before == null || p.createdAt.isBefore(before)))
          _withLikes(p).copyWith(gymName: gyms[p.gymId]?.name),
    ];
    return list.take(limit).toList();
  }

  @override
  Future<List<Post>> hot(
    List<String> gymIds, {
    int days = 7,
    int limit = 5,
  }) async {
    final since = clock().subtract(Duration(days: days));
    final list = [
      for (final p in _posts)
        if (gymIds.contains(p.gymId) &&
            _visible(p.authorId) &&
            p.createdAt.isAfter(since))
          _withLikes(p).copyWith(gymName: gyms[p.gymId]?.name),
    ]..removeWhere((p) => p.likeCount == 0);
    list.sort((a, b) {
      final c = b.likeCount.compareTo(a.likeCount);
      return c != 0 ? c : b.commentCount.compareTo(a.commentCount);
    });
    return list.take(limit).toList();
  }

  /// Adds a post as someone else (demo data, tests).
  Post seedPost(
    String gymId,
    String authorId,
    String body, {
    DateTime? at,
    List<String> images = const [],
    PostTag tag = PostTag.free,
  }) {
    final p = Post(
      id: _id(),
      gymId: gymId,
      tag: tag,
      authorId: authorId,
      nickname: nicknames[authorId] ?? '',
      body: body,
      images: images,
      createdAt: at ?? clock(),
    );
    _posts.add(p);
    _posts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return p;
  }

  Comment seedComment(
    String postId,
    String authorId,
    String body, {
    String? parentId,
  }) {
    // Replies to a reply go under its top-level comment.
    final parent = parentId == null
        ? null
        : _comments.where((c) => c.id == parentId).firstOrNull;
    final c = Comment(
      id: _id(),
      postId: postId,
      parentId: parent?.parentId ?? parent?.id,
      authorId: authorId,
      nickname: nicknames[authorId] ?? '',
      body: body,
      createdAt: clock(),
    );
    _comments.add(c);
    // Like comments_notify: whoever was answered, and the post's author.
    final postAuthor = _posts
        .where((p) => p.id == postId)
        .firstOrNull
        ?.authorId;
    final replyTo = parent?.authorId;
    if (replyTo != null) {
      _notify(replyTo, authorId, NotificationKind.reply, postId, c.id);
    }
    if (postAuthor != replyTo) {
      _notify(postAuthor, authorId, NotificationKind.comment, postId, c.id);
    }
    return c;
  }

  void seedLike(String postId, String userId) {
    final s = _likes[postId] ??= {};
    if (!s.add(userId)) return;
    final author = _posts.where((p) => p.id == postId).firstOrNull?.authorId;
    _notify(author, userId, NotificationKind.postLike, postId, null);
    if (s.length == CommunityLimits.hotLikes &&
        !_notes.any(
          (n) => n.postId == postId && n.kind == NotificationKind.hot,
        )) {
      _notify(author, null, NotificationKind.hot, postId, null);
    }
  }

  void seedCommentLike(String commentId, String userId) {
    if (!(_commentLikes[commentId] ??= {}).add(userId)) return;
    final c = _comments.where((c) => c.id == commentId).firstOrNull;
    if (c == null) return;
    _notify(c.authorId, userId, NotificationKind.commentLike, c.postId, c.id);
  }

  /// Like community_notify(): not to myself or someone who blocked me;
  /// likes on one thing stay one unread notification.
  void _notify(
    String? target,
    String? who,
    NotificationKind kind,
    String? postId,
    String? commentId,
  ) {
    if (target == null || target == who) return;
    if (who != null && blocks.contains((target, who))) return;
    if (kind == NotificationKind.postLike ||
        kind == NotificationKind.commentLike) {
      final same = _notes.where(
        (n) =>
            n.userId == target &&
            n.kind == kind &&
            !n.read &&
            n.postId == postId &&
            n.commentId == commentId,
      );
      if (same.isNotEmpty) {
        same.first
          ..count += 1
          ..actor = who ?? same.first.actor
          ..at = clock();
        return;
      }
    }
    _notes.add(_Note(_id(), target, who, kind, postId, commentId, clock()));
  }

  @override
  Future<Post> writePost(
    String gymId,
    String body,
    List<Uint8List> photos, {
    PostTag tag = PostTag.free,
  }) async {
    if (containsBlockedWords(body)) {
      throw const CommunityException(CommunityError.blockedWords);
    }
    if (photos.any((b) => imageMimeType(b) == null)) {
      throw const CommunityException(CommunityError.badImage);
    }
    final recent = _posts.where(
      (p) =>
          p.authorId == myId &&
          clock().difference(p.createdAt) < const Duration(minutes: 10),
    );
    if (recent.length >= 5) {
      throw const CommunityException(CommunityError.rateLimited);
    }
    // Photos stay in memory as data URLs (shown on the web demo).
    return seedPost(
      gymId,
      myId!,
      body.trim(),
      tag: tag,
      images: [
        for (final b in photos)
          'data:${imageMimeType(b)};base64,${base64Encode(b)}',
      ],
    ).copyWith(gymName: gyms[gymId]?.name, avatarUrl: avatars[myId]);
  }

  @override
  Future<Post> editPost(Post post, String body, {PostTag? tag}) async {
    final i = _posts.indexWhere((p) => p.id == post.id);
    final edited = _posts[i].copyWith(
      body: body.trim(),
      tag: tag,
      editedAt: clock(),
    );
    _posts[i] = edited;
    return _withLikes(edited)
        .copyWith(gymName: gyms[edited.gymId]?.name, avatarUrl: avatars[myId]);
  }

  @override
  Future<Post?> post(String id) async {
    final p = _posts.where((p) => p.id == id).firstOrNull;
    return p == null
        ? null
        : _withLikes(p).copyWith(gymName: gyms[p.gymId]?.name);
  }

  @override
  Future<List<Post>> myPosts({DateTime? before, int limit = 20}) async => [
    for (final p in _posts.reversed)
      if (p.authorId == myId &&
          (before == null || p.createdAt.isBefore(before)))
        _withLikes(p).copyWith(gymName: gyms[p.gymId]?.name),
  ].take(limit).toList();

  @override
  Future<List<MyComment>> myComments({
    DateTime? before,
    int limit = 20,
  }) async => [
    for (final c in _comments.reversed)
      if (c.authorId == myId &&
          (before == null || c.createdAt.isBefore(before)))
        if (_posts.where((p) => p.id == c.postId).firstOrNull case final p?)
          MyComment(
            comment: _withAuthor(c),
            postBody: p.body,
            gymId: p.gymId,
            gymName: gyms[p.gymId]?.name,
          ),
  ].take(limit).toList();

  @override
  Future<void> deletePost(Post post) async {
    _posts.removeWhere((p) => p.id == post.id);
    _comments.removeWhere((c) => c.postId == post.id);
  }

  @override
  Future<List<Comment>> comments(String postId) async => [
    for (final c in _comments)
      if (c.postId == postId && _visible(c.authorId)) _withAuthor(c),
  ];

  Comment _withAuthor(Comment c) => Comment(
    id: c.id,
    postId: c.postId,
    parentId: c.parentId,
    authorId: c.authorId,
    nickname: nicknames[c.authorId] ?? c.nickname,
    avatarUrl: avatars[c.authorId],
    body: c.body,
    createdAt: c.createdAt,
    likeCount: _commentLikes[c.id]?.length ?? 0,
    likedByMe: _commentLikes[c.id]?.contains(myId) ?? false,
  );

  @override
  Future<Comment> addComment(
    String postId,
    String body, {
    String? parentId,
  }) async {
    if (containsBlockedWords(body)) {
      throw const CommunityException(CommunityError.blockedWords);
    }
    return _withAuthor(
      seedComment(postId, myId!, body.trim(), parentId: parentId),
    );
  }

  @override
  Future<void> deleteComment(Comment comment) async => _comments.removeWhere(
    (c) => c.id == comment.id || c.parentId == comment.id,
  );

  @override
  Future<void> setLike(String postId, bool liked) async {
    liked ? seedLike(postId, myId!) : _likes[postId]?.remove(myId);
  }

  @override
  Future<void> setCommentLike(String commentId, bool liked) async {
    liked
        ? seedCommentLike(commentId, myId!)
        : _commentLikes[commentId]?.remove(myId);
  }

  @override
  Future<List<CommunityNotification>> notifications({
    DateTime? before,
    int limit = 30,
  }) async {
    final mine = [
      for (final n in _notes)
        if (n.userId == myId && (before == null || n.at.isBefore(before))) n,
    ]..sort((a, b) => b.at.compareTo(a.at));
    return [
      for (final n in mine.take(limit))
        CommunityNotification(
          id: n.id,
          kind: n.kind,
          actorId: n.actor,
          actorNickname: n.actor == null ? null : nicknames[n.actor],
          actorAvatar: n.actor == null ? null : avatars[n.actor],
          count: n.count,
          postId: n.postId,
          commentId: n.commentId,
          postBody:
              _posts.where((p) => p.id == n.postId).firstOrNull?.body ?? '',
          commentBody: _comments
              .where((c) => c.id == n.commentId)
              .firstOrNull
              ?.body,
          gymId: _posts.where((p) => p.id == n.postId).firstOrNull?.gymId,
          read: n.read,
          createdAt: n.at,
        ),
    ];
  }

  @override
  Future<int> unreadNotifications() async =>
      _notes.where((n) => n.userId == myId && !n.read).length;

  @override
  Future<void> markNotificationsRead() async {
    for (final n in _notes) {
      if (n.userId == myId) n.read = true;
    }
  }

  @override
  Future<void> report(String type, String id, ReportReason reason) async =>
      reports.add((type, id, reason));

  @override
  Future<void> block(String userId) async => blocks.add((myId!, userId));

  @override
  Future<void> deleteMyPhotos() async {}

  /// A few gyms, people and posts for the demo build and screenshots.
  static MemoryCommunity demo({
    String? me,
    DateTime Function()? clock,
    bool meJoined = false,
  }) {
    final c = MemoryCommunity(myId: me, clock: clock);
    final now = c.clock();
    Duration ago({int d = 0, int h = 0, int m = 0}) =>
        Duration(days: d, hours: h, minutes: m);
    for (final (id, name, addr) in [
      ('l-1', '에이블짐 강남점', '서울특별시 강남구 테헤란로 152'),
      ('l-2', '바디스페이스 역삼', '서울특별시 강남구 역삼로 120'),
      ('l-3', '스포애니 신촌점', '서울특별시 서대문구 연세로 10'),
      ('l-4', '짐박스 망원', '서울특별시 마포구 망원로 45'),
      ('l-5', '파워하우스 해운대', '부산광역시 해운대구 해운대로 600'),
    ]) {
      c.gyms[id] = Gym(id: id, name: name, address: addr);
    }
    c.nicknames.addAll({
      'u1': '하체는사랑',
      'u2': '새벽운동러',
      'u3': '벤치100',
      'u4': '초보헬린이',
      'u5': '데드리프트장인',
      'u6': '러닝머신지박령',
    });
    for (final u in ['u1', 'u2', 'u3', 'u4', 'u5', 'u6']) {
      c.members[u] = {'l-1'};
    }
    c.members['u3']!.add('l-2');
    c.members['u5']!.add('l-2');
    if (me != null && meJoined) {
      c.nicknames[me] = '헬린이철수';
      c.members[me] = {'l-1', 'l-2'};
    }
    final p1 = c.seedPost(
      'l-1',
      'u2',
      '평일 새벽 6시에 하체 같이 하실 분 있나요? 스쿼트 보조 서로 봐주면 좋을 것 같아요!',
      at: now.subtract(ago(m: 42)),
      tag: PostTag.mate,
    );
    final p2 = c.seedPost(
      'l-1',
      'u4',
      '헬스 시작한 지 2주 됐는데 3분할이 나을까요 무분할이 나을까요? 주 4회 갈 수 있어요.',
      at: now.subtract(ago(h: 3)),
      tag: PostTag.question,
    );
    final p3 = c.seedPost(
      'l-1',
      'u1',
      '오늘 스미스머신 옆 케이블 하나 고장났어요. 카운터에 말해뒀습니다!',
      at: now.subtract(ago(h: 5)),
      tag: PostTag.info,
    );
    c.seedPost(
      'l-1',
      'u6',
      '저녁 7~8시가 제일 붐비네요. 9시 넘어가면 랙 여유 있어요!',
      at: now.subtract(ago(d: 1, h: 2)),
      tag: PostTag.info,
    );
    c.seedPost(
      'l-1',
      'u5',
      '3개월 만에 데드 140 찍었습니다… 다들 꾸준히 하면 됩니다 진짜로',
      at: now.subtract(ago(d: 2)),
      tag: PostTag.free,
    );
    final p6 = c.seedPost(
      'l-2',
      'u3',
      '역삼 바디스페이스 PT 받아보신 분 후기 궁금해요. 가격대랑 선생님 스타일요!',
      at: now.subtract(ago(h: 8)),
      tag: PostTag.question,
    );
    c.seedPost(
      'l-2',
      'u5',
      '새로 들어온 해머스트렝스 로우 머신 좋네요. 등 자극 확실합니다',
      at: now.subtract(ago(d: 1, h: 6)),
      tag: PostTag.review,
    );
    final l1 = c.seedPost(
      't-running',
      'u6',
      '이번 주 토요일 아침 7시 한강 반포 10km 같이 뛰실 분! 페이스 6분대입니다',
      at: now.subtract(ago(h: 2)),
      tag: PostTag.mate,
    );
    final l2 = c.seedPost(
      't-diet',
      'u4',
      '단백질 쉐이크 하루 2번 먹는데 너무 많은가요? 체중 62kg이에요',
      at: now.subtract(ago(h: 4)),
      tag: PostTag.question,
    );
    final l3 = c.seedPost(
      't-crossfit',
      'u5',
      '오늘 WOD 머프 완주했습니다… 1시간 2분. 다리가 제 것이 아니네요',
      at: now.subtract(ago(h: 9)),
      tag: PostTag.review,
    );
    c.seedPost(
      't-yoga',
      'u1',
      '하체 운동 다음 날 요가 30분 하니까 회복이 훨씬 빨라요. 추천합니다',
      at: now.subtract(ago(d: 1)),
      tag: PostTag.info,
    );
    c.seedPost(
      't-free',
      'u3',
      '다들 운동 끝나고 뭐 드세요? 저는 무조건 국밥…',
      at: now.subtract(ago(d: 1, h: 3)),
    );
    for (final u in ['u1', 'u2', 'u3', 'u4', 'u5']) {
      c.seedLike(l1.id, u);
    }
    for (final u in ['u1', 'u2', 'u6']) {
      c.seedLike(l3.id, u);
    }
    c.seedLike(l2.id, 'u5');
    c.seedComment(l1.id, 'u2', '반포 어디서 모이나요? 저 갈게요');
    c.seedComment(l2.id, 'u5', '식사로 채우기 힘들면 괜찮아요. 총량만 체중×1.6g 정도');
    if (me != null && meJoined) {
      final mine = c.seedPost(
        'l-1',
        me,
        '오늘 처음으로 풀업 5개 성공했어요! 다들 등 운동 뭐부터 하세요?',
        at: now.subtract(ago(d: 3)),
        tag: PostTag.review,
      );
      c.seedComment(mine.id, 'u3', '축하해요! 저는 랫풀다운부터 해요');
      for (final u in ['u3', 'u1', 'u2', 'u5', 'u6']) {
        c.seedLike(mine.id, u);
      }
    }
    c.seedComment(p1.id, 'u3', '저도 새벽파입니다 ㅎㅎ');
    final c1 = c.seedComment(p1.id, 'u1', '월수금 6시 가능해요. 스쿼트 위주면 좋아요');
    c.seedComment(
      p1.id,
      'u2',
      '@하체는사랑 좋아요! 월요일 6시에 스쿼트랙 앞에서 봬요',
      parentId: c1.id,
    );
    c.seedComment(p2.id, 'u3', '처음엔 무분할로 전신 3회 추천해요. 자세 익히기 좋아요');
    c.seedComment(p3.id, 'u6', '감사합니다 오늘 못 쓸 뻔');
    if (me != null && meJoined) {
      final myComment = c.seedComment(p2.id, me, '저도 무분할로 시작했는데 자세 잡는 데 좋았어요!');
      c.seedCommentLike(myComment.id, 'u4');
      c.seedComment(
        p2.id,
        'u4',
        '@헬린이철수 오 감사해요! 무분할 루틴 공유해 주실 수 있나요?',
        parentId: myComment.id,
      );
    }
    c.seedComment(p6.id, 'u5', '저 받아봤는데 자세 교정 꼼꼼하게 봐주세요');
    for (final u in ['u1', 'u3', 'u4', 'u5', 'u6']) {
      c.seedLike(p1.id, u);
    }
    for (final u in ['u1', 'u5']) {
      c.seedLike(p2.id, u);
    }
    c.seedLike(p3.id, 'u2');
    return c;
  }
}

class _Note {
  final String id;
  final String userId;
  String? actor;
  final NotificationKind kind;
  final String? postId;
  final String? commentId;
  DateTime at;
  var count = 1;
  var read = false;
  _Note(
    this.id,
    this.userId,
    this.actor,
    this.kind,
    this.postId,
    this.commentId,
    this.at,
  );
}
