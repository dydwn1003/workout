"""Loads gyms (체력단련장업, open businesses only) into Supabase public.gyms
(supabase/community.sql) for the gym community boards.

Source: 행정안전부 지방행정 인허가 데이터 "체력단련장업", either
  - the data.go.kr open API (1741000/fitness_centers/info; apply for it
    with the same account as DATA_GO_KR_KEY), or
  - a downloaded CSV of the same data (--csv file.csv, Korean headers).

Environment (never written to disk; do not commit keys):
  DATA_GO_KR_KEY             data.go.kr service key (API mode)
  SUPABASE_URL               https://<project>.supabase.co
  SUPABASE_SERVICE_ROLE_KEY  secret key

Usage:
  python3 tool/load_gyms.py                 # API -> Supabase
  python3 tool/load_gyms.py --csv gyms.csv  # CSV -> Supabase
  python3 tool/load_gyms.py --dry-run       # print what would be loaded
"""
import argparse
import csv
import http.client
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

API = "https://apis.data.go.kr/1741000/fitness_centers/info"

# Same fields under the names the API and the CSV use (older LOCALDATA
# exports use the camelCase ones).
FIELDS = {
    "mgt": ["MNG_NO", "mgtNo", "관리번호"],
    "gov": ["OPN_ATMY_GRP_CD", "opnSfTeamCode", "개방자치단체코드"],
    "name": ["BPLC_NM", "bplcNm", "사업장명"],
    "road": ["ROAD_NM_ADDR", "rdnWhlAddr", "도로명전체주소", "도로명주소"],
    "lot": ["LOTNO_ADDR", "siteWhlAddr", "소재지전체주소", "지번주소"],
    "state": ["SALS_STTS_NM", "trdStateNm", "영업상태명", "DTL_SALS_STTS_NM", "dtlStateNm", "상세영업상태명"],
}


def field(row, name):
    lower = {k.lower(): v for k, v in row.items()}
    for k in FIELDS[name]:
        v = row.get(k, lower.get(k.lower()))
        if v not in (None, ""):
            return str(v).strip()
    return ""


def gym(row):
    """public.gyms row for an open gym, or None (closed, no name)."""
    state = field(row, "state")
    if state and not any(s in state for s in ("영업", "정상")):
        return None  # 폐업, 휴업, 취소...
    name = " ".join(field(row, "name").split())[:60]
    mgt = field(row, "mgt")
    if not name or not mgt:
        return None
    address = " ".join((field(row, "road") or field(row, "lot")).split())
    # "서울특별시 강남구 테헤란로 1 (역삼동)" -> 서울특별시, 강남구
    parts = address.split()
    sido = parts[0] if parts else ""
    sigungu = parts[1] if len(parts) > 1 else ""
    if len(parts) > 2 and parts[1].endswith("시") and parts[2].endswith("구"):
        sigungu = f"{parts[1]} {parts[2]}"  # 수원시 영통구
    gov = field(row, "gov")
    return {
        "id": f"l-{gov}-{mgt}" if gov else f"l-{mgt}",
        "name": name,
        "address": address[:200],
        "sido": sido,
        "sigungu": sigungu,
        "source": "open",
    }


def items_of(payload):
    """The records of one API page, whatever the envelope looks like."""
    if isinstance(payload, list):
        return payload
    for key in ("response", "body", "items", "item", "row", "data"):
        if isinstance(payload, dict) and key in payload:
            inner = payload[key]
            if isinstance(inner, list):
                return inner
            got = items_of(inner)
            if got is not None:
                return got
    if isinstance(payload, dict):
        for v in payload.values():
            if isinstance(v, (dict, list)):
                got = items_of(v)
                if got:
                    return got
    return None


def api_page(key, n, rows):
    """(items, totalCount) of one API page, retrying dropped connections."""
    q = urllib.parse.urlencode({"serviceKey": key, "pageNo": n, "numOfRows": rows,
                                "returnType": "json"})
    for attempt in range(8):
        try:
            with urllib.request.urlopen(f"{API}?{q}", timeout=120) as r:
                text = r.read().decode("utf-8")
            payload = json.loads(text)
            break
        except (OSError, http.client.HTTPException, json.JSONDecodeError) as e:
            if attempt == 7:
                sys.exit(f"page {n} failed: {e}")
            print(f"  page {n}: {e}, retrying", file=sys.stderr)
            time.sleep(2 ** min(attempt, 4))
    if "SERVICE_KEY" in text[:500] or "NO_OPENAPI" in text[:500]:
        sys.exit(f"API refused: {text[:300]}")
    body = payload.get("response", {}).get("body", {}) if isinstance(payload, dict) else {}
    items = items_of(payload) or []
    if isinstance(items, dict):
        items = [items]
    return items, int(body.get("totalCount") or 0)


def api_rows(key, rows=100):
    """Every record, 100 per page (the API's maximum), 4 pages at a time."""
    from concurrent.futures import ThreadPoolExecutor
    first, total = api_page(key, 1, rows)
    yield from first
    pages = -(-total // rows)
    print(f"  {total} records, {pages} pages", file=sys.stderr)
    with ThreadPoolExecutor(4) as pool:
        for n, (items, _) in zip(range(2, pages + 1),
                                 pool.map(lambda n: api_page(key, n, rows), range(2, pages + 1))):
            yield from items
            if n % 20 == 0:
                print(f"  page {n}/{pages}", file=sys.stderr)


def csv_rows(path):
    for enc in ("utf-8-sig", "cp949"):
        try:
            with open(path, encoding=enc, newline="") as f:
                yield from csv.DictReader(f)
            return
        except UnicodeDecodeError:
            continue


def upload(gyms, batch=500):
    url = os.environ["SUPABASE_URL"].rstrip("/") + "/rest/v1/gyms"
    key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    headers = {
        "apikey": key,
        "Content-Type": "application/json",
        # Keep member/post counts of gyms already there.
        "Prefer": "resolution=merge-duplicates,return=minimal",
    }
    if not key.startswith("sb_"):
        headers["Authorization"] = f"Bearer {key}"
    for i in range(0, len(gyms), batch):
        body = json.dumps(gyms[i:i + batch], ensure_ascii=False).encode()
        req = urllib.request.Request(url + "?on_conflict=id", data=body, method="POST", headers=headers)
        for attempt in range(5):
            try:
                with urllib.request.urlopen(req, timeout=120):
                    break
            except urllib.error.HTTPError as e:
                sys.exit(f"upload failed: {e.code} {e.read()[:300]}")
            except (OSError, http.client.HTTPException):
                if attempt == 4:
                    raise
                time.sleep(2 ** attempt)
        print(f"  uploaded {min(i + batch, len(gyms))}/{len(gyms)}", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    rows = csv_rows(args.csv) if args.csv else api_rows(os.environ["DATA_GO_KR_KEY"])
    seen, gyms, closed = set(), [], 0
    for row in rows:
        g = gym(row)
        if g is None:
            closed += 1
            continue
        if g["id"] not in seen:
            seen.add(g["id"])
            gyms.append(g)
    print(f"{len(gyms)} open gyms ({closed} closed or unnamed skipped)", file=sys.stderr)
    if args.dry_run:
        for g in gyms[:20]:
            print(g)
        return
    upload(gyms)


if __name__ == "__main__":
    main()
