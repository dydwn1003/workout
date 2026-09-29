"""Estimates nutrition for well-known franchise menus the MFDS database does
not cover (e.g. bhc, 네네치킨, 서브웨이, 설빙, 한솥도시락, 엽기떡볶이).

Nothing is published for these, so every value is an estimate: per 100 g,
kcal is the median of similar published foods and protein/carbs/fat split
it by their median energy shares (same method as gen_foods.estimate()).
"Similar" is a reference type from TYPES below: a 대표식품명 group of the
MFDS 음식 data, optionally narrowed by a name pattern. A menu can narrow
further with "type:pattern" (e.g. "bingsu:인절미"); when fewer than
MIN_POOL foods match, the pattern is dropped, then the type's fallback is
used. Serving weights are typical estimates too.

Input:  data/franchise_menus.txt   (curated brand/menu list, see its header)
        data/mfds_api_food.csv, data/mfds_api_process.csv
        (downloads from tool/fetch_mfds_api.py)
Output: data/foods_franchise.tsv   (read by gen_foods.py and load_supabase.py;
        unknown = "kpcf": kcal and all macros estimated; 당류 and 포화지방
        are medians of the same reference foods)

Run: python3 tool/gen_franchise.py && python3 tool/gen_foods.py
"""
import os
import re
import statistics
import sys

sys.path.insert(0, os.path.dirname(__file__))
import gen_foods  # noqa: E402
import load_supabase  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
MENUS = os.path.join(ROOT, "data", "franchise_menus.txt")
OUT = os.path.join(ROOT, "data", "foods_franchise.tsv")
MIN_POOL = 3

CHICKEN = r"^(닭튀김|닭다리튀김)$"
# Packaged products named like a dish but not the dish itself.
NOT_A_DISH = r"소스|양념장|분말|믹스|시즈닝|파우더|엑기스|농축|베이스|키트|밀키트|튀김가루"

UNITS = {
    "chicken": [("1조각", 70), ("1마리", 1000)],
    "boneless": [("1조각", 30), ("1마리", 700)],
    "roast": [("1조각", 70), ("1마리", 800)],
    "wings": [("1개", 40)],
    "cup": [("1컵", 300)],
    "nugget": [("1조각", 20)],
    "ball": [("1개", 25)],
    "fries": [("1회 제공량", 120)],
    "stick": [("1개", 30)],
    "side": [("1컵", 100)],
    "biscuit": [("1개", 60)],
    "tart": [("1개", 60)],
    "hashbrown": [("1개", 55)],
    "pie": [("1개", 80)],
    "icecream": [("1개", 150)],
    "drink": [("1잔", 400)],
    "tteok": [("1인분", 400)],
    "twigim": [("1개", 40)],
    "sundae": [("1인분", 200)],
    "soup": [("1그릇", 300)],
    "gimbap": [("1줄", 230)],
    "rice_ball": [("1개", 220)],
    "noodle": [("1그릇", 550)],
    "udon": [("1그릇", 600)],
    "dumpling": [("1인분", 250)],
    "cutlet": [("1인분", 300)],
    "box": [("1개", 450)],
    "bowl": [("1그릇", 450)],
    "porridge": [("1그릇", 500)],
    "jjajang": [("1그릇", 650)],
    "jjamppong": [("1그릇", 900)],
    "portion": [("1인분", 300)],
    "stew": [("1인분", 400)],
    "meat": [("1인분", 200)],
    "jjimdak": [("1인분", 500)],
    "malatang": [("1그릇", 600)],
    "burger": [("1개", 230)],
    "sandwich": [("1개", 230)],
    "sub": [("1개(15cm)", 230), ("1개(30cm)", 460)],
    "salad": [("1개", 250)],
    "wrap": [("1개", 220)],
    "toast": [("1개", 200)],
    "bingsu": [("1그릇", 550)],
    "hotdog": [("1개", 130)],
    "cookie": [("1개", 45)],
    "side_dish": [("1인분", 150)],
}

# type: rep = 대표식품명 regex, name = food-name regex (both must match),
# ex = excluded names, proc = name regex over 가공식품 used when the 음식
# pool is too small, fb = fallback type, unit = UNITS key. The app category
# is CATEGORY[type], else the most common one among the reference foods.
TYPES = {
    # Chicken
    "fried": dict(rep=CHICKEN, name=r"후라이드|오리지[널날]|크리스피|바삭|클래식",
                  ex=r"양념|간장|치즈|매운|핫|마늘|갈릭|순살", unit="chicken"),
    "yangnyeom": dict(rep=CHICKEN, name=r"양념", fb="fried", unit="chicken"),
    "half": dict(rep=CHICKEN, name=r"반반|후라이드|양념", fb="yangnyeom", unit="chicken"),
    "ganjang": dict(rep=CHICKEN, name=r"간장|소이", fb="fried", unit="chicken"),
    "garlic": dict(rep=CHICKEN, name=r"마늘|갈릭|알리오", fb="ganjang", unit="chicken"),
    "spicy": dict(rep=CHICKEN, name=r"매운|핫|볼케이노|불|땡초|고추|청양|레드", fb="yangnyeom", unit="chicken"),
    "cheese": dict(rep=CHICKEN, name=r"치즈|시즈닝|스노윙|어니언|콘소메|뿌링", fb="fried", unit="chicken"),
    "cream": dict(rep=CHICKEN, name=r"크림|투움바|로제", fb="cheese", unit="chicken"),
    "mayo": dict(rep=CHICKEN, name=r"마요", fb="spicy", unit="chicken"),
    "curry": dict(rep=CHICKEN, name=r"커리|카레", fb="cheese", unit="chicken"),
    "green_onion": dict(rep=CHICKEN, name=r"파닭|파채", fb="fried", unit="chicken"),
    "roasted": dict(rep=r"^(닭구이|닭다리구이|닭날개구이)$", fb="fried", unit="roast"),
    "charcoal": dict(rep=r"^(닭구이|닭다리구이|닭볶음\(닭갈비\))$", name=r"양념|숯불|매운",
                     fb="roasted", unit="roast"),
    "wings": dict(rep=CHICKEN, name=r"윙|봉|날개", fb="fried", unit="wings"),
    "dakgangjeong": dict(rep=r"^닭강정$", proc=r"닭강정", fb="yangnyeom", unit="cup"),
    "nugget": dict(rep=CHICKEN, name=r"너겟|텐더|스트립|팝콘", proc=r"너겟|너게트|치킨텐더",
                   fb="fried", unit="nugget"),
    # Sides and desserts
    "cheeseball": dict(rep=r"^치즈볼$", unit="ball"),
    "fries": dict(rep=r"^감자튀김$", ex=r"양념|케이준|시즈닝|치즈", unit="fries"),
    "seasoned_fries": dict(rep=r"^감자튀김$", name=r"양념|케이준|시즈닝|치즈", fb="fries", unit="fries"),
    "cheesestick": dict(rep=r"^치즈스틱$", unit="stick"),
    "coleslaw": dict(rep=r".", name=r"코울슬로|콜슬로", ex=r"버거|치킨|샌드위치", proc=r"코울슬로|콜슬로", fb="corn_salad", unit="side"),
    "corn_salad": dict(rep=r"^(옥수수샐러드|콘샐러드)$", proc=r"콘샐러드|옥수수샐러드", unit="side"),
    "biscuit": dict(rep=r"^스콘$", unit="biscuit"),
    "egg_tart": dict(rep=r"^타르트$", name=r"에그", proc=r"에그타르트", fb="tart", unit="tart"),
    "tart": dict(rep=r"^타르트$", unit="tart"),
    "onion_ring": dict(rep=r".", name=r"어니언링|양파링", proc=r"어니언링|양파링", fb="fries", unit="fries"),
    "hashbrown": dict(rep=r".", name=r"해쉬브라운|해시브라운", proc=r"해쉬브라운|해시브라운", fb="fries",
                      unit="hashbrown"),
    "apple_pie": dict(rep=r"^파이/만주$", name=r"애플|사과", proc=r"애플파이|사과파이", fb="pie", unit="pie"),
    "pie": dict(rep=r"^파이/만주$", unit="pie"),
    "soft_serve": dict(rep=r"^아이스크림$", name=r"선데|소프트|콘|플러리", fb="icecream", unit="icecream"),
    "icecream": dict(rep=r"^아이스크림$", unit="icecream"),
    "shake": dict(rep=r"^(스무디|밀크쉐이크)$", name=r"쉐이크|셰이크", unit="drink"),
    "cookie": dict(rep=r"^비스킷/쿠키/크래커$", name=r"쿠키", unit="cookie"),
    # 분식
    "tteokbokki": dict(rep=r"^떡볶이$", unit="tteok"),
    "rabokki": dict(rep=r"^라볶이$", proc=r"라볶이", fb="tteokbokki", unit="tteok"),
    "twigim": dict(rep=r"^(김말이튀김|오징어튀김|고구마튀김|새우튀김|채소튀김|야채튀김)$", unit="twigim"),
    "sundae": dict(rep=r"^순대$", proc=r"순대", unit="sundae"),
    "eomuk": dict(rep=r"^(어묵탕|어묵국\(어묵탕\))$", unit="soup"),
    "gimbap": dict(rep=r"^김밥$", unit="gimbap"),
    "rice_ball": dict(rep=r"^(주먹밥|삼각김밥)$", unit="rice_ball"),
    "ramyeon": dict(rep=r"^라면$", unit="noodle"),
    "jjolmyeon": dict(rep=r"^쫄면$", fb="bibim_noodle", unit="noodle"),
    "bibim_noodle": dict(rep=r"국수|쫄면|냉면", name=r"비빔|쫄면|막국수", fb="noodle", unit="noodle"),
    "noodle": dict(rep=r"^(국수|잔치국수|비빔국수|칼국수|막국수)$", unit="noodle"),
    "udon": dict(rep=r"우동", unit="udon"),
    "dumpling": dict(rep=r"^(만두|고기만두|김치만두)$", unit="dumpling"),
    "hotdog": dict(rep=r"^핫도그$", unit="hotdog"),
    "egg_roll": dict(rep=r"^(달걀말이|달걀찜)$", unit="side_dish"),
    # 한식·중식·도시락
    "donkatsu": dict(rep=r"돈가스", unit="cutlet"),
    "dosirak": dict(rep=r"덮밥|^(카레라이스|짜장밥|잡채밥|오므라이스)$", unit="box"),
    "omurice": dict(rep=r"^오므라이스$", fb="dosirak", unit="bowl"),
    "bibimbap": dict(rep=r"비빔밥", unit="bowl"),
    "porridge": dict(rep=r"죽", ex=r"팥죽", unit="porridge"),
    "jjajang": dict(rep=r"^(자장면|짜장면|간자장)$", unit="jjajang"),
    "jjamppong": dict(rep=r"^짬뽕$", unit="jjamppong"),
    "jjamppongbap": dict(rep=r"^짬뽕밥$", fb="jjamppong", unit="jjamppong"),
    "fried_rice": dict(rep=r"볶음밥", unit="bowl"),
    "tangsuyuk": dict(rep=r"^탕수육$", unit="portion"),
    "kimchi_jjigae": dict(rep=r"^김치찌개$", unit="stew"),
    "jeyuk": dict(rep=r"^제육볶음$", unit="meat"),
    "pork_bulgogi": dict(rep=r"^돼지불고기$", fb="jeyuk", unit="meat"),
    "pork_grill": dict(rep=r"^(돼지고기구이|삼겹살구이|목살구이|돼지갈비구이)$", fb="pork_bulgogi", unit="meat"),
    "bossam": dict(rep=r"수육", ex=r"탕수육", proc=r"보쌈|수육", unit="portion"),
    "jokbal": dict(rep=r"^족발$", proc=r"족발", unit="portion"),
    "jjimdak": dict(rep=r"^닭찜$", unit="jjimdak"),
    "malatang": dict(rep=r"^마라탕$", proc=r"마라탕", unit="malatang"),
    "malaxiangguo": dict(rep=r"^마라샹궈$", proc=r"마라샹궈", fb="malatang", unit="malatang"),
    # Burgers, sandwiches, toast, salads
    "burger": dict(rep=r"^(버거|햄버거)$", unit="burger"),
    "sandwich": dict(rep=r"^샌드위치$", unit="sandwich"),
    "sub": dict(rep=r"^샌드위치$", fb="sandwich", unit="sub"),
    "salad": dict(rep=r"^샐러드$", unit="salad"),
    "wrap": dict(rep=r"^(또띠아|샌드위치)$", name=r"랩|또띠아", fb="sandwich", unit="wrap"),
    "toast": dict(rep=r"^토스트$", unit="toast"),
    # Drinks and desserts
    "coffee": dict(rep=r"^커피$", unit="drink"),
    "latte": dict(rep=r"^라떼$", unit="drink"),
    "bingsu": dict(rep=r"^빙수$", unit="bingsu"),
}


CATEGORY = {
    **dict.fromkeys(["tteokbokki", "rabokki", "twigim", "sundae", "eomuk", "gimbap", "rice_ball",
                     "jjolmyeon", "hotdog"], "분식"),
    **dict.fromkeys(["cheeseball", "fries", "seasoned_fries", "cheesestick", "coleslaw", "corn_salad",
                     "onion_ring", "hashbrown", "nugget", "wings", "roasted", "charcoal",
                     "dakgangjeong", "biscuit"], "패스트푸드"),
    **dict.fromkeys(["donkatsu", "jjimdak", "jeyuk", "pork_bulgogi", "pork_grill", "bossam", "jokbal"],
                    "고기·생선"),
    **dict.fromkeys(["tangsuyuk", "malatang", "malaxiangguo"], "중식·기타"),
}


def load_menus(path=MENUS):
    """[(brand, brand_aliases, menu, type_spec)] from the curated list."""
    out, brand, aliases = [], None, []
    for n, line in enumerate(open(path, encoding="utf-8"), 1):
        line = line.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        if line.startswith("@"):
            brand, *aliases = [x.strip() for x in line[1:].split("|")]
            continue
        if brand is None or "\t" not in line:
            sys.exit(f"{path}:{n}: expected '@brand' first, then 'menu<TAB>type'")
        menu, spec = [x.strip() for x in line.split("\t", 1)]
        if spec.split(":", 1)[0] not in TYPES:
            sys.exit(f"{path}:{n}: unknown type {spec!r}")
        out.append((brand, aliases, menu, spec))
    return out


def rep_of(fd):
    """대표식품명: the importer keeps it as the first alias unless it is the name."""
    return fd["aliases"][0] if fd["aliases"] else fd["name"]


class Pools:
    def __init__(self, food, process):
        self.food, self.process = food, process
        self.cache = {}

    def _match(self, t, extra):
        rows = [fd for fd in self.food
                if re.search(t["rep"], rep_of(fd))
                and (not t.get("name") or re.search(t["name"], fd["name"]))
                and not (t.get("ex") and re.search(t["ex"], fd["name"]))
                and (not extra or re.search(extra, fd["name"]))]
        if len(rows) < MIN_POOL and t.get("proc"):
            rows += [fd for fd in self.process
                     if re.search(t["proc"], fd["name"])
                     and not re.search(NOT_A_DISH, fd["name"])
                     and (not extra or re.search(extra, fd["name"]))]
        return [fd for fd in rows if fd["kcal"] > 0]

    def pool(self, spec):
        """(type name, foods) for "type" or "type:pattern", with fallbacks."""
        if spec in self.cache:
            return self.cache[spec]
        name, _, extra = spec.partition(":")
        seen = []
        while name and name not in seen:
            seen.append(name)
            t = TYPES[name]
            for pattern in ([extra, None] if extra else [None]):
                rows = self._match(t, pattern)
                if len(rows) >= MIN_POOL:
                    self.cache[spec] = (name, rows)
                    return self.cache[spec]
            name = t.get("fb")
        sys.exit(f"no reference foods for {spec!r} (tried {seen})")


def estimate_menu(rows):
    kcal = statistics.median(fd["kcal"] for fd in rows)
    shares = []
    for fd in rows:
        e = (fd["p"] * 4, fd["c"] * 4, fd["f"] * 9)
        if sum(e) > 0:
            shares.append([x / sum(e) for x in e])
    sh = [statistics.median(s[i] for s in shares) for i in range(3)]
    total = sum(sh) or 1
    return (round(kcal), *(round(kcal * sh[i] / total / per, 1) for i, per in enumerate((4, 4, 9))))


def median_of(rows, key):
    """Median 당류/포화지방 per 100 g of the reference foods that have it."""
    vals = [fd[key] for fd in rows if fd.get(key) is not None]
    return f"{statistics.median(vals):.1f}" if len(vals) >= MIN_POOL else ""


def main():
    menus = load_menus()
    curated = gen_foods.load()
    food = load_supabase.foods_of(load_supabase.SOURCES[0][1], "m")
    process = load_supabase.foods_of(load_supabase.SOURCES[1][1], "m")
    gen_foods.estimate(food, curated + food)
    pools = Pools(food, process)
    existing = {fd["name"].lower() for fd in curated + food}
    lines = [
        "# Estimated franchise menus: generated by tool/gen_franchise.py from data/franchise_menus.txt.",
        "# Not published by the brands or MFDS: kcal and macros per 100 g are medians of similar",
        "# MFDS foods (column 2 lists the reference group), serving weights are typical estimates.",
    ]
    names = set()
    for brand, aliases, menu, spec in menus:
        name = f"{menu} ({brand})"
        if name.lower() in existing or name in names:
            sys.exit(f"duplicate menu: {name}")
        names.add(name)
        tname, rows = pools.pool(spec)
        kcal, p, c, f = estimate_menu(rows)
        t = TYPES[tname]
        cats = [fd["cat"] for fd in rows]
        cat = CATEGORY.get(tname) or max(set(cats), key=cats.count)
        unit = UNITS["boneless" if "순살" in menu and t["unit"] == "chicken" else t["unit"]]
        reps = [rep_of(fd) for fd in rows]
        group = max(set(reps), key=reps.count)
        search = [f"{b} {menu}" for b in [brand, *aliases]]
        lines.append("\t".join([
            name, ",".join([group, *search]), cat, str(kcal), str(p), str(c), str(f),
            ";".join(f"{l}:{g}" for l, g in unit), "kpcf",
            median_of(rows, "sugar"), median_of(rows, "satfat"),
        ]).rstrip("\t"))
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")
    print(f"{len(menus)} menus from {len({m[0] for m in menus})} brands -> {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
