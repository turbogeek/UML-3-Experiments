"""
Checks the SysUML and UML3 requirements and use cases in requirements/ (rules in docs/REQUIREMENTS-GUIDE.md) and renders
docs/UML3-Requirements.md.

  FORM         requirement id 'UML3-<AREA>-nnn', unique, area matches its package; statement contains "shall";
               @Rationale text, @StatusInfo status, @Priority level and @VerificationMethod kind present
  EVIDENCE     done/tbc requirements end their doc with "Verified by:"; each entry resolves:
               'tools/run_tests.py suite <name>' (a suite of run_tests.py), 'Enn' (an experiment), a repository path
  REALIZATION  done requirements are the target of at least one '#realizes dependency from <element> to <id>'
               whose client resolves (library/ or requirements/)
  USECASE      every use case def has a doc, a subject, an actor and an objective, and '#traces' at least one
               existing requirement
  COVERAGE     (warning) requirements that no use case traces
  DOC          the committed Markdown equals the rendering (use --write to regenerate)

Usage: python tools/check_requirements.py [--write] [--report r.json] [--stdlib dir]
Exit code: 0 ok, 1 findings, 2 tool error.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_names as cn  # noqa: E402
from check_docs import lex  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
REQ_DIR = ROOT / "requirements"
DOC = ROOT / "docs" / "UML3-Requirements.md"
RELEASE = Path(os.environ.get("SYSML_RELEASE", ROOT.parent / "SysML-v2-Release"))

AREAS = [  # code, package, title
    ("CORE", "UML3CoreRequirements", "Core language"),
    ("STR", "UML3StructureRequirements", "Structure"),
    ("DT", "UML3DataTypeRequirements", "Data types"),
    ("BHV", "UML3BehaviorRequirements", "Behavior"),
    ("EXT", "UML3ExtensibilityRequirements", "Extensibility"),
    ("VER", "UML3VerificationRequirements", "Verification"),
    ("VAL", "UML3ValidationRequirements", "Validation"),
    ("VIEW", "UML3ViewRequirements", "Views and diagrams"),
    ("ARCH", "UML3ArchitectureRequirements", "Software architecture and deployment"),
    ("DATA", "UML3DataModelingRequirements", "Data modeling"),
    ("MSG", "UML3MessagingRequirements", "Messaging and interaction"),
    ("SEC", "UML3SecurityRequirements", "Security"),
    ("TEST", "UML3TestingRequirements", "Testing"),
    ("OPS", "UML3DevOpsRequirements", "DevOps"),
    ("GEN", "UML3GenerationRequirements", "Generation of code and artifacts"),
    ("RPT", "UML3ReportRequirements", "Reports and documentation"),
    ("LANG", "UML3LanguageRequirements", "Legacy and new languages"),
    ("AI", "UML3AIRequirements", "Artificial intelligence"),
    ("SYS", "UML3SysMLInteropRequirements", "SysML v2 and KerML interoperation"),
    ("REQ", "UML3RequirementModelingRequirements", "Requirement modeling"),
    ("PAT", "UML3PatternRequirements", "Patterns"),
    ("IMPL", "UML3ImplementationRequirements", "Implementations: SysUML and UML3"),
]
AREA_BY_PACKAGE = {p: c for c, p, _ in AREAS}
ID_RE = re.compile(r"^UML3-([A-Z]+)-(\d{3})$")
STATUSES = ["done", "tbc", "open", "tbd", "tbr", "closed"]


def blocks(toks, keyword_seq):
    """Yield (start index, header tokens, body token range) for statements starting with keyword_seq and a body."""
    n = len(keyword_seq)
    for i in range(len(toks) - n):
        if [t[1] for t in toks[i:i + n]] != keyword_seq:
            continue
        j = i + n
        while j < len(toks) and toks[j][1] not in ("{", ";"):
            j += 1
        if j >= len(toks) or toks[j][1] != "{":
            continue
        depth, k = 0, j
        while k < len(toks):
            if toks[k][1] == "{":
                depth += 1
            elif toks[k][1] == "}":
                depth -= 1
                if depth == 0:
                    break
            k += 1
        yield i, toks[i + n:j], (j + 1, k)


def doc_text(toks, rng) -> str | None:
    depth = 0
    for k in range(*rng):
        v = toks[k][1]
        if v == "{":
            depth += 1
        elif v == "}":
            depth -= 1
        elif depth == 0 and v == "doc":
            m = k + 1
            while m < rng[1] and toks[m][0] != "comment":
                m += 1
            if m < rng[1]:
                body = toks[m][1][2:-2]
                return "\n".join(l.strip() for l in body.strip("\n").splitlines()).strip()
    return None


def body_source(toks, rng) -> str:
    return " ".join(t[1] for t in toks[rng[0]:rng[1]])


def enclosing_package(toks, idx) -> str | None:
    depth, k = 0, idx - 1
    while k >= 0:
        v = toks[k][1]
        if v == "}":
            depth += 1
        elif v == "{":
            if depth == 0:
                m = k - 1
                while m >= 0 and toks[m][1] not in (";", "{", "}"):
                    if toks[m][1] == "package" and m + 1 < len(toks):
                        return toks[m + 1][1]
                    m -= 1
            else:
                depth -= 1
        k -= 1
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--report")
    ap.add_argument("--stdlib", default=str(RELEASE / "sysml.library"))
    args = ap.parse_args()
    files = sorted(REQ_DIR.glob("*.sysml"))
    if not files:
        print("TOOL ERROR: no requirements/*.sysml", file=sys.stderr)
        return 2

    idx = cn.Index()
    for f in cn.collect([args.stdlib], (".sysml", ".kerml")) + cn.collect([str(ROOT / "library"), str(REQ_DIR)], (".sysml",)):
        idx.add(cn.index_file(f))
    idx.finalize()
    run_tests = (ROOT / "tools" / "run_tests.py").read_text(encoding="utf-8")
    suites = set(re.findall(r'report\["suites"\]\["([a-z0-9-]+)"\]', run_tests))
    experiments = set(re.findall(r"\bE\d{2}\b", (ROOT / "docs" / "DESIGN.md").read_text(encoding="utf-8")))
    experiments |= {m.group(1).upper() for p in ROOT.glob("tests/**/*") for m in [re.match(r"(e\d{2})", p.name)] if m}

    findings: list[dict] = []
    reqs: dict[str, dict] = {}
    usecases: dict[str, dict] = {}
    realizes: dict[str, list[str]] = defaultdict(list)
    traces: dict[str, list[str]] = defaultdict(list)

    def add(code, file, line, msg, severity="error"):
        findings.append({"code": code, "severity": severity, "file": file.name, "line": line, "message": msg})

    def resolves(qname: str) -> bool:
        if idx.lookup(qname) is not None:
            return True
        owner, _, simple = qname.rpartition("::")
        scope = idx.lookup(owner) if owner else None
        return scope is not None and simple in scope.members

    for f in files:
        text = f.read_text(encoding="utf-8")
        toks = lex(text)
        for i, header, rng in blocks(toks, ["requirement"]):
            if len(header) < 4 or header[0][1] != "<" or header[2][1] != ">":
                continue  # requirement defs and unnamed usages are not catalog entries
            rid = header[1][1].strip("'")
            name = header[3][1]
            line = toks[i][2]
            src = body_source(toks, rng)
            pkg = enclosing_package(toks, i)
            doc = doc_text(toks, rng)
            m = ID_RE.match(rid)
            r = {"id": rid, "name": name, "file": f.name, "line": line, "package": pkg, "statement": doc or "",
                 "rationale": None, "status": None, "priority": None, "verification": []}
            if not m:
                add("FORM", f, line, f"id '{rid}' does not match UML3-<AREA>-nnn")
            elif AREA_BY_PACKAGE.get(pkg) != m.group(1):
                add("FORM", f, line, f"id '{rid}' is in package {pkg} (area {AREA_BY_PACKAGE.get(pkg)})")
            if rid in reqs:
                add("FORM", f, line, f"duplicate id '{rid}' (also {reqs[rid]['file']}:{reqs[rid]['line']})")
            if not doc or "shall" not in doc:
                add("FORM", f, line, f"{rid}: statement (doc) missing or without 'shall'")
            mm = re.search(r'@ Rationale \{ text = ("(?:[^"\\]|\\.)*")', src)
            r["rationale"] = json.loads(mm.group(1)) if mm else None
            mm = re.search(r"@ StatusInfo \{.*?status = StatusKind : : (\w+)", src)
            r["status"] = mm.group(1) if mm else None
            mm = re.search(r"@ Priority \{ level = PriorityKind : : (\w+)", src)
            r["priority"] = mm.group(1) if mm else None
            mm = re.search(r"@ VerificationMethod \{ kind = (.*?) ; \}", src)
            r["verification"] = re.findall(r"VerificationMethodKind : : (\w+)", mm.group(1)) if mm else []
            # the implementations the requirement binds; without @AppliesTo it is a SysUML requirement
            mm = re.search(r"@ AppliesTo \{ implementations = (.*?) ; \}", src)
            kinds = re.findall(r"ImplementationKind : : (\w+)", mm.group(1)) if mm else []
            r["appliesTo"] = [{"sysUML": "SysUML", "uml3": "UML3"}.get(k, k) for k in kinds] or ["SysUML"]
            if mm and not kinds:
                add("FORM", f, line, f"{rid}: @AppliesTo names no ImplementationKind")
            for field in ("rationale", "status", "priority"):
                if not r[field]:
                    add("FORM", f, line, f"{rid}: missing {field}")
            if not r["verification"]:
                add("FORM", f, line, f"{rid}: missing verification method")
            evidence = []
            vm = re.search(r"^Verified by:(.*)$", doc or "", re.M)
            if vm:
                evidence = [e.strip().rstrip(".") for e in vm.group(1).split(";") if e.strip()]
            r["evidence"] = evidence
            if r["status"] in ("done", "tbc"):
                if not evidence:
                    add("EVIDENCE", f, line, f"{rid}: status {r['status']} needs a 'Verified by:' line")
                for e in evidence:
                    ms = re.match(r"tools/run_tests\.py suite ([a-z0-9-]+)$", e)
                    if ms:
                        ok = ms.group(1) in suites
                    elif re.match(r"^E\d{2}$", e):
                        ok = e in experiments
                    else:
                        ok = (ROOT / e).exists()
                    if not ok:
                        add("EVIDENCE", f, line, f"{rid}: evidence '{e}' does not resolve")
            reqs[rid] = r
        # '#realizes dependency from X to Y;' and '#traces dependency from X to Y;'
        for kw, store in (("realizes", realizes), ("traces", traces)):
            for mm in re.finditer(r"#" + kw + r"\s+dependency\s+from\s+([\w:']+(?:\s*,\s*[\w:']+)*)\s+to\s+([\w:'\-]+(?:\s*,\s*[\w:'\-]+)*)\s*;", text):
                clients = [c.strip() for c in mm.group(1).split(",")]
                targets = [t.strip().rpartition("::")[2].strip("'") for t in mm.group(2).split(",")]
                line = text.count("\n", 0, mm.start()) + 1
                for c in clients:
                    for t in targets:
                        store[t].append(c)
                    if kw == "realizes" and not resolves(c.replace("'", "")):
                        add("REALIZATION", f, line, f"realizing element '{c}' does not resolve")
        for i, header, rng in blocks(toks, ["use", "case", "def"]):
            name = header[0][1] if header else "?"
            line = toks[i][2]
            src = body_source(toks, rng)
            doc = doc_text(toks, rng)
            uc = {"name": name, "file": f.name, "line": line, "package": enclosing_package(toks, i), "doc": doc or "",
                  "actors": re.findall(r"\bactor (\w+) :", src), "objective": None}
            om = re.search(r"objective \{ doc (/\*.*?\*/)", src, re.S)
            uc["objective"] = " ".join(l.strip() for l in om.group(1)[2:-2].splitlines()).strip() if om else None
            if not doc:
                add("USECASE", f, line, f"use case {name}: missing doc")
            if " subject " not in f" {src} ":
                add("USECASE", f, line, f"use case {name}: missing subject")
            if not uc["actors"]:
                add("USECASE", f, line, f"use case {name}: missing actor")
            if not uc["objective"]:
                add("USECASE", f, line, f"use case {name}: missing objective with a doc")
            if name in usecases:
                prior = usecases[name]
                add("USECASE", f, line, f"use case name {name} is also used at {prior['file']}:{prior['line']} "
                                        "(names must be unique across areas; traces are matched by name)")
            usecases[name] = uc

    for rid, r in reqs.items():
        if r["status"] == "done" and not realizes.get(rid):
            add("REALIZATION", ROOT / r["file"], r["line"], f"{rid}: done but no #realizes dependency")
    for t, clients in realizes.items():
        if t not in reqs:
            add("REALIZATION", REQ_DIR / "?", 0, f"#realizes target '{t}' is not a requirement")
    uc_reqs: dict[str, list[str]] = defaultdict(list)
    for t, clients in traces.items():
        for c in clients:
            ucname = c.rpartition("::")[2]
            if ucname in usecases:
                if t not in reqs:
                    add("USECASE", ROOT / usecases[ucname]["file"], usecases[ucname]["line"], f"{ucname} traces unknown requirement '{t}'")
                else:
                    uc_reqs[ucname].append(t)
    for name, uc in usecases.items():
        if not uc_reqs.get(name):
            add("USECASE", ROOT / uc["file"], uc["line"], f"use case {name}: traces no requirement")
    for rid, r in reqs.items():
        r["usecases"] = sorted(n for n, rs in uc_reqs.items() if rid in rs)
        r["realizedBy"] = sorted(set(realizes.get(rid, [])))
        if usecases and not r["usecases"]:
            add("COVERAGE", ROOT / r["file"], r["line"], f"{rid}: not traced by any use case", "warning")

    markdown = render(reqs, usecases, uc_reqs)
    if args.write:
        DOC.write_text(markdown, encoding="utf-8")
    elif not DOC.exists() or DOC.read_text(encoding="utf-8") != markdown:
        add("DOC", DOC, 0, "docs/UML3-Requirements.md is not up to date (run with --write)")

    errors = [x for x in findings if x["severity"] == "error"]
    warnings = [x for x in findings if x["severity"] == "warning"]
    for x in findings:
        print(f"{x['severity'].upper():7} {x['code']:11} {x['file']}:{x['line']}: {x['message']}")
    counts = Counter(r["status"] for r in reqs.values())
    print(f"SUMMARY requirements={len(reqs)} {dict(counts)} usecases={len(usecases)} errors={len(errors)} warnings={len(warnings)}")
    if args.report:
        Path(args.report).write_text(json.dumps({"requirements": reqs, "usecases": usecases, "findings": findings},
                                                indent=2), encoding="utf-8")
    return 1 if errors else 0


def cell(s: str | None) -> str:
    return (s or "").replace("|", "\\|").replace("\n", " ")


def render(reqs: dict, usecases: dict, uc_reqs: dict) -> str:
    out = ["# SysUML and UML3 requirements", "",
           "Generated from `requirements/*.sysml` by `tools/check_requirements.py --write`; do not edit. Rules: "
           "[REQUIREMENTS-GUIDE.md](REQUIREMENTS-GUIDE.md).", "",
           "Two implementations share these requirements: **SysUML** models software in SysML v2 with libraries and "
           "semantic keywords (the implementation in use), and **UML3** extends KerML with its own textual syntax and "
           "grammar (the next step). A requirement applies to SysUML unless its *Applies to* column says otherwise.", ""]
    by_area: dict[str, list[dict]] = defaultdict(list)
    for r in reqs.values():
        m = ID_RE.match(r["id"])
        by_area[m.group(1) if m else "?"].append(r)
    out += ["## Summary", "", "| Area | Requirements | done | tbc | open | tbd | mandatory | optional | SysUML | UML3 |",
            "|---|---|---|---|---|---|---|---|---|---|"]
    for code, _, title in AREAS:
        rs = by_area.get(code, [])
        c = Counter(r["status"] for r in rs)
        p = Counter(r["priority"] for r in rs)
        a = Counter(k for r in rs for k in r["appliesTo"])
        out.append(f"| [{code}](#{code.lower()}) {title} | {len(rs)} | {c['done']} | {c['tbc']} | {c['open']} | {c['tbd']} | "
                   f"{p['mandatory']} | {p['optional']} | {a['SysUML']} | {a['UML3']} |")
    total = Counter(r["status"] for r in reqs.values())
    applies = Counter(k for r in reqs.values() for k in r["appliesTo"])
    out += [f"| **Total** | **{len(reqs)}** | {total['done']} | {total['tbc']} | {total['open']} | {total['tbd']} | | | "
            f"{applies['SysUML']} | {applies['UML3']} |", ""]
    for code, pkg, title in AREAS:
        rs = sorted(by_area.get(code, []), key=lambda r: r["id"])
        if not rs:
            continue
        out += [f"## {code}", "", f"**{title}** (`{pkg}`)", "",
                "| ID | Requirement | Applies to | Priority | Status | Verification | Realized by | Use cases |",
                "|---|---|---|---|---|---|---|---|"]
        for r in rs:
            statement = re.sub(r"\s*Verified by:.*$", "", r["statement"], flags=re.S).replace("\n", " ")
            text = f"**{r['name']}**: {cell(statement)}<br>*Rationale:* {cell(r['rationale'])}"
            if r.get("evidence"):
                text += f"<br>*Verified by:* {cell('; '.join(r['evidence']))}"
            out.append(f"| {r['id']} | {text} | {', '.join(r['appliesTo'])} | {r['priority']} | {r['status']} | "
                       f"{', '.join(r['verification'])} | {cell(', '.join('`' + x + '`' for x in r['realizedBy']))} | "
                       f"{cell(', '.join(r['usecases']))} |")
        out.append("")
    if usecases:
        out += ["## Use cases", "", "| Use case | Actors | Objective | Requirements |", "|---|---|---|---|"]
        for name in sorted(usecases, key=lambda n: (usecases[n]["package"] or "", n)):
            uc = usecases[name]
            out.append(f"| **{name}** ({uc['package']})<br>{cell(uc['doc'].splitlines()[0] if uc['doc'] else '')} | "
                       f"{', '.join(uc['actors'])} | {cell(uc['objective'])} | {', '.join(sorted(set(uc_reqs.get(name, []))))} |")
        out.append("")
    return "\n".join(out)


if __name__ == "__main__":
    sys.exit(main())
