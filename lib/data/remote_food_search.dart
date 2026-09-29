import 'dart:convert';

import 'package:http/http.dart' as http;

import 'food.dart';

/// Server food search: the full ~307k-food table on Supabase
/// (supabase/schema.sql, search_foods()). Read-only with the public anon
/// key; configured at build time:
///
/// ```sh
/// flutter build web --dart-define=SUPABASE_URL=https://<project>.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=<anon or sb_publishable_ key>
/// ```
class RemoteFoodSearch {
  final String url;
  final String anonKey;
  final http.Client _client;
  final _cache = <String, List<Food>>{};

  RemoteFoodSearch({
    required this.url,
    required this.anonKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// From the --dart-define values, or null when they are not set.
  static RemoteFoodSearch? fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isEmpty || key.isEmpty) return null;
    return RemoteFoodSearch(url: url, anonKey: key);
  }

  /// Ranked like the app's local search. Throws on network/server errors.
  Future<List<Food>> search(String query, {int limit = 40}) async {
    final q = normalizeQuery(query);
    if (q.isEmpty) return const [];
    final hit = _cache[q];
    if (hit != null) return hit;
    var res = await _call('search_foods_v2', query, limit);
    // Before supabase/food_nutrients.sql is run there's only search_foods().
    if (res.statusCode == 404) res = await _call('search_foods', query, limit);
    if (res.statusCode != 200) {
      throw Exception('search_foods: HTTP ${res.statusCode}');
    }
    final rows = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    final foods = [
      for (final r in rows) Food.fromJson((r as Map).cast<String, Object?>()),
    ];
    if (_cache.length > 100) _cache.clear();
    return _cache[q] = foods;
  }

  Future<http.Response> _call(String fn, String query, int limit) => _client
      .post(
        Uri.parse('${url.replaceAll(RegExp(r'/+$'), '')}/rest/v1/rpc/$fn'),
        headers: {
          'apikey': anonKey,
          // Legacy JWT keys also go in Authorization; sb_ keys must not.
          if (!anonKey.startsWith('sb_')) 'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'q': query, 'lim': limit}),
      )
      .timeout(const Duration(seconds: 15));
}
