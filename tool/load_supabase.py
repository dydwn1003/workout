"""Loads the full food database into Supabase (table public.foods, see
supabase/schema.sql): the curated foods plus every row of the MFDS API
downloads, including all ~590k 가공식품, and the estimated franchise menus
(data/foods_franchise.tsv).

Needs the downloads from tool/fetch_mfds_api.py and these environment
variables (never written to disk; do not commit keys):
  SUPABASE_URL               https://<project>.supabase.co
  SUPABASE_SERVICE_ROLE_KEY  secret key (sb_secret_...) or legacy service_role key

Usage:
  python3 tool/load_supabase.py                 # upsert into Supabase
  python3 tool/load_supabase.py --csv out.csv   # write a CSV for COPY instead
  python3 tool/load_supabase.py --skip 260000   # resume after an interrupted upload
  python3 tool/load_supabase.py --only-estimated  # re-upload just the rows with estimated macros
  python3 tool/load_supabase.py --source estimated  # just the estimated franchise menus
"""
import argparse
import csv
import json
import os
import sys
import time
import urllib.request

sys.path.insert(0, os.path.dirname(__file__))
import gen_foods  # noqa: E402
import import_mfds  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
SOURCES = [
    ("mfds_food", os.path.join(ROOT, "data", "mfds_api_food.csv"), "m"),
    ("mfds_process", os.path.join(ROOT, "data", "mfds_api_process.csv"), "m"),
]
COLUMNS = ["id", "name", "aliases", "category", "kcal", "protein", "carbs", "fat",
           "units", "unknown", "source", "search"]

def norm(s):  # same as normalizeQuery() in lib/data/food.dart
    return s.lower().replace(" ", "")


def record(fd, source):
    names = [fd["name"], *fd["aliases"]]
    if source != "curated" and fd["name"].endswith(")") and " (" in fd["name"]:
        names.insert(1, fd["name"].rsplit(" (", 1)[0])  # 신라면 ((주)농심) -> 신라면
    keys = list(dict.fromkeys(norm(k) for k in names if norm(k)))
    return {
        "id": fd["id"], "name": fd["name"], "aliases": fd["aliases"], "category": fd["cat"],
        "kcal": fd["kcal"], "protein": fd["p"], "carbs": fd["c"], "fat": fd["f"],
        "units": [{"label": l, "g": g} for l, g in fd["units"]],
        "unknown": fd["unknown"], "source": source,
        "search": "|".join(keys),
    }


def foods_of(path, prefix):
    """Every row of one download, per 100 g, via the same importer the app uses."""
    rows, _, _ = import_mfds.convert(path, include_processed=True, per_group=0)
    tmp = path + ".tsv"
    with open(tmp, "w", encoding="utf-8") as f:
        for r in rows:
            f.write("\t".join(r) + "\n")
    try:
        return gen_foods.load(tmp, prefix)
    finally:
        os.remove(tmp)


def all_records():
    curated = gen_foods.load()
    names = {fd["name"].lower() for fd in curated}
    groups = []
    for source, path, prefix in SOURCES:
        if not os.path.exists(path):
            sys.exit(f"missing {path}: run tool/fetch_mfds_api.py first")
        new = [fd for fd in foods_of(path, prefix) if fd["name"].lower() not in names]
        names.update(fd["name"].lower() for fd in new)
        gen_foods.check(new, strict=False)  # also fails on id collisions
        groups.append((source, new))
        print(f"{source}: {len(new)} foods")
    imported = [fd for _, new in groups for fd in new]
    gen_foods.estimate(imported, curated + imported)
    franchise = [fd for fd in gen_foods.load(gen_foods.FRANCHISE, "e") if fd["name"].lower() not in names]
    gen_foods.check(franchise, strict=False)
    groups.append(("estimated", franchise))
    print(f"estimated: {len(franchise)} foods")
    return [record(fd, "curated") for fd in curated] + [
        record(fd, source) for source, new in groups for fd in new]


def pg_array(xs):
    return "{" + ",".join('"' + x.replace("\\", "\\\\").replace('"', '\\"') + '"' for x in xs) + "}"


def write_csv(recs, path):
    with open(path, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(COLUMNS)
        for r in recs:
            w.writerow([pg_array(r[c]) if c == "aliases"
                        else json.dumps(r[c], ensure_ascii=False) if c == "units"
                        else r[c] for c in COLUMNS])
    print(f"wrote {len(recs)} rows to {path}")


def post(url, key, batch):
    body = json.dumps(batch, ensure_ascii=False).encode("utf-8")
    headers = {
        "apikey": key,
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    }
    if not key.startswith("sb_"):  # legacy JWT keys also go in Authorization
        headers["Authorization"] = f"Bearer {key}"
    req = urllib.request.Request(url, data=body, method="POST", headers=headers)
    for attempt in range(6):
        try:
            with urllib.request.urlopen(req, timeout=120):
                return
        except urllib.error.HTTPError as e:
            if e.code < 500:
                sys.exit(f"HTTP {e.code}: {e.read()[:500].decode(errors='replace')}")
            err = e
        except Exception as e:  # network hiccups: back off and retry
            err = e
        print(f"  retry after error: {err}", file=sys.stderr)
        time.sleep(min(2 ** (attempt + 1), 30))
    sys.exit(f"giving up: {err}")


def upload(recs, batch_size, skip=0):
    base = os.environ.get("SUPABASE_URL", "").rstrip("/")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not base or not key:
        sys.exit("set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY")
    url = f"{base}/rest/v1/foods?on_conflict=id"
    for i in range(skip, len(recs), batch_size):
        post(url, key, recs[i:i + batch_size])
        done = min(i + batch_size, len(recs))
        if done % (batch_size * 20) == 0 or done == len(recs):
            print(f"{done}/{len(recs)} rows")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--csv", help="write a CSV for COPY instead of uploading")
    ap.add_argument("--batch", type=int, default=1000)
    ap.add_argument("--skip", type=int, default=0, help="rows already uploaded (resume)")
    ap.add_argument("--source", help="only rows from this source (curated, mfds_food, mfds_process, estimated)")
    ap.add_argument("--only-estimated", action="store_true",
                    help="only rows whose macros are estimated (after changing estimate())")
    a = ap.parse_args()
    recs = all_records()
    if a.only_estimated:
        recs = [r for r in recs if r["unknown"]]
    if a.source:
        recs = [r for r in recs if r["source"] == a.source]
    print(f"{len(recs)} foods total")
    if a.csv:
        write_csv(recs, a.csv)
    else:
        upload(recs, a.batch, a.skip)


if __name__ == "__main__":
    main()
