"""
Verify and render the UML3 -> implementation languages, frameworks and platforms map.

Source of truth: traceability/uml3-to-languages.json
Generated doc:   docs/UML3-to-Languages.md

The question the table answers is whether UML3 can describe software that is actually built, so the rows that
matter are the ones that are not COVERED. They are only useful if they say why, which is what SCHEMA enforces.

Checks (each failure is reported and makes the exit code 1):
  SCHEMA    coverage is a known value; every row has an area and a concept; every row that is not COVERED
            carries a note saying what is missing or lost; COVERED rows cite a UML3 construct
  TARGET    every target named on a row is declared in 'targets', and every declared target is used
  UML3      every cited qualified UML3 name (Package::element) exists in library/
  DOC       the committed Markdown equals the rendering of the JSON (run with --write to regenerate)

Usage: python tools/check_languages.py --stdlib <sysml.library> [--write] [--report r.json]
Exit code: 0 ok, 1 findings, 2 tool error.
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_names as cn  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
COVERAGE = ("COVERED", "PARTIAL", "GAP", "TBD")
# Where a gap would be fixed, by the decision procedure of docs/UML3-LAYERING.md. A gap without a layer is an
# unanswered design question, and a specification is judged partly on what it refused to add.
LAYERS = ("language", "library", "metadata", "out-of-scope")

# Every coverage map has the same shape, so they share one checker and one renderer. Adding a map is a data
# file and a line here - not a second copy of this logic, which is how tools/make_omg_doc.py came to drop the
# rationale from every PARTIAL and NOT_ADOPTED row of Annex A.
MAPS = {
    "languages": (ROOT / "traceability" / "uml3-to-languages.json", ROOT / "docs" / "UML3-to-Languages.md"),
    "ddl": (ROOT / "traceability" / "uml3-to-ddl.json", ROOT / "docs" / "UML3-to-DDL.md"),
    "infrastructure": (ROOT / "traceability" / "uml3-to-infrastructure.json",
                       ROOT / "docs" / "UML3-to-Infrastructure.md"),
}


def row_notes(row: dict) -> str:
    """The prose a reader needs for one row. One definition, shared by every renderer."""
    return (row.get("notes") or "").strip()


def check(data: dict, idx: cn.Index | None) -> list[dict]:
    findings: list[dict] = []

    def add(code: str, row: dict, msg: str) -> None:
        findings.append({"code": code, "concept": row.get("concept", "?"), "message": msg})

    declared = {t["id"] for t in data["targets"]}
    used: set[str] = set()
    seen: set[tuple] = set()
    for row in data["rows"]:
        key = (row.get("area"), row.get("concept"))
        if key in seen:
            add("SCHEMA", row, "duplicate row")
        seen.add(key)
        if not row.get("area") or not row.get("concept"):
            add("SCHEMA", row, "every row needs an area and a concept")
        cov = row.get("coverage")
        if cov not in COVERAGE:
            add("SCHEMA", row, f"unknown coverage {cov!r}")
        # the rule this table exists for: a gap that does not say what is missing teaches nobody anything
        if cov in ("PARTIAL", "GAP", "TBD") and not row_notes(row):
            add("SCHEMA", row, f"{cov} requires a note saying what is missing or lost")
        # the accounting docs/UML3-LAYERING.md asks for: a gap must say where it would be fixed, so that the
        # language-layer count stays small and arguable and the library-layer count is just a work list
        layer = row.get("layer")
        if cov in ("PARTIAL", "GAP", "TBD"):
            if not layer:
                add("LAYER", row, f"{cov} requires a layer: one of {', '.join(LAYERS)}")
            elif layer not in LAYERS:
                add("LAYER", row, f"unknown layer {layer!r}")
        if cov == "COVERED" and layer:
            add("LAYER", row, "COVERED rows need no layer; it is already covered")
        if cov == "COVERED" and not row.get("uml3"):
            add("SCHEMA", row, "COVERED requires the UML3 construct to be named")
        for target in (row.get("targets") or {}):
            used.add(target)
            if target not in declared:
                add("TARGET", row, f"target {target!r} is not declared in 'targets'")
        for name in row.get("uml3", []):
            # entries are either qualified UML3 names or prose such as 'KerML multiplicity [0..1]'
            if "::" in name and idx is not None and idx.lookup(name) is None:
                add("UML3", row, f"UML3 element {name} not found in library/")
    for target in sorted(declared - used):
        findings.append({"code": "TARGET", "concept": "-", "message": f"declared target {target!r} is never used"})
    return findings


def cell(text: str) -> str:
    return (text or "").replace("|", "\\|").replace("\n", " ").strip() or "—"


def render(data: dict) -> str:
    rows = data["rows"]
    counts = Counter(r["coverage"] for r in rows)
    targets = data["targets"]
    out = [f"# {data['title']}", "",
           "<!-- GENERATED by tools/check_languages.py from traceability/uml3-to-languages.json."
           " Do not edit by hand. -->", "",
           data["description"], "", "## Coverage legend", ""]
    out += [f"* **{k}**: {v}" for k, v in data["coverageLegend"].items()]
    out += ["", "## Targets", "", "| Target | Version | Evidence |", "|---|---|---|"]
    out += [f"| {cell(t['name'])} | {cell(t['version'])} | {cell(t.get('evidence', ''))} |" for t in targets]
    out += ["", data["versionBasis"], "", "## Summary", "", "| Coverage | Concepts |", "|---|---|"]
    out += [f"| {k} | {counts.get(k, 0)} |" for k in COVERAGE]
    out += [f"| **Total** | **{len(rows)}** |", ""]
    layers = Counter(r["layer"] for r in rows if r.get("layer"))
    if layers:
        out += ["Where the rows that are not COVERED would be fixed "
                "(see [UML3-LAYERING.md](UML3-LAYERING.md)):", "",
                "| Layer | Concepts |", "|---|---|"]
        out += [f"| {k} | {layers[k]} |" for k in LAYERS if layers.get(k)]
        out += [""]

    header = "| Concept | Coverage | Layer | UML3 | " + " | ".join(t["name"] for t in targets) + " | Notes |"
    sep = "|---" * (4 + len(targets) + 1) + "|"
    for area in dict.fromkeys(r["area"] for r in rows):
        out += [f"## {area}", "", header, sep]
        for r in (x for x in rows if x["area"] == area):
            cells = [cell(r["concept"]), f"**{r['coverage']}**", cell(r.get("layer") or "NA"),
                     cell(", ".join(f"`{n}`" for n in r.get("uml3", [])))]
            cells += [cell((r.get("targets") or {}).get(t["id"]) or "NA") for t in targets]
            cells.append(cell(row_notes(r)))
            out.append("| " + " | ".join(cells) + " |")
        out.append("")
    return "\n".join(out) + "\n"


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", default="all", choices=["all", *sorted(MAPS)], help="which coverage map to check")
    ap.add_argument("--stdlib", help="sysml.library, so cited UML3 names can be resolved")
    ap.add_argument("--write", action="store_true", help="regenerate the Markdown")
    ap.add_argument("--report")
    args = ap.parse_args(argv)

    idx = None
    if args.stdlib:
        idx = cn.Index()
        for f in cn.collect([args.stdlib], (".sysml", ".kerml")) + cn.collect([str(ROOT / "library")], (".sysml",)):
            idx.add(cn.index_file(f))
        idx.finalize()

    selected = sorted(MAPS) if args.map == "all" else [args.map]
    all_findings: list[dict] = []
    per_map: dict[str, dict] = {}
    for name in selected:
        data_path, doc_path = MAPS[name]
        if not data_path.exists():
            all_findings.append({"code": "SCHEMA", "concept": "-", "message": f"{data_path.name} is missing"})
            continue
        data = json.loads(data_path.read_text(encoding="utf-8"))
        findings = [dict(f, map=name) for f in check(data, idx)]

        rendered = render(data)
        if args.write:
            doc_path.write_text(rendered, encoding="utf-8")
        elif not doc_path.exists() or doc_path.read_text(encoding="utf-8") != rendered:
            findings.append({"code": "DOC", "concept": "-", "map": name,
                             "message": f"{doc_path.name} is out of date; run with --write"})

        counts = Counter(r["coverage"] for r in data["rows"])
        per_map[name] = {"rows": len(data["rows"]), "counts": dict(counts), "findings": findings}
        all_findings += findings
        for f in findings:
            print(f"{f['code']:7s} {name:15s} {f['concept'][:36]:38s} {f['message']}")
        print(f"MAP {name:15s} rows={len(data['rows']):3d} "
              + " ".join(f"{k}={counts.get(k, 0)}" for k in COVERAGE) + f" findings={len(findings)}")

    print(f"SUMMARY maps={len(per_map)} rows={sum(m['rows'] for m in per_map.values())} "
          f"findings={len(all_findings)}")
    if args.report:
        Path(args.report).write_text(json.dumps({"maps": per_map, "findings": all_findings}, indent=2),
                                     encoding="utf-8")
    return 1 if all_findings else 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except Exception as exc:  # pragma: no cover
        print(f"TOOL ERROR: {exc!r}", file=sys.stderr)
        sys.exit(2)
