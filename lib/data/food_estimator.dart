/// Offline text-to-nutrition estimator used until the AI server function
/// exists. It matches common foods from a small built-in table and scales by
/// quantity ("닭가슴살 200g", "계란 2개", "rice 1 bowl"). Results are always
/// editable by the user.
class FoodItem {
  final List<String> names;
  final double servingG;
  final double kcal;
  final double p;
  final double c;
  final double f;

  const FoodItem(this.names, this.servingG, this.kcal, this.p, this.c, this.f);
}

class EstimatedItem {
  final String name;
  final double servings;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final bool matched;

  const EstimatedItem({
    required this.name,
    required this.servings,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.matched,
  });
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

// Per typical serving: grams, kcal, protein, carbs, fat.
// Approximate reference values; users are expected to adjust.
const foodTable = <FoodItem>[
  FoodItem(['현미밥', 'brown rice'], 210, 300, 6.5, 63, 2.3),
  FoodItem(['잡곡밥', 'multigrain rice'], 210, 305, 7, 64, 1.8),
  FoodItem(
    ['흰쌀밥', '쌀밥', '공기밥', '밥', 'white rice', 'rice'],
    210,
    310,
    5.5,
    68,
    0.6,
  ),
  FoodItem(['닭가슴살', 'chicken breast'], 100, 165, 31, 0, 3.6),
  FoodItem(
    ['삶은계란', '삶은 계란', '계란', '달걀', 'boiled egg', 'eggs', 'egg'],
    50,
    72,
    6.3,
    0.4,
    4.8,
  ),
  FoodItem(['바나나', 'banana'], 120, 105, 1.3, 27, 0.4),
  FoodItem(['사과', 'apple'], 200, 104, 0.5, 28, 0.3),
  FoodItem(['고구마', 'sweet potato'], 150, 129, 2.4, 30, 0.2),
  FoodItem(['오트밀', 'oatmeal', 'oats'], 40, 150, 5, 27, 3),
  FoodItem(['그릭요거트', '그릭 요거트', 'greek yogurt'], 150, 120, 15, 6, 4),
  FoodItem(['우유', 'milk'], 200, 130, 6.4, 9.6, 7.6),
  FoodItem(
    ['프로틴', '단백질 쉐이크', '프로틴쉐이크', 'protein shake', 'whey'],
    30,
    120,
    24,
    3,
    1.5,
  ),
  FoodItem(['김치찌개', 'kimchi stew'], 400, 250, 16, 10, 16),
  FoodItem(['된장찌개', 'soybean paste stew'], 400, 180, 12, 12, 9),
  FoodItem(['라면', 'ramen', 'ramyeon'], 120, 500, 10, 79, 16),
  FoodItem(['김밥', 'gimbap', 'kimbap'], 230, 450, 13, 70, 12),
  FoodItem(['비빔밥', 'bibimbap'], 500, 560, 20, 85, 15),
  FoodItem(['삼겹살', 'pork belly'], 100, 360, 18, 0, 31),
  FoodItem(['제육볶음', 'spicy pork'], 250, 450, 25, 15, 32),
  FoodItem(['돈까스', '돈가스', 'tonkatsu', 'pork cutlet'], 250, 700, 30, 55, 40),
  FoodItem(['소고기', 'beef', 'steak', '스테이크'], 100, 250, 26, 0, 16),
  FoodItem(['연어', 'salmon'], 100, 208, 20, 0, 13),
  FoodItem(['참치', 'tuna'], 100, 120, 25, 0, 2),
  FoodItem(['두부', 'tofu'], 150, 120, 13, 3, 7),
  FoodItem(['샐러드', 'salad'], 150, 80, 3, 10, 3),
  FoodItem(['아메리카노', 'americano', 'black coffee'], 350, 10, 0.5, 1.5, 0),
  FoodItem(['라떼', 'latte'], 350, 190, 10, 15, 10),
  FoodItem(['치킨', 'fried chicken'], 100, 290, 18, 10, 20),
  FoodItem(['피자', 'pizza'], 110, 280, 12, 33, 11),
  FoodItem(['햄버거', '버거', 'burger', 'hamburger'], 220, 520, 26, 45, 26),
  FoodItem(['떡볶이', 'tteokbokki'], 300, 480, 10, 100, 5),
  FoodItem(['짜장면', 'jjajangmyeon'], 650, 700, 20, 110, 20),
  FoodItem(['아몬드', 'almonds', 'almond'], 30, 174, 6, 6, 15),
  FoodItem(['식빵', '빵', 'bread', 'toast', '토스트'], 40, 105, 3.5, 20, 1.3),
  FoodItem(['닭갈비', 'dakgalbi'], 300, 480, 35, 25, 25),
  FoodItem(['불고기', 'bulgogi'], 200, 380, 28, 18, 20),
  FoodItem(['갈비탕', 'galbitang'], 600, 450, 35, 15, 25),
  FoodItem(['순두부찌개', 'soft tofu stew'], 450, 270, 18, 12, 16),
  FoodItem(['부대찌개', 'budae jjigae'], 500, 550, 25, 40, 30),
  FoodItem(['냉면', 'naengmyeon', 'cold noodles'], 600, 550, 18, 100, 6),
  FoodItem(['칼국수', 'kalguksu'], 600, 550, 18, 95, 9),
  FoodItem(['우동', 'udon'], 600, 450, 14, 85, 5),
  FoodItem(['짬뽕', 'jjamppong'], 700, 650, 28, 95, 18),
  FoodItem(['볶음밥', 'fried rice'], 350, 600, 15, 85, 20),
  FoodItem(['카레', 'curry'], 400, 550, 15, 85, 16),
  FoodItem(['오므라이스', 'omurice'], 400, 650, 20, 90, 22),
  FoodItem(['덮밥', 'rice bowl', 'donburi'], 450, 650, 28, 90, 18),
  FoodItem(['포케', 'poke'], 400, 520, 30, 60, 16),
  FoodItem(['샌드위치', 'sandwich'], 200, 400, 20, 40, 16),
  FoodItem(['베이글', 'bagel'], 100, 270, 10, 53, 1.5),
  FoodItem(['크림치즈', 'cream cheese'], 20, 70, 1.2, 1, 7),
  FoodItem(['파스타', 'pasta', 'spaghetti', '스파게티'], 350, 600, 20, 85, 18),
  FoodItem(['만두', 'dumplings', 'mandu'], 30, 60, 3, 7, 2.5),
  FoodItem(['순대', 'sundae'], 150, 280, 12, 35, 9),
  FoodItem(['어묵', 'fish cake', 'eomuk'], 100, 150, 10, 15, 5),
  FoodItem(['족발', 'jokbal'], 150, 380, 35, 2, 25),
  FoodItem(['보쌈', 'bossam'], 200, 500, 35, 5, 38),
  FoodItem(['회', 'sashimi'], 150, 180, 32, 0, 5),
  FoodItem(['초밥', 'sushi'], 30, 50, 2.5, 8, 0.8),
  FoodItem(['새우', 'shrimp'], 100, 100, 21, 0, 1.5),
  FoodItem(['고등어', 'mackerel'], 100, 260, 20, 0, 20),
  FoodItem(['돼지고기', 'pork loin', 'pork'], 100, 200, 25, 0, 11),
  FoodItem(['오리고기', 'duck'], 100, 300, 18, 0, 25),
  FoodItem(['감자', 'potato'], 150, 115, 3, 26, 0.2),
  FoodItem(['단호박', 'kabocha', 'pumpkin'], 150, 90, 2.5, 20, 0.3),
  FoodItem(['옥수수', 'corn'], 150, 140, 5, 30, 2),
  FoodItem(['브로콜리', 'broccoli'], 100, 34, 2.8, 7, 0.4),
  FoodItem(['방울토마토', '토마토', 'tomato', 'cherry tomato'], 150, 27, 1.3, 6, 0.3),
  FoodItem(['블루베리', 'blueberries', 'blueberry'], 100, 57, 0.7, 14, 0.3),
  FoodItem(['딸기', 'strawberries', 'strawberry'], 150, 48, 1, 12, 0.5),
  FoodItem(['귤', 'mandarin', 'tangerine'], 90, 40, 0.6, 10, 0.2),
  FoodItem(['아보카도', 'avocado'], 100, 160, 2, 9, 15),
  FoodItem(['땅콩버터', 'peanut butter'], 16, 95, 4, 3, 8),
  FoodItem(['치즈', 'cheese'], 20, 70, 4.5, 0.5, 5.5),
  FoodItem(['두유', 'soy milk'], 190, 100, 7, 7, 5),
  FoodItem(['요거트', 'yogurt'], 100, 80, 3.5, 12, 2.5),
  FoodItem(['단백질바', '프로틴바', 'protein bar'], 50, 200, 20, 20, 7),
  FoodItem(['견과류', 'mixed nuts', 'nuts'], 25, 150, 5, 5, 13),
  FoodItem(['과자', 'chips', 'snack'], 60, 320, 4, 35, 18),
  FoodItem(['아이스크림', 'ice cream'], 100, 210, 3.5, 25, 11),
  FoodItem(['초콜릿', 'chocolate'], 30, 160, 2, 17, 9),
  FoodItem(['떡', 'rice cake', 'tteok'], 100, 230, 4, 50, 0.5),
  FoodItem(['맥주', 'beer'], 500, 215, 2, 18, 0),
  FoodItem(['소주', 'soju'], 360, 400, 0, 0, 0),
  FoodItem(['콜라', 'cola', 'coke'], 355, 150, 0, 39, 0),
  FoodItem(['오렌지주스', 'orange juice'], 250, 110, 1.7, 26, 0.5),
];

final _gramRe = RegExp(r'(\d+(?:\.\d+)?)\s*(g|그램|ml|밀리)', caseSensitive: false);
final _countRe = RegExp(
  r'(\d+(?:\.\d+)?)\s*(개|공기|인분|조각|줄|잔|장|컵|스쿱|알|x|pcs|pieces?|bowls?|cups?|slices?|scoops?|servings?)?',
  caseSensitive: false,
);

double _koreanCount(String s) {
  if (s.contains('반')) return 0.5;
  const words = {'한': 1.0, '두': 2.0, '세': 3.0, '네': 4.0};
  for (final e in words.entries) {
    if (RegExp('${e.key}\\s*(개|공기|인분|조각|줄|잔|장|컵|스쿱|알)').hasMatch(s)) {
      return e.value;
    }
  }
  return 1;
}

Estimate estimateFromText(String input) {
  final chunks = input
      .split(RegExp(r'[,+\n/]|\band\b|그리고|랑|하고'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty);
  final items = <EstimatedItem>[];
  for (final chunk in chunks) {
    final lower = chunk.toLowerCase();
    FoodItem? match;
    var matchLen = 0;
    for (final f in foodTable) {
      for (final n in f.names) {
        if (lower.contains(n) && n.length > matchLen) {
          match = f;
          matchLen = n.length;
        }
      }
    }
    if (match == null) {
      items.add(
        EstimatedItem(
          name: chunk,
          servings: 1,
          kcal: 0,
          proteinG: 0,
          carbsG: 0,
          fatG: 0,
          matched: false,
        ),
      );
      continue;
    }
    double servings;
    final g = _gramRe.firstMatch(lower);
    if (g != null) {
      servings = double.parse(g.group(1)!) / match.servingG;
    } else {
      final cm = _countRe.firstMatch(lower);
      servings = cm != null ? double.parse(cm.group(1)!) : _koreanCount(lower);
    }
    items.add(
      EstimatedItem(
        name: chunk,
        servings: servings,
        kcal: match.kcal * servings,
        proteinG: match.p * servings,
        carbsG: match.c * servings,
        fatG: match.f * servings,
        matched: true,
      ),
    );
  }
  return Estimate(items);
}
