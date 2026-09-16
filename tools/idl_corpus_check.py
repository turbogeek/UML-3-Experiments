"""
IDL corpus regression check: the UML3 IDL core against third-party IDL files (git submodules in external/idl).

Runs tools/idl/idl_corpus.groovy over every external/idl/**/*.idl and compares each outcome with
tests/idl/corpus/baseline.json. Invariants (any violation fails):
  I1  no CRASH and no TIMEOUT: every failure must be a proper IdlException with a line number
  I2  every ACCEPTed file has a STABLE canonical round trip (write -> parse -> write identical)
  I3  a file under a known-invalid directory (expectations.json "mustFail") is not ACCEPTed,
      unless the baseline records it as a known leniency (v1 has no semantic checks)
  I4  no regression: a file ACCEPTed in the baseline is still ACCEPTed
  I5  code generation never crashes (CRASH) and generated Java always compiles (no NOCOMPILE): a generator may
      only refuse a construct with an IdlException (NOMAP)
  I6  no regression: Java / Rust generation that was OK in the baseline is still OK
Newly ACCEPTed files are reported as improvements; rerun with --update-baseline to record them.

Usage: python tools/idl_corpus_check.py [--update-baseline] [--report logs/idl-corpus/report.json]
Exit code: 0 pass, 1 invariant violated, 2 environment problem (e.g. submodules not checked out).
"""
from __future__ import annotations

import argparse
import collections
import csv
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORPUS = ROOT / "external" / "idl"
EXPECT = ROOT / "tests" / "idl" / "corpus" / "expectations.json"
BASELINE = ROOT / "tests" / "idl" / "corpus" / "baseline.json"
LOGS = ROOT / "logs" / "idl-corpus"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--update-baseline", action="store_true")
    ap.add_argument("--report", default=str(LOGS / "report.json"))
    args = ap.parse_args()

    files = sorted(p.relative_to(ROOT).as_posix() for p in CORPUS.rglob("*.idl"))
    if not files:
        print("ENVIRONMENT ERROR: no IDL corpus; run: git submodule update --init --depth 1", file=sys.stderr)
        return 2
    LOGS.mkdir(parents=True, exist_ok=True)
    (LOGS / "files.txt").write_text("\n".join(files) + "\n", encoding="utf-8")
    results_tsv = LOGS / "results.tsv"
    g = subprocess.run(["groovy", str(ROOT / "tools" / "idl" / "idl_corpus.groovy"), str(LOGS / "files.txt"),
                        str(results_tsv), "20"], cwd=ROOT, capture_output=True, text=True, encoding="utf-8",
                       errors="replace", shell=(os.name == "nt"), timeout=1200)
    summary = next((l for l in g.stdout.splitlines() if l.startswith("SUMMARY|")), None)
    if summary is None or not results_tsv.exists():
        print("TOOL ERROR: corpus runner produced no summary\n" + g.stdout[-2000:] + g.stderr[-2000:], file=sys.stderr)
        return 2
    rows = {r["file"]: r for r in csv.DictReader(results_tsv.open(encoding="utf-8"), delimiter="\t")}

    expectations = json.loads(EXPECT.read_text(encoding="utf-8"))
    must_fail = lambda f: any(f.startswith(prefix) for prefix in expectations["mustFail"])
    baseline = json.loads(BASELINE.read_text(encoding="utf-8"))["files"] if BASELINE.exists() else {}
    # baseline entries: {"outcome", "java", "rust"} (older baselines: the outcome string)
    baseline = {f: (v if isinstance(v, dict) else {"outcome": v}) for f, v in baseline.items()}

    violations, improvements, changes = [], [], []
    for f, r in rows.items():
        o, entry = r["outcome"], baseline.get(f, {})
        before = entry.get("outcome")
        for col in ("java", "rust"):
            val = r.get(col) or "-"
            if val.startswith("CRASH") or val.startswith("NOCOMPILE"):
                violations.append(f"I5 {col} {val[:200]} {f}")
            if entry.get(col) == "OK" and val != "OK":
                violations.append(f"I6 {col} regression {f}: was OK, now {val[:200]}")
        if o in ("CRASH", "TIMEOUT"):
            violations.append(f"I1 {o} {f}: {r['detail']}")
        if o == "ACCEPT" and r["roundTrip"] != "STABLE":
            violations.append(f"I2 round trip {r['roundTrip']} {f}")
        if o == "ACCEPT" and must_fail(f) and before != "ACCEPT":
            violations.append(f"I3 known-invalid file newly ACCEPTed {f}")
        if before == "ACCEPT" and o != "ACCEPT":
            violations.append(f"I4 regression {f}: was ACCEPT, now {o}: {r['detail']}")
        if before is not None and before != o:
            changes.append(f"{f}: {before} -> {o}")
            if o == "ACCEPT" and not must_fail(f):
                improvements.append(f)
    missing = sorted(set(baseline) - set(rows))

    def counts(pred):
        return dict(collections.Counter(r["outcome"] for f, r in rows.items() if pred(f)))

    report = {"summary": summary, "files": len(rows), "validCorpus": counts(lambda f: not must_fail(f)),
              "knownInvalid": counts(must_fail), "violations": violations, "improvements": improvements,
              "changes": changes, "missingFromCorpus": missing, "passed": not violations}
    Path(args.report).write_text(json.dumps(report, indent=2), encoding="utf-8")

    if args.update_baseline:
        if any(v.startswith(("I1", "I2", "I5")) for v in violations):
            print("REFUSED: fix I1/I2 violations before recording a baseline", file=sys.stderr)
        else:
            BASELINE.write_text(json.dumps({"description": "Outcome per corpus file (tools/idl_corpus_check.py "
                                            "--update-baseline). ACCEPT entries are regression-protected.",
                                            "counts": dict(collections.Counter(r["outcome"] for r in rows.values())),
                                            "codegen": {"javaOK": sum(r.get("java") == "OK" for r in rows.values()),
                                                        "rustOK": sum(r.get("rust") == "OK" for r in rows.values())},
                                            "files": {f: {"outcome": r["outcome"], "java": r.get("java", "-")[:6].rstrip(":"),
                                                          "rust": r.get("rust", "-")[:6].rstrip(":")}
                                                      for f, r in sorted(rows.items())}},
                                           indent=1) + "\n", encoding="utf-8")
            print(f"baseline written: {BASELINE}")
            report["passed"] = not any(v.startswith(("I1", "I2", "I5")) for v in violations)

    print(summary)
    print(f"valid corpus {report['validCorpus']}  known-invalid {report['knownInvalid']}")
    for v in violations[:40]:
        print("VIOLATION " + v)
    if improvements:
        print(f"{len(improvements)} newly ACCEPTed files (record with --update-baseline)")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
