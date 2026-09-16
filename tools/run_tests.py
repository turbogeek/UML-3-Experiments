"""
Regression harness for the UML3 SysML v2 extension library.

Suites (each result is recorded in logs/test-report.json):
  syntax-positive     ANTLR sysml-validator on library/ and examples/        -> must PASS
  names-positive      check_names.py on library/ and examples/               -> must PASS
  negative            each tests/negative/*.sysml must FAIL with its EXPECT code
                      (SYNTAX via the validator, IMPORT/TYPE/KEYWORD via check_names)
  checker-calibration check_names.py on the official OMG models              -> must PASS
                      (guards the checker against false positives)

Paths default to sibling checkouts and can be overridden with environment variables:
  SYSML_RELEASE   (default ../SysML-v2-Release)
  SYSML_VALIDATOR_JAR (default ../sysml-validator/validator-cli/target/sysml-validator.jar)

Usage: python tools/run_tests.py [--skip-calibration]
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
EXPECT_RE = re.compile(r"EXPECT:\s*(SYNTAX|IMPORT|TYPE|KEYWORD|QUALIFIED)")


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

    # 1. syntax, positive
    ok, errs = syntax_check(library + examples)
    report["suites"]["syntax-positive"] = {"passed": ok, "files": len(library + examples), "errors": errs}

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
