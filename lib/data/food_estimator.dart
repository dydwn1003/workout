import 'food.dart';
import 'food_db.g.dart';

/// Offline text-to-nutrition estimator used until the AI server function
/// exists. Matches foods from the built-in table (plus custom foods) and
/// scales by quantity ("닭가슴살 200g", "계란 2개", "rice 1 bowl").
/// Results are always editable by the user.
class EstimatedItem {
  final String name;
  final Food? food;
  final double grams;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const EstimatedItem({
    required this.name,
    required this.food,
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  bool get matched => food != null;
}

class Estimate {
  final List<EstimatedItem> items;
  const Estimate(this.items);

  double get kcal => items.fold(0, (a, i) => a + i.kcal);
  double get proteinG => items.fold(0, (a, i) => a + i.proteinG);
  double get carbsG => items.fold(0, (a, i) => a + i.carbsG);
  double get fatG => items.fold(0, (a, i) => a + i.fatG);
  bool get hasUnmatched => items.any((i) => !i.matched);
}

final _gramRe = RegExp(r'(\d+(?:\.\d+)?)\s*(g|그램|ml|밀리)', caseSensitive: false);
final _countRe = RegExp(r'(\d+(?:\.\d+)?)\s*([가-힣a-z]*)', caseSensitive: false);
const _koreanNumbers = {'한': 1.0, '두': 2.0, '세': 3.0, '네': 4.0};

Food? _match(String lower, List<Food> foods) {
  Food? best;
  var len = 0;
  for (final f in foods) {
    for (final n in [f.name, ...f.aliases]) {
      final key = n.toLowerCase();
      if (key.length > len && lower.contains(key)) {
        best = f;
        len = key.length;
      }
    }
  }
  return best;
}

/// Picks the unit whose label mentions [word] (e.g. "공기", "개").
FoodUnit _unitFor(Food f, String word) {
  if (word.isNotEmpty) {
    for (final u in f.units) {
      if (u.label.contains(word)) return u;
    }
  }
  return f.units.first;
}

Estimate estimateFromText(String input, {List<Food> foods = builtInFoods}) {
  final chunks = input
      .split(RegExp(r'[,+\n/]|\band\b|그리고|랑|하고'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty);
  final items = <EstimatedItem>[];
  for (final chunk in chunks) {
    final lower = chunk.toLowerCase();
    final food = _match(lower, foods);
    if (food == null) {
      items.add(
        EstimatedItem(
          name: chunk,
          food: null,
          grams: 0,
          kcal: 0,
          proteinG: 0,
          carbsG: 0,
          fatG: 0,
        ),
      );
      continue;
    }
    double grams;
    final g = _gramRe.firstMatch(lower);
    if (g != null) {
      grams = double.parse(g.group(1)!);
    } else {
      final c = _countRe.firstMatch(lower);
      if (c != null) {
        grams =
            _unitFor(food, c.group(2) ?? '').grams * double.parse(c.group(1)!);
      } else {
        var n = 1.0;
        var word = '';
        if (lower.contains('반')) n = 0.5;
        for (final e in _koreanNumbers.entries) {
          final m = RegExp('${e.key}\\s*([가-힣]+)').firstMatch(lower);
          if (m != null &&
              food.units.any((u) => u.label.contains(m.group(1)!))) {
            n = e.value;
            word = m.group(1)!;
          }
        }
        grams = _unitFor(food, word).grams * n;
      }
    }
    final nut = food.forGrams(grams);
    items.add(
      EstimatedItem(
        name: chunk,
        food: food,
        grams: grams,
        kcal: nut.kcal,
        proteinG: nut.proteinG,
        carbsG: nut.carbsG,
        fatG: nut.fatG,
      ),
    );
  }
  return Estimate(items);
}
