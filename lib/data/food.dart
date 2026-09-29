/// A food with nutrition per 100 g and its common serving units.
class Food {
  final String id;
  final String name;
  final List<String> aliases;
  final String category;
  final double kcal; // per 100 g
  final double proteinG;
  final double carbsG;
  final double fatG;
  final List<FoodUnit> units;

  /// True for user-created foods. Their units may not have real gram
  /// weights, so no gram unit is offered for them.
  final bool custom;

  /// Values the source does not publish: any of 'p', 'c', 'f' (e.g. many
  /// franchise menus list only kcal and protein) and 'k' (menus missing from
  /// the MFDS data altogether, where kcal is estimated too). They hold
  /// estimates from similar foods (tool/gen_foods.py, tool/gen_franchise.py)
  /// and are shown as such.
  final String unknown;

  const Food(
    this.id,
    this.name,
    this.aliases,
    this.category,
    this.kcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.units, {
    this.custom = false,
    this.unknown = '',
    this.sugarG,
    this.satFatG,
  });

  bool get hasEstimatedMacros => unknown.isNotEmpty;
  bool get kcalEstimated => unknown.contains('k');

  /// 당류 per 100 g; null when the source doesn't have it.
  final double? sugarG;

  /// 포화지방 per 100 g; null when the source doesn't have it.
  final double? satFatG;

  /// Same shape as a row of the server's public.foods table
  /// (supabase/schema.sql), so server results and cached ones share a parser.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'aliases': aliases,
    'category': category,
    'kcal': kcal,
    'protein': proteinG,
    'carbs': carbsG,
    'fat': fatG,
    'units': [
      for (final u in units) {'label': u.label, 'g': u.grams},
    ],
    'unknown': unknown,
    if (sugarG != null) 'sugar': sugarG,
    if (satFatG != null) 'sat_fat': satFatG,
  };

  factory Food.fromJson(Map<String, Object?> j) {
    double n(Object? v) => (v as num?)?.toDouble() ?? 0;
    return Food(
      j['id'] as String,
      j['name'] as String,
      [for (final a in (j['aliases'] as List? ?? const [])) a as String],
      j['category'] as String? ?? '',
      n(j['kcal']),
      n(j['protein']),
      n(j['carbs']),
      n(j['fat']),
      [
        for (final u in (j['units'] as List? ?? const []))
          FoodUnit((u as Map)['label'] as String, (u['g'] as num).toDouble()),
      ],
      unknown: j['unknown'] as String? ?? '',
      sugarG: (j['sugar'] as num?)?.toDouble(),
      satFatG: (j['sat_fat'] as num?)?.toDouble(),
    );
  }

  /// Units shown to the user: the food's own units plus grams.
  List<FoodUnit> get allUnits =>
      custom ? units : [...units, const FoodUnit('g', 1)];

  Nutrition forGrams(double grams) => Nutrition(
    kcal: kcal * grams / 100,
    proteinG: proteinG * grams / 100,
    carbsG: carbsG * grams / 100,
    fatG: fatG * grams / 100,
    sugarG: sugarG == null ? null : sugarG! * grams / 100,
    satFatG: satFatG == null ? null : satFatG! * grams / 100,
  );

  Nutrition forPortion(FoodUnit unit, double qty) => forGrams(unit.grams * qty);

  /// Custom foods are stored per serving; this builds the per-100 g model
  /// with a single unit weighing [grams] (100 when unknown).
  factory Food.customPerServing({
    required String id,
    required String name,
    required String unitLabel,
    double? grams,
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) {
    final g = grams ?? 100;
    final k = 100 / g;
    return Food(
      id,
      name,
      const [],
      customCategory,
      kcal * k,
      proteinG * k,
      carbsG * k,
      fatG * k,
      [FoodUnit(unitLabel, g)],
      custom: true,
    );
  }

  static const customCategory = '내 음식';
}

class FoodUnit {
  final String label;
  final double grams;
  const FoodUnit(this.label, this.grams);

  bool get isGram => label == 'g';
}

class Nutrition {
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? sugarG;
  final double? satFatG;
  const Nutrition({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.sugarG,
    this.satFatG,
  });
}

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

String normalizeQuery(String s) => s.toLowerCase().replaceAll(' ', '');

/// Drops Korean letters still being typed at the end ("소고기ㄱ", "밥ㅓ"):
/// lone consonants and vowels never match a food name.
String stripComposing(String s) =>
    s.replaceAll(RegExp(r'[\u3131-\u318E]+$'), '').trimRight();

/// Ranked search: exact > prefix > contains, over names and aliases.
List<Food> searchFoods(
  List<Food> foods,
  String query, {
  int limit = 40,
  bool retry = true,
}) {
  final q = normalizeQuery(stripComposing(query));
  if (q.isEmpty) return const [];
  final scored = <(int, int, Food)>[];
  for (var i = 0; i < foods.length; i++) {
    final f = foods[i];
    var best = -1;
    for (final raw in [f.name, ...f.aliases]) {
      final n = normalizeQuery(raw);
      final score = n == q
          ? 3
          : n.startsWith(q)
          ? 2
          : n.contains(q)
          ? 1
          : -1;
      if (score > best) best = score;
    }
    if (best >= 0) scored.add((best, i, f));
  }
  // Words in another order or run together ("교촌허니콤보" for "닭튀김
  // 허니콤보 치킨 (교촌치킨)", "맘스터치싸이버거" for "싸이버거 (맘스터치)"):
  // when few foods contain the whole query, also take foods containing
  // both halves of it, for some split into two parts of 2+ letters.
  if (scored.length < 5 && q.length >= 4) {
    final found = {for (final s in scored) s.$2};
    for (var i = 0; i < foods.length; i++) {
      if (found.contains(i)) continue;
      final f = foods[i];
      final all = [f.name, ...f.aliases].map(normalizeQuery).join('|');
      for (var cut = 2; cut <= q.length - 2; cut++) {
        if (all.contains(q.substring(0, cut)) &&
            all.contains(q.substring(cut))) {
          scored.add((0, i, f));
          break;
        }
      }
    }
  }
  // Nothing at all: the last syllable may still be mid-composition
  // ("소고깆" while typing 소고기), so try once without it.
  if (scored.isEmpty && retry && q.length >= 3) {
    return searchFoods(
      foods,
      q.substring(0, q.length - 1),
      limit: limit,
      retry: false,
    );
  }
  scored.sort((a, b) {
    final s = b.$1.compareTo(a.$1);
    if (s != 0) return s;
    final l = a.$3.name.length.compareTo(b.$3.name.length);
    return l != 0 ? l : a.$2.compareTo(b.$2);
  });
  return [for (final s in scored.take(limit)) s.$3];
}

/// Categories in the order they first appear.
List<String> categoriesOf(List<Food> foods) {
  final seen = <String>{};
  return [
    for (final f in foods)
      if (seen.add(f.category)) f.category,
  ];
}
