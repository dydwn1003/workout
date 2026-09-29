"""Downloads 포화지방 (and 당류) per food from the 식품의약품안전처
식품영양성분DB정보 API and writes data/mfds_ntr.csv, keyed by 식품코드.

  https://apis.data.go.kr/1471000/FoodNtrCpntDbInfo03/getFoodNtrCpntDbInq03

The same key as tool/fetch_mfds_api.py (DATA_GO_KR_KEY, never written to
disk). The rows are the same foods as the standard data, with the same
식품코드, so tool/import_mfds.py uses this file to fill 포화지방 where the
standard data leaves it empty. Nutrients come as numbered fields; the ones
kept here were checked against the standard data (fasat == AMT_NUM24 for
the same 식품코드).

Usage:
  DATA_GO_KR_KEY=... python3 tool/fetch_mfds_ntr.py [--workers 6]
"""
import csv
import json
import os
import sys
import urllib.parse
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.path.insert(0, os.path.dirname(__file__))
from fetch_mfds_api import get  # noqa: E402  (retrying GET)

URL = "https://apis.data.go.kr/1471000/FoodNtrCpntDbInfo03/getFoodNtrCpntDbInq03"
OUT = os.path.join("data", "mfds_ntr.csv")
CACHE = os.path.join("data", ".mfds_cache", "FoodNtrCpntDbInfo03")
# Pages of 500 rows (the cap) take ~10 s and the connection is often cut
# at ~11 s; 100-row pages come back in ~4 s.
ROWS = 100

# API field -> output header
FIELDS = {
    "FOOD_CD": "식품코드",
    "FOOD_NM_KR": "식품명",
    "MAKER_NM": "업체명",
    "DB_GRP_NM": "데이터구분명",
    "DB_CLASS_NM": "데이터분류명",  # 품목대표: MFDS's representative value for a dish
    "FOOD_REF_NM": "대표식품명",
    "SERVING_SIZE": "영양성분함량기준량",
    "AMT_NUM1": "에너지(kcal)",
    "AMT_NUM3": "단백질(g)",
    "AMT_NUM4": "지방(g)",
    "AMT_NUM6": "탄수화물(g)",
    "AMT_NUM7": "당류(g)",
    "AMT_NUM24": "포화지방산(g)",
}


def page(key, n):
    path = os.path.join(CACHE, f"{ROWS}-{n}.json")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            cached = json.load(f)
        return cached["items"], cached["total"]
    q = urllib.parse.urlencode({"serviceKey": key, "pageNo": n, "numOfRows": ROWS, "type": "json"})
    text = get(f"{URL}?{q}")
    try:
        payload = json.loads(text)
    except json.JSONDecodeError:
        raise SystemExit(f"unexpected response (not JSON): {text[:300]}")
    header = payload.get("header", {})
    if header.get("resultCode") not in ("00", "0"):
        raise SystemExit(f"API error: {text[:300]}")
    body = payload.get("body", {})
    items = [{k: (it.get(k) or "") for k in FIELDS} for it in body.get("items") or []]
    total = int(body.get("totalCount", 0) or 0)
    os.makedirs(CACHE, exist_ok=True)
    with open(path + ".tmp", "w", encoding="utf-8") as f:
        json.dump({"items": items, "total": total}, f, ensure_ascii=False)
    os.replace(path + ".tmp", path)
    return items, total


def main():
    key = os.environ.get("DATA_GO_KR_KEY")
    if not key:
        sys.exit("set DATA_GO_KR_KEY")
    args = sys.argv[1:]
    workers = int(args[args.index("--workers") + 1]) if "--workers" in args else 6
    first, total = page(key, 1)
    pages = max(1, -(-total // ROWS))
    results = {1: first}
    with ThreadPoolExecutor(workers) as ex:
        futures = {ex.submit(page, key, n): n for n in range(2, pages + 1)}
        for i, fut in enumerate(as_completed(futures), 2):
            results[futures[fut]] = fut.result()[0]
            if i % 20 == 0 or i == pages:
                print(f"{i}/{pages} pages")
    items = [it for n in sorted(results) for it in results[n]]
    if len(items) < total:
        print(f"warning: got {len(items)} of {total} rows", file=sys.stderr)
    with open(OUT, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(FIELDS.values())
        for it in items:
            w.writerow(it[k] for k in FIELDS)
    print(f"wrote {len(items)} rows to {OUT}")


if __name__ == "__main__":
    main()
