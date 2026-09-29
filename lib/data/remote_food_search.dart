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

  /// Per 100 g (kcal, 당류, 포화지방) of the given server food ids; ids the
  /// server doesn't know are left out.
  Future<Map<String, ({double kcal, double? sugarG, double? satFatG})>>
  nutrientsOf(List<String> ids) async {
    final out = <String, ({double kcal, double? sugarG, double? satFatG})>{};
    for (var i = 0; i < ids.length; i += 50) {
      final list = ids.skip(i).take(50).map((id) => '"$id"').join(',');
      final foods = await _get('foods?select=id,kcal&id=in.($list)');
      final nutrients = {
        for (final n in await _get(
          'food_nutrients?select=id,sugar,sat_fat&id=in.($list)',
        ))
          n['id'] as String: n,
      };
      for (final f in foods) {
        final n = nutrients[f['id']];
        out[f['id'] as String] = (
          kcal: (f['kcal'] as num).toDouble(),
          sugarG: (n?['sugar'] as num?)?.toDouble(),
          satFatG: (n?['sat_fat'] as num?)?.toDouble(),
        );
      }
    }
    return out;
  }

  Future<List<Map<String, Object?>>> _get(String path) async {
    final res = await _client
        .get(
          Uri.parse('${url.replaceAll(RegExp(r'/+$'), '')}/rest/v1/$path'),
          headers: {
            'apikey': anonKey,
            if (!anonKey.startsWith('sb_')) 'Authorization': 'Bearer $anonKey',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('$path: HTTP ${res.statusCode}');
    return [
      for (final r in jsonDecode(utf8.decode(res.bodyBytes)) as List)
        (r as Map).cast<String, Object?>(),
    ];
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
