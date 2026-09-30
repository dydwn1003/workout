import 'dart:async';

import 'package:flutter/widgets.dart';

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

  bool get signedIn => repo.myId != null;
  bool isMine(String gymId) => myGyms.any((g) => g.id == gymId);

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

  Future<void> join(Gym gym) async {
    if (isMine(gym.id)) return;
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
