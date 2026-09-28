"""Imports the MFDS (식약처) food nutrition database into data/foods_mfds.tsv.

Source: 식품의약품안전처 식품영양성분 데이터베이스 (통합 식품영양성분 DB),
downloaded as .xlsx or .csv from the 식품영양성분DB site or 공공데이터포털.
Attribution required in the app: "출처: 식품의약품안전처 식품영양성분 데이터베이스".

Column names differ between releases, so headers are matched by keyword.
Rows need at least a name and energy; values are per the row's basis amount
(usually 100 g) and normalized to per 100 g.

Works with the 공공데이터포털 standard data files
(전국통합식품영양성분정보(음식)표준데이터, (원재료성)표준데이터, ...).

Usage:
  python3 tool/import_mfds.py <file.csv|file.xlsx> [more files...] [--include-processed]
  python3 tool/gen_foods.py

By default only dishes (음식) and raw ingredients (원재료성) are imported;
--include-processed adds branded packaged products (가공식품), which is a
much larger set.
"""
import csv
import io
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "data", "foods_mfds.tsv")

# Header keyword candidates, most specific first.
COLS = {
    "name": ["식품명"],
    "kcal": ["에너지(kcal)", "에너지(㎉)", "에너지"],
    "protein": ["단백질(g)", "단백질"],
    "fat": ["지방(g)", "지방"],
    "carbs": ["탄수화물(g)", "탄수화물"],
    "basis": ["영양성분함량기준량", "영양성분기준량", "기준량"],
    "category": ["식품대분류명", "식품대분류", "대분류"],
    "rep": ["대표식품명"],
    "type": ["데이터구분명", "데이터구분"],
    "serving": ["1회제공량", "1회 제공량", "1회섭취참고량", "1회 섭취참고량", "식품중량"],
    "maker": ["제조사명", "업체명", "업소명"],
}


def find_cols(header):
    norm = [re.sub(r"\s", "", h or "") for h in header]
    out = {}
    for key, cands in COLS.items():
        for cand in cands:
            c = re.sub(r"\s", "", cand)
            idx = next((i for i, h in enumerate(norm) if h == c), None)
            if idx is None:
                idx = next((i for i, h in enumerate(norm) if h.startswith(c)), None)
            if idx is not None:
                out[key] = idx
                break
    missing = [k for k in ("name", "kcal") if k not in out]
    if missing:
        sys.exit(f"could not find columns {missing} in header: {header}")
    return out


def rows_from(path):
    if path.lower().endswith((".xlsx", ".xlsm")):
        from openpyxl import load_workbook

        wb = load_workbook(path, read_only=True, data_only=True)
        ws = wb.worksheets[0]
        for row in ws.iter_rows(values_only=True):
            yield ["" if v is None else str(v) for v in row]
        return
    raw = open(path, "rb").read()
    for enc in ("utf-8-sig", "cp949", "euc-kr"):
        try:
            text = raw.decode(enc)
            break
        except UnicodeDecodeError:
            continue
    else:
        sys.exit("unknown text encoding")
    yield from csv.reader(io.StringIO(text))


def num(v):
    v = (v or "").strip().replace(",", "")
    if v in ("", "-", "—", "N/A", "tr", "Tr"):
        return 0.0
    m = re.match(r"^-?\d+(\.\d+)?", v)
    return float(m.group(0)) if m else 0.0


def grams_of(v):
    """'100g', '1인분(400g)', '250mL', '400' -> grams (ml ~ g)."""
    v = v or ""
    m = re.search(r"(\d+(?:\.\d+)?)\s*(?:g|ml|㎖)\b", v, re.IGNORECASE)
    if m:
        return float(m.group(1))
    m = re.fullmatch(r"\s*(\d+(?:\.\d+)?)\s*", v)  # bare number, e.g. "400"
    return float(m.group(1)) if m else None


def clean_name(n):
    n = re.sub(r"\s+", " ", n.replace("_", " ")).strip()
    return n


def convert(path, include_processed=False):
    it = rows_from(path)
    header = None
    for row in it:  # skip title rows until a header with 식품명 appears
        if any("식품명" in (c or "") for c in row):
            header = row
            break
    if header is None:
        sys.exit("header row with 식품명 not found")
    col = find_cols(header)
    get = lambda r, k: r[col[k]] if k in col and col[k] < len(r) else ""

    foods, seen = [], set()
    skipped = 0
    for r in it:
        name = clean_name(get(r, "name"))
        if not name:
            continue
        kind = get(r, "type")
        if kind and "가공" in kind and not include_processed:
            skipped += 1
            continue
        basis = grams_of(get(r, "basis")) or 100.0
        k = 100.0 / basis
        kcal = num(get(r, "kcal")) * k
        if kcal <= 0 and num(get(r, "protein")) == 0:
            continue
        maker = get(r, "maker").strip()
        if kind and "가공" in kind and maker and maker not in ("-", "해당없음"):
            name = f"{name} ({maker})"
        if name in seen:
            continue
        seen.add(name)
        cat = (get(r, "category") or "기타").strip() or "기타"
        serving = grams_of(get(r, "serving"))
        units = f"1인분:{serving:g}" if serving and 0 < serving < 3000 else "100g:100"
        rep = get(r, "rep").strip()
        aliases = rep if rep and rep != name else ""
        foods.append([
            name, aliases, cat,
            f"{kcal:.1f}", f"{num(get(r, 'protein')) * k:.1f}",
            f"{num(get(r, 'carbs')) * k:.1f}", f"{num(get(r, 'fat')) * k:.1f}",
            units,
        ])
    return foods, skipped


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args:
        sys.exit(__doc__)
    foods, skipped, names = [], 0, set()
    for path in args:
        fs, sk = convert(path, "--include-processed" in sys.argv)
        new = [f for f in fs if f[0] not in names]
        names.update(f[0] for f in new)
        foods += new
        skipped += sk
        print(f"{os.path.basename(path)}: {len(new)} foods")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("# Imported from 식품의약품안전처 식품영양성분 데이터베이스 by tool/import_mfds.py\n")
        f.write("# 출처: 식품의약품안전처 식품영양성분 데이터베이스 (per 100 g)\n")
        for row in foods:
            f.write("\t".join(row) + "\n")
    print(f"wrote {len(foods)} foods to {os.path.relpath(OUT, ROOT)}"
          + (f" (skipped {skipped} processed; use --include-processed)" if skipped else ""))


if __name__ == "__main__":
    main()
