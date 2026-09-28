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
  python3 tool/import_mfds.py <file.csv|file.xlsx> [more files...]
      [--include-processed] [--processed-per-group N] [--allow-partial]
  python3 tool/gen_foods.py

By default only dishes (음식) and raw ingredients (원재료성) are imported;
--include-processed adds branded packaged products (가공식품). That set is
huge (~590k rows), so only N products per 대표식품명 are kept
(--processed-per-group, default 10; 0 keeps all), preferring products with
a known package weight, then the most recently updated.

Many franchise menus publish only kcal, protein and sugar. Such rows are
imported with the missing macros marked in a 9th column (e.g. "cf"), which
the app shows as "—" instead of 0 g. --full-macros-only skips them.
"""
import argparse
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
    "maker": ["제조사명", "업체명"],
    "rest": ["업소명"],
    "origin": ["식품기원명"],
    "date": ["crtrYmd", "데이터기준일자"],
}


# MFDS 식품대분류 -> the app's own categories (data/foods_ko.tsv), so the
# category chips stay short. Unlisted categories are kept as they are.
CATEGORY_MAP = {
    "밥류": "밥·죽",
    "죽 및 스프류": "밥·죽",
    "면 및 만두류": "면·만두",
    "국 및 탕류": "국·찌개",
    "찌개 및 전골류": "국·찌개",
    "빵 및 과자류": "빵·시리얼",
    "음료 및 차류": "음료",
    "유제품류 및 빙과류": "유제품",
    "구이류": "반찬",
    "볶음류": "반찬",
    "조림류": "반찬",
    "찜류": "반찬",
    "튀김류": "반찬",
    "전·적 및 부침류": "반찬",
    "생채·무침류": "반찬",
    "나물·숙채류": "반찬",
    "김치류": "반찬",
    "장아찌·절임류": "반찬",
    "젓갈류": "반찬",
    "수·조·어·육류": "고기·생선",
    "채소, 해조류": "채소",
    "과일류": "과일",
    "두류, 견과 및 종실류": "간식·디저트",
    "곡류, 서류 제품": "빵·시리얼",
    "장류, 양념류": "양념·소스",
    # 가공식품
    "과자류·빵류 또는 떡류": "간식·디저트",
    "코코아가공품류 또는 초콜릿류": "간식·디저트",
    "빙과류": "간식·디저트",
    "즉석식품류": "즉석식품",
    "음료류": "음료",
    "식육가공품 및 포장육": "고기·생선",
    "수산가공식품류": "고기·생선",
    "동물성가공식품류": "고기·생선",
    "면류": "면·만두",
    "유가공품류": "유제품",
    "두부류 또는 묵류": "계란·두부",
    "알가공품류": "계란·두부",
    "절임류 또는 조림류": "반찬",
    "조미식품": "양념·소스",
    "장류": "양념·소스",
    "식용유지류": "양념·소스",
    "당류": "양념·소스",
    "잼류": "양념·소스",
    "벌꿀 및 화분가공 식품류": "양념·소스",
    "농산가공식품류": "농산 가공식품",
    "특수영양식품": "기타 가공식품",
    "특수의료용도식품": "기타 가공식품",
    "기타식품류": "기타 가공식품",
}


# 대표식품명 overrides for dishes MFDS files under a broad group (burgers and
# pizza are 빵 및 과자류, fried chicken is 튀김류).
REP_CATEGORY = {
    **dict.fromkeys(["피자", "버거", "햄버거", "샌드위치", "핫도그", "닭튀김", "닭다리튀김"], "패스트푸드"),
    **dict.fromkeys(["케이크", "도넛", "와플", "마카롱", "크로플", "츄러스", "머핀", "스콘"], "간식·디저트"),
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
    # Names are "대표식품_세부명" (e.g. 피자_치즈피자, 김밥_샐러리). Drop the
    # prefix when the rest already says it; the prefix is kept as an alias.
    head, sep, rest = n.partition("_")
    if sep and head.strip() and head.strip() in rest:
        n = rest
    return re.sub(r"\s+", " ", n.replace("_", " ")).strip()


def convert(path, include_processed=False, per_group=10, full_only=False):
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

    foods, seen, groups = [], set(), {}
    skipped = partial = 0
    for r in it:
        name = clean_name(get(r, "name"))
        if not name:
            continue
        kind = get(r, "type")
        processed = bool(kind) and "가공" in kind
        if processed and not include_processed:
            skipped += 1
            continue
        unknown = "".join(
            m for m, k in (("p", "protein"), ("c", "carbs"), ("f", "fat"))
            if k in col and not get(r, k).strip()
        )
        if unknown and full_only:
            partial += 1
            continue
        basis = grams_of(get(r, "basis")) or 100.0
        k = 100.0 / basis
        kcal = num(get(r, "kcal")) * k
        if kcal <= 0 and num(get(r, "protein")) == 0:
            continue
        maker = get(r, "maker").strip() if processed else ""
        if not processed and "외식" in get(r, "origin"):
            maker = get(r, "rest").strip()  # franchise menus: brand name
        if maker and maker not in ("-", "해당없음"):
            name = f"{name} ({maker})"
        if name in seen:
            continue
        rep = get(r, "rep").strip()
        cat = (get(r, "category") or "기타").strip() or "기타"
        cat = REP_CATEGORY.get(rep) or CATEGORY_MAP.get(cat, cat)
        serving = grams_of(get(r, "serving"))
        # 음식: one serving as listed; 가공식품: the whole package.
        label = "1개(포장)" if processed else "1회 제공량"
        has_serving = bool(serving and 0 < serving < 3000)
        units = f"{label}:{serving:g}" if has_serving else "100g:100"
        aliases = rep if rep and rep != name else ""
        row = [
            name, aliases, cat,
            f"{kcal:.1f}", f"{num(get(r, 'protein')) * k:.1f}",
            f"{num(get(r, 'carbs')) * k:.1f}", f"{num(get(r, 'fat')) * k:.1f}",
            units,
        ] + ([unknown] if unknown else [])
        if processed and per_group:
            groups.setdefault((cat, rep or name), []).append(((has_serving, get(r, "date")), row))
            continue
        seen.add(name)
        foods.append(row)
    for cands in groups.values():
        cands.sort(key=lambda c: c[0], reverse=True)
        kept = 0
        for _, row in cands:
            if kept == per_group:
                skipped += 1
            elif row[0] not in seen:
                seen.add(row[0])
                foods.append(row)
                kept += 1
    return foods, skipped, partial


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="+")
    ap.add_argument("--include-processed", action="store_true")
    ap.add_argument("--processed-per-group", type=int, default=10)
    ap.add_argument("--full-macros-only", action="store_true")
    a = ap.parse_args()
    foods, skipped, partial, names = [], 0, 0, set()
    for path in a.files:
        fs, sk, pa = convert(path, a.include_processed, a.processed_per_group, a.full_macros_only)
        new = [f for f in fs if f[0] not in names]
        names.update(f[0] for f in new)
        foods += new
        skipped += sk
        partial += pa
        print(f"{os.path.basename(path)}: {len(new)} foods")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("# Imported from 식품의약품안전처 식품영양성분 데이터베이스 by tool/import_mfds.py\n")
        f.write("# 출처: 식품의약품안전처 식품영양성분 데이터베이스 (per 100 g)\n")
        for row in foods:
            f.write("\t".join(row) + "\n")
    print(f"wrote {len(foods)} foods to {os.path.relpath(OUT, ROOT)}"
          + (f"; skipped {skipped} processed (see --include-processed, --processed-per-group)" if skipped else "")
          + (f"; skipped {partial} without full macros" if partial else ""))


if __name__ == "__main__":
    main()
