"""
Checks that the UML3 diagram-kind model, the view filters and the tool palettes say the same thing (issue I-35).

library/UML3DiagramKinds.sysml records per diagram kind which keywords a view shows ('shows'), which keywords a
palette creates ('creates') and which view definitions render it ('views'). This checker reports:

  SHOWS     a view definition listed by a kind whose filter does not select exactly the kind's 'shows' keywords
  CREATES   a palette (annotated '@PaletteForDiagramKind { kind = ... }') whose buttons do not create exactly the
            kind's 'creates' keywords; a templated button's keyword is the keyword of the element its template owns
  ORPHAN    a view definition in UML3Views that no kind lists, or a palette without the annotation
  MODEL     a name in the model, a filter or a template that does not resolve to a metadata definition

Usage:
  python tools/check_diagram_kinds.py [--kinds F] [--views F] [--palettes F] [--templates F] [--report R]
Defaults are the repository files. Exit code: 0 consistent, 1 differences, 2 tool error.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_names as cn  # noqa: E402

KINDS = ROOT / "library" / "UML3DiagramKinds.sysml"
VIEWS = ROOT / "library" / "UML3Views.sysml"
PALETTES = ROOT / "customization" / "catia-magic" / "UML3CatiaMagic.sysml"
STUB = ROOT / "tests" / "catia-magic"


def build_index(stdlib: Path) -> cn.Index:
    idx = cn.Index()
    for f in cn.collect([str(stdlib)], (".sysml", ".kerml")):
        idx.add(cn.index_file(f))
    for f in cn.collect([str(ROOT / "library"), str(STUB)], (".sysml",)):
        idx.add(cn.index_file(f))
    idx.finalize()
    return idx


def resolve(name: str, idx: cn.Index) -> str:
    """Canonical qualified name of a keyword or metaclass written in a model, filter or template."""
    if "::" in name:
        return name
    cands = [c for c in idx.metadata_defs(name) if c.qname.startswith("UML3")] or idx.metadata_defs(name)
    if len(cands) == 1:
        return cands[0].qname
    scope = idx.lookup(name, "UML3Core") or idx.lookup(name)
    return scope.qname if scope is not None else name


def parse_kinds(path: Path, idx: cn.Index) -> dict[str, dict]:
    text = path.read_text(encoding="utf-8")
    kinds: dict[str, dict] = {}
    for m in re.finditer(r"\n\tpart (\w+) : DiagramKind \{(.*?)\n\t\}", text, re.S):
        name, body = m.group(1), m.group(2)
        body = re.sub(r"/\*.*?\*/", "", body, flags=re.S)  # documentation is not data
        entry = {"label": None, "shows": set(), "creates": set(), "views": set()}
        label = re.search(r':>> label = "([^"]*)"', body)
        entry["label"] = label.group(1) if label else None
        for role in ("shows", "creates", "views"):
            b = re.search(rf":>> {role} = \((.*?)\);", body, re.S)
            if not b:
                continue
            entry[role] = {resolve(x, idx) for x in re.findall(r"([\w:]+) meta ", b.group(1))}
        kinds[name] = entry
    return kinds


def parse_view_filters(path: Path, idx: cn.Index) -> dict[str, set[str]]:
    text = path.read_text(encoding="utf-8")
    # the package declaration may be preceded by a comment, so search for it rather than matching the first line
    pkg = re.search(r"(?m)^\s*(?:standard\s+)?(?:library\s+)?package\s+(\w+)", text)
    prefix = (pkg.group(1) + "::") if pkg else ""
    views: dict[str, set[str]] = {}
    for m in re.finditer(r"\n\tview def (?:<\w+> )?(\w+)[^{]*\{(.*?)\n\t\}", text, re.S):
        body = re.sub(r"/\*.*?\*/", "", m.group(2), flags=re.S)
        views[prefix + m.group(1)] = {resolve(s, idx) for s in re.findall(r"@([\w:]+)", body)}
    return views


def parse_palettes(path: Path, idx: cn.Index) -> dict[str, dict]:
    """Palette definitions with their diagram kind and the keywords their templated buttons create."""
    text = path.read_text(encoding="utf-8")
    # template packages are collected by brace matching, because a template body can be several lines deep
    templates: dict[str, set[str]] = {}
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        m = re.match(r"\s*package (\w+Template) \{", lines[i])
        if m:
            depth, body, j = 0, [], i
            while j < len(lines):
                depth += lines[j].count("{") - lines[j].count("}")
                body.append(lines[j])
                j += 1
                if depth <= 0:
                    break
            templates[m.group(1)] = {resolve(k, idx) for k in re.findall(r"#(\w+)\b", "\n".join(body))}
            i = j
            continue
        i += 1
    palettes: dict[str, dict] = {}
    for m in re.finditer(r"\n\tpart def (\w+Palette) :> (\w+) \{(.*?)\n\t\}", text, re.S):
        name, body = m.group(1), m.group(3)
        kind = re.search(r"@PaletteForDiagramKind \{ kind = UML3DiagramKinds::(\w+) meta", body)
        keywords: set[str] = set()
        for t in re.findall(r"UML3ElementTemplates::(\w+Template) meta", body):
            keywords |= templates.get(t, set())
        palettes[name] = {"kind": kind.group(1) if kind else None, "creates": keywords,
                          "templates": sorted(set(re.findall(r"UML3ElementTemplates::(\w+Template) meta", body)))}
    return palettes


def check(kinds: dict, views: dict, palettes: dict) -> dict:
    problems: list[str] = []
    listed_views = {v for k in kinds.values() for v in k["views"]}
    for name, kind in kinds.items():
        for view in sorted(kind["views"]):
            selectors = views.get(view)
            if selectors is None:
                problems.append(f"MODEL  {name}: view definition {view} does not exist")
                continue
            missing = sorted(kind["shows"] - selectors)
            extra = sorted(selectors - kind["shows"])
            if missing:
                problems.append(f"SHOWS  {view}: filter does not select {missing} (listed by {name}::shows)")
            if extra:
                problems.append(f"SHOWS  {view}: filter selects {extra}, which {name}::shows does not list")
    for view in sorted(views):
        if view not in listed_views:
            problems.append(f"ORPHAN {view}: no diagram kind lists this view definition")
    for name, palette in sorted(palettes.items()):
        if palette["kind"] is None:
            problems.append(f"ORPHAN {name}: no @PaletteForDiagramKind annotation")
            continue
        kind = kinds.get(palette["kind"])
        if kind is None:
            problems.append(f"MODEL  {name}: diagram kind {palette['kind']} does not exist")
            continue
        missing = sorted(kind["creates"] - palette["creates"])
        extra = sorted(palette["creates"] - kind["creates"])
        if missing:
            problems.append(f"CREATES {name}: no button creates {missing} (listed by {palette['kind']}::creates)")
        if extra:
            problems.append(f"CREATES {name}: buttons create {extra}, which {palette['kind']}::creates does not list")
    return {"passed": not problems, "kinds": {k: {r: sorted(v[r]) for r in ("shows", "creates", "views")}
                                              for k, v in kinds.items()},
            "palettes": {k: {"kind": v["kind"], "creates": sorted(v["creates"])} for k, v in palettes.items()},
            "problems": problems}


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--kinds", default=str(KINDS))
    ap.add_argument("--views", default=str(VIEWS))
    ap.add_argument("--palettes", default=str(PALETTES))
    ap.add_argument("--stdlib", default=str(ROOT.parent / "SysML-v2-Release" / "sysml.library"))
    ap.add_argument("--report")
    args = ap.parse_args(argv)

    idx = build_index(Path(args.stdlib))
    kinds = parse_kinds(Path(args.kinds), idx)
    if not kinds:
        print(f"TOOL ERROR: no diagram kinds parsed from {args.kinds}", file=sys.stderr)
        return 2
    views = parse_view_filters(Path(args.views), idx)
    palettes = parse_palettes(Path(args.palettes), idx)
    report = check(kinds, views, palettes)
    for p in report["problems"]:
        print(p)
    print(f"SUMMARY kinds={len(kinds)} views={len(views)} palettes={len(palettes)} "
          f"problems={len(report['problems'])}")
    if args.report:
        Path(args.report).parent.mkdir(parents=True, exist_ok=True)
        Path(args.report).write_text(json.dumps(report, indent=2), encoding="utf-8")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except Exception as exc:
        import traceback
        (ROOT / "logs").mkdir(exist_ok=True)
        (ROOT / "logs" / "check-diagram-kinds-error.log").write_text(traceback.format_exc(), encoding="utf-8")
        print(f"TOOL ERROR: {exc!r} (see logs/check-diagram-kinds-error.log)", file=sys.stderr)
        sys.exit(2)
