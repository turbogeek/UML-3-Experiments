"""
Regression harness for the UML3 SysML v2 extension library.

Suites (each result is recorded in logs/test-report.json):
  syntax-positive     ANTLR sysml-validator on library/ and examples/        -> must PASS
  names-positive      check_names.py on library/ and examples/               -> must PASS
  negative            each tests/negative/*.sysml must FAIL with its EXPECT code
                      (SYNTAX via the validator, IMPORT/TYPE/KEYWORD/QUALIFIED/DEPENDENCY/LINT via check_names)
  checker-calibration check_names.py on the official OMG models              -> must PASS
                      (guards the checker against false positives)
  requirements        requirements/*.sysml: syntax, names, tools/check_requirements.py (form, evidence, realization, use cases)
  docs                tools/check_docs.py: documentation rules D01-D05 on library/ and examples/, checker fixtures
  keywords            tools/check_keywords.py: docs/UML3-Keywords.md matches the libraries (keyword, terse id, base)
  refinements         tools/check_refinements.py fixtures (answers to an external requirement set): expected
                      finding codes and exit codes, and the answers of the clean case
  dogfood             DogFoodUML3/: the effort modeled in SysUML, with its domain metamodel; syntax, names,
                      design rules and documentation
  samples             samples/: the SysUML file of each sample pair (syntax, names, design rules, docs)
  idl-corpus          tools/idl_corpus_check.py: IDL core vs third-party corpora (external/idl submodules)
  catia-customization customization/catia-magic: syntax, names, documentation and rules of the tool customization,
                      and tools/check_diagram_kinds.py (model vs view filters vs palettes, with fixtures)
  cameo-patterns      (--cameo) the E22 pattern probes: load, validate, implied relationships, and the verdicts of
                      CATIA Magic's evaluation engine for the pattern requirements (model-level ones included)
  cameo (--cameo)     tools/cameo_check.py: load library + examples into CATIA Magic through
                      the SysMLv2 test harness REST API, undo the loads and reset the harness,
                      which keeps running (--shutdown-harness stops it). The harness updates
                      itself from sysml-validator/utilityScripts when those files change.
                      This is the authoritative semantic check.
  sample-diagrams     (--cameo) the sample of samples/uml3 drawn as diagrams in CATIA Magic and exported to SVG
                      and PNG (E23): the sample says nothing about how to draw it, so every shape on the diagram
                      is there because a UML3 keyword put it there. The run creates its own empty SysML v2
                      project from the installation's template, so it needs no project opened by hand.

Paths default to sibling checkouts and can be overridden with environment variables:
  SYSML_RELEASE   (default ../SysML-v2-Release)
  SYSML_VALIDATOR_JAR (default ../sysml-validator/validator-cli/target/sysml-validator.jar)

Usage: python tools/run_tests.py [--skip-calibration] [--cameo [--shutdown-harness]]
Exit code: 0 all suites pass, 1 any failure, 2 environment problem.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RELEASE = Path(os.environ.get("SYSML_RELEASE", ROOT.parent / "SysML-v2-Release"))
STDLIB = RELEASE / "sysml.library"
JAR = Path(os.environ.get("SYSML_VALIDATOR_JAR",
                          ROOT.parent / "sysml-validator" / "validator-cli" / "target" / "sysml-validator.jar"))
CHECKER = ROOT / "tools" / "check_names.py"
LOGS = ROOT / "logs"
EXPECT_RE = re.compile(r"EXPECT:\s*(SYNTAX|IMPORT|TYPE|KEYWORD|QUALIFIED|DEPENDENCY|FUNCTION|LINT|APPLICABILITY)")


def run(cmd: list[str], timeout: int = 600) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=timeout)


def syntax_check(files: list[Path]) -> tuple[bool, list[str]]:
    """Returns (passed, error lines). Uses the validator's exit code AND its error lines."""
    r = run(["java", f"-Dsysml.library.path={STDLIB}", "-jar", str(JAR), "--no-color", *map(str, files)])
    errors = [ln.strip() for ln in r.stdout.splitlines() if ln.startswith("[ERROR]") or "SYNTAX_ERROR" in ln]
    return r.returncode == 0 and not errors, errors


def name_check(check: list[Path], index: list[Path], report: Path) -> tuple[int, dict]:
    cmd = [sys.executable, str(CHECKER), "--stdlib", str(STDLIB), "--report", str(report)]
    if index:
        cmd += ["--index", *map(str, index)]
    cmd += ["--check", *map(str, check)]
    r = run(cmd)
    if r.returncode == 2 or not report.exists():
        raise RuntimeError(f"checker tool error: {r.stderr.strip() or r.stdout[-500:]}")
    return r.returncode, json.loads(report.read_text(encoding="utf-8"))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--skip-calibration", action="store_true")
    ap.add_argument("--cameo", action="store_true", help="also run the CATIA Magic harness check")
    ap.add_argument("--shutdown-harness", action="store_true",
                    help="with --cameo: stop the harness afterwards; by default it keeps running and is reset")
    ap.add_argument("--keep-harness", action="store_true", help=argparse.SUPPRESS)   # the default since harness 2.0
    args = ap.parse_args()

    LOGS.mkdir(exist_ok=True)
    env_problems = [str(p) for p in (STDLIB, JAR, CHECKER) if not p.exists()]
    if env_problems:
        print("ENVIRONMENT ERROR, missing: " + ", ".join(env_problems), file=sys.stderr)
        return 2

    library = sorted((ROOT / "library").glob("*.sysml"))
    examples = sorted((ROOT / "examples").glob("*.sysml"))
    negatives = sorted((ROOT / "tests" / "negative").glob("*.sysml"))
    if not library or not examples or not negatives:
        print("ENVIRONMENT ERROR: library/, examples/ or tests/negative/ is empty", file=sys.stderr)
        return 2

    report: dict = {"started": dt.datetime.now().isoformat(timespec="seconds"),
                    "stdlib": str(STDLIB), "validatorJar": str(JAR), "suites": {}}

    # 1. syntax, positive (files hitting documented ANTLR-validator gaps are exempt; see 1b)
    gaps = json.loads((ROOT / "tests" / "validator-known-gaps.json").read_text(encoding="utf-8"))
    exempt = {(ROOT / p).resolve() for p in gaps["exemptFromAntlrSyntax"]}
    # probe and experiment models are loaded into CATIA Magic too, so they go through the syntax check as well
    probe_models = (sorted((ROOT / "tests" / "cameo-experiments").glob("*.sysml"))
                    + sorted((ROOT / "tests" / "cameo-negative").glob("*.sysml"))
                    + sorted((ROOT / "tests" / "diagram-kinds").glob("*.sysml"))
                    + sorted((ROOT / "customization").rglob("*.sysml")))
    syntax_files = [f for f in library + examples + probe_models if f.resolve() not in exempt]
    ok, errs = syntax_check(syntax_files)
    report["suites"]["syntax-positive"] = {"passed": ok, "files": len(syntax_files),
                                           "exempt": sorted(str(p) for p in exempt), "errors": errs}

    # 1b. validator gaps must still be real: each official OMG evidence file must still fail the ANTLR
    #     validator; if one passes, the gap is fixed and the exemption should be removed
    gap_cases = []
    for g in gaps["gaps"]:
        evidence = RELEASE / g["evidence"]
        still_fails = evidence.exists() and not syntax_check([evidence])[0]
        gap_cases.append({"construct": g["construct"], "evidence": g["evidence"], "stillFails": still_fails})
    report["suites"]["validator-gaps"] = {"passed": all(c["stillFails"] for c in gap_cases), "cases": gap_cases}

    # 2. names, positive
    name_fixtures = sorted((ROOT / "tests" / "names").glob("*.sysml"))   # checker regressions that must resolve cleanly
    rc, rep = name_check(library + examples + name_fixtures, [], LOGS / "names-positive.json")
    report["suites"]["names-positive"] = {"passed": rc == 0, "files": len(rep["files"]),
                                          "findings": [f | {"file": x["file"]} for x in rep["files"] for f in x["findings"]]}

    # 3. negative tests: each must fail, with the expected code
    neg_results = []
    for f in negatives:
        m = EXPECT_RE.search(f.read_text(encoding="utf-8"))
        expected = m.group(1) if m else None
        if expected is None:
            neg_results.append({"file": f.name, "passed": False, "reason": "no EXPECT header"})
            continue
        if expected == "SYNTAX":
            syn_ok, syn_errs = syntax_check([f])
            passed = not syn_ok
            detail = syn_errs[:3]
        else:
            rc, rep = name_check([f], library, LOGS / "names-negative.json")
            codes = [x["code"] for fr in rep["files"] for x in fr["findings"]]
            passed = rc == 1 and expected in codes
            detail = [f'{x["code"]} line {x["line"]}: {x["message"]}' for fr in rep["files"] for x in fr["findings"]]
        neg_results.append({"file": f.name, "expected": expected, "passed": passed, "observed": detail})
    report["suites"]["negative"] = {"passed": all(r["passed"] for r in neg_results), "cases": neg_results}

    # 4. checker calibration on official models
    if not args.skip_calibration:
        official = [RELEASE / "sysml" / "src" / d for d in ("validation", "examples", "training")]
        rc, rep = name_check([p for p in official if p.exists()], [], LOGS / "calibration-report.json")
        report["suites"]["checker-calibration"] = {
            "passed": rc == 0, "files": len(rep["files"]),
            "findings": [f | {"file": x["file"]} for x in rep["files"] for f in x["findings"]]}

    # 4a. UML 2.x -> UML3 traceability: every cited metaclass / UML3 element / view / example exists and
    #     the generated document is up to date
    tr = run([sys.executable, str(ROOT / "tools" / "check_traceability.py"), "--stdlib", str(STDLIB),
              "--report", str(LOGS / "traceability-report.json")])
    tr_rep = json.loads((LOGS / "traceability-report.json").read_text(encoding="utf-8")) if tr.returncode != 2 else {}
    report["suites"]["traceability"] = {"passed": tr.returncode == 0, "rows": tr_rep.get("rows"),
                                        "statusCounts": tr_rep.get("statusCounts"),
                                        "findings": tr_rep.get("findings", [tr.stderr.strip()])}

    # 4b. design rules: examples must have no ERROR findings; each tests/rules file must produce exactly
    #     the rule IDs in its EXPECT-RULES header (R12 stacking warnings are allowed extras), 'none' = clean
    rules_script = ROOT / "tools" / "check_rules.py"
    rr = run([sys.executable, str(rules_script), "--stdlib", str(STDLIB), "--index", str(ROOT / "library"),
              "--check", str(ROOT / "examples"), "--report", str(LOGS / "rules-examples.json")])
    rules_rep = json.loads((LOGS / "rules-examples.json").read_text(encoding="utf-8")) if rr.returncode != 2 else {}
    report["suites"]["rules-examples"] = {
        "passed": rr.returncode == 0, "errors": rules_rep.get("errors"), "warnings": rules_rep.get("warnings"),
        "findings": rules_rep.get("findings", []) if rr.returncode != 2 else [rr.stderr.strip()]}
    rl = run([sys.executable, str(rules_script), "--stdlib", str(STDLIB), "--index", str(ROOT / "library"),
              "--check", str(ROOT / "library"), "--report", str(LOGS / "rules-library.json")])
    rl_rep = json.loads((LOGS / "rules-library.json").read_text(encoding="utf-8")) if rl.returncode != 2 else {}
    report["suites"]["rules-library"] = {
        "passed": rl.returncode == 0 and rl_rep.get("warnings") == 0, "errors": rl_rep.get("errors"),
        "warnings": rl_rep.get("warnings"), "findings": rl_rep.get("findings", [rl.stderr.strip()])}
    rule_cases = []
    for f in sorted((ROOT / "tests" / "rules").glob("*.sysml")):
        m = re.search(r"EXPECT-RULES:\s*([A-Za-z0-9 ,]+)", f.read_text(encoding="utf-8"))
        expected = set() if m is None or m.group(1).strip().startswith("none") else \
            set(re.findall(r"R\d\d", m.group(1)))
        out = LOGS / "rules-negative.json"
        rc = run([sys.executable, str(rules_script), "--stdlib", str(STDLIB), "--index", str(ROOT / "library"),
                  "--check", str(f), "--report", str(out)])
        observed = {x["rule"] for x in json.loads(out.read_text(encoding="utf-8"))["findings"]} if rc.returncode != 2 else {"TOOL_ERROR"}
        extra = observed - expected - ({"R12"} if expected else set())
        passed = m is not None and expected <= observed and not extra
        rule_cases.append({"file": f.name, "expected": sorted(expected), "observed": sorted(observed), "passed": passed})
    report["suites"]["rules-tests"] = {"passed": bool(rule_cases) and all(c["passed"] for c in rule_cases),
                                       "cases": rule_cases}

    # 4c. IDL import (Groovy core, outside CATIA Magic): each tests/idl/*.idl must import, keep a stable canonical
    #     round trip, contain every line of its .expect file, and yield SysML that passes syntax/names/rules;
    #     each tests/idl/unsupported fixture must fail with its expected message
    groovy = "groovy.bat" if os.name == "nt" else "groovy"
    idl_dir = LOGS / "idl"
    idl_cases = []
    for idl in sorted((ROOT / "tests" / "idl").glob("*.idl")):
        out_sysml = idl_dir / (idl.stem + ".sysml")
        g = run([groovy, str(ROOT / "tools" / "idl" / "idl2sysml.groovy"), str(idl), str(out_sysml),
                 str(idl_dir / (idl.stem + ".canonical.idl"))])
        lines = g.stdout.splitlines()
        case = {"file": idl.name, "result": next((l for l in lines if l.startswith("RESULT|")), g.stderr.strip()[:300]),
                "roundtrip": next((l for l in lines if l.startswith("ROUNDTRIP|")), None), "missingExpected": [],
                "syntaxErrors": [], "nameFindings": None, "ruleErrors": None}
        ok = case["result"].startswith("RESULT|OK") and case["roundtrip"] == "ROUNDTRIP|STABLE"
        expect = idl.with_suffix(".expect")
        if ok and expect.exists():
            generated = {l.strip() for l in out_sysml.read_text(encoding="utf-8").splitlines()}
            case["missingExpected"] = [l.strip() for l in expect.read_text(encoding="utf-8").splitlines()
                                       if l.strip() and not l.startswith("#") and l.strip() not in generated]
            syn_ok, case["syntaxErrors"] = syntax_check([out_sysml])
            nrc, nrep = name_check([out_sysml], library, LOGS / "names-idl.json")
            case["nameFindings"] = sum(len(x["findings"]) for x in nrep["files"])
            rrc = run([sys.executable, str(rules_script), "--stdlib", str(STDLIB), "--index", str(ROOT / "library"),
                       "--check", str(out_sysml), "--report", str(LOGS / "rules-idl.json")])
            case["ruleErrors"] = json.loads((LOGS / "rules-idl.json").read_text(encoding="utf-8"))["errors"]
            ok = ok and not case["missingExpected"] and syn_ok and nrc == 0 and rrc.returncode == 0
        elif ok:
            ok = False
            case["missingExpected"] = ["no .expect file"]
        case["passed"] = ok
        idl_cases.append(case)
    expected_errors = ROOT / "tests" / "idl" / "unsupported" / "expected-errors.txt"
    for entry in expected_errors.read_text(encoding="utf-8").splitlines():
        if not entry.strip() or entry.startswith("#"):
            continue
        fname, substring = entry.split("|", 1)
        g = run([groovy, str(ROOT / "tools" / "idl" / "idl2sysml.groovy"),
                 str(ROOT / "tests" / "idl" / "unsupported" / fname), str(idl_dir / ("unsupported-" + fname + ".sysml"))])
        result = next((l for l in g.stdout.splitlines() if l.startswith("RESULT|")), g.stderr.strip()[:300])
        idl_cases.append({"file": "unsupported/" + fname, "result": result, "expectedError": substring,
                          "passed": result.startswith("RESULT|FAIL") and substring in result})
    report["suites"]["idl-import"] = {"passed": bool(idl_cases) and all(c["passed"] for c in idl_cases),
                                      "cases": idl_cases}

    # 4b2. documentation (docs/DOC-CONVENTIONS.md): library and examples are fully documented with verifiable
    #      citations; each tests/docs fixture yields exactly its expected finding codes
    doc_cases = []
    for profile, target in (("library", ROOT / "library"), ("example", ROOT / "examples"), ("example", ROOT / "requirements")):
        rep_path = LOGS / f"docs-{target.name}.json"
        d = run([sys.executable, str(ROOT / "tools" / "check_docs.py"), "--profile", profile, "--report", str(rep_path), str(target)])
        rep = json.loads(rep_path.read_text(encoding="utf-8")) if d.returncode != 2 and rep_path.exists() else {}
        doc_cases.append({"case": f"{target.name} ({profile})", "passed": d.returncode == 0, "counts": rep.get("counts"),
                          "error": d.stderr.strip()[-300:] if d.returncode == 2 else None})
    for entry in (ROOT / "tests" / "docs" / "expected.txt").read_text(encoding="utf-8").splitlines():
        if not entry.strip() or entry.startswith("#"):
            continue
        fname, codes = entry.split("|", 1)
        rep_path = LOGS / "docs-fixture.json"
        d = run([sys.executable, str(ROOT / "tools" / "check_docs.py"), "--report", str(rep_path), str(ROOT / "tests" / "docs" / fname)])
        observed = sorted({x["code"] for fr in json.loads(rep_path.read_text(encoding="utf-8"))["files"] for x in fr["findings"]})             if d.returncode != 2 else ["TOOL_ERROR"]
        expected = sorted(c for c in codes.split(",") if c.strip())
        doc_cases.append({"case": "fixture " + fname, "expected": expected, "observed": observed, "passed": observed == expected})
    report["suites"]["docs"] = {"passed": all(c["passed"] for c in doc_cases), "cases": doc_cases}

    # 4b2. the generated keyword reference (docs/UML3-Keywords.md) matches the libraries: every keyword, its
    #      terse id and its base, so a keyword added to a library cannot be missing from the reference
    kw = run([sys.executable, str(ROOT / "tools" / "check_keywords.py"), "--report", str(LOGS / "keywords.json")])
    kw_rep = json.loads((LOGS / "keywords.json").read_text(encoding="utf-8")) if kw.returncode != 2 else {}
    report["suites"]["keywords"] = {"passed": kw.returncode == 0, "counts": kw_rep.get("counts"),
                                    "findings": kw_rep.get("findings", [kw.stderr.strip()[-300:]])}

    # 4b3. requirements and use cases (docs/REQUIREMENTS-GUIDE.md): ANTLR syntax, name resolution against the
    #      libraries, form/evidence/realization/use-case checks and the generated docs/UML3-Requirements.md
    req_files = sorted((ROOT / "requirements").glob("*.sysml"))
    req_syn_ok, req_syn_errs = syntax_check(req_files) if req_files else (False, ["no requirements/*.sysml"])
    req_rc, req_names = name_check(req_files, library + req_files, LOGS / "names-requirements.json") if req_files else (1, {"files": []})
    rq = run([sys.executable, str(ROOT / "tools" / "check_requirements.py"), "--report", str(LOGS / "requirements-report.json")])
    rq_rep = json.loads((LOGS / "requirements-report.json").read_text(encoding="utf-8")) if rq.returncode != 2 else {}
    report["suites"]["requirements"] = {
        "passed": req_syn_ok and req_rc == 0 and rq.returncode == 0,
        "syntaxErrors": req_syn_errs,
        "nameFindings": [x | {"file": fr["file"]} for fr in req_names["files"] for x in fr["findings"]],
        "summary": next((l for l in rq.stdout.splitlines() if l.startswith("SUMMARY")), rq.stderr.strip()[-300:]),
        "errors": [x for x in rq_rep.get("findings", []) if x["severity"] == "error"],
        "warnings": [x for x in rq_rep.get("findings", []) if x["severity"] == "warning"]}

    # 4b3b. tools/check_refinements.py (answers to an external requirement set): each tests/refinements case yields
    #       exactly its expected finding codes and exit code, and the clean case reports the answers and notes of
    #       clean-answers.json (a positive control on content, not only on the absence of findings)
    ref_dir = ROOT / "tests" / "refinements"
    ref_cases = []
    for entry in (ref_dir / "expected.txt").read_text(encoding="utf-8").splitlines():
        if not entry.strip() or entry.startswith("#"):
            continue
        case, external, codes, exit_code = entry.split("|")
        rep_path = LOGS / "refinements-fixture.json"
        rep_path.unlink(missing_ok=True)
        rf = run([sys.executable, str(ROOT / "tools" / "check_refinements.py"), "--external", str(ref_dir / external),
                  "--refinements", str(ref_dir / case), "--report", str(rep_path)])
        rep = json.loads(rep_path.read_text(encoding="utf-8")) if rf.returncode != 2 and rep_path.exists() else None
        observed = sorted({x["code"] for x in rep["findings"]}) if rep else ["TOOL_ERROR"]
        expected = sorted(c for c in codes.split(",") if c.strip())
        result = {"case": f"{case} / {external}", "expected": expected, "observed": observed,
                  "exit": rf.returncode, "passed": observed == expected and rf.returncode == int(exit_code)}
        if case == "clean.sysml" and external == "external.sysml":
            want = json.loads((ref_dir / "clean-answers.json").read_text(encoding="utf-8"))
            got = {iid: {impl: sorted({a["requirement"] for a in rep["items"][iid]["answers"] if impl in a["appliesTo"]})
                         for impl in ("SysUML", "UML3")} for iid in want["answers"] if rep and iid in rep["items"]}
            notes = {iid: rep["items"][iid]["notes"] for iid in want["notes"] if rep and iid in rep["items"]}
            result["contentMatches"] = got == want["answers"] and notes == want["notes"]
            result["passed"] = result["passed"] and result["contentMatches"]
        ref_cases.append(result)
    report["suites"]["refinements"] = {"passed": bool(ref_cases) and all(c["passed"] for c in ref_cases),
                                       "cases": ref_cases}

    # 4b4. DogFoodUML3, the effort modeled in SysUML (UML3-CORE-014): ANTLR syntax, names against the libraries
    #      and the requirements it traces to, the design rules and the documentation rules
    dog_files = sorted((ROOT / "DogFoodUML3").rglob("*.sysml"))
    dog_syn_ok, dog_syn_errs = syntax_check(dog_files) if dog_files else (False, ["no DogFoodUML3/*.sysml"])
    dog_rc, dog_names = name_check(dog_files, library + req_files + dog_files, LOGS / "names-dogfood.json") \
        if dog_files else (1, {"files": []})
    dr = run([sys.executable, str(ROOT / "tools" / "check_rules.py"), "--stdlib", str(STDLIB), "--index",
              str(ROOT / "library"), str(ROOT / "DogFoodUML3"), "--check", str(ROOT / "DogFoodUML3"),
              "--report", str(LOGS / "rules-dogfood.json")])
    dd = run([sys.executable, str(ROOT / "tools" / "check_docs.py"), "--profile", "example", "--report",
              str(LOGS / "docs-dogfood.json"), str(ROOT / "DogFoodUML3")])
    report["suites"]["dogfood"] = {
        "passed": dog_syn_ok and dog_rc == 0 and dr.returncode == 0 and dd.returncode == 0,
        "files": len(dog_files), "syntaxErrors": dog_syn_errs,
        "nameFindings": [x | {"file": fr["file"]} for fr in dog_names["files"] for x in fr["findings"]],
        "rules": next((l for l in dr.stdout.splitlines() if l.startswith("SUMMARY")), dr.stderr.strip()[-300:]),
        "docs": next((l for l in dd.stdout.splitlines() if l.startswith("SUMMARY")), dd.stderr.strip()[-300:])}

    # 4b5. samples/: models that show a capability to readers (samples/uml3 shows one model in both
    #      implementations). The SysUML file of each pair is checked like an example; the .uml3 sketch is not
    #      parsed by any tool yet (issue I-39)
    sample_files = sorted((ROOT / "samples").rglob("*.sysml"))
    smp_syn_ok, smp_syn_errs = syntax_check(sample_files) if sample_files else (False, ["no samples/**/*.sysml"])
    smp_rc, smp_names = name_check(sample_files, library, LOGS / "names-samples.json") if sample_files else (1, {"files": []})
    sr = run([sys.executable, str(ROOT / "tools" / "check_rules.py"), "--stdlib", str(STDLIB), "--index",
              str(ROOT / "library"), "--check", str(ROOT / "samples"), "--report", str(LOGS / "rules-samples.json")])
    sd = run([sys.executable, str(ROOT / "tools" / "check_docs.py"), "--profile", "example", "--report",
              str(LOGS / "docs-samples.json"), str(ROOT / "samples")])
    report["suites"]["samples"] = {
        "passed": smp_syn_ok and smp_rc == 0 and sr.returncode == 0 and sd.returncode == 0,
        "files": len(sample_files), "syntaxErrors": smp_syn_errs,
        "nameFindings": [x | {"file": fr["file"]} for fr in smp_names["files"] for x in fr["findings"]],
        "rules": next((l for l in sr.stdout.splitlines() if l.startswith("SUMMARY")), sr.stderr.strip()[-300:]),
        "docs": next((l for l in sd.stdout.splitlines() if l.startswith("SUMMARY")), sd.stderr.strip()[-300:])}

    # 4c2. IDL code generation (Java: OMG IDL4-Java 1.0, Rust: docs/IDL-CODEGEN.md): spec naming examples; every
    #      tests/idl/codegen fixture generates, compiles (javac in-process; rustc when on PATH) and contains its
    #      .java.expect / .rs.expect lines; tests/idl/*.idl Java compiles; expected generator errors occur
    gen_cases = []
    g = run([groovy, str(ROOT / "tools" / "idl" / "codegen_selftest.groovy"), str(ROOT / "tests" / "idl" / "codegen" / "naming-examples.txt")])
    gen_cases.append({"case": "naming-examples", "result": next((l for l in g.stdout.splitlines() if l.startswith("RESULT|")), g.stderr[-300:]),
                      "failures": [l for l in g.stdout.splitlines() if l.startswith("CASE|FAIL")]})
    gen_cases[-1]["passed"] = gen_cases[-1]["result"].startswith("RESULT|OK")
    code_dir = LOGS / "codegen"
    for idl in sorted((ROOT / "tests" / "idl" / "codegen").glob("*.idl")):
        out = code_dir / idl.stem
        g = run([groovy, str(ROOT / "tools" / "idl" / "idl2code.groovy"), str(idl), str(out), "java", "rust", "compile"])
        lines = g.stdout.splitlines()
        case = {"case": "codegen/" + idl.name, "result": next((l for l in lines if l.startswith("RESULT|")), g.stderr[-300:]),
                "compile": [l for l in lines if l.startswith(("JAVAC|", "RUSTC|"))], "missing": []}
        jx = idl.with_name(idl.stem + ".java.expect")
        if jx.exists():
            for e in jx.read_text(encoding="utf-8").splitlines():
                if e.strip() and not e.startswith("#"):
                    rel, want = e.split("|", 1)
                    f = out / "java" / rel
                    if not f.exists() or want.strip() not in {x.strip() for x in f.read_text(encoding="utf-8").splitlines()}:
                        case["missing"].append(e)
        rx = idl.with_name(idl.stem + ".rs.expect")
        if rx.exists():
            rs = out / "rust" / "lib.rs"
            have = {x.strip() for x in rs.read_text(encoding="utf-8").splitlines()} if rs.exists() else set()
            case["missing"] += [e for e in rx.read_text(encoding="utf-8").splitlines() if e.strip() and not e.startswith("#") and e.strip() not in have]
        case["passed"] = case["result"].startswith("RESULT|OK") and not case["missing"]
        gen_cases.append(case)
    for idl in sorted((ROOT / "tests" / "idl").glob("*.idl")):
        g = run([groovy, str(ROOT / "tools" / "idl" / "idl2code.groovy"), str(idl), str(code_dir / idl.stem), "java", "compile"])
        res = next((l for l in g.stdout.splitlines() if l.startswith("RESULT|")), g.stderr[-300:])
        gen_cases.append({"case": "java/" + idl.name, "result": res, "compile": [l for l in g.stdout.splitlines() if l.startswith("JAVAC|")],
                          "passed": res.startswith("RESULT|OK")})
    for e in (ROOT / "tests" / "idl" / "codegen" / "expected-errors.txt").read_text(encoding="utf-8").splitlines():
        if not e.strip() or e.startswith("#"):
            continue
        rel, target, want = e.split("|", 2)
        g = run([groovy, str(ROOT / "tools" / "idl" / "idl2code.groovy"), str(ROOT / "tests" / "idl" / rel), str(code_dir / ("err-" + target)), target])
        res = next((l for l in g.stdout.splitlines() if l.startswith("RESULT|")), g.stderr[-300:])
        gen_cases.append({"case": f"error/{rel}/{target}", "result": res, "expected": want,
                          "passed": res.startswith("RESULT|FAIL") and want in res})
    report["suites"]["idl-codegen"] = {"passed": all(c["passed"] for c in gen_cases), "cases": gen_cases}

    # 4d. IDL corpus: the core against 701 third-party IDL files (git submodules in external/idl); invariants and
    #     per-file baseline in tools/idl_corpus_check.py
    cc = run([sys.executable, str(ROOT / "tools" / "idl_corpus_check.py"), "--report", str(LOGS / "idl-corpus" / "report.json")],
             timeout=1500)
    corpus_rep = LOGS / "idl-corpus" / "report.json"
    corpus = json.loads(corpus_rep.read_text(encoding="utf-8")) if cc.returncode != 2 and corpus_rep.exists() else {}
    report["suites"]["idl-corpus"] = {"passed": cc.returncode == 0, "summary": corpus.get("summary"),
                                      "violations": corpus.get("violations") or [cc.stderr.strip()[-500:]],
                                      "improvements": corpus.get("improvements", [])}

    # 4e. CATIA Magic customization (customization/catia-magic): syntax, names against the stub of the vendor
    #     library names (tests/catia-magic), documentation and design rules
    cust = sorted((ROOT / "customization").rglob("*.sysml"))
    stub = ROOT / "tests" / "catia-magic"
    cust_cases = []
    if cust:
        syn_ok, syn_errs = syntax_check(cust)
        cust_cases.append({"case": "syntax", "passed": syn_ok, "errors": syn_errs[:10]})
        rc_n, names_rep = name_check(cust, library + sorted(stub.glob("*.sysml")), LOGS / "names-customization.json")
        cust_cases.append({"case": "names", "passed": rc_n == 0,
                           "errors": [f'{Path(f["file"]).name}:{x["line"]} {x["code"]} {x["message"]}'
                                      for f in names_rep["files"] for x in f.get("findings", [])][:10]})
        for profile, targets in (("library", [f for f in cust if f.parent.name == "catia-magic"]),
                                 ("example", [f for f in cust if f.parent.name == "examples"])):
            if not targets:
                continue
            rep_path = LOGS / f"docs-customization-{profile}.json"
            d = run([sys.executable, str(ROOT / "tools" / "check_docs.py"), "--profile", profile,
                     "--report", str(rep_path), *map(str, targets)])
            rep = json.loads(rep_path.read_text(encoding="utf-8")) if d.returncode != 2 and rep_path.exists() else {}
            cust_cases.append({"case": f"docs ({profile})", "passed": d.returncode == 0, "counts": rep.get("counts")})
        rr_c = run([sys.executable, str(ROOT / "tools" / "check_rules.py"), "--stdlib", str(STDLIB),
                    "--index", str(ROOT / "library"), str(stub), "--check", str(ROOT / "customization"),
                    "--report", str(LOGS / "rules-customization.json")])
        cust_cases.append({"case": "rules", "passed": rr_c.returncode == 0,
                           "errors": [rr_c.stdout[-300:]] if rr_c.returncode else []})
        # the diagram-kind model, the view filters and the palettes must agree (issue I-35), and each
        # tests/diagram-kinds fixture must produce exactly its expected problem codes
        dk = run([sys.executable, str(ROOT / "tools" / "check_diagram_kinds.py"), "--stdlib", str(STDLIB),
                  "--report", str(LOGS / "diagram-kinds.json")])
        cust_cases.append({"case": "diagram kinds", "passed": dk.returncode == 0,
                           "errors": [l for l in dk.stdout.splitlines() if not l.startswith("SUMMARY")][:10]})
        # the palette check can fail: each negative control mutates a recorded CATIA Magic read-back once
        pc = run([sys.executable, str(ROOT / "tools" / "check_palettes.py"), "--controls",
                  str(ROOT / "tests" / "cameo" / "palettes-recorded.txt")])
        cust_cases.append({"case": "palette negative controls", "passed": pc.returncode == 0,
                           "errors": [l for l in pc.stdout.splitlines() if l.startswith("FAIL")][:10]})
        dk_dir = ROOT / "tests" / "diagram-kinds"
        for entry in (dk_dir / "expected.txt").read_text(encoding="utf-8").splitlines():
            if not entry.strip() or entry.startswith("#"):
                continue
            case, codes = entry.split("|", 1)
            expected = sorted(c for c in codes.split(",") if c.strip())
            f = run([sys.executable, str(ROOT / "tools" / "check_diagram_kinds.py"), "--stdlib", str(STDLIB),
                     "--kinds", str(dk_dir / f"kinds-{case}.sysml"), "--views", str(dk_dir / f"views-{case}.sysml"),
                     "--palettes", str(dk_dir / f"palettes-{case}.sysml")])
            observed = sorted({l.split()[0] for l in f.stdout.splitlines() if not l.startswith("SUMMARY")})
            cust_cases.append({"case": f"diagram-kind fixture {case}", "expected": expected, "observed": observed,
                               "passed": observed == expected})
    report["suites"]["catia-customization"] = {
        "passed": bool(cust_cases) and all(c["passed"] for c in cust_cases), "cases": cust_cases,
        "errors": [f'{c["case"]}: {e}' for c in cust_cases for e in c.get("errors", [])]}

    # 5. authoritative check in CATIA Magic (optional; needs the harness running)
    if args.cameo:
        # 5a. probes: library + tests/cameo-negative, verify what Cameo builds, undo (harness stays up)
        probes = sorted((ROOT / "tests" / "cameo-negative").glob("*.sysml"))
        r = run([sys.executable, str(ROOT / "tools" / "cameo_check.py"), "--library-only", "--undo", "--validate",
                 "--hypotheses", str(ROOT / "tests" / "cameo-negative" / "probe-effects.json"),
                 "--probes", *map(str, probes)])
        cameo_report = ROOT / "logs" / "cameo" / "cameo-report.json"
        details = json.loads(cameo_report.read_text(encoding="utf-8")) if cameo_report.exists() else {}
        (ROOT / "logs" / "cameo" / "cameo-probes-report.json").write_text(json.dumps(details, indent=2), encoding="utf-8")
        probe_rows = details.get("probes", [])
        report["suites"]["cameo-probes"] = {
            "passed": r.returncode == 0 and bool(probe_rows) and all(p["matchesPrediction"] for p in probe_rows),
            "errors": [f'{p["file"]}: expected {p["expected"]}, observed {p["observed"]}'
                       for p in probe_rows if not p["matchesPrediction"]] or ([r.stderr.strip()] if r.returncode else []),
            "inspectAfterUndo": details.get("inspectAfterUndo"),
            "validationEngine": details.get("validationEngine")}
        if details.get("validationEngine") and not details["validationEngine"]["passed"]:
            report["suites"]["cameo-probes"]["passed"] = False
            report["suites"]["cameo-probes"]["errors"] += details["validationEngine"]["mismatches"]

        # 5a2. patterns (E22): the Observer pattern probes load and validate, their implied relationships hold (a
        #      non-conforming role binding intersects types), and CATIA Magic's evaluation engine gives the
        #      expected verdicts for the pattern requirements, including a model-level one and two false controls
        exp = ROOT / "tests" / "cameo-experiments"
        r = run([sys.executable, str(ROOT / "tools" / "cameo_check.py"), "--library-only", "--undo", "--validate",
                 "--hypotheses", str(exp / "e22-hypotheses.json"), "--evaluations", str(exp / "e22-evaluations.json"),
                 "--probes", str(exp / "e22-pattern-observer.sysml"), str(exp / "e22b-pattern-wrong-binding.sysml"),
                 str(exp / "e22c-pattern-evaluation-controls.sysml")])
        pat = json.loads(cameo_report.read_text(encoding="utf-8")) if cameo_report.exists() else {}
        (ROOT / "logs" / "cameo" / "cameo-patterns-report.json").write_text(json.dumps(pat, indent=2), encoding="utf-8")
        pat_errors = [f'{p["file"]}: expected {p["expected"]}, observed {p["observed"]}'
                      for p in pat.get("probes", []) if not p["matchesPrediction"]]
        pat_errors += [f'{h["id"]}: expected {h["expected"]}, observed {h["observed"]}'
                       for h in pat.get("impliedSpecializations", {}).get("results", []) if h.get("status") != "PASS"]
        pat_errors += [f'{e["id"]}: expected {e["expected"]}, observed {e["observed"]}'
                       for e in pat.get("evaluations", {}).get("results", []) if not e["passed"]]
        report["suites"]["cameo-patterns"] = {
            "passed": r.returncode == 0 and not pat_errors and bool(pat.get("evaluations")),
            "errors": pat_errors or ([r.stderr.strip()[-300:]] if r.returncode else []),
            "evaluations": pat.get("evaluations"), "inspectAfterUndo": pat.get("inspectAfterUndo")}

        # 5b. full load of library + examples, implied-specialization hypotheses, undo, reset
        cmd = [sys.executable, str(ROOT / "tools" / "cameo_check.py"), "--open", "--undo", "--validate", "--display",
               "--views", "--idl", "--svg", "--palettes"]
        if args.shutdown_harness:
            cmd.append("--shutdown")
        r = run(cmd)
        cameo_report = ROOT / "logs" / "cameo" / "cameo-report.json"
        details = json.loads(cameo_report.read_text(encoding="utf-8")) if cameo_report.exists() else {}
        # Surface every failing check, not just load errors (M15 previously showed an empty error).
        errors = [f'{Path(x["file"]).name}: {e}' for x in details.get("loads", []) for e in x["errors"]]
        errors += [f'hypothesis {h["id"]}: expected {h["expected"]}, observed {h["observed"]} {h.get("detail", "")}'
                   for h in details.get("impliedSpecializations", {}).get("results", []) if h.get("status") != "PASS"]
        errors += [f'label {k["id"]} {k["subject"]}: observed {k["observedText"]!r}'
                   for k in details.get("keywordDisplay", {}).get("results", []) if not k["passed"]]
        errors += details.get("validationEngine", {}).get("mismatches", [])
        errors += [f'IDL round trip {r["file"]}: import {r["import"]}, export {r["export"]}, identical={r["identical"]}'
                   for r in details.get("idlRoundTrip", {}).get("results", []) if not r["passed"]]
        errors += [f'view diagram {r["view"]}: {"; ".join(r["problems"])}'
                   for r in details.get("viewDiagrams", {}).get("results", []) if not r["passed"]]
        errors += [f'palette {r["view"]}: {"; ".join(r["problems"])}'
                   for r in details.get("palettes", {}).get("results", []) if not r["passed"]]
        errors += [f'Create View dialog: {e}' for e in
                   ((details.get("palettes", {}).get("dialog") or {}).get("problems") or [])]
        if r.returncode and not errors:
            errors = [r.stderr.strip() or f"cameo_check exit code {r.returncode}"]
        report["suites"]["cameo"] = {
            "passed": r.returncode == 0, "exitCode": r.returncode, "errors": errors,
            "inspectAfterUndo": details.get("inspectAfterUndo")}

        # 5c. sample diagrams (E23): the sample of samples/uml3 drawn in CATIA Magic. It says nothing about how
        #     to draw itself, so every shape is there because a UML3 keyword put it there; the run creates its
        #     own empty SysML v2 project, exports SVG and PNG, and checks modes, layout, shapes, labels and that
        #     the images really rasterised
        r = run([sys.executable, str(ROOT / "tools" / "cameo_check.py"), "--open", "--library-only", "--sample-svg",
                 "--undo"])
        sample = json.loads(cameo_report.read_text(encoding="utf-8")) if cameo_report.exists() else {}
        (ROOT / "logs" / "cameo" / "cameo-sample-report.json").write_text(json.dumps(sample, indent=2),
                                                                         encoding="utf-8")
        smp_errors = [f'{Path(x["file"]).name}: {e}' for x in sample.get("loads", []) for e in x["errors"]]
        smp_errors += [f'sample diagram {d["view"]}: {"; ".join(d["problems"])}'
                       for d in sample.get("sampleDiagrams", {}).get("results", []) if not d["passed"]]
        if (sample.get("project") or {}).get("passed") is False:
            smp_errors.append("no project: " + str(sample["project"]["report"])[-200:])
        if r.returncode and not smp_errors:
            smp_errors = [r.stderr.strip() or f"cameo_check exit code {r.returncode}"]
        report["suites"]["sample-diagrams"] = {
            "passed": r.returncode == 0 and not smp_errors, "errors": smp_errors,
            "diagrams": [{"view": d["view"], "mode": d["mode"], "labels": d["labels"], "png": d.get("pngSize")}
                         for d in sample.get("sampleDiagrams", {}).get("results", [])],
            "inspectAfterUndo": sample.get("inspectAfterUndo")}

    report["finished"] = dt.datetime.now().isoformat(timespec="seconds")
    report["passed"] = all(s["passed"] for s in report["suites"].values())
    (LOGS / "test-report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")

    for name, s in report["suites"].items():
        print(f"{'PASS' if s['passed'] else 'FAIL'}  {name}")
        if name == "negative":
            for c in s["cases"]:
                print(f"    {'ok  ' if c['passed'] else 'FAIL'} {c['file']} expected {c.get('expected')}"
                      + ("" if c["passed"] else f" observed {c.get('observed') or c.get('reason')}"))
        elif not s["passed"]:
            for e in (s.get("errors") or s.get("findings") or [])[:10]:
                print(f"    {e}")
    print(f"OVERALL {'PASS' if report['passed'] else 'FAIL'}  (report: {LOGS / 'test-report.json'})")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        LOGS.mkdir(exist_ok=True)
        (LOGS / "test-harness-error.log").write_text(f"{dt.datetime.now().isoformat()} {exc!r}\n", encoding="utf-8")
        print(f"HARNESS ERROR: {exc!r} (see logs/test-harness-error.log)", file=sys.stderr)
        sys.exit(2)
