"""
Checks diagrams rendered from SysML v2 views in CATIA Magic (tools/cameo-scripts/exportViewDiagrams.groovy output)
against tests/cameo/svg-expectations.json.

Per view:
  EXPORTED   an SVG was written with <text> elements (mode svgTextTags), so names can be read from the file
  MODE       the display mode derived from the view's rendering (TREE, NESTED, UNDEFINED, UNKNOWN) is as expected
  LAYOUT     no two sibling shapes overlap (maxOverlaps, default 0)
  SHAPES     every expected element is drawn as a shape, except those listed in notDrawn; no excluded element is
  LABELS     every expected element appears in the SVG as a declared-name label, and no excluded element does.
             A declared-name label is a text whose declared name is the element name: 'Customer',
             'Customer :> Party', '#primaryKey customerId : Uuid', '#table def CUSTOMER'. Names after ':' or ':>'
             (types) and words inside documentation sentences do not count.
Includes and excludes come from the view's entry or, with predictionId, from tests/cameo/view-predictions.json.

Usage (library): check(export_text, svg_dir) -> report dict;  CLI: python tools/check_view_svg.py export.txt svg_dir
"""
from __future__ import annotations

import html
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXPECTATIONS = ROOT / "tests" / "cameo" / "svg-expectations.json"
PREDICTIONS = ROOT / "tests" / "cameo" / "view-predictions.json"

IDENT = r"[A-Za-z_][A-Za-z0-9_]*"
LABEL_PATTERNS = [
    re.compile(rf"^(?:#{IDENT}\s+|abstract\s+|ref\s+|end\s+|in\s+|out\s+|inout\s+)*def\s+({IDENT})$"),
    re.compile(rf"^(?:#{IDENT}\s+|abstract\s+|ref\s+|end\s+|derived\s+|constant\s+)*({IDENT})\s*(?:\[[^\]]*\])?\s*(?::>>|:>|:)\s*\S.*$"),
    re.compile(rf"^(?:#{IDENT}\s+)*({IDENT})$"),
]


KEYWORDS = {"ref", "end", "in", "out", "inout", "abstract", "derived", "constant", "def", "variation", "individual"}


def declared_name(text: str) -> str | None:
    t = text.strip()
    for pattern in LABEL_PATTERNS:
        m = pattern.match(t)
        if m:
            return None if m.group(1) in KEYWORDS else m.group(1)
    return None


def svg_labels(svg: str) -> set[str]:
    names = set()
    for raw in re.findall(r"<text\b[^>]*>([^<]*)", svg):
        name = declared_name(html.unescape(raw))
        if name:
            names.add(name)
    return names


def parse_export(text: str) -> dict[str, dict]:
    views: dict[str, dict] = {}
    for line in text.splitlines():
        f = line.split("|")
        if len(f) < 2 or f[0] not in ("VIEW", "MODE", "OVERLAP", "ELEM", "SVG", "ERROR"):
            continue
        v = views.setdefault(f[1], {"shapes": set(), "errors": []})
        if f[0] == "VIEW":
            v["found"] = f[2] == "true"
        elif f[0] == "MODE":
            v["mode"] = f[2]
        elif f[0] == "OVERLAP":
            v["overlaps"] = int(f[2])
            v["overlapExamples"] = f[3] if len(f) > 3 else ""
        elif f[0] == "ELEM":
            v["shapes"].add(f[2])
        elif f[0] == "SVG":
            v["svg"], v["svgBytes"], v["svgMode"] = f[2], int(f[3]), f[4] if len(f) > 4 else None
        elif f[0] == "ERROR":
            v["errors"].append("|".join(f[2:]))
    return views


def load_expectations() -> list[dict]:
    spec = json.loads(EXPECTATIONS.read_text(encoding="utf-8"))
    preds = {p["id"]: p for p in json.loads(PREDICTIONS.read_text(encoding="utf-8"))["views"]}
    out = []
    for e in spec["views"]:
        e = dict(e)
        if "predictionId" in e:
            p = preds[e["predictionId"]]
            e.setdefault("includes", p["includes"])
            e.setdefault("excludes", p.get("excludes", []))
        e.setdefault("notDrawn", [])
        e.setdefault("maxOverlaps", spec.get("maxOverlaps", 0))
        out.append(e)
    return out


def check(export_text: str, expectations: list[dict] | None = None) -> dict:
    expectations = expectations if expectations is not None else load_expectations()
    observed = parse_export(export_text)
    results = []
    for e in expectations:
        o = observed.get(e["view"], {"shapes": set(), "errors": ["view not in export output"]})
        problems = list(o.get("errors", []))
        if o.get("found") is False:
            problems.append("view not found in the project")
        if o.get("svgMode") != "svgTextTags":
            problems.append(f"SVG not exported with text tags (mode {o.get('svgMode')})")
        if e.get("mode") and o.get("mode") != e["mode"]:
            problems.append(f"display mode {o.get('mode')}, expected {e['mode']}")
        if o.get("overlaps", 0) > e["maxOverlaps"]:
            problems.append(f"{o.get('overlaps')} overlapping shape pairs (e.g. {o.get('overlapExamples')})")
        labels = set()
        if o.get("svg") and Path(o["svg"]).exists():
            labels = svg_labels(Path(o["svg"]).read_text(encoding="utf-8"))
        drawn_expected = [n for n in e["includes"] if n not in e["notDrawn"]]
        missing_shapes = [n for n in drawn_expected if n not in o["shapes"]]
        missing_labels = [n for n in drawn_expected if n not in labels]
        excluded_shapes = [n for n in e["excludes"] if n in o["shapes"]]
        excluded_labels = [n for n in e["excludes"] if n in labels]
        drawn_anyway = [n for n in e["notDrawn"] if n in o["shapes"]]
        if missing_shapes:
            problems.append(f"not drawn: {missing_shapes}")
        if missing_labels:
            problems.append(f"no label in SVG: {missing_labels}")
        if excluded_shapes or excluded_labels:
            problems.append(f"excluded but drawn: {sorted(set(excluded_shapes + excluded_labels))}")
        if drawn_anyway:
            problems.append(f"expected not drawn but drawn (update notDrawn): {drawn_anyway}")
        results.append({"view": e["view"], "mode": o.get("mode"), "overlaps": o.get("overlaps"),
                        "svgBytes": o.get("svgBytes"), "labels": len(labels), "problems": problems,
                        "passed": not problems})
    return {"passed": bool(results) and all(r["passed"] for r in results), "results": results}


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    report = check(Path(sys.argv[1]).read_text(encoding="utf-8"))
    for r in report["results"]:
        print(f"{'PASS' if r['passed'] else 'FAIL'}  {r['view']}  mode={r['mode']} overlaps={r['overlaps']} "
              f"labels={r['labels']}  {'; '.join(r['problems'])}")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
