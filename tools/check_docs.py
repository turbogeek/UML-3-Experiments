"""
Documentation checker for UML3 SysML v2 files (rules in docs/DOC-CONVENTIONS.md).

  D01  banner / separator lines ('=====', '-----') or leading ' * ' decoration in comment text
  D02  unattached /* */ comment (neither 'doc' nor 'comment ... about ...'): it would annotate the namespace
  D03  '//' note or '//* */' block note (not a model element)
  D04  named element without an owned 'doc'
       profile 'library': every named definition, usage, feature and enumeration literal
       profile 'example': every named definition and usage except parameters (in/out/inout) and enum literals
  D05  unresolvable citation in comment text: 'KerML n.n', 'SysML n.n' (clause numbers of the specification PDFs,
       extracted with pdftotext), 'UML 2.5.1 Name' (a UML concept of traceability/uml2-to-uml3.json),
       'UML3Xxx::Name' (an element of library/), 'Enn' (an experiment in tests/ or docs/DESIGN.md)

Usage: python tools/check_docs.py [--profile library|example] [--report r.json] [--stdlib dir] files...
Exit code: 0 no findings, 1 findings, 2 tool error.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_names as cn  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
RELEASE = Path(os.environ.get("SYSML_RELEASE", ROOT.parent / "SysML-v2-Release"))
SPEC_PDFS = {"KerML": "1-Kernel_Modeling_Language.pdf", "SysML": "2a-OMG_Systems_Modeling_Language.pdf"}
SPEC_CACHE = ROOT / "logs" / "specs"

LEX = re.compile(r"""
    (?P<blocknote>//\*.*?\*/)
  | (?P<note>//[^\n]*)
  | (?P<comment>/\*.*?\*/)
  | (?P<string>"(?:[^"\\]|\\.)*")
  | (?P<qname>'(?:[^'\\]|\\.)*')
  | (?P<ident>[A-Za-z_][A-Za-z0-9_]*)
  | (?P<ws>\s+)
  | (?P<other>.)
""", re.S | re.X)

BANNER = re.compile(r"^\s*\*?\s*([=\-~#*_])\1{4,}\s*$")
STAR_LINE = re.compile(r"^\s*\*(\s|$)")
CITE_SPEC = re.compile(r"\b(KerML|SysML)\s+(?:v?\d\.\d\s+)?(?:clause\s+)?(\d+(?:\.\d+)+)")
CITE_UML = re.compile(r"\bUML 2\.5\.1\s+([A-Z][A-Za-z]+)")
CITE_UML3 = re.compile(r"\b(UML3[A-Za-z]+::[A-Za-z_][A-Za-z0-9_:]*)")
CITE_EXP = re.compile(r"\b(E\d{2})\b")


def lex(text: str) -> list[tuple[str, str, int]]:
    out, line = [], 1
    for m in LEX.finditer(text):
        kind, val = m.lastgroup, m.group()
        if kind != "ws":
            out.append((kind, val, line))
        line += val.count("\n")
    return out


def comment_findings(path: Path, toks: list[tuple[str, str, int]]) -> tuple[list[dict], list[tuple[str, int]]]:
    findings, bodies = [], []
    for i, (kind, val, line) in enumerate(toks):
        if kind in ("note", "blocknote"):
            findings.append({"code": "D03", "line": line, "message": "note is not a model element; use doc or comment about"})
            continue
        if kind != "comment":
            continue
        bodies.append((val, line))
        # attached: 'doc [name] [locale "x"] /*' or a statement starting with 'comment'
        j = i - 1
        if j >= 0 and toks[j][0] == "string" and j >= 1 and toks[j - 1][1] == "locale":
            j -= 2
        attached = False
        if j >= 0 and toks[j][1] in ("doc", "comment"):
            attached = True
        elif j >= 1 and toks[j][0] in ("ident", "qname") and toks[j - 1][1] in ("doc", "comment"):
            attached = True
        else:
            # 'comment Name about A, B::C' : walk back over the about-list to 'comment'
            k = j
            while k >= 0 and (toks[k][0] in ("ident", "qname") or toks[k][1] in (",", ":", ".")):
                if toks[k][1] == "comment":
                    attached = True
                    break
                k -= 1
            if k >= 0 and toks[k][1] == "comment":
                attached = True
        if not attached:
            findings.append({"code": "D02", "line": line,
                             "message": "unattached comment annotates the namespace; use doc or 'comment Name about ...'"})
        for n, text_line in enumerate(val[2:-2].splitlines()):
            if BANNER.match(text_line):
                findings.append({"code": "D01", "line": line + n, "message": "banner/separator line in comment text"})
                break
        if any(STAR_LINE.match(l) for l in val[2:-2].splitlines()[1:]):
            findings.append({"code": "D01", "line": line, "message": "leading ' * ' decoration in comment text"})
    return findings, bodies


def spec_clauses() -> dict[str, set[str]]:
    clauses: dict[str, set[str]] = {}
    tool = shutil.which("pdftotext")
    SPEC_CACHE.mkdir(parents=True, exist_ok=True)
    for spec, pdf in SPEC_PDFS.items():
        txt = SPEC_CACHE / (spec.lower() + ".txt")
        if not txt.exists():
            src = RELEASE / "doc" / pdf
            if tool is None or not src.exists():
                raise RuntimeError(f"cannot verify {spec} citations: need pdftotext and {src}")
            subprocess.run([tool, "-layout", str(src), str(txt)], check=True)
        heads = set()
        for l in txt.read_text(encoding="utf-8", errors="replace").splitlines():
            m = re.match(r"^\s*(\d+(?:\.\d+)+)\s+[A-Z]", l)
            if m:
                heads.add(m.group(1))
        if len(heads) < 100:
            raise RuntimeError(f"{spec} clause index looks empty ({len(heads)} headings) - check {txt}")
        clauses[spec] = heads
    return clauses


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--profile", choices=["library", "example"], default="library")
    ap.add_argument("--report")
    ap.add_argument("--stdlib", default=str(RELEASE / "sysml.library"))
    ap.add_argument("files", nargs="+")
    args = ap.parse_args()

    try:
        clauses = spec_clauses()
        idx = cn.Index()
        for f in cn.collect([args.stdlib], (".sysml", ".kerml")) + cn.collect([str(ROOT / "library")], (".sysml",)):
            idx.add(cn.index_file(f))
        idx.finalize()
        uml_concepts = {r["uml2"].split()[0] for r in json.loads((ROOT / "traceability" / "uml2-to-uml3.json")
                                                                  .read_text(encoding="utf-8"))["rows"]}
        experiments = set(re.findall(r"\bE\d{2}\b", (ROOT / "docs" / "DESIGN.md").read_text(encoding="utf-8")))
        experiments |= {m.group(1).upper() for p in ROOT.glob("tests/**/*") for m in [re.match(r"(e\d{2})", p.name)] if m}
    except Exception as exc:  # environment problems are exit code 2
        print(f"TOOL ERROR: {exc}", file=sys.stderr)
        return 2

    report = {"profile": args.profile, "files": []}
    total = 0
    for f in cn.collect(args.files, (".sysml",)):
        text = f.read_text(encoding="utf-8")
        findings, bodies = comment_findings(f, lex(text))
        # D05 citations
        for body, line in bodies:
            for m in CITE_SPEC.finditer(body):
                if m.group(2) not in clauses[m.group(1)]:
                    findings.append({"code": "D05", "line": line, "message": f"{m.group(1)} clause {m.group(2)} does not exist"})
            for m in CITE_UML.finditer(body):
                if m.group(1) not in uml_concepts:
                    findings.append({"code": "D05", "line": line, "message": f"UML 2.5.1 {m.group(1)} is not in the traceability map"})
            for m in CITE_UML3.finditer(body):
                if idx.lookup(m.group(1).rstrip(":")) is None:
                    findings.append({"code": "D05", "line": line, "message": f"{m.group(1)} does not resolve in library/"})
            for m in CITE_EXP.finditer(body):
                if m.group(1) not in experiments:
                    findings.append({"code": "D05", "line": line, "message": f"experiment {m.group(1)} not found"})
        # D04 missing documentation
        fm = cn.index_file(f)
        seen: set[int] = set()

        def walk(scope: cn.Scope) -> None:
            for child in scope.children.values():
                if id(child) in seen:
                    continue
                seen.add(id(child))
                if child.decl and child.name:
                    words = {t.text for t in child.decl if t.kind == "ident"}
                    is_param = bool(words & {"in", "out", "inout"}) and not child.is_def
                    is_literal = child.decl_kind == "enum" and not child.is_def
                    exempt = args.profile == "example" and (is_param or is_literal)
                    depth, has_doc = 0, False
                    for t in child.body:
                        if t.text == "{":
                            depth += 1
                        elif t.text == "}":
                            depth -= 1
                        elif depth == 0 and t.text == "doc":
                            has_doc = True
                            break
                    if not has_doc and not exempt:
                        kind = (child.decl_kind or "element") + (" def" if child.is_def else "")
                        findings.append({"code": "D04", "line": child.decl[0].line,
                                         "message": f"{kind} '{child.name}' has no doc"})
                walk(child)

        walk(fm.root)
        findings.sort(key=lambda x: (x["line"], x["code"]))
        total += len(findings)
        report["files"].append({"file": str(f), "findings": findings})
        for x in findings:
            print(f"{f.name}:{x['line']}: {x['code']} {x['message']}")
    counts: dict[str, int] = {}
    for fr in report["files"]:
        for x in fr["findings"]:
            counts[x["code"]] = counts.get(x["code"], 0) + 1
    report["counts"] = counts
    print(f"SUMMARY {args.profile}: {total} findings {counts}")
    if args.report:
        Path(args.report).write_text(json.dumps(report, indent=2), encoding="utf-8")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
