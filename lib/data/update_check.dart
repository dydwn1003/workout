import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Commit the web build was made from (--dart-define=BUILD_ID, set by
/// .github/workflows/pages.yml, which also publishes it as build.txt).
const buildId = String.fromEnvironment('BUILD_ID');

/// Whether a newer web build has been published than the one running.
/// Browsers keep GitHub Pages files cached for a while, so an open tab or a
/// home-screen app can run an old build until it reloads.
Future<bool> newBuildAvailable() async {
  if (!kIsWeb || buildId.isEmpty) return false;
  try {
    final url = Uri.base.resolve(
      'build.txt?t=${DateTime.now().millisecondsSinceEpoch}',
    );
    final res = await http.get(url).timeout(const Duration(seconds: 10));
    final latest = res.body.trim();
    return res.statusCode == 200 && latest.isNotEmpty && latest != buildId;
  } catch (_) {
    return false; // offline: try again next time
  }
}
