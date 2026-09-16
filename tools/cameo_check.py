"""
Authoritative semantic check through the CATIA Magic / Cameo SysML v2 test harness.

The harness (sysml-validator/utilityScripts/start-v2language-test-harness.groovy) exposes
  GET  /status
  POST /load-sysml  {"filePath": ...}   parse + link + validate; on SUCCESS the model is
                                        COPIED INTO THE OPEN PROJECT (errors cancel the session)
  POST /run-script  {"scriptName": ...} run a Groovy script from the harness scripts dir
  POST /shutdown

Because later files resolve names against what earlier loads persisted, files are loaded in
dependency order and the run stops at the first failure (later errors would be cascades).

Usage:
  python tools/cameo_check.py [--port 8770] [--undo] [--shutdown] [files...]
    default files: library (Core, Types, Components, Messaging, Data) then examples/*.sysml
    --undo      afterwards run undoUML3Loads.groovy to remove only the packages loaded here
    --shutdown  afterwards stop the harness (frees cached script classes)
Writes logs/cameo/cameo-report.json and one response file per load.
Exit code: 0 all loaded, 1 a load failed, 2 harness unavailable / tool error.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOGS = ROOT / "logs" / "cameo"
LIBRARY_ORDER = ["UML3Core", "UML3Types", "UML3Components", "UML3Messaging", "UML3Data"]
UNDO_SCRIPT = "undoUML3Loads.groovy"
INSPECT_SCRIPT = "inspectUML3Roots.groovy"


def call(port: int, path: str, payload: dict | None = None, timeout: int = 600) -> tuple[int, dict]:
    url = f"http://localhost:{port}{path}"
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="GET" if payload is None else "POST",
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8", errors="replace")
            status = resp.status
    except urllib.error.HTTPError as e:  # harness uses 400/500 for model errors
        body = e.read().decode("utf-8", errors="replace")
        status = e.code
    try:
        return status, json.loads(body)
    except json.JSONDecodeError:
        return status, {"raw": body}


def split_errors(resp: dict) -> list[str]:
    err = resp.get("error") or ""
    # the harness joins diagnostics with a literal backslash-n
    return [ln for ln in err.replace("\\n", "\n").splitlines() if ln.strip()]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8770)
    ap.add_argument("--undo", action="store_true")
    ap.add_argument("--shutdown", action="store_true")
    ap.add_argument("files", nargs="*")
    args = ap.parse_args()
    LOGS.mkdir(parents=True, exist_ok=True)

    try:
        status, st = call(args.port, "/status", timeout=10)
    except Exception as exc:
        print(f"HARNESS UNAVAILABLE on port {args.port}: {exc!r} - start the SysMLv2 test harness in Cameo",
              file=sys.stderr)
        return 2
    if status != 200:
        print(f"HARNESS UNAVAILABLE: /status returned {status} {st}", file=sys.stderr)
        return 2

    if args.files:
        files = [Path(f).resolve() for f in args.files]
    else:
        files = [ROOT / "library" / f"{n}.sysml" for n in LIBRARY_ORDER] + sorted((ROOT / "examples").glob("*.sysml"))
    missing = [str(f) for f in files if not f.exists()]
    if missing:
        print("MISSING FILES: " + ", ".join(missing), file=sys.stderr)
        return 2

    report: dict = {"started": dt.datetime.now().isoformat(timespec="seconds"), "port": args.port, "loads": []}
    _, before = call(args.port, "/run-script", {"scriptName": INSPECT_SCRIPT})
    report["inspectBefore"] = before.get("result", before)
    if "matches=0" not in str(report["inspectBefore"]):
        print("WARNING: UML3 packages already present in the project before loading:\n" + str(report["inspectBefore"]))

    failed = False
    for f in files:
        status, resp = call(args.port, "/load-sysml", {"filePath": f.as_posix()})
        errors = split_errors(resp)
        ok = status == 200 and resp.get("success") is True
        (LOGS / f"load-{f.stem}.json").write_text(json.dumps({"status": status, "response": resp}, indent=2),
                                                  encoding="utf-8")
        report["loads"].append({"file": str(f), "httpStatus": status, "success": ok, "errors": errors})
        print(f"{'PASS' if ok else 'FAIL'}  {f.name}  (HTTP {status}, {len(errors)} error lines)")
        for e in errors[:40]:
            print(f"    {e}")
        if not ok:
            failed = True
            print("    stopping: later files depend on this one")
            break

    _, after = call(args.port, "/run-script", {"scriptName": INSPECT_SCRIPT})
    report["inspectAfterLoads"] = after.get("result", after)

    if args.undo:
        _, undo = call(args.port, "/run-script", {"scriptName": UNDO_SCRIPT})
        report["undo"] = undo.get("result", undo)
        _, clean = call(args.port, "/run-script", {"scriptName": INSPECT_SCRIPT})
        report["inspectAfterUndo"] = clean.get("result", clean)
        print("UNDO: " + str(report["undo"]).strip().replace("\n", " | "))
        print("AFTER UNDO: " + str(report["inspectAfterUndo"]).strip().replace("\n", " | "))

    if args.shutdown:
        _, sd = call(args.port, "/shutdown", {})
        report["shutdown"] = sd

    report["finished"] = dt.datetime.now().isoformat(timespec="seconds")
    report["passed"] = not failed
    (LOGS / "cameo-report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"OVERALL {'PASS' if not failed else 'FAIL'}  (report: {LOGS / 'cameo-report.json'})")
    return 0 if not failed else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        LOGS.mkdir(parents=True, exist_ok=True)
        (LOGS / "cameo-check-error.log").write_text(f"{dt.datetime.now().isoformat()} {exc!r}\n", encoding="utf-8")
        print(f"TOOL ERROR: {exc!r}", file=sys.stderr)
        sys.exit(2)
