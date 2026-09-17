"""
Checks the UML3 palettes that CATIA Magic builds from customization/catia-magic (verifyPalettes.groovy output)
against tests/cameo/palette-expectations.json.

Per view:
  VISUALIZATION  the view's visualization is the UML3 one, so the view definition is registered (E17: CATIA Magic
                 registers a custom view definition only through its FIRST general type)
  CATEGORIES     every expected UML3 category is in the palette, and no category listed in absentCategories is
  BUTTONS        every expected button is there with the element kind and UML3 keyword its template carries
                 (a 'class' button must copy an ItemDefinition annotated with ClassMetadata), and no templated
                 button is left without a template
  DIALOG         the UML3 Create View dialog is the active one and offers the expected commands (optional)

Usage (library): check(verify_text) -> report dict;  CLI: python tools/check_palettes.py palettes.txt
"""
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXPECTATIONS = ROOT / "tests" / "cameo" / "palette-expectations.json"


def parse(text: str) -> dict:
    """verifyPalettes.groovy output -> {views: {path: {...}}, dialogs: {...}, dslValid: bool, registered: [names]}"""
    views: dict[str, dict] = defaultdict(lambda: {"categories": [], "buttons": defaultdict(list), "errors": []})
    out = {"views": views, "registered": [], "dslValid": None, "activeDialog": None, "dialogItems": defaultdict(list)}
    for line in text.splitlines():
        f = line.split("|")
        if f[0] == "DSL" and len(f) > 2:
            out["dslValid"] = f[2] == "true"
        elif f[0] == "VISLIST" and len(f) > 1:
            out["registered"].append(f[1])
        elif f[0] == "VIS" and len(f) > 4:
            views[f[1]]["visualization"] = f[4]
        elif f[0] == "CAT" and len(f) > 2:
            views[f[1]]["categories"].append(f[2])
        elif f[0] == "BTN" and len(f) > 8:
            m = re.match(r"template:(\w+):([^:]*):([\w,]*)$", f[8])
            views[f[1]]["buttons"][f[2]].append({
                "label": f[5], "kind": m.group(1) if m else None,
                "keywords": [k for k in (m.group(3).split(",") if m else []) if k],
                "operation": f[8]})
        elif f[0] == "ERROR" and len(f) > 2:
            views[f[1]]["errors"].append("|".join(f[2:]))
        elif f[0] == "DLGACTIVE" and len(f) > 1:
            out["activeDialog"] = f[1]
        elif f[0] == "DLGITEM" and len(f) > 3:
            out["dialogItems"][f[1]].append(f[3])
    return out


def load_expectations() -> dict:
    return json.loads(EXPECTATIONS.read_text(encoding="utf-8"))


def check(verify_text: str, expectations: dict | None = None) -> dict:
    spec = expectations if expectations is not None else load_expectations()
    observed = parse(verify_text)
    absent = spec.get("absentCategories", [])
    results = []
    for e in spec["views"]:
        o = observed["views"].get(e["view"])
        problems: list[str] = []
        if o is None:
            problems.append("view not in the verifyPalettes output")
            o = {"categories": [], "buttons": {}, "errors": []}
        problems += list(o.get("errors", []))
        if o.get("visualization") != e["visualization"]:
            problems.append(f"visualization {o.get('visualization')!r}, expected {e['visualization']!r} "
                            "(is the view definition registered? its first general type must be bsv)")
        for category, buttons in e["categories"].items():
            if category not in o["categories"]:
                problems.append(f"category {category!r} missing (palette has {o['categories']})")
                continue
            seen = {b["label"]: b for b in o["buttons"].get(category, [])}
            for label, kind, keyword in buttons:
                b = seen.get(label)
                if b is None:
                    problems.append(f"{category}: no button labeled {label!r}")
                elif b["kind"] != kind or (keyword and keyword not in b["keywords"]):
                    problems.append(f"{category}: button {label!r} copies {b['kind']} {b['keywords']}, "
                                    f"expected {kind} [{keyword}]")
            for b in o["buttons"].get(category, []):
                if b["operation"].startswith("template:null"):
                    problems.append(f"{category}: button {b['label']!r} has no template element")
        for category in absent:
            if category in o["categories"]:
                problems.append(f"category {category!r} should have been removed")
        results.append({"view": e["view"], "visualization": o.get("visualization"),
                        "categories": len(o["categories"]), "problems": problems, "passed": not problems})
    dialog = spec.get("dialog")
    dialog_result = None
    if dialog:
        problems = []
        if observed["activeDialog"] != dialog["active"]:
            problems.append(f"active Create View dialog is {observed['activeDialog']!r}, expected {dialog['active']!r}")
        items = observed["dialogItems"].get(dialog["active"], [])
        for label in dialog.get("commands", []):
            if label not in items:
                problems.append(f"no Create View command labeled {label!r}")
        dialog_result = {"active": observed["activeDialog"], "problems": problems, "passed": not problems}
    passed = bool(results) and all(r["passed"] for r in results) and observed["dslValid"] is not False \
        and (dialog_result is None or dialog_result["passed"])
    return {"passed": passed, "dslValid": observed["dslValid"], "registered": observed["registered"],
            "results": results, "dialog": dialog_result}


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    report = check(Path(sys.argv[1]).read_text(encoding="utf-8"))
    for r in report["results"]:
        print(f"{'PASS' if r['passed'] else 'FAIL'}  {r['view']}  {r['visualization']}  "
              f"{'; '.join(r['problems'])}")
    if report["dialog"] is not None:
        d = report["dialog"]
        print(f"{'PASS' if d['passed'] else 'FAIL'}  Create View dialog {d['active']}  {'; '.join(d['problems'])}")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
