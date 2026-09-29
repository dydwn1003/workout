import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Commit the web build was made from (--dart-define=BUILD_ID, set by
/// .github/workflows/pages.yml, which also publishes it as build.txt).
const buildId = String.fromEnvironment('BUILD_ID');

/// Where the latest app version is published (app_version.json next to
/// the web app, written by the Pages workflow from pubspec.yaml).
const _latestUrl = String.fromEnvironment(
  'APP_VERSION_URL',
  defaultValue: 'https://dydwn1003.github.io/workout/app_version.json',
);

/// Store pages the apps send people to for updates.
const androidStoreUrl =
    'https://play.google.com/store/apps/details?id=com.adapt.adapt_coach';
const _iosAppId = String.fromEnvironment('IOS_APP_ID');
const iosStoreUrl = _iosAppId == ''
    ? ''
    : 'https://apps.apple.com/app/id$_iosAppId';

enum UpdateAction {
  /// Web: a newer build is deployed; reloading picks it up.
  reload,

  /// Apps: a newer version is out; update it from the store.
  store,
}

/// A newer version than the one running, with the id of that version.
typedef AvailableUpdate = ({UpdateAction action, String latest});

/// Checks for a newer build (web) or app version (Android/iOS). Null when
/// up to date, offline or not configured.
Future<AvailableUpdate?> checkForUpdate() async {
  try {
    if (kIsWeb) {
      if (buildId.isEmpty) return null;
      final res = await http
          .get(Uri.base.resolve('build.txt?t=${_now()}'))
          .timeout(const Duration(seconds: 10));
      final latest = res.body.trim();
      if (res.statusCode != 200 || latest.isEmpty || latest == buildId) {
        return null;
      }
      return (action: UpdateAction.reload, latest: latest);
    }
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    if (ios && iosStoreUrl.isEmpty) return null;
    final res = await http
        .get(Uri.parse('$_latestUrl?t=${_now()}'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final latest = (jsonDecode(res.body) as Map)['version'] as String?;
    final current = (await PackageInfo.fromPlatform()).version;
    if (latest == null || !isNewerVersion(latest, current)) return null;
    return (action: UpdateAction.store, latest: latest);
  } catch (_) {
    return null; // try again next time
  }
}

int _now() => DateTime.now().millisecondsSinceEpoch;

/// "1.2.10" > "1.2.9"; build suffixes (+3) are ignored.
bool isNewerVersion(String latest, String current) {
  List<int> parts(String v) => [
    for (final p in v.split('+').first.split('.')) int.tryParse(p) ?? 0,
  ];
  final a = parts(latest), b = parts(current);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}
