"""Generates the built-in food table from data/foods_ko.tsv (curated) plus
data/foods_mfds.tsv (imported from the 식약처 DB by tool/import_mfds.py, if
present):

  lib/data/food_db.g.dart   (const Dart list for the app)
  (plus data/foods_franchise.tsv, estimated menus from tool/gen_franchise.py)
  preview/src/foods.json    (embedded into the single-file preview)

Also sanity-checks each row (kcal vs 4/4/9 macro energy) and estimates the
macros a source does not publish (see estimate()).
Run: python3 tool/gen_foods.py
"""
import hashlib
import json
import statistics
from collections import defaultdict
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "data", "foods_ko.tsv")
MFDS = os.path.join(ROOT, "data", "foods_mfds.tsv")
FRANCHISE = os.path.join(ROOT, "data", "foods_franchise.tsv")  # all estimated, tool/gen_franchise.py


def slug(name: str, prefix: str) -> str:
    # Stable across edits: meals store this id. Imported foods ("m") number
    # in the hundreds of thousands on the server, so they get more digits.
    digits = 8 if prefix == "f" else 12
    return prefix + hashlib.sha1(name.encode("utf-8")).hexdigest()[:digits]


def load(path=SRC, prefix="f"):
    foods = []
    if not os.path.exists(path):
        return foods
    for n, line in enumerate(open(path, encoding="utf-8"), 1):
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        cols = line.split("\t")
        if len(cols) not in (8, 9, 10):
            sys.exit(f"line {n}: expected 8 to 10 columns, got {len(cols)}")
        name, aliases, cat, kcal, p, c, f, units = cols[:8]
        unknown = cols[8].strip() if len(cols) >= 9 else ""  # not published: k/p/c/f
        sugar = cols[9].strip() if len(cols) == 10 else ""  # 당류 g/100 g, "" = unknown
        us = []
        for u in units.split(";"):
            label, grams = u.rsplit(":", 1)
            us.append((label.strip(), float(grams)))
        foods.append({
            "id": slug(name.strip(), prefix),
            "name": name.strip(),
            "aliases": [a.strip() for a in aliases.split(",") if a.strip()],
            "cat": cat.strip(),
            "kcal": float(kcal), "p": float(p), "c": float(c), "f": float(f),
            "units": us,
            "unknown": unknown,
            "sugar": float(sugar) if sugar else None,
        })
    return foods


def _shares(fd):
    """Energy shares (protein, carbs, fat) of a fully published food."""
    e = (fd["p"] * 4, fd["c"] * 4, fd["f"] * 9)
    total = sum(e)
    return tuple(x / total for x in e) if total > 0 else None


def estimate(foods, refs):
    """Fills macros the source does not publish ("unknown", e.g. franchise
    menus list only kcal and protein) with estimates, in place. The energy
    left after the published macros is split between the missing ones by
    the median energy shares of fully published foods in the same group
    (대표식품명, the first alias), else the same category, else evenly.
    `unknown` keeps the letters so the app can label the values as estimates.
    """
    by_group, by_cat = defaultdict(list), defaultdict(list)
    for r in refs:
        sh = None if r["unknown"] else _shares(r)
        if sh:
            by_group[r["aliases"][0] if r["aliases"] else r["name"]].append(sh)
            by_cat[r["cat"]].append(sh)
    medians = {}

    def ratio(key, pool):
        if key not in medians:
            medians[key] = tuple(statistics.median(x[i] for x in pool) for i in range(3))
        return medians[key]

    kcal_per_g = (4, 4, 9)
    for fd in foods:
        miss = [i for i, k in enumerate("pcf") if k in fd["unknown"]]
        if not miss or "k" in fd["unknown"]:  # kcal estimated too: already filled
            continue
        group = fd["aliases"][0] if fd["aliases"] else fd["name"]
        if len(by_group[group]) >= 3:
            sh = ratio(("g", group), by_group[group])
        elif len(by_cat[fd["cat"]]) >= 3:
            sh = ratio(("c", fd["cat"]), by_cat[fd["cat"]])
        else:
            sh = (1 / 3, 1 / 3, 1 / 3)
        vals = [fd["p"], fd["c"], fd["f"]]
        left = max(0.0, fd["kcal"] - sum(vals[i] * kcal_per_g[i] for i in range(3) if i not in miss))
        weight = sum(sh[i] for i in miss) or len(miss)
        for i in miss:
            share = sh[i] / weight if sum(sh[i] for i in miss) else 1 / len(miss)
            vals[i] = round(left * share / kcal_per_g[i], 1)
        fd["p"], fd["c"], fd["f"] = vals


def check(foods, strict=True):
    names, ids = set(), set()
    for fd in foods:
        if fd["name"] in names:
            sys.exit(f"duplicate name: {fd['name']}")
        if fd["id"] in ids:
            sys.exit(f"duplicate id {fd['id']}: {fd['name']}")
        names.add(fd["name"])
        ids.add(fd["id"])
        macro = fd["p"] * 4 + fd["c"] * 4 + fd["f"] * 9
        if not strict or fd["unknown"] or fd["cat"] == "주류" or fd["kcal"] < 20:
            continue  # alcohol energy / near-zero drinks
        if abs(macro - fd["kcal"]) / fd["kcal"] > 0.25:
            print(f"warn: {fd['name']} kcal {fd['kcal']} vs macros {macro:.0f}")


def num(v: float) -> str:
    return str(int(v)) if v == int(v) else repr(v)


def dart(foods) -> str:
    esc = lambda s: s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")
    out = [
        "// GENERATED by tool/gen_foods.py from data/foods_ko.tsv. Do not edit.",
        "// Approximate reference values per 100 g.",
        "import 'food.dart';",
        "",
        "const builtInFoods = <Food>[",
    ]
    for fd in foods:
        aliases = ", ".join(f"'{esc(a)}'" for a in fd["aliases"])
        units = ", ".join(f"FoodUnit('{esc(l)}', {num(g)})" for l, g in fd["units"])
        out.append(
            f"  Food('{fd['id']}', '{esc(fd['name'])}', [{aliases}], '{esc(fd['cat'])}', "
            f"{num(fd['kcal'])}, {num(fd['p'])}, {num(fd['c'])}, {num(fd['f'])}, [{units}]"
            + (f", unknown: '{fd['unknown']}'" if fd["unknown"] else "")
            + (f", sugarG: {num(fd['sugar'])}" if fd.get("sugar") is not None else "") + "),"
        )
    out.append("];")
    return "\n".join(out) + "\n"


def main():
    foods = load()
    check(foods)
    curated = {f["name"].lower() for f in foods}
    imported = [f for f in load(MFDS, "m") if f["name"].lower() not in curated]
    check(imported, strict=False)
    estimate(imported, foods + imported)
    names = curated | {f["name"].lower() for f in imported}
    franchise = [f for f in load(FRANCHISE, "e") if f["name"].lower() not in names]
    check(franchise, strict=False)
    foods += imported + franchise
    with open(os.path.join(ROOT, "lib", "data", "food_db.g.dart"), "w", encoding="utf-8") as fh:
        fh.write(dart(foods))
    compact = [[fd["id"], fd["name"], fd["aliases"], fd["cat"], fd["kcal"], fd["p"], fd["c"], fd["f"],
                [[l, g] for l, g in fd["units"]]]
               + ([fd["unknown"], fd["sugar"]] if fd.get("sugar") is not None
                  else [fd["unknown"]] if fd["unknown"] else [])
               for fd in foods]
    with open(os.path.join(ROOT, "preview", "src", "foods.json"), "w", encoding="utf-8") as fh:
        json.dump(compact, fh, ensure_ascii=False, separators=(",", ":"))
    print(f"{len(foods)} foods ({len(imported)} imported, {len(franchise)} estimated franchise menus), "
          f"{len({f['cat'] for f in foods})} categories")


if __name__ == "__main__":
    main()
