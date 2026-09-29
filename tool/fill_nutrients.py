"""Fills 당류 and 포화지방 (columns 10 and 11) of the hand-made foods in
data/foods_ko.tsv from the MFDS database.

Needs data/mfds_ntr.csv (tool/fetch_mfds_ntr.py). For each food, the MFDS
foods with the same name (or one of its aliases) are looked up, then raw
ingredients by a part of their name ("버터, 가염" for 버터), preferring
MFDS's own representative value (데이터분류명 품목대표) over the median of
all matches. Matches whose energy is far from ours (another dish with the
same name) are ignored. Recipes differ, so 포화지방 is our fat times the
matches' 포화지방/지방 ratio, and 당류 is capped at our carbs. Foods without
a match keep their 당류; their 포화지방 uses the median ratio of their
category's matched foods.

Each row's source is written to data/foods_ko_nutrients.txt for review.

Usage:
  python3 tool/fill_nutrients.py && python3 tool/gen_foods.py
"""
import csv
import os
import re
import statistics
import sys

sys.path.insert(0, os.path.dirname(__file__))
import import_mfds  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "data", "foods_ko.tsv")
NTR = os.path.join(ROOT, "data", "mfds_ntr.csv")
REPORT = os.path.join(ROOT, "data", "foods_ko_nutrients.txt")


def key(s):
    return re.sub(r"[\s_()]", "", s.lower())


GENERIC = {"생것", "삶은것", "구운것", "볶은것", "찐것", "말린것", "데친것", "튀긴것", "가염", "무염",
           "국산", "수입산", "냉동", "통조림"}


def load_mfds():
    """(by name, by part of a raw ingredient's name): key -> [(representative?,
    kcal, sugar, satfat, fat)] per 100 g."""
    by_name, by_part = {}, {}
    with open(NTR, encoding="utf-8") as f:
        for r in csv.DictReader(f):
            if "가공" in r["데이터구분명"] or r["업체명"].strip():
                continue  # branded products: not the generic dish
            k = 100.0 / (import_mfds.grams_of(r["영양성분함량기준량"]) or 100.0)
            val = lambda c: import_mfds.num(r[c]) * k if r[c].strip() else None
            kcal = val("에너지(kcal)")
            if not kcal:
                continue
            row = (r["데이터분류명"] == "품목대표", kcal, val("당류(g)"), val("포화지방산(g)"), val("지방(g)"))
            names = {r["식품명"], import_mfds.clean_name(r["식품명"])}
            if r["데이터분류명"] == "품목대표" and r["대표식품명"].strip():
                names.add(r["대표식품명"])
            for n in names:
                by_name.setdefault(key(n), []).append(row)
            if "원재료" in r["데이터구분명"]:
                for part in r["식품명"].split(",")[:2]:
                    if part.strip() and part.strip() not in GENERIC:
                        by_part.setdefault(key(part), []).append(row)
    return by_name, by_part


def lookup(rows, kcal, of):
    """(value, how) of of(row) over the matches near [kcal], or None."""
    near = [r for r in rows if 0.5 <= r[1] / kcal <= 2 and of(r) is not None]
    rep = [of(r) for r in near if r[0]]
    if rep:
        return statistics.median(rep), "품목대표"
    if near:
        return statistics.median(of(r) for r in near), f"median of {len(near)}"
    return None


sugar_of = lambda r: r[2]
sat_ratio_of = lambda r: (min(r[3] / r[4], 1.0) if r[4] else 0.0) if r[3] is not None and r[4] is not None else None


def find(tables, names, kcal, of):
    """First match: by name, then by part of a raw ingredient's name."""
    for table in tables:
        for n in names:
            hit = lookup(table.get(key(n), []), kcal, of) if kcal > 0 else None
            if hit:
                return hit
    return None


def main():
    if not os.path.exists(NTR):
        sys.exit(f"missing {NTR}: run tool/fetch_mfds_ntr.py first")
    tables = load_mfds()
    lines = open(SRC, encoding="utf-8").read().split("\n")
    foods = []  # (line index, cols, match rows)
    for i, line in enumerate(lines):
        if not line.strip() or line.startswith("#"):
            continue
        cols = line.split("\t")
        cols += [""] * (11 - len(cols))
        names = [cols[0], *[a for a in cols[1].split(",") if a]]
        foods.append((i, cols, names))

    report, ratios = [], {}
    for i, cols, names in foods:
        kcal, carbs, fat = float(cols[3]), float(cols[5]), float(cols[6])
        sugar = find(tables, names, kcal, sugar_of)
        ratio = find(tables, names, kcal, sat_ratio_of)
        if sugar:
            cols[9] = f"{sugar[0]:.1f}"
        if cols[9] and float(cols[9]) > carbs:
            cols[9] = f"{carbs:.1f}"
        if ratio:
            cols[10] = f"{fat * ratio[0]:.1f}"
            if fat > 0.5:
                ratios.setdefault(cols[2], []).append(ratio[0])
        report.append([cols[0], sugar[1] if sugar else "kept", ratio[1] if ratio else None])

    all_ratios = [r for rs in ratios.values() for r in rs]
    for (i, cols, _), rep in zip(foods, report):
        if rep[2] is None:
            rs = ratios.get(cols[2]) if len(ratios.get(cols[2], [])) >= 3 else all_ratios
            cols[10] = f"{float(cols[6]) * statistics.median(rs):.1f}"
            rep[2] = f"estimated ({cols[2]} 포화지방/지방)"
        lines[i] = "\t".join(cols).rstrip("\t")

    with open(SRC, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    with open(REPORT, "w", encoding="utf-8") as f:
        f.write("# Source of 당류 / 포화지방 per food in foods_ko.tsv (tool/fill_nutrients.py)\n")
        for name, s, t in report:
            f.write(f"{name}\t당류: {s}\t포화지방: {t}\n")
    count = lambda j, p: sum(r[j].startswith(p) for r in report)
    print(f"{len(report)} foods: 당류 from MFDS {len(report) - count(1, 'kept')}, kept {count(1, 'kept')}; "
          f"포화지방 from MFDS {len(report) - count(2, 'estimated')}, estimated {count(2, 'estimated')}")


if __name__ == "__main__":
    main()
