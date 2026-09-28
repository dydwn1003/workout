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

  /// Macros the source does not publish: any of 'p', 'c', 'f' (e.g. many
  /// franchise menus list only kcal and protein). Their values are estimates
  /// from similar foods (tool/gen_foods.py estimate()), shown as such.
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
  });

  bool get hasEstimatedMacros => unknown.isNotEmpty;

  /// Units shown to the user: the food's own units plus grams.
  List<FoodUnit> get allUnits =>
      custom ? units : [...units, const FoodUnit('g', 1)];

  Nutrition forGrams(double grams) => Nutrition(
    kcal: kcal * grams / 100,
    proteinG: proteinG * grams / 100,
    carbsG: carbsG * grams / 100,
    fatG: fatG * grams / 100,
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
  const Nutrition({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

String normalizeQuery(String s) => s.toLowerCase().replaceAll(' ', '');

/// Ranked search: exact > prefix > contains, over names and aliases.
List<Food> searchFoods(List<Food> foods, String query, {int limit = 40}) {
  final q = normalizeQuery(query);
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
