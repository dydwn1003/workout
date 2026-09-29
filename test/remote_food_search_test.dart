import 'dart:convert';

import 'package:adapt_coach/data/food.dart';
import 'package:adapt_coach/data/food_db.g.dart';
import 'package:adapt_coach/data/remote_food_search.dart';
import 'package:adapt_coach/data/repository.dart';
import 'package:adapt_coach/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final now = DateTime(2026, 9, 29, 12);
  final ramen = {
    'id': 'm0123456789ab',
    'name': '신라면 ((주)농심)',
    'aliases': ['라면'],
    'category': '즉석식품',
    'kcal': 417,
    'protein': 8.6,
    'carbs': 63.8,
    'fat': 14.1,
    'units': [
      {'label': '1회 제공량', 'g': 120},
    ],
    'unknown': '',
    'source': 'mfds_process',
    'search': '신라면((주)농심)|라면',
  };

  RemoteFoodSearch remote(List<Map<String, Object?>> rows, {int status = 200}) {
    var calls = 0;
    return RemoteFoodSearch(
      url: 'https://example.supabase.co/',
      anonKey: 'sb_publishable_test',
      client: MockClient((req) async {
        calls++;
        expect(req.url.path, '/rest/v1/rpc/search_foods');
        expect(req.headers['apikey'], 'sb_publishable_test');
        expect(req.headers.containsKey('Authorization'), isFalse);
        expect(jsonDecode(req.body)['q'], isNotEmpty);
        expect(calls, 1, reason: 'repeat queries come from the cache');
        return http.Response(
          jsonEncode(rows),
          status,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
  }

  test('parses server rows and caches by query', () async {
    final r = remote([ramen]);
    final foods = await r.search('신라면');
    expect(foods.single.name, '신라면 ((주)농심)');
    expect(foods.single.kcal, 417);
    expect(foods.single.units.single.grams, 120);
    expect(await r.search(' 신라면 '), same(foods));
  });

  test('server errors throw so the UI can fall back', () async {
    expect(remote(const [], status: 500).search('x'), throwsException);
  });

  test('remote results skip local ones; logged ones are remembered', () async {
    final local = builtInFoods.first;
    final s = AppState(
      MemoryCoachRepository(),
      clock: () => now,
      remoteSearch: remote([local.toJson(), ramen]),
    );
    await s.load();
    final extra = await s.searchRemoteFoods('q', [local]);
    expect(extra.map((f) => f.name), ['신라면 ((주)농심)']);

    expect(s.foodById(extra.single.id), isNull);
    await s.rememberFood(extra.single);
    expect(s.foodById(extra.single.id)!.kcal, 417);
    // Built-in foods are never copied.
    await s.rememberFood(local);
    final reloaded = AppState(s.repo, clock: () => now);
    await reloaded.load();
    expect(reloaded.foodById(extra.single.id)!.name, '신라면 ((주)농심)');
  });

  test('Food json round-trips', () {
    final f = builtInFoods.firstWhere((f) => f.unknown.isNotEmpty);
    final back = Food.fromJson(f.toJson());
    expect(back.name, f.name);
    expect(back.unknown, f.unknown);
    expect(back.units.length, f.units.length);
  });
}
