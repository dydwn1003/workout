"""Downloads 전국통합식품영양성분정보 standard data from the 공공데이터포털 API
and writes a CSV that tool/import_mfds.py understands.

The API key is read from the DATA_GO_KR_KEY environment variable and is never
written to disk. Do not commit keys.

Datasets (same host, same key):
  food     tn_pubr_public_nutri_food_info_api     음식 (dishes, eating out)
  process  tn_pubr_public_nutri_process_info_api  가공식품 (packaged products)

Usage:
  DATA_GO_KR_KEY=... python3 tool/fetch_mfds_api.py            # both datasets
  DATA_GO_KR_KEY=... python3 tool/fetch_mfds_api.py food       # one dataset
  python3 tool/import_mfds.py data/mfds_api_food.csv data/mfds_api_process.csv --include-processed
"""
import csv
import json
import os
import sys
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

BASE = "https://api.data.go.kr/openapi/"
DATASETS = {
    "food": "tn_pubr_public_nutri_food_info_api",
    "process": "tn_pubr_public_nutri_process_info_api",
}

# API field -> Korean header used by import_mfds.py; the mapping is matched
# loosely because field names differ slightly between datasets. Fields not
# listed keep their API name.
FIELD_MAP = {
    "foodNm": "식품명",
    "foodnm": "식품명",
    "dataNm": "데이터구분명",
    "typeNm": "데이터구분명",
    "foodOriginNm": "식품기원명",
    "foodLv3Nm": "식품대분류명",
    "foodLv4Nm": "대표식품명",
    "foodLv5Nm": "식품중분류명",
    "nutConSrtrQua": "영양성분함량기준량",
    "enerc": "에너지(kcal)",
    "prot": "단백질(g)",
    "fatce": "지방(g)",
    "chocdf": "탄수화물(g)",
    "sugar": "당류(g)",
    "foodSize": "식품중량",
    "mfrNm": "업체명",
    "mkrNm": "업체명",
    "restNm": "업소명",
}


def get(url):
    for attempt in range(6):
        try:
            with urllib.request.urlopen(url, timeout=120) as r:
                return r.read().decode("utf-8")
        except Exception as e:  # the API often resets connections: back off and retry
            if attempt == 5:
                raise
            print(f"  retry after error: {e}", file=sys.stderr)
            time.sleep(min(2 ** (attempt + 1), 30))


def envelope(payload):
    # The standard-data API returns {"header", "body"} at the top level; older
    # data.go.kr services wrap them in "response". Accept both.
    return payload.get("response", payload)


def items_of(payload):
    body = envelope(payload).get("body", {})
    items = body.get("items", [])
    if isinstance(items, dict):
        items = items.get("item", [])
    if isinstance(items, dict):
        items = [items]
    return items, int(body.get("totalCount", 0) or 0)


# Fields kept in the output. The full records carry ~60 fields (minerals,
# vitamins, codes); the 가공식품 set has ~590k rows, so keeping everything
# would be close to 1 GB.
KEEP = [
    "foodCd", "foodNm", "typeNm", "foodOriginNm", "foodLv3Nm", "foodLv4Nm",
    "nutConSrtrQua", "enerc", "prot", "fatce", "chocdf", "sugar",
    "foodSize", "mfrNm", "restNm", "crtrYmd",
]
CACHE = os.path.join("data", ".mfds_cache")


def main():
    key = os.environ.get("DATA_GO_KR_KEY")
    if not key:
        sys.exit("set DATA_GO_KR_KEY")
    args = sys.argv[1:]
    opt = lambda name, default: args[args.index(name) + 1] if name in args else default
    rows = int(opt("--rows", "1000"))  # the API caps pages at 1000
    workers = int(opt("--workers", "4"))
    names = [a for a in args if a in DATASETS] or list(DATASETS)
    for name in names:
        print(f"== {name} ({DATASETS[name]})")
        fetch(key, DATASETS[name], os.path.join("data", f"mfds_api_{name}.csv"), rows, workers)


def page(key, endpoint, n, rows):
    """Returns (items, totalCount) for page n, cached on disk so an
    interrupted download resumes where it stopped."""
    path = os.path.join(CACHE, endpoint, f"{rows}-{n}.json")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            cached = json.load(f)
        return cached["items"], cached["total"]
    q = urllib.parse.urlencode({"serviceKey": key, "pageNo": n, "numOfRows": rows, "type": "json"})
    text = get(f"{BASE}{endpoint}?{q}")
    try:
        payload = json.loads(text)
    except json.JSONDecodeError:
        raise SystemExit(f"unexpected response (not JSON): {text[:300]}")
    header = envelope(payload).get("header", {})
    if header.get("resultCode") not in (None, "00", "0"):
        raise SystemExit(f"API error {header.get('resultCode')}: {header.get('resultMsg')}")
    items, total = items_of(payload)
    items = [{k: it.get(k, "") for k in KEEP} for it in items]
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path + ".tmp", "w", encoding="utf-8") as f:
        json.dump({"items": items, "total": total}, f, ensure_ascii=False)
    os.replace(path + ".tmp", path)
    return items, total


def fetch(key, endpoint, out, rows, workers):
    first, total = page(key, endpoint, 1, rows)
    pages = max(1, -(-total // rows))
    results = {1: first}
    with ThreadPoolExecutor(workers) as ex:
        futures = {ex.submit(page, key, endpoint, n, rows): n for n in range(2, pages + 1)}
        for i, fut in enumerate(as_completed(futures), 2):
            results[futures[fut]] = fut.result()[0]
            if i % 20 == 0 or i == pages:
                print(f"{i}/{pages} pages")
    all_items = [it for n in sorted(results) for it in results[n]]
    if len(all_items) < total:
        print(f"warning: got {len(all_items)} of {total} rows", file=sys.stderr)

    headers = [FIELD_MAP.get(k, k) for k in KEEP]
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    with open(out, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(headers)
        for it in all_items:
            w.writerow([it.get(k, "") for k in KEEP])
    print(f"wrote {len(all_items)} rows to {out}")


if __name__ == "__main__":
    main()
