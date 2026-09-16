"""
Regression harness for the UML3 SysML v2 extension library.

Suites (each result is recorded in logs/test-report.json):
  syntax-positive     ANTLR sysml-validator on library/ and examples/        -> must PASS
  names-positive      check_names.py on library/ and examples/               -> must PASS
  negative            each tests/negative/*.sysml must FAIL with its EXPECT code
                      (SYNTAX via the validator, IMPORT/TYPE/KEYWORD/QUALIFIED/LINT via check_names)
  checker-calibration check_names.py on the official OMG models              -> must PASS
                      (guards the checker against false positives)
  cameo (--cameo)     tools/cameo_check.py: load library + examples into CATIA Magic through
                      the SysMLv2 test harness REST API, undo the loads, stop the harness.
                      This is the authoritative semantic check.

Paths default to sibling checkouts and can be overridden with environment variables:
  SYSML_RELEASE   (default ../SysML-v2-Release)
  SYSML_VALIDATOR_JAR (default ../sysml-validator/validator-cli/target/sysml-validator.jar)

Usage: python tools/run_tests.py [--skip-calibration] [--cameo [--keep-harness]]
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
EXPECT_RE = re.compile(r"EXPECT:\s*(SYNTAX|IMPORT|TYPE|KEYWORD|QUALIFIED|LINT|APPLICABILITY)")


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
    ap.add_argument("--keep-harness", action="store_true", help="with --cameo: do not shut the harness down")
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
    syntax_files = [f for f in library + examples if f.resolve() not in exempt]
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
    rc, rep = name_check(library + examples, [], LOGS / "names-positive.json")
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

        # 5b. full load of library + examples, implied-specialization hypotheses, undo, shutdown
        cmd = [sys.executable, str(ROOT / "tools" / "cameo_check.py"), "--undo", "--validate", "--display", "--views"]
        if not args.keep_harness:
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
        if r.returncode and not errors:
            errors = [r.stderr.strip() or f"cameo_check exit code {r.returncode}"]
        report["suites"]["cameo"] = {
            "passed": r.returncode == 0, "exitCode": r.returncode, "errors": errors,
            "inspectAfterUndo": details.get("inspectAfterUndo")}

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
