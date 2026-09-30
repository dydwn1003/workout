import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/community.dart';

/// Who I am in the community (nickname) and my gyms. Boards and posts are
/// loaded by their screens.
class CommunityState extends ChangeNotifier {
  final CommunityRepository repo;
  CommunityState(this.repo);

  CommunityProfile? profile;
  List<Gym> myGyms = const [];
  bool loading = false;
  bool failed = false;
  String? _loadedFor;
  var _loadedOnce = false;

  /// A board to open from an invite link (?gym=...), taken by the
  /// community tab.
  String? pendingBoard;

  /// 운동 라운지 boards I starred (on this device, as many as I like),
  /// and whether the lounge shows only those.
  Set<String> favoriteTopics = {};
  bool loungeFavoritesOnly = false;

  static const _favKey = 'community.favoriteTopics';
  static const _favOnlyKey = 'community.loungeFavoritesOnly';

  Future<void> loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      favoriteTopics = {...?prefs.getStringList(_favKey)};
      loungeFavoritesOnly = prefs.getBool(_favOnlyKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('community prefs failed: $e');
    }
  }

  Future<void> _saveLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favKey, favoriteTopics.toList());
      await prefs.setBool(_favOnlyKey, loungeFavoritesOnly);
    } catch (e) {
      debugPrint('community prefs failed: $e');
    }
  }

  bool isFavorite(String id) => favoriteTopics.contains(id);

  void toggleFavorite(String id) {
    favoriteTopics = {...favoriteTopics};
    if (!favoriteTopics.remove(id)) favoriteTopics.add(id);
    notifyListeners();
    _saveLocal();
  }

  void setLoungeFavoritesOnly(bool v) {
    loungeFavoritesOnly = v;
    notifyListeners();
    _saveLocal();
  }

  /// The lounge boards to show: my favorites (in lounge order) when
  /// asked and there are any, else all of them.
  List<String> get loungeBoards =>
      loungeFavoritesOnly && favoriteTopics.isNotEmpty
      ? [
          for (final id in topicIds)
            if (favoriteTopics.contains(id)) id,
        ]
      : topicIds;

  bool get signedIn => repo.myId != null;
  bool isMine(String gymId) => myGyms.any((g) => g.id == gymId);

  /// 내 헬스장 holds [CommunityLimits.myGyms] gyms at most.
  bool get gymsFull => myGyms.length >= CommunityLimits.myGyms;

  /// Loads the profile and my gyms, again when the signed-in user changed.
  Future<void> refresh({bool force = false}) async {
    final me = repo.myId;
    if (!force && _loadedOnce && me == _loadedFor) return;
    _loadedFor = me;
    _loadedOnce = true;
    if (me == null) {
      profile = null;
      myGyms = const [];
      notifyListeners();
      return;
    }
    loading = true;
    failed = false;
    notifyListeners();
    try {
      final r = await Future.wait([repo.myProfile(), repo.myGyms()]);
      if (repo.myId != me) return; // signed out meanwhile
      profile = r[0] as CommunityProfile?;
      myGyms = r[1] as List<Gym>;
    } catch (e) {
      debugPrint('community load failed: $e');
      failed = true;
      _loadedOnce = false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createProfile(String nickname) async {
    profile = await repo.createProfile(nickname);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? nickname,
    Uint8List? photo,
    bool removePhoto = false,
  }) async {
    profile = await repo.updateProfile(
      nickname: nickname,
      photo: photo,
      removePhoto: removePhoto,
    );
    notifyListeners();
  }

  Future<void> join(Gym gym) async {
    if (isMine(gym.id)) return;
    if (gymsFull) throw const CommunityException(CommunityError.gymLimit);
    myGyms = [...myGyms, gym.copyWith(memberCount: gym.memberCount + 1)];
    notifyListeners();
    try {
      await repo.join(gym.id);
    } catch (_) {
      myGyms = [
        for (final g in myGyms)
          if (g.id != gym.id) g,
      ];
      notifyListeners();
      rethrow;
    }
  }

  Future<void> leave(String gymId) async {
    final before = myGyms;
    myGyms = [
      for (final g in myGyms)
        if (g.id != gymId) g,
    ];
    notifyListeners();
    try {
      await repo.leave(gymId);
    } catch (_) {
      myGyms = before;
      notifyListeners();
      rethrow;
    }
  }

  /// A post was written: my gym's counts move along.
  void postedIn(String gymId) {
    myGyms = [
      for (final g in myGyms)
        g.id == gymId
            ? g.copyWith(postCount: g.postCount + 1, lastPostAt: DateTime.now())
            : g,
    ];
    notifyListeners();
  }
}

class CommunityScope extends InheritedNotifier<CommunityState> {
  const CommunityScope({
    super.key,
    required CommunityState state,
    required super.child,
  }) : super(notifier: state);

  static CommunityState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CommunityScope>()!.notifier!;

  static CommunityState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CommunityScope>()!.notifier!;

  static CommunityState? maybeRead(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CommunityScope>()?.notifier;
}
