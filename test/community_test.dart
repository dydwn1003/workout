import 'dart:typed_data';

import 'package:adapt_coach/data/community.dart';
import 'package:adapt_coach/state/community_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('blocked words ignore spacing and punctuation', () {
    expect(containsBlockedWords('오늘 하체 같이 하실 분'), isFalse);
    expect(containsBlockedWords('시발'), isTrue);
    expect(containsBlockedWords('시 . 발'), isTrue);
    expect(containsBlockedWords('F u c k'), isTrue);
    // Everyday words that contain a bad one's letters stay allowed.
    expect(containsBlockedWords('걱정하지 말고 보지 마세요'), isFalse);
    expect(containsBlockedWords('밤새 자지 않고 운동'), isFalse);
    expect(containsBlockedWords('우리 시바견'), isFalse);
  });

  test('nicknames: 2-12 letters or numbers, no blocked words', () {
    expect(validNickname('헬린이'), isTrue);
    expect(validNickname('bench_100'), isTrue);
    expect(validNickname('a'), isFalse);
    expect(validNickname('너무너무긴닉네임입니다정말로'), isFalse);
    expect(validNickname('공백 있음'), isFalse);
    expect(validNickname('병신'), isFalse);
  });

  test('image type from the first bytes', () {
    expect(
      imageMimeType(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0])),
      'image/jpeg',
    );
    expect(
      imageMimeType(
        Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0]),
      ),
      'image/png',
    );
    expect(
      imageMimeType(
        Uint8List.fromList('RIFF\x00\x00\x00\x00WEBPVP8 '.codeUnits),
      ),
      'image/webp',
    );
    // HEIC ("....ftypheic") isn't accepted by the bucket.
    expect(
      imageMimeType(Uint8List.fromList('\x00\x00\x00\x18ftypheic'.codeUnits)),
      isNull,
    );
  });

  test('gym short address drops the province', () {
    const g = Gym(id: 'x', name: 'x', address: '서울특별시 강남구 테헤란로 152 (역삼동)');
    expect(g.shortAddress, '강남구 테헤란로 152');
  });

  group('memory community', () {
    late DateTime now;
    late MemoryCommunity repo;
    setUp(() {
      now = DateTime(2026, 9, 30, 20);
      repo = MemoryCommunity.demo(me: 'me', clock: () => now);
    });

    test('search matches every word, spaces ignored', () async {
      expect((await repo.searchGyms('강남 에이블')).map((g) => g.id), ['l-1']);
      expect((await repo.searchGyms('에이블짐강남')).map((g) => g.id), ['l-1']);
      expect(await repo.searchGyms('없는헬스장'), isEmpty);
    });

    test('profile, join, post, like, comment', () async {
      final c = CommunityState(repo);
      await c.refresh();
      expect(c.profile, isNull);
      await expectLater(
        c.createProfile('하체는사랑'),
        throwsA(
          isA<CommunityException>().having(
            (e) => e.error,
            'error',
            CommunityError.nicknameTaken,
          ),
        ),
      );
      await c.createProfile('헬린이');
      final gym = (await repo.searchGyms('망원')).single;
      await c.join(gym);
      expect(c.isMine(gym.id), isTrue);

      final post = await repo.writePost(gym.id, '  같이 운동해요  ', const []);
      expect(post.body, '같이 운동해요');
      expect(post.nickname, '헬린이');
      await repo.setLike(post.id, true);
      await repo.addComment(post.id, '좋아요');
      final board = await repo.posts(gym.id);
      expect(board.single.likedByMe, isTrue);
      expect(board.single.likeCount, 1);
      expect(board.single.commentCount, 1);

      await c.leave(gym.id);
      expect(c.isMine(gym.id), isFalse);
    });

    test('newest first, paged with before', () async {
      final all = await repo.posts('l-1');
      expect(all.length, 5);
      expect(
        all.map((p) => p.createdAt).toList(),
        [...all.map((p) => p.createdAt)]..sort((a, b) => b.compareTo(a)),
      );
      final older = await repo.posts('l-1', before: all.first.createdAt);
      expect(older.length, 4);
    });

    test('blocking hides the person\'s posts and comments', () async {
      final before = await repo.posts('l-1');
      final u2 = before.firstWhere((p) => p.authorId == 'u2');
      await repo.block('u2');
      final after = await repo.posts('l-1');
      expect(after.any((p) => p.authorId == 'u2'), isFalse);
      expect(after.length, before.length - 1);
      final other = before.firstWhere((p) => p.authorId == 'u4');
      final cs = await repo.comments(other.id);
      expect(cs.any((c) => c.authorId == 'u2'), isFalse);
      expect(await repo.comments(u2.id), isNotEmpty); // others' still there
    });

    test('blocked words and rate limit refuse the post', () async {
      await repo.createProfile('헬린이');
      await expectLater(
        repo.writePost('l-1', '이 시발', const []),
        throwsA(isA<CommunityException>()),
      );
      for (var i = 0; i < 5; i++) {
        await repo.writePost('l-4', '글 $i', const []);
      }
      await expectLater(
        repo.writePost('l-4', '여섯 번째', const []),
        throwsA(
          isA<CommunityException>().having(
            (e) => e.error,
            'error',
            CommunityError.rateLimited,
          ),
        ),
      );
    });

    test('tags filter a board; the feed mixes my gyms with names', () async {
      final mates = await repo.posts('l-1', tag: PostTag.mate);
      expect(mates, isNotEmpty);
      expect(mates.every((p) => p.tag == PostTag.mate), isTrue);
      final feed = await repo.feed(['l-1', 'l-2']);
      expect(feed.map((p) => p.gymId).toSet(), {'l-1', 'l-2'});
      expect(feed.every((p) => p.gymName != null), isTrue);
      final times = feed.map((p) => p.createdAt).toList();
      expect(times, [...times]..sort((a, b) => b.compareTo(a)));
      expect(await repo.feed(const []), isEmpty);

      await repo.createProfile('헬린이');
      final p = await repo.writePost(
        'l-3',
        '같이 해요',
        const [],
        tag: PostTag.mate,
      );
      expect(p.tag, PostTag.mate);
      final edited = await repo.editPost(p, '같이 해요!', tag: PostTag.info);
      expect(edited.tag, PostTag.info);
      expect(PostTag.parse('nope'), PostTag.free);
    });

    test('photos stay with the post', () async {
      await repo.createProfile('헬린이');
      final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);
      final p = await repo.writePost('l-4', '사진', [jpeg, jpeg]);
      expect(p.images.length, 2);
      expect(p.images.first, startsWith('data:image/jpeg;base64,'));
      expect((await repo.posts('l-4')).single.images.length, 2);
    });

    test('added gyms are searchable and marked as user-added', () async {
      final g = await repo.addGym('우리동네 크로스핏', '서울 마포구 망원로 1');
      expect(g.userAdded, isTrue);
      expect((await repo.searchGyms('크로스핏')).single.id, g.id);
    });

    test('signed out: no profile, no gyms', () async {
      final c = CommunityState(MemoryCommunity.demo());
      await c.refresh();
      expect(c.signedIn, isFalse);
      expect(c.myGyms, isEmpty);
    });

    test('my gyms hold 3 at most; lounge boards are for everyone', () async {
      final repo = MemoryCommunity.demo(me: 'me', meJoined: true);
      final c = CommunityState(repo);
      await c.refresh();
      expect(c.myGyms, hasLength(2));
      await c.join(const Gym(id: 'l-3', name: 'C'));
      expect(c.gymsFull, isTrue);
      await expectLater(
        c.join(const Gym(id: 'l-4', name: 'D')),
        throwsA(
          isA<CommunityException>().having(
            (e) => e.error,
            'error',
            CommunityError.gymLimit,
          ),
        ),
      );
      expect(c.myGyms, hasLength(3));
      // The server says no too, even when the app's list is behind.
      await expectLater(repo.join('l-4'), throwsA(isA<CommunityException>()));
      await c.leave('l-1');
      await c.join(const Gym(id: 'l-4', name: 'D'));
      expect([for (final g in c.myGyms) g.id], ['l-2', 'l-3', 'l-4']);
      // 라운지 boards aren't gyms: not in search, not joinable.
      expect(await repo.searchGyms('헬스'), isEmpty);
      await expectLater(repo.join('t-health'), throwsA(anything));
    });

    test('lounge: boards with counts, hot posts by likes', () async {
      final repo = MemoryCommunity.demo(me: 'me', meJoined: true);
      final boards = await repo.boards(['t-running', 't-nope', 'l-1']);
      expect([for (final g in boards) g.id], ['t-running', 'l-1']);
      expect(boards.first.isTopic, isTrue);
      expect(boards.first.postCount, 1);
      final hot = await repo.hot(topicIds);
      expect(hot.first.gymId, 't-running');
      expect(hot.first.likeCount, 5);
      expect(hot.every((p) => p.likeCount > 0), isTrue);
      final latest = await repo.feed(topicIds);
      expect(latest, hasLength(5));
      expect(latest.every((p) => isTopicId(p.gymId)), isTrue);
    });

    test('profile: nickname and photo change everywhere', () async {
      final repo = MemoryCommunity.demo(me: 'me', meJoined: true);
      final c = CommunityState(repo);
      await c.refresh();
      final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2]);
      await c.updateProfile(nickname: '풀업왕', photo: jpeg);
      expect(c.profile!.nickname, '풀업왕');
      expect(c.profile!.avatarUrl, startsWith('data:image/jpeg'));
      final mine = await repo.myPosts();
      expect(mine.single.nickname, '풀업왕');
      expect(mine.single.avatarUrl, isNotNull);
      await c.updateProfile(removePhoto: true);
      expect(c.profile!.avatarUrl, isNull);
      await expectLater(
        c.updateProfile(nickname: '하체는사랑'),
        throwsA(isA<CommunityException>()),
      );
    });

    test('my activity: my posts and comments with their posts', () async {
      final repo = MemoryCommunity.demo(me: 'me', meJoined: true);
      final posts = await repo.myPosts();
      expect(posts.single.body, contains('풀업'));
      final comments = await repo.myComments();
      expect(comments.single.postBody, contains('3분할'));
      expect(comments.single.gymName, '에이블짐 강남점');
      final post = await repo.post(comments.single.comment.postId);
      expect(post!.authorId, 'u4');
      expect(await repo.post('nope'), isNull);
    });

    test('lounge favorites: any number, favorites only on demand', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final c = CommunityState(MemoryCommunity(myId: 'me'));
      expect(c.loungeBoards, topicIds);
      c.setLoungeFavoritesOnly(true);
      expect(c.loungeBoards, topicIds); // none starred yet: all
      for (final id in ['t-yoga', 't-running', 't-free', 't-diet']) {
        c.toggleFavorite(id);
      }
      expect(c.loungeBoards, ['t-running', 't-yoga', 't-diet', 't-free']);
      c.toggleFavorite('t-free');
      expect(c.isFavorite('t-free'), isFalse);
      c.setLoungeFavoritesOnly(false);
      expect(c.loungeBoards, topicIds);
    });
  });
}
