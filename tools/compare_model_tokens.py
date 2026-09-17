"""
Checks that a documentation-only change did not change the model: compares the token stream of a file with its
version in a git revision after removing everything documentation adds or moves.

Removed before comparing: comments and notes, 'doc [name] [locale "x"]' prefixes, 'comment [name] [about a, b::c]
[locale "x"]' statements, and body braces that became empty ('x { }' is compared as 'x ;').

Usage: python tools/compare_model_tokens.py [--rev HEAD] files...
Output: SAME <file> / CHANGED <file> first difference ... ; exit code 0 all same, 1 any change, 2 tool error.
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_names as cn  # noqa: E402


def normalized(text: str) -> list[str]:
    toks = [t.text for t in cn.tokenize(text)]
    out: list[str] = []
    i = 0
    while i < len(toks):
        t = toks[i]
        if t == "doc":
            i += 1
            if i < len(toks) and toks[i] == "locale":
                i += 2
            elif i < len(toks) and toks[i] not in ("{", "}", ";") and toks[i].isidentifier() and i + 1 < len(toks) \
                    and toks[i + 1] in ("locale",):
                i += 3
            continue
        if t == "comment":
            i += 1
            if i < len(toks) and toks[i].isidentifier() and toks[i] not in ("about", "locale"):
                i += 1
            if i < len(toks) and toks[i] == "about":
                i += 1
                while i < len(toks):
                    i += 1  # element name
                    while i + 1 < len(toks) and toks[i] == "::":
                        i += 2
                    if i < len(toks) and toks[i] == ",":
                        i += 1
                        continue
                    break
            if i < len(toks) and toks[i] == "locale":
                i += 2
            continue
        out.append(t)
        i += 1
    # 'x { }' -> 'x ;'
    changed = True
    while changed:
        changed = False
        res: list[str] = []
        j = 0
        while j < len(out):
            if out[j] == "{" and j + 1 < len(out) and out[j + 1] == "}":
                res.append(";")
                j += 2
                changed = True
            else:
                res.append(out[j])
                j += 1
        out = res
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--rev", default="HEAD")
    ap.add_argument("files", nargs="+")
    args = ap.parse_args()
    root = Path(__file__).resolve().parent.parent
    changed = 0
    for f in args.files:
        p = Path(f).resolve()
        rel = p.relative_to(root).as_posix()
        old = subprocess.run(["git", "show", f"{args.rev}:{rel}"], cwd=root, capture_output=True, text=True, encoding="utf-8")
        if old.returncode != 0:
            print(f"TOOL ERROR {rel}: {old.stderr.strip()}", file=sys.stderr)
            return 2
        a, b = normalized(old.stdout), normalized(p.read_text(encoding="utf-8"))
        if a == b:
            print(f"SAME {rel} ({len(b)} tokens)")
            continue
        changed += 1
        k = next((k for k in range(min(len(a), len(b))) if a[k] != b[k]), min(len(a), len(b)))
        print(f"CHANGED {rel} first difference at token {k}: old {' '.join(a[max(0, k - 6):k + 6])!r} "
              f"new {' '.join(b[max(0, k - 6):k + 6])!r}")
    return 1 if changed else 0


if __name__ == "__main__":
    sys.exit(main())
