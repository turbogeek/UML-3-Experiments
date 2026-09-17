"""
Keyword reference generator: docs/UML3-Keywords.md from the libraries.

Every UML3 keyword metadata definition carries two names (see DESIGN.md, "Naming rules"):

    metadata def <classType> cls :> SemanticMetadata { :>> baseType = classes meta SysML::Usage; }

the SHORT name is the keyword, which is what a modeler writes and what CATIA Magic shows on a shape
(«#classType», E21), and the DECLARED name is a terse id where one saves at least three characters
('#cls'), otherwise a descriptive name ('QueryMetadata'). Both spellings resolve to the same definition,
so the reference table lists them side by side.

Usage:
  python check_keywords.py [--write] [--report r.json]
Exit code: 0 = the document matches the libraries, 1 = out of date (run with --write), 2 = tool error.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIBRARY = ROOT / "library"
DOC = ROOT / "docs" / "UML3-Keywords.md"
ORDER = ["UML3Core", "UML3Components", "UML3Data", "UML3Messaging", "UML3Types", "UML3IDL", "UML3Views"]

DEF_RE = re.compile(r"(?m)^\t(abstract )?metadata def (?:<(\w+)> )?(\w+)([^{;]*)\{")


def keywords(text: str) -> list[dict]:
    """Every keyword metadata def of one library file, in declaration order."""
    out = []
    for m in DEF_RE.finditer(text):
        if m.group(1) or not m.group(2):  # categories and plain valued metadata are not written as keywords
            continue
        body = _body(text, m.end() - 1)
        base = re.search(r":>> baseType = ([\w:]+) meta", body)
        # the doc body is written either as 'doc /* one line */' or as 'doc' + an indented /* block */
        doc = re.search(r"doc\s*/\*(.*?)\*/", body, re.S)
        sentence = re.sub(r"\s+", " ", doc.group(1)).strip() if doc else ""
        sentence = re.sub(r"^Keyword #\w+ ?(\([^)]*\))?: ?", "", sentence).split(". ")[0].rstrip(".")
        out.append({"keyword": m.group(2), "id": m.group(3), "supers": m.group(4).strip(" :>,"),
                    "base": base.group(1) if base else "", "doc": sentence})
    return out


def _body(text: str, brace: int) -> str:
    depth, i = 0, brace
    while i < len(text):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[brace + 1:i]
        i += 1
    return text[brace:]


def render(per_library: dict[str, list[dict]]) -> str:
    lines = ["# UML3 keywords", "",
             "Generated from `library/*.sysml` by `tools/check_keywords.py`; do not edit by hand.", "",
             "Every keyword has two spellings, and they mean exactly the same thing:", "",
             "```sysml",
             "#classType item def Customer;   // the keyword: what diagrams show («#classType»)",
             "#cls item def Customer;         // the terse id: the same definition, fewer keystrokes",
             "```", "",
             "A terse id exists only where it saves at least three characters; the other keywords are already "
             "short (`#id`, `#uses`, `#table`). Both names also work in the body form (`@classType { ... }`), in "
             "view filters and in queries. `tools/check_rules.py` R16 keeps the two slots in this order.", ""]
    total, ids = 0, 0
    for lib in ORDER:
        rows = per_library.get(lib, [])
        if not rows:
            continue
        lines += [f"## {lib}", "", "| Keyword | Terse id | Base | Meaning |", "|---|---|---|---|"]
        for r in rows:
            total += 1
            terse = f"`#{r['id']}`" if r["id"][:1].islower() else ""
            ids += 1 if terse else 0
            # dependency keywords bind no base: they mark a dependency and are grouped by their category
            base = f"`{r['base']}`" if r["base"] else (f"({r['supers']})" if r["supers"]
                                                       else "(plain metadata)")
            lines.append(f"| `#{r['keyword']}` | {terse} | {base} | {r['doc']} |")
        lines.append("")
    lines += [f"{total} keywords, {ids} with a terse id.", ""]
    return "\n".join(lines)


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--report")
    args = ap.parse_args(argv)

    per_library = {}
    for f in sorted(LIBRARY.glob("*.sysml")):
        text = f.read_text(encoding="utf-8")
        pkg = re.search(r"(?m)^(?:standard )?(?:library )?package (\w+)", text)
        rows = keywords(text)
        if pkg and rows:
            per_library[pkg.group(1)] = rows
    unknown = sorted(set(per_library) - set(ORDER))
    if unknown:
        print(f"ERROR unknown library package(s) {unknown}: add them to ORDER", file=sys.stderr)
        return 2

    doc = render(per_library)
    current = DOC.read_text(encoding="utf-8").replace("\r\n", "\n") if DOC.exists() else ""
    findings = []
    if doc != current:
        if args.write:
            DOC.write_bytes(doc.encode("utf-8"))
            print(f"wrote {DOC}")
        else:
            findings.append({"code": "DOC", "message": f"docs/{DOC.name} is not up to date (run with --write)"})
    counts = {lib: len(rows) for lib, rows in per_library.items()}
    if args.report:
        Path(args.report).write_text(json.dumps({"counts": counts, "findings": findings}, indent=1) + "\n",
                                     encoding="utf-8")
    total = sum(counts.values())
    terse = sum(1 for rows in per_library.values() for r in rows if r["id"][:1].islower())
    print(f"SUMMARY keywords={total} terseIds={terse} libraries={len(counts)} findings={len(findings)}")
    for f in findings:
        print(f"  {f['code']}  {f['message']}")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
