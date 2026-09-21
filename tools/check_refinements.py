"""
Checks how the SysUML and UML3 requirements answer an external requirement set, such as a request for proposals,
and renders the coverage matrix.

External set (--external): requirement and concern usages with a short name; concerns may nest:
    requirement <'X-1'> name : SomeRequirementDef { doc /* statement */ @Priority { level = PriorityKind::mandatory; } }
    concern <'X-2'> name { doc /* question */ concern <'X-2.1'> followUp { doc /* ... */ } }
Answers (--refinements): dependencies from requirements of requirements/ to items of the external set, each in a
package that carries '@AppliesTo { implementations = ...; }' for the implementations its source requirements bind:
    #refinement dependency from UML3StructureRequirements::'UML3-STR-001' to 'X-1';     (ModelingMetadata::Refinement)
    #deviation dependency from UML3ImplementationRequirements::'UML3-IMPL-010' to 'X-1';  (UML3Requirements::Deviation)
Named comments about external items in those files are rendered as notes. The satisfy and allocate relationships of
the requirements in the --architecture files extend each answer to the parts responsible for it.

  FORM      external ids are unique; every external item has a doc; every external requirement has a @Priority
  RESOLVE   every source is a requirement of requirements/ and every target an item of the external set; in a
            qualified name the segment before the id names the element's package (or, when nested, its parent)
  GROUP     the @AppliesTo of the package holding a dependency equals the AppliesTo of each source requirement
  COVERAGE  a mandatory external requirement without a refinement or deviation is an error, an optional one a warning
  DOC       the committed matrix equals the rendering (--doc; --write regenerates it)

Usage: python tools/check_refinements.py --external F... --refinements F... [--architecture F...]
                                         [--doc OUT [--write]] [--title T] [--report r.json] [--stdlib DIR]
Exit code: 0 ok, 1 findings, 2 tool error (also when the external set or the dependencies are empty).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_requirements as cr  # noqa: E402
from check_docs import lex  # noqa: E402

ROOT = cr.ROOT
IMPLEMENTATIONS = ["SysUML", "UML3"]
KIND_NAMES = {"sysUML": "SysUML", "uml3": "UML3"}
DEPENDENCY_KINDS = ("refinement", "deviation")
STATUS_RANK = {s: i for i, s in enumerate(["done", "tbc", "open", "tbd", "tbr", "closed"])}


def spans(toks: list) -> list[tuple[int, int, list]]:
    """Every '{...}' as (open index, close index, head), the head being the tokens of the statement before '{'."""
    out, stack = [], []
    for i, t in enumerate(toks):
        if t[1] == "{":
            m = i - 1
            while m >= 0 and toks[m][1] not in (";", "{", "}"):
                m -= 1
            stack.append((i, toks[m + 1:i]))
        elif t[1] == "}" and stack:
            o, head = stack.pop()
            out.append((o, i, head))
    return sorted(out)


def enclosing(sps: list, idx: int, pick=lambda sp: True):
    """The innermost span around token idx that satisfies pick, or None."""
    best = None
    for sp in sps:
        if sp[0] < idx < sp[1] and pick(sp) and (best is None or sp[0] > best[0]):
            best = sp
    return best


def head_item(head: list) -> tuple[str, str, str | None, int] | None:
    """(kind, id, name, line) when the head declares "requirement <'id'> name" or "concern <'id'> name"."""
    vals = [t[1] for t in head]
    for k, v in enumerate(vals):
        if (v in ("requirement", "concern") and head[k][0] == "ident" and vals[k + 1:k + 2] == ["<"]
                and k + 3 < len(vals) and head[k + 2][0] == "qname" and vals[k + 3] == ">"):
            name = vals[k + 4] if k + 4 < len(vals) and head[k + 4][0] == "ident" else None
            return v, vals[k + 2].strip("'"), name, head[k][2]
    return None


def head_word(head: list, word: str) -> str | None:
    """The name after the keyword word in a head ('package P', 'part p : T'), or None."""
    for k, t in enumerate(head[:-1]):
        if t[1] == word and t[0] == "ident" and head[k + 1][0] in ("ident", "qname"):
            return head[k + 1][1].strip("'")
    return None


def names_until(toks: list, j: int, stops: tuple) -> tuple[list[str], int]:
    """Reads a comma-separated list of (qualified or chained) names up to a stop value or a comment token."""
    names, cur = [], ""
    while j < len(toks) and toks[j][1] not in stops and toks[j][0] != "comment":
        if toks[j][1] == ",":
            names.append(cur)
            cur = ""
        else:
            cur += toks[j][1]
        j += 1
    if cur:
        names.append(cur)
    return names, j


def segments(qname: str) -> list[str]:
    return [s.strip("'") for s in qname.split("::")]


def comment_text(val: str) -> str:
    return " ".join(l.strip() for l in val[2:-2].strip().splitlines()).strip()


def parse_external(files: list[Path], add) -> tuple[dict, list]:
    """External items by id, and the external packages in file order as (name, doc, file)."""
    items: dict[str, dict] = {}
    packages: list[tuple[str, str, str]] = []
    for f in files:
        toks = lex(f.read_text(encoding="utf-8"))
        sps = spans(toks)
        item_spans = {sp[0]: head_item(sp[2]) for sp in sps if head_item(sp[2])}
        for sp in sps:
            pkg = head_word(sp[2], "package")
            if pkg:
                packages.append((pkg, cr.doc_text(toks, (sp[0] + 1, sp[1])) or "", f.name))
        for sp in sps:
            decl = item_spans.get(sp[0])
            if not decl:
                continue
            kind, iid, name, line = decl
            children = [c for c in sps if c[0] in item_spans and sp[0] < c[0] < sp[1]]
            own = [toks[k][1] for k in range(sp[0] + 1, sp[1]) if not any(c[0] <= k <= c[1] for c in children)]
            src = " ".join(own)
            mm = re.search(r"@ Priority \{ level = PriorityKind : : (\w+)", src)
            parent = enclosing(sps, sp[0], lambda s: s[0] in item_spans)
            pkg = enclosing(sps, sp[0], lambda s: head_word(s[2], "package") is not None)
            item = {"id": iid, "name": name, "kind": kind, "file": f.name, "line": line,
                    "package": head_word(pkg[2], "package") if pkg else None,
                    "parent": item_spans[parent[0]][1] if parent else None,
                    "parentName": item_spans[parent[0]][2] if parent else None,
                    "statement": cr.doc_text(toks, (sp[0] + 1, sp[1])) or "",
                    "priority": mm.group(1) if mm else None}
            if iid in items:
                add("FORM", f.name, line, f"duplicate external id '{iid}' (also {items[iid]['file']}:{items[iid]['line']})")
            if not item["statement"]:
                add("FORM", f.name, line, f"external item '{iid}' has no doc")
            if kind == "requirement" and not item["priority"]:
                add("FORM", f.name, line, f"external requirement '{iid}' has no @Priority")
            items[iid] = item
    return items, packages


def parse_answers(files: list[Path], add) -> tuple[list, list]:
    """Refinement and deviation dependencies with the implementations of their package, and named comments."""
    deps, notes = [], []
    for f in files:
        toks = lex(f.read_text(encoding="utf-8"))
        sps = spans(toks)
        applies: dict[int, set[str]] = {}
        for sp in sps:
            if [t[1] for t in sp[2][-2:]] == ["@", "AppliesTo"]:
                owner = enclosing(sps, sp[0])
                if owner and head_word(owner[2], "package"):
                    kinds = re.findall(r"ImplementationKind : : (\w+)", " ".join(t[1] for t in toks[sp[0]:sp[1]]))
                    applies[owner[0]] = {KIND_NAMES.get(k, k) for k in kinds}
        for i in range(len(toks) - 2):
            if toks[i][1] == "#" and toks[i + 1][1] in DEPENDENCY_KINDS and toks[i + 2][1] == "dependency":
                line = toks[i][2]
                k = i + 3
                while k < len(toks) and toks[k][1] not in ("from", "to", ";", "{"):
                    k += 1
                j = k + 1 if k < len(toks) and toks[k][1] == "from" else i + 3
                sources, j = names_until(toks, j, ("to", ";", "{"))
                if j >= len(toks) or toks[j][1] != "to":
                    add("RESOLVE", f.name, line, "dependency without 'to'")
                    continue
                targets, _ = names_until(toks, j + 1, (";", "{"))
                pkg = enclosing(sps, i, lambda s: head_word(s[2], "package") is not None)
                deps.append({"kind": toks[i + 1][1], "sources": sources, "targets": targets, "file": f.name,
                             "line": line, "package": head_word(pkg[2], "package") if pkg else None,
                             "implementations": sorted(applies[pkg[0]]) if pkg and pkg[0] in applies else None})
        for i, t in enumerate(toks):
            if t[1] != "comment" or t[0] != "ident":
                continue
            j = i + 1
            name = None
            if j < len(toks) and toks[j][0] in ("ident", "qname") and toks[j][1] != "about":
                name = toks[j][1].strip("'")
                j += 1
            if j >= len(toks) or toks[j][1] != "about":
                continue
            about, j = names_until(toks, j + 1, (";",))
            if j < len(toks) and toks[j][0] == "comment":
                notes.append({"name": name, "about": about, "text": comment_text(toks[j][1]), "file": f.name,
                              "line": t[2]})
    return deps, notes


def parse_architecture(files: list[Path], req_ids: set[str]) -> dict[str, list[dict]]:
    """For each requirement id: the satisfy and allocate relationships to it, with the owning part's name."""
    out: dict[str, list[dict]] = defaultdict(list)
    for f in files:
        toks = lex(f.read_text(encoding="utf-8"))
        sps = spans(toks)
        for i, t in enumerate(toks):
            if t[0] != "ident" or t[1] not in ("satisfy", "allocate"):
                continue
            j = i + 1 + (toks[i + 1][1] == "requirement")
            sep = "by" if t[1] == "satisfy" else "to"
            sources, j = names_until(toks, j, (sep, ";", "{"))
            if j >= len(toks) or toks[j][1] != sep:
                continue
            targets, _ = names_until(toks, j + 1, (";", "{"))
            owner = enclosing(sps, i, lambda s: head_word(s[2], "part") is not None)
            prefix = head_word(owner[2], "part") + "." if owner else ""
            for s in sources:
                rid = segments(s)[-1]
                if rid in req_ids:
                    out[rid] += [{"relation": t[1], "target": prefix + x, "file": f.name, "line": t[2]} for x in targets]
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--external", nargs="+", required=True)
    ap.add_argument("--refinements", nargs="+", required=True)
    ap.add_argument("--architecture", nargs="*", default=[])
    ap.add_argument("--doc")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--title", default="Refinement of an external requirement set")
    ap.add_argument("--report")
    ap.add_argument("--stdlib", default=str(cr.RELEASE / "sysml.library"))
    args = ap.parse_args()

    findings: list[dict] = []

    def add(code, file, line, msg, severity="error"):
        findings.append({"code": code, "severity": severity, "file": file, "line": line, "message": msg})

    try:
        reqs, _, _, req_findings = cr.analyze(args.stdlib)
    except cr.ToolError as e:
        print(f"TOOL ERROR: {e}", file=sys.stderr)
        return 2
    if any(x["severity"] == "error" for x in req_findings):
        print("TOOL ERROR: requirements/ has errors; run tools/check_requirements.py first", file=sys.stderr)
        return 2
    ext_files = [Path(p) for p in args.external]
    ans_files = [Path(p) for p in args.refinements]
    arch_files = [Path(p) for p in args.architecture]
    missing = [str(p) for p in ext_files + ans_files + arch_files if not p.is_file()]
    if missing:
        print("TOOL ERROR: missing " + ", ".join(missing), file=sys.stderr)
        return 2

    items, packages = parse_external(ext_files, add)
    deps, notes = parse_answers(ans_files, add)
    if not items or not deps:
        print(f"TOOL ERROR: found {len(items)} external items and {len(deps)} dependencies; both must be non-empty",
              file=sys.stderr)
        return 2
    arch = parse_architecture(arch_files, set(reqs))

    answers: dict[str, list[dict]] = defaultdict(list)   # external id -> answers
    for d in deps:
        if d["implementations"] is None:
            add("GROUP", d["file"], d["line"], f"#{d['kind']} dependency in package {d['package']}, which has no @AppliesTo")
        sources = []
        for s in d["sources"]:
            segs = segments(s)
            r = reqs.get(segs[-1])
            if r is None:
                add("RESOLVE", d["file"], d["line"], f"source '{s}' is not a requirement of requirements/")
                continue
            if len(segs) > 1 and segs[-2] != r["package"]:
                add("RESOLVE", d["file"], d["line"], f"source '{s}' is in package {r['package']}, not {segs[-2]}")
            if d["implementations"] is not None and sorted(r["appliesTo"]) != d["implementations"]:
                add("GROUP", d["file"], d["line"],
                    f"{r['id']} applies to {', '.join(r['appliesTo'])}, but package {d['package']} states "
                    f"{', '.join(d['implementations'])}")
            sources.append(r)
        for t in d["targets"]:
            segs = segments(t)
            item = items.get(segs[-1])
            if item is None:
                add("RESOLVE", d["file"], d["line"], f"target '{t}' is not an item of the external set")
                continue
            if len(segs) > 1 and segs[-2] not in (item["package"], item["parent"], item["parentName"]):
                add("RESOLVE", d["file"], d["line"], f"target '{t}' is in {item['parent'] or item['package']}, not {segs[-2]}")
            for r in sources:
                answers[item["id"]].append({"kind": d["kind"], "requirement": r["id"], "status": r["status"],
                                            "appliesTo": r["appliesTo"], "realizedBy": r.get("realizedBy", []),
                                            "architecture": arch.get(r["id"], [])})
    notes_by_item: dict[str, list[dict]] = defaultdict(list)
    for n in notes:
        for a in n["about"]:
            iid = segments(a)[-1]
            if iid in items:
                notes_by_item[iid].append(n)

    for iid, item in items.items():
        item["answers"] = answers.get(iid, [])
        item["notes"] = [n["name"] for n in notes_by_item.get(iid, [])]
        if item["kind"] == "requirement" and item["priority"] in ("mandatory", "optional") and not item["answers"]:
            add("COVERAGE", item["file"], item["line"], f"{item['priority']} external requirement '{iid}' is neither "
                "refined nor deviated from", "error" if item["priority"] == "mandatory" else "warning")

    doc_names = sorted({p.name for p in ext_files}) + sorted({p.name for p in ans_files})
    markdown = render(args.title, doc_names, items, packages, notes)
    if args.doc:
        doc = Path(args.doc)
        if args.write:
            doc.write_text(markdown, encoding="utf-8")
        elif not doc.exists() or doc.read_text(encoding="utf-8") != markdown:
            add("DOC", doc.name, 0, f"{doc.name} is not up to date (run with --write)")

    errors = [x for x in findings if x["severity"] == "error"]
    warnings = [x for x in findings if x["severity"] == "warning"]
    for x in findings:
        print(f"{x['severity'].upper():7} {x['code']:9} {x['file']}:{x['line']}: {x['message']}")
    kinds = Counter(d["kind"] for d in deps)
    covered = {impl: sum(1 for it in items.values() if any(impl in a["appliesTo"] for a in it["answers"]))
               for impl in IMPLEMENTATIONS}
    print(f"SUMMARY items={len(items)} dependencies={dict(kinds)} answered={covered} "
          f"unanswered={sum(1 for it in items.values() if not it['answers'])} errors={len(errors)} warnings={len(warnings)}")
    if args.report:
        Path(args.report).write_text(json.dumps({"items": items, "dependencies": deps, "notes": notes,
                                                 "findings": findings}, indent=2), encoding="utf-8")
    return 1 if errors else 0


def cell(s: str | None) -> str:
    return (s or "").replace("|", "\\|").replace("\n", " ")


def answer_cell(answers: list[dict], impl: str) -> str:
    rows = sorted({(a["requirement"], a["status"], a["kind"]) for a in answers if impl in a["appliesTo"]},
                  key=lambda x: (x[2] != "refinement", STATUS_RANK.get(x[1], 9), x[0]))
    return "<br>".join(f"{rid} ({status})" + (" *deviates*" if kind == "deviation" else "") for rid, status, kind in rows) or "–"


def implemented_cell(answers: list[dict]) -> str:
    refs = [a for a in answers if a["kind"] == "refinement"]
    elements = sorted({e for a in refs for e in a["realizedBy"]})
    parts = sorted({f"{x['target']} ({x['relation']})" for a in refs for x in a["architecture"]})
    return cell(", ".join(f"`{e}`" for e in elements + parts)) or "–"


def render(title: str, sources: list[str], items: dict, packages: list, notes: list) -> str:
    out = [f"# {title}", "",
           f"Generated from `{'`, `'.join(sources)}` by `tools/check_refinements.py --write`; do not edit.", "",
           "A requirement of this project **refines** an external requirement when it states it more precisely "
           "(`#refinement`, SysML v2 ModelingMetadata) and **deviates** from it when it answers it differently "
           "(`#deviation`, UML3Requirements). Answers are listed under the implementation that their requirement "
           "applies to: **SysUML**, the SysML v2-based implementation in use, and **UML3**, the KerML-based language "
           "planned next; a requirement that applies to both appears in both columns. *Implemented by* follows the "
           "refining requirements to the elements that realize them and to the parts that satisfy them or are "
           "allocated them.", ""]
    pkg_order = [p[0] for p in packages]
    by_pkg: dict[str, list[dict]] = defaultdict(list)
    for it in items.values():
        by_pkg[it["package"]].append(it)
    out += ["## Summary", "",
            "| Section | Items | Mandatory | Optional | Concerns | Answered for SysUML | Answered for UML3 | "
            "With a deviation | Unanswered |", "|---|---|---|---|---|---|---|---|---|"]
    totals = Counter()
    for pkg in pkg_order:
        its = by_pkg.get(pkg, [])
        if not its:
            continue
        row = Counter(items=len(its),
                      mandatory=sum(1 for i in its if i["priority"] == "mandatory"),
                      optional=sum(1 for i in its if i["priority"] == "optional"),
                      concerns=sum(1 for i in its if i["kind"] == "concern"),
                      sysuml=sum(1 for i in its if any("SysUML" in a["appliesTo"] for a in i["answers"])),
                      uml3=sum(1 for i in its if any("UML3" in a["appliesTo"] for a in i["answers"])),
                      deviation=sum(1 for i in its if any(a["kind"] == "deviation" for a in i["answers"])),
                      unanswered=sum(1 for i in its if not i["answers"]))
        totals.update(row)
        out.append(f"| [{pkg}](#{pkg.lower()}) | {row['items']} | {row['mandatory']} | {row['optional']} | "
                   f"{row['concerns']} | {row['sysuml']} | {row['uml3']} | {row['deviation']} | {row['unanswered']} |")
    out += [f"| **Total** | **{totals['items']}** | {totals['mandatory']} | {totals['optional']} | {totals['concerns']} | "
            f"{totals['sysuml']} | {totals['uml3']} | {totals['deviation']} | {totals['unanswered']} |", ""]
    for pkg, doc, _ in packages:
        its = by_pkg.get(pkg, [])
        if not its:
            continue
        out += [f"## {pkg}", "", cell(doc.split("\n\n")[0]), "",
                "| ID | Item | Priority | SysUML | UML3 | Implemented by | Notes |", "|---|---|---|---|---|---|---|"]
        for it in its:
            text = f"**{it['name']}**: {cell(it['statement'])}" if it["name"] else cell(it["statement"])
            if it["parent"]:
                text = f"↳ {text}"
            priority = it["priority"] or it["kind"]
            out.append(f"| {it['id']} | {text} | {priority} | {answer_cell(it['answers'], 'SysUML')} | "
                       f"{answer_cell(it['answers'], 'UML3')} | {implemented_cell(it['answers'])} | "
                       f"{cell(', '.join(it['notes']))} |")
        out.append("")
    named = [n for n in notes if n["name"] and any(segments(a)[-1] in items for a in n["about"])]
    if named:
        out += ["## Notes", ""]
        for n in named:
            about = ", ".join(segments(a)[-1] for a in n["about"])
            out += [f"**{n['name']}** (about {about}): {cell(n['text'])}", ""]
    return "\n".join(out)


if __name__ == "__main__":
    sys.exit(main())
