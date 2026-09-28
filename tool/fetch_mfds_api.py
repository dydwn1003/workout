"""Downloads 전국통합식품영양성분정보 standard data from the 공공데이터포털 API
and writes a CSV that tool/import_mfds.py understands.

The API key is read from the DATA_GO_KR_KEY environment variable and is never
written to disk. Do not commit keys.

Usage:
  DATA_GO_KR_KEY=... python3 tool/fetch_mfds_api.py [--out data/mfds_api.csv]
      [--endpoint tn_pubr_public_nutri_food_info_api] [--rows 1000]
  python3 tool/import_mfds.py data/mfds_api.csv [--include-processed]
"""
import csv
import json
import os
import sys
import time
import urllib.parse
import urllib.request

BASE = "https://api.data.go.kr/openapi/"

# API field -> Korean header used by import_mfds.py. Unknown fields are kept
# under their API name so nothing is lost; the mapping is matched loosely
# because field names differ slightly between datasets.
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
}


def get(url):
    for attempt in range(4):
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                return r.read().decode("utf-8")
        except Exception as e:  # network hiccups: back off and retry
            if attempt == 3:
                raise
            print(f"  retry after error: {e}", file=sys.stderr)
            time.sleep(2 ** (attempt + 1))


def items_of(payload):
    body = payload.get("response", {}).get("body", {})
    items = body.get("items", [])
    if isinstance(items, dict):
        items = items.get("item", [])
    if isinstance(items, dict):
        items = [items]
    return items, int(body.get("totalCount", 0) or 0)


def main():
    key = os.environ.get("DATA_GO_KR_KEY")
    if not key:
        sys.exit("set DATA_GO_KR_KEY")
    args = sys.argv[1:]
    opt = lambda name, default: args[args.index(name) + 1] if name in args else default
    endpoint = opt("--endpoint", "tn_pubr_public_nutri_food_info_api")
    out = opt("--out", os.path.join("data", "mfds_api.csv"))
    rows = int(opt("--rows", "1000"))

    all_items, page, total = [], 1, None
    while True:
        q = urllib.parse.urlencode({"serviceKey": key, "pageNo": page, "numOfRows": rows, "type": "json"})
        text = get(f"{BASE}{endpoint}?{q}")
        try:
            payload = json.loads(text)
        except json.JSONDecodeError:
            sys.exit(f"unexpected response (not JSON): {text[:300]}")
        header = payload.get("response", {}).get("header", {})
        if header.get("resultCode") not in (None, "00", "0"):
            sys.exit(f"API error {header.get('resultCode')}: {header.get('resultMsg')}")
        items, total_count = items_of(payload)
        total = total or total_count
        all_items += items
        print(f"page {page}: {len(items)} items ({len(all_items)}/{total})")
        if not items or len(all_items) >= total:
            break
        page += 1

    keys = []
    for it in all_items:
        for k in it:
            if k not in keys:
                keys.append(k)
    headers = [FIELD_MAP.get(k, k) for k in keys]
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    with open(out, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(headers)
        for it in all_items:
            w.writerow([it.get(k, "") for k in keys])
    unmapped = [k for k in keys if k not in FIELD_MAP]
    print(f"wrote {len(all_items)} rows to {out}")
    if unmapped:
        print("fields kept under API names:", ", ".join(unmapped))


if __name__ == "__main__":
    main()
