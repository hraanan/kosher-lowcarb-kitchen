#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Kitush build script (cross-platform twin of build.ps1).

Merges data/recipes/*.json into template.html and writes book.html + index.html.
Usage:  python build.py   (from the repo root)
"""
import json, glob, os, sys, io

ROOT = os.path.dirname(os.path.abspath(__file__))
CAT_ORDER = ["dairy-vegetarian-mains", "meat-mains", "legumes-grains", "snacks",
             "baking-savory", "baking-sweet", "desserts-dairy", "desserts-pareve"]

def read(path):
    with io.open(path, "r", encoding="utf-8-sig") as f:
        return f.read()

recipes = []
for path in sorted(glob.glob(os.path.join(ROOT, "data", "recipes", "*.json"))):
    arr = json.loads(read(path))
    print("%s: %d recipes" % (os.path.basename(path), len(arr)))
    recipes.extend(arr)

ids = set()
problems = []
for r in recipes:
    if r["id"] in ids:
        problems.append("duplicate id: " + r["id"])
    ids.add(r["id"])
    if r.get("category") not in CAT_ORDER:
        problems.append("%s: bad category" % r["id"])
    n = r.get("nutrition") or {}
    if n.get("netCarbsG", 99) > 20:
        problems.append("%s: net carbs > 20" % r["id"])

print("TOTAL: %d recipes" % len(recipes))
if problems:
    print("PROBLEMS:")
    for p in problems:
        print("  " + p)
    sys.exit(1)

ordered = []
for cat in CAT_ORDER:
    ordered.extend(sorted([r for r in recipes if r["category"] == cat],
                          key=lambda r: (r.get("nutrition") or {}).get("netCarbsG", 99)))

html = read(os.path.join(ROOT, "template.html"))
marker = "/*__DATA__*/[]"
if marker not in html:
    print("template marker missing!"); sys.exit(1)
html = html.replace(marker, json.dumps(ordered, ensure_ascii=False).replace("</", "<\\/"))

supa = os.path.join(ROOT, "data", "supabase-config.json")
if os.path.exists(supa):
    html = html.replace("/*__SUPA__*/null", read(supa).strip())
    print("Injected backend config")

community = os.path.join(ROOT, "data", "community.json")
if os.path.exists(community):
    html = html.replace('id="communityData">{"ratings":{},"submissions":[]}</script>',
                        'id="communityData">' + read(community).strip() + "</script>")

for out in ("book.html", "index.html"):
    with io.open(os.path.join(ROOT, out), "w", encoding="utf-8") as f:
        f.write(html)
    print("Wrote %s (%d KB)" % (out, len(html.encode("utf-8")) // 1024))
