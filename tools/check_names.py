"""
Lightweight SysML v2 name-resolution checker.

Why this exists: the ANTLR-based sysml-validator reports syntax errors but does NOT
resolve names (proven: unresolved types/imports pass). This checker indexes the
standard library plus project files and verifies, per file:

  IMPORT      import targets exist                     (import P::*; import P::N;)
  TYPE        typing / subsetting / conjugation targets  (: T   :> T   ~T   meta T)
  KEYWORD     prefix / body metadata                     (#kw   @Meta)
  QUALIFIED   A::B::C in value expressions (e.g. Enum::literal), reported only when the
              missing member belongs to a package or enum def (complete member lists)
  LINT        constraints the ANTLR validator accepts but CATIA Magic / Pilot reject:
              member prefix order (visibility, direction, derived, abstract, constant,
              ref/end, #keywords) and integer literals beyond 32-bit int

Visibility model (deliberately approximate, documented so results are interpretable):
  visible(file) = names declared anywhere in the file
                ∪ members of packages/types imported by the file (::* direct, ::** recursive),
                  following public (non-private) re-exports to a fixpoint
                ∪ root-level namespace names of all indexed files
Not checked: redefinition targets (:>>), feature chains (a.b.c), inherited members,
simple names inside expressions, typing conformance, multiplicities, and the implied
specialization created by SemanticMetadata. Those require full semantic analysis
(OMG Pilot Implementation).

Calibration: run against SysML-v2-Release validation/, examples/ and training/ models,
which are known to be valid; any finding there is a checker false positive.

Usage:
  python check_names.py --stdlib <sysml.library> --index <dir-or-file>... --check <dir-or-file>...
         [--report report.json]
Exit code: 0 = no findings, 1 = findings, 2 = tool error.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

# ---------------------------------------------------------------------------
# Lexing
# ---------------------------------------------------------------------------

TOKEN_RE = re.compile(
    r"""
    (?P<ws>\s+)
  | (?P<comment>/\*.*?\*/)
  | (?P<blocknote>//\*.*?\*/)
  | (?P<note>//[^\n]*)
  | (?P<string>"(?:[^"\\]|\\.)*")
  | (?P<qname>'(?:[^'\\]|\\.)*')
  | (?P<number>\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)
  | (?P<ident>[A-Za-z_][A-Za-z0-9_]*)
  | (?P<sym>::>|:>>|::\*\*|::\*|::|:>|\.\.|[~#@<>{}();:,\[\]=.*+\-/%?&|!^$])
  | (?P<other>.)
    """,
    re.VERBOSE | re.DOTALL,
)


@dataclass
class Tok:
    kind: str  # ident | sym | string | number | other
    text: str
    line: int


def tokenize(text: str) -> list[Tok]:
    toks: list[Tok] = []
    line = 1
    for m in TOKEN_RE.finditer(text):
        kind = m.lastgroup
        val = m.group()
        if kind in ("ws", "comment", "blocknote", "note"):
            pass
        elif kind == "qname":
            toks.append(Tok("ident", val[1:-1], line))
        elif kind in ("ident", "sym", "string", "number"):
            toks.append(Tok(kind, val, line))
        else:
            toks.append(Tok("other", val, line))
        line += val.count("\n")
    return toks


# Keywords after which the next identifier (optionally preceded by <short>) is a declared name.
DECL_KEYWORDS = {
    # SysML
    "package", "def", "part", "item", "attribute", "port", "action", "calc", "connection",
    "allocation", "enum", "occurrence", "state", "constraint", "requirement", "flow",
    "interface", "ref", "individual", "snapshot", "timeslice", "event", "message", "view",
    "viewpoint", "rendering", "concern", "case", "analysis", "verification", "use", "dependency",
    "succession", "binding", "alias", "metadata", "subject", "actor", "stakeholder", "objective",
    "return", "in", "out", "inout", "end", "exhibit", "perform", "include", "transition",
    # KerML
    "feature", "class", "datatype", "struct", "assoc", "behavior", "function", "predicate",
    "metaclass", "type", "classifier", "connector", "expr", "step", "bool", "inv", "namespace",
    "interaction", "multiplicity",
}
# Tokens that may appear between a declaration keyword and the declared name.
DECL_SKIP = {"def", "ref", "abstract", "variation", "derived", "constant", "readonly", "var",
             "composite", "portion", "individual", "in", "out", "inout", "end", "all"} | DECL_KEYWORDS
NOT_A_NAME = {
    "specializes", "subsets", "redefines", "references", "conjugates", "defined", "by", "from",
    "to", "of", "all", "about", "then", "if", "else", "for", "while", "until", "via", "accept",
    "send", "do", "entry", "exit", "first", "connect", "allocate", "bind", "true", "false", "null",
    "new", "meta", "as", "hastype", "istype", "and", "or", "xor", "not", "implies", "ordered",
    "nonunique", "default", "private", "public", "protected", "import", "library", "standard",
    "filter", "expose", "doc", "comment", "language", "rep", "locale", "disjoint", "unions",
    "intersects", "differences", "chains", "inverse", "featured", "typed", "specialization",
    "subclassifier", "subtype", "subset", "redefinition", "conjugation", "disjoining", "featuring",
    "crosses", "start", "done", "this", "self", "that",
} | DECL_KEYWORDS - {"def"}


# ---------------------------------------------------------------------------
# Indexing
# ---------------------------------------------------------------------------

@dataclass
class Scope:
    qname: str
    name: str
    members: set[str] = field(default_factory=set)       # direct member names (incl. short names)
    children: dict[str, "Scope"] = field(default_factory=dict)
    metadata_names: set[str] = field(default_factory=set)  # names of metadata defs declared here
    reexports: list[tuple[str, str]] = field(default_factory=list)  # non-private imports: (target, mode)
    closed: bool = False  # package / enum def: member list is complete (nothing inherited)


@dataclass
class FileModel:
    path: Path
    tokens: list[Tok]
    root: Scope
    declared: set[str] = field(default_factory=set)
    metadata_declared: set[str] = field(default_factory=set)
    imports: list[tuple[str, int, str, str]] = field(default_factory=list)  # (target, line, mode, scope qname)


def parse_qualified(toks: list[Tok], i: int) -> tuple[str, int]:
    """Read A::B::C starting at i; returns (qualified name, next index)."""
    parts = [toks[i].text]
    j = i + 1
    while j + 1 < len(toks) and toks[j].text == "::" and toks[j + 1].kind == "ident":
        parts.append(toks[j + 1].text)
        j += 2
    return "::".join(parts), j


def index_file(path: Path) -> FileModel:
    text = path.read_text(encoding="utf-8", errors="replace")
    toks = tokenize(text)
    root = Scope("", "")
    fm = FileModel(path, toks, root)
    stack: list[Scope] = [root]
    pending: Scope | None = None  # scope to push on next '{'
    i = 0
    while i < len(toks):
        t = toks[i]
        if t.text == "{":
            stack.append(pending if pending is not None else Scope(stack[-1].qname, ""))
            pending = None
        elif t.text == "}":
            if len(stack) > 1:
                stack.pop()
        elif t.text == ";":
            pending = None
        elif t.kind == "ident" and t.text == "import":
            j = i + 1
            if j < len(toks) and toks[j].text == "all":
                j += 1
            if j < len(toks) and toks[j].kind == "ident":
                target, k = parse_qualified(toks, j)
                mode = "name"
                if k < len(toks) and toks[k].text in ("::*", "::**"):
                    mode = "star" if toks[k].text == "::*" else "recursive"
                fm.imports.append((target, t.line, mode, stack[-1].qname))
                # SysML v2: imports are public unless marked private, and public imports re-export.
                if not (i >= 1 and toks[i - 1].text == "private"):
                    stack[-1].reexports.append((target, mode))
                i = k
                continue
        elif (t.kind == "ident" and t.text not in NOT_A_NAME and _at_statement_start(toks, i)
              and i + 1 < len(toks) and toks[i + 1].text in (":", ":>", "{", ";", "[", "=")):
            # Keyword-less declaration: 'distancePerVolume :> scalarQuantities = ...;'
            # or an extended usage '#system service_registry { ... }'.
            scope = stack[-1]
            scope.members.add(t.text)
            fm.declared.add(t.text)
            q = f"{scope.qname}::{t.text}" if scope.qname else t.text
            child = scope.children.get(t.text) or Scope(q, t.text)
            scope.children[t.text] = child
            pending = child
        elif t.kind == "ident" and t.text in DECL_KEYWORDS:
            is_metadata_def = t.text == "metadata" and i + 1 < len(toks) and toks[i + 1].text == "def"
            j = i + 1
            while j < len(toks) and toks[j].kind == "ident" and toks[j].text in DECL_SKIP:
                j += 1
            short = None
            if j + 2 < len(toks) and toks[j].text == "<" and toks[j + 1].kind == "ident" and toks[j + 2].text == ">":
                short = toks[j + 1].text
                j += 3
            name = None
            if j < len(toks) and toks[j].kind == "ident" and toks[j].text not in NOT_A_NAME:
                # A usage like 'attribute x : T' or a def name. Exclude qualified references
                # such as 'perform action a::b' by requiring the next token is not '::'.
                if not (j + 1 < len(toks) and toks[j + 1].text in ("::", ".")):
                    name = toks[j].text
            scope = stack[-1]
            for n in (short, name):
                if n:
                    scope.members.add(n)
                    fm.declared.add(n)
                    if is_metadata_def:
                        scope.metadata_names.add(n)
                        fm.metadata_declared.add(n)
            if name or short:
                key = name or short
                q = f"{scope.qname}::{key}" if scope.qname else key
                child = scope.children.get(key) or Scope(q, key)
                scope.children[key] = child
                if short and name:
                    scope.children[short] = child
                # Packages and enumerations have no inherited members, so their member
                # lists are complete and a missing member is a real error.
                if t.text == "package" or (t.text == "enum" and i + 1 < len(toks) and toks[i + 1].text == "def"):
                    child.closed = True
                pending = child
            i = j + (1 if name else 0)
            continue
        i += 1
    return fm


class Index:
    """Namespace index. Call finalize() after all add() calls, before any lookup."""

    def __init__(self) -> None:
        self.roots: dict[str, Scope] = {}  # root-level namespaces by name (merged across files)
        self.all_metadata: set[str] = set()
        self._eff: dict[int, dict[str, Scope]] = {}    # effective children incl. re-exports
        self._eff_meta: dict[int, set[str]] = {}       # effective metadata names incl. re-exports
        self._by_qname: dict[str, Scope] = {}
        self._scopes: list[Scope] = []
        self._finalized = False
        self.nested_names: set[str] = set()

    def add(self, fm: FileModel) -> None:
        for key, child in fm.root.children.items():
            existing = self.roots.get(key)
            if existing is None:
                self.roots[key] = child
            else:
                merge(existing, child)
        self.all_metadata |= fm.metadata_declared
        self._finalized = False

    def finalize(self, max_passes: int = 20) -> int:
        """Resolve public re-exports to a fixpoint. Returns the number of passes used."""
        self._scopes, self._by_qname, seen = [], {}, set()
        stack = list(self.roots.values())
        while stack:
            s = stack.pop()
            if id(s) in seen:
                continue
            seen.add(id(s))
            self._scopes.append(s)
            self._by_qname.setdefault(s.qname, s)
            stack.extend(s.children.values())
        self.nested_names = {n for s in self._scopes if s.qname.count("::") >= 1 for n in s.members}
        self._eff = {id(s): dict(s.children) for s in self._scopes}
        self._eff_meta = {id(s): set(s.metadata_names) for s in self._scopes}
        self._finalized = True
        for n in range(1, max_passes + 1):
            changed = False
            for s in self._scopes:
                eff, meta = self._eff[id(s)], self._eff_meta[id(s)]
                for target, mode in s.reexports:
                    tgt = self.lookup(target, s.qname)
                    if tgt is None:
                        continue
                    if mode == "name":
                        for n in {target.rpartition("::")[2], tgt.name}:
                            if n not in eff:
                                eff[n] = tgt
                                changed = True
                            if n in self.all_metadata and n not in meta:
                                meta.add(n)
                                changed = True
                    else:
                        for k, v in list(self._eff[id(tgt)].items()):
                            if k not in eff:
                                eff[k] = v
                                changed = True
                        new_meta = self._eff_meta[id(tgt)] - meta
                        if new_meta:
                            meta |= new_meta
                            changed = True
            if not changed:
                return n
        return max_passes

    def child(self, scope: Scope, name: str) -> Scope | None:
        eff = self._eff.get(id(scope))
        return eff.get(name) if eff is not None else scope.children.get(name)

    def lookup(self, qname: str, context: str = "") -> Scope | None:
        """Resolve a qualified name relative to enclosing scope qname 'context', then from the root."""
        parts = qname.split("::")
        ctx = context
        while True:
            if ctx:
                base = self._by_qname.get(ctx)
                scope = self.child(base, parts[0]) if base is not None else None
            else:
                scope = self.roots.get(parts[0])
            for p in parts[1:]:
                if scope is None:
                    break
                scope = self.child(scope, p)
            if scope is not None or not ctx:
                return scope
            ctx = ctx.rpartition("::")[0]

    def exported_names(self, scope: Scope, recursive: bool = False) -> tuple[set[str], set[str], dict[str, Scope]]:
        """(member names, metadata names, child scopes) made visible by importing scope::* (or ::**)."""
        kids: dict[str, Scope] = {}
        meta: set[str] = set()
        names: set[str] = set()
        stack, seen = [scope], set()
        while stack:
            s = stack.pop()
            if id(s) in seen:
                continue
            seen.add(id(s))
            eff = self._eff.get(id(s), s.children)
            names |= s.members | set(eff.keys())
            meta |= self._eff_meta.get(id(s), s.metadata_names)
            for k, v in eff.items():
                kids.setdefault(k, v)
            if not recursive:
                break
            stack.extend(eff.values())
        return names, meta, kids


def merge(into: Scope, other: Scope) -> None:
    into.members |= other.members
    into.metadata_names |= other.metadata_names
    into.reexports.extend(r for r in other.reexports if r not in into.reexports)
    into.closed = into.closed or other.closed
    for k, v in other.children.items():
        if k in into.children:
            if into.children[k] is not v:
                merge(into.children[k], v)
        else:
            into.children[k] = v


# ---------------------------------------------------------------------------
# Checking
# ---------------------------------------------------------------------------

@dataclass
class Finding:
    code: str
    line: int
    message: str


def find_scope_in_file(fm: FileModel, name: str) -> Scope | None:
    """Depth-first search for a scope with the given simple name declared in this file."""
    stack = [fm.root]
    seen: set[int] = set()
    while stack:
        s = stack.pop()
        if id(s) in seen:
            continue
        seen.add(id(s))
        if name in s.children:
            return s.children[name]
        stack.extend(s.children.values())
    return None


def check_file(fm: FileModel, idx: Index) -> list[Finding]:
    findings: list[Finding] = []
    visible: set[str] = set(fm.declared) | set(idx.roots.keys())
    visible_scopes: dict[str, Scope] = {}
    visible_metadata: set[str] = set(fm.metadata_declared)

    def resolve_import(target: str, context: str) -> Scope | None:
        scope = idx.lookup(target, context)
        if scope is None:
            parts = target.split("::")
            # head may be file-local, or made visible by another (e.g. enclosing) import
            local = find_scope_in_file(fm, parts[0]) or visible_scopes.get(parts[0])
            for p in parts[1:]:
                local = idx.child(local, p) if local is not None else None
            scope = local
        return scope

    pending = list(fm.imports)
    # Resolve in rounds: an import may depend on names made visible by another import.
    while pending:
        unresolved = []
        for target, line, mode, context in pending:
            scope = resolve_import(target, context)
            if scope is None:
                unresolved.append((target, line, mode, context))
                continue
            if mode == "name":
                # register both the name as written (may be a short name) and the declared name
                for n in {target.rpartition("::")[2], scope.name}:
                    visible.add(n)
                    visible_scopes[n] = scope
                    if n in idx.all_metadata or n in fm.metadata_declared:
                        visible_metadata.add(n)
            else:
                names, meta, kids = idx.exported_names(scope, recursive=(mode == "recursive"))
                visible |= names
                visible_metadata |= meta
                for k, c in kids.items():
                    visible_scopes.setdefault(k, c)
        if len(unresolved) == len(pending):
            for target, line, _, _ in unresolved:
                findings.append(Finding("IMPORT", line, f"import target '{target}' not found"))
            break
        pending = unresolved

    def resolve_qualified(qn: str, line: int, code: str, closed_only: bool = False) -> None:
        """closed_only: report only misses inside packages/enums (used for value expressions,
        where the head may be a usage whose members are inherited from its type)."""
        parts = qn.split("::")
        head = parts[0]
        scope = find_scope_in_file(fm, head) or visible_scopes.get(head) or idx.roots.get(head)
        if scope is None:
            if not closed_only:
                findings.append(Finding(code, line, f"'{head}' (in '{qn}') is not visible"))
            return
        for p in parts[1:]:
            nxt = idx.child(scope, p)
            if nxt is None and p not in scope.members:
                if closed_only and not scope.closed:
                    return
                findings.append(Finding(code, line, f"'{p}' is not a member of '{scope.qname or head}' (in '{qn}')"))
                return
            scope = nxt if nxt is not None else Scope(f"{scope.qname}::{p}", p)

    toks = fm.tokens
    findings.extend(lint_file(toks))
    i = 0
    while i < len(toks):
        t = toks[i]
        # skip import statements (already checked)
        if t.kind == "ident" and t.text == "import":
            while i < len(toks) and toks[i].text != ";":
                i += 1
            continue
        ref_start = None
        code = None
        subsetting = False  # ':>' / 'subsets' / list continuation, vs ':' typing
        if t.text in ("#", "@") and i + 1 < len(toks) and toks[i + 1].kind == "ident":
            ref_start, code = i + 1, "KEYWORD"
        elif t.text in (":", ":>", "~") and i + 1 < len(toks) and toks[i + 1].kind == "ident":
            if t.text == ":>" and _is_inherited_subsetting(toks, i):
                i += 1
                continue
            ref_start, code = i + 1, "TYPE"
            subsetting = t.text == ":>"
        elif t.kind == "ident" and t.text in ("specializes", "subsets", "meta") and i + 1 < len(toks) and toks[i + 1].kind == "ident":
            ref_start, code = i + 1, "TYPE"
            subsetting = t.text == "subsets"
        elif t.text == "," and i >= 1 and i + 1 < len(toks) and toks[i + 1].kind == "ident" and _in_specialization_list(toks, i):
            ref_start, code = i + 1, "TYPE"
            subsetting = True
        if ref_start is not None:
            first = toks[ref_start]
            if first.text in NOT_A_NAME and first.text not in ("state", "item", "part"):
                i += 1
                continue
            qn, nxt = parse_qualified(toks, ref_start)
            # Ignore feature chains (a.b) - not resolvable without semantics.
            if nxt < len(toks) and toks[nxt].text == ".":
                i = nxt
                continue
            if "::" in qn:
                resolve_qualified(qn, first.line, code)
            elif code == "KEYWORD":
                if qn not in visible_metadata:
                    hint = " (declared in an indexed library but not imported)" if qn in idx.all_metadata else ""
                    findings.append(Finding(code, first.line, f"metadata/keyword '{qn}' is not visible{hint}"))
            elif qn not in visible and not (subsetting and qn in idx.nested_names):
                # A subsetted name that exists as a nested feature somewhere is most likely an
                # inherited feature, which this checker cannot resolve - not reported.
                findings.append(Finding(code, first.line, f"type or feature '{qn}' is not visible"))
            i = nxt
            continue
        # Qualified names anywhere else (value expressions such as Enum::literal).
        if (t.kind == "ident" and i + 2 < len(toks) and toks[i + 1].text == "::"
                and toks[i + 2].kind == "ident" and not (i >= 1 and toks[i - 1].text in ("::", "."))):
            qn, nxt = parse_qualified(toks, i)
            if not (nxt < len(toks) and toks[nxt].text == "."):
                resolve_qualified(qn, t.line, "QUALIFIED", closed_only=True)
            i = nxt
            continue
        i += 1
    return findings


# Member prefix ordering from the SysML textual BNF (sysml-validator's ANTLR grammar is more
# lenient than CATIA Magic / Pilot, which reject out-of-order prefixes):
#   MemberPrefix(visibility) RefPrefix(direction derived abstract|variation constant)
#   ['ref' | 'end' | 'individual'] UsageExtensionKeyword/DefinitionExtensionKeyword('#Kw')*
PREFIX_RANK = {
    "public": 0, "private": 0, "protected": 0,
    "in": 1, "out": 1, "inout": 1,
    "derived": 2,
    "abstract": 3, "variation": 3,
    "constant": 4,
    "ref": 5, "end": 5, "individual": 5,
    "#": 6,
}
MAX_INT_LITERAL = 2147483647  # CATIA Magic stores integer literals as Java int


def lint_file(toks: list[Tok]) -> list[Finding]:
    """Grammar/implementation constraints the ANTLR validator does not enforce."""
    findings: list[Finding] = []
    for i, t in enumerate(toks):
        if t.kind == "number" and t.text.isdigit() and int(t.text) > MAX_INT_LITERAL:
            findings.append(Finding("LINT", t.line, f"integer literal {t.text} exceeds 32-bit int; "
                                                    "use a Real literal such as 4.294967295E9"))
    i = 0
    while i < len(toks):
        prev = toks[i - 1].text if i >= 1 else "{"
        # 'doc' counts as a boundary because the lexer strips its /* body */
        if prev in ("{", ";", "}", "doc") and toks[i].text in PREFIX_RANK:
            seq: list[tuple[str, int]] = []
            j = i
            while j < len(toks) and toks[j].text in PREFIX_RANK:
                if toks[j].text == "#":
                    if j + 1 >= len(toks) or toks[j + 1].kind != "ident":
                        break
                    _, k = parse_qualified(toks, j + 1)
                    seq.append(("#" + toks[j + 1].text, toks[j].line))
                    j = k
                else:
                    seq.append((toks[j].text, toks[j].line))
                    j += 1
            ranks = [PREFIX_RANK["#" if w.startswith("#") else w] for w, _ in seq]
            for (w1, _), (w2, line), r1, r2 in zip(seq, seq[1:], ranks, ranks[1:]):
                if r2 < r1:
                    findings.append(Finding("LINT", line, f"prefix '{w2}' must come before '{w1}' "
                                                          "(order: visibility, direction, derived, abstract, "
                                                          "constant, ref/end, #keywords)"))
                    break
            i = max(j, i + 1)
            continue
        i += 1
    return findings


def _at_statement_start(toks: list[Tok], k: int) -> bool:
    """True if toks[k] begins a member (after '{', ';', '}', visibility, or a '#Kw' / '#Q::Kw' prefix)."""
    j = k - 1
    # skip any number of prefix metadata keywords: '#a #b::c'
    while j >= 1 and toks[j].kind == "ident":
        m = j
        while m >= 2 and toks[m - 1].text == "::" and toks[m - 2].kind == "ident":
            m -= 2
        if m >= 1 and toks[m - 1].text == "#":
            j = m - 2
        else:
            break
    if j < 0:
        return True
    # 'doc' is a boundary because its /* body */ is stripped by the lexer
    return toks[j].text in ("{", ";", "}", "public", "private", "protected", "doc")


def _is_inherited_subsetting(toks: list[Tok], k: int) -> bool:
    """':>' with no declared name before it subsets an inherited feature (unverifiable here)."""
    prev = toks[k - 1] if k >= 1 else None
    return prev is None or prev.text in ("{", ";", "}") or (prev.kind == "ident" and prev.text in DECL_SKIP)


def _in_specialization_list(toks: list[Tok], i: int) -> bool:
    """True if the ',' at i continues a ':>' / ':' / 'specializes' list on the same declaration."""
    j = i - 1
    depth = 0
    while j >= 0:
        s = toks[j].text
        if s in (";", "{", "}"):
            return False
        if s in (")", "]"):
            depth += 1
        elif s in ("(", "["):
            if depth == 0:
                return False
            depth -= 1
        elif depth == 0 and s in (":>", ":", "specializes", "subsets", "~"):
            return not (s == ":>" and _is_inherited_subsetting(toks, j))
        elif depth == 0 and s in ("=", ":=", ":>>", "redefines", "to", "from"):
            return False
        j -= 1
    return False


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def collect(paths: list[str], exts: tuple[str, ...]) -> list[Path]:
    out: list[Path] = []
    for p in paths:
        pp = Path(p)
        if pp.is_dir():
            out.extend(sorted(f for f in pp.rglob("*") if f.suffix in exts))
        elif pp.is_file():
            out.append(pp)
        else:
            raise FileNotFoundError(p)
    return out


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--stdlib", required=True)
    ap.add_argument("--index", nargs="*", default=[], help="extra files/dirs to index (not checked)")
    ap.add_argument("--check", nargs="+", required=True, help="files/dirs to index AND check")
    ap.add_argument("--report", help="write JSON report here")
    args = ap.parse_args(argv)

    started = time.time()
    idx = Index()
    std_files = collect([args.stdlib], (".sysml", ".kerml"))
    if not std_files:
        print(f"TOOL ERROR: no standard library files under {args.stdlib}", file=sys.stderr)
        return 2
    for f in std_files:
        idx.add(index_file(f))
    # Guard against a silently empty index (would make every check meaningless).
    for must in ("ScalarValues", "Metaobjects", "SysML", "Parts"):
        if must not in idx.roots:
            print(f"TOOL ERROR: standard library index missing '{must}' - check --stdlib path", file=sys.stderr)
            return 2

    extra = [index_file(f) for f in collect(args.index, (".sysml", ".kerml"))]
    checked = [index_file(f) for f in collect(args.check, (".sysml",))]
    for fm in extra + checked:
        idx.add(fm)
    passes = idx.finalize()

    report = {"tool": "check_names.py", "stdlibFiles": len(std_files), "rootNamespaces": len(idx.roots), "reexportPasses": passes,
              "files": [], "totalFindings": 0}
    total = 0
    for fm in checked:
        fnd = check_file(fm, idx)
        total += len(fnd)
        status = "PASS" if not fnd else "FAIL"
        print(f"{status}  {fm.path}  ({len(fnd)} findings)")
        for f in fnd:
            print(f"    {f.code:<9} line {f.line}: {f.message}")
        report["files"].append({"file": str(fm.path), "status": status,
                                "findings": [f.__dict__ for f in fnd]})
    report["totalFindings"] = total
    report["elapsedSeconds"] = round(time.time() - started, 2)
    if args.report:
        Path(args.report).parent.mkdir(parents=True, exist_ok=True)
        Path(args.report).write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"SUMMARY files={len(checked)} findings={total} stdlibFiles={len(std_files)} roots={len(idx.roots)}")
    return 0 if total == 0 else 1


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except Exception as exc:  # report tool failures distinctly from model findings
        print(f"TOOL ERROR: {exc!r}", file=sys.stderr)
        sys.exit(2)
