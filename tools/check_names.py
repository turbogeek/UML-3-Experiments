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
  APPLICABILITY  a #keyword applied to an incompatible element kind. Derived from the library:
              SemanticMetadata -> kind of its baseType usage (item allows part, attribute
              allows enum, ...), non-Types rejected; plain metadata -> its annotatedElement
              restriction (inherited through metadata specialization). CATIA Magic's builder
              accepts such models silently (tests/cameo-negative), so this check is required.

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
    quoted: bool = False  # a quoted name ('enum'): never a keyword, whatever its text


def tokenize(text: str) -> list[Tok]:
    """Tokens without comments and notes. The body of an annotating element ('doc', 'comment', 'rep') ends that
    statement without a ';', so a synthetic end-of-statement token (kind 'eos', text ';') is emitted after it;
    otherwise the declaration that follows would not be seen at a statement start."""
    toks: list[Tok] = []
    line = 1
    stmt_start = 0  # index in toks of the first token of the current statement
    for m in TOKEN_RE.finditer(text):
        kind = m.lastgroup
        val = m.group()
        if kind == "comment":
            if stmt_start < len(toks) and toks[stmt_start].text in ("doc", "comment", "rep"):
                toks.append(Tok("eos", ";", line + val.count("\n")))
                stmt_start = len(toks)
        elif kind in ("ws", "blocknote", "note"):
            pass
        elif kind == "qname":
            toks.append(Tok("ident", val[1:-1], line, quoted=True))
        elif kind in ("ident", "sym", "string", "number"):
            toks.append(Tok(kind, val, line))
        else:
            toks.append(Tok("other", val, line))
        if kind == "sym" and val in ("{", "}", ";"):
            stmt_start = len(toks)
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
    # SysML control nodes can be named: 'merge retry;', 'join packedAndLabelled;'
    "merge", "join", "fork", "decide",
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

# Not reserved in SysML (8.2.2.6 / SysML reserved-keyword list) but used like keywords in successions
# ('first start then done'); they are legal element names, e.g. ModelingMetadata::StatusKind::done.
SOFT_NAMES = {"start", "done", "this", "self", "that"}
# Named comments are owned members of their namespace (KerML 7.2.4.2): 'comment Name about ...' or 'comment Name /* */'.
NAMED_COMMENT_RE = re.compile(r"\bcomment\s+([A-Za-z_][A-Za-z0-9_]*|'[^']*')\s+(?=about\b|locale\b|/\*)")

# Construct keywords that determine an element's kind (for keyword applicability).
CONSTRUCT_KINDS = {
    "item", "part", "attribute", "action", "calc", "connection", "allocation", "port", "occurrence",
    "enum", "interface", "flow", "state", "requirement", "concern", "constraint", "case", "analysis",
    "verification", "use", "view", "viewpoint", "rendering", "metadata", "package", "dependency",
    "event", "message", "snapshot", "timeslice", "connect", "allocate",
}
# Kinds whose usages/definitions may specialize a base of the key kind (SysML kind hierarchy).
SUBKINDS = {
    "occurrence": {"occurrence", "item", "part", "connection", "allocation", "interface", "port", "action",
                   "calc", "state", "flow", "event", "requirement", "concern", "constraint", "case",
                   "analysis", "verification", "use", "view", "viewpoint", "rendering", "metadata"},
    "item": {"item", "part", "connection", "allocation", "interface", "metadata"},
    "part": {"part", "connection", "allocation", "interface", "view", "viewpoint", "rendering"},
    "connection": {"connection", "allocation", "interface"},
    "allocation": {"allocation"},
    "interface": {"interface"},
    "port": {"port"},
    "attribute": {"attribute", "enum"},
    "enum": {"enum"},
    "action": {"action", "calc", "state", "case", "analysis", "verification", "use"},
    "calc": {"calc", "case", "analysis", "verification", "use"},
    "state": {"state"},
    "flow": {"flow"},
    "constraint": {"constraint", "requirement", "concern"},
    "requirement": {"requirement", "concern"},
    "concern": {"concern"},
    "case": {"case", "analysis", "verification", "use"},
}
NON_TYPE_KINDS = {"package", "dependency"}
# Type families for SemanticMetadata compatibility. Implied specialization ADDS a supertype, so it
# is only invalid when it joins disjoint families. Normative disjointness in the Kernel library:
#   Occurrences::Occurrence disjoint from Base::DataValue
#   Performances::Performance disjoint from Objects::Object
# (e.g. '#goal constraint' with a requirement baseType is legal: both are Performances.)
KIND_FAMILY = {
    "attribute": "data", "enum": "data",
    "item": "object", "part": "object", "connection": "object", "allocation": "object",
    "interface": "object", "port": "object", "metadata": "object", "view": "object", "rendering": "object",
    "action": "performance", "calc": "performance", "state": "performance", "constraint": "performance",
    "requirement": "performance", "concern": "performance", "case": "performance", "analysis": "performance",
    "verification": "performance", "use": "performance", "viewpoint": "performance",
    "occurrence": "occurrence", "event": "occurrence", "flow": "occurrence",
}
DISJOINT_FAMILIES = [{"data", "object"}, {"data", "performance"}, {"data", "occurrence"}, {"object", "performance"}]
APPLICATION_ALIASES = {"connect": "connection", "allocate": "allocation", "message": "flow",
                       "snapshot": "occurrence", "timeslice": "occurrence"}


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
    decl_kind: str | None = None  # construct keyword: item, part, attribute, action, metadata, package...
    is_def: bool = False
    is_metadata_def: bool = False
    supers: list[str] = field(default_factory=list)  # names after ':>' / 'specializes' in the declaration
    body: list[Tok] = field(default_factory=list)    # tokens between the declaration's braces
    decl: list[Tok] = field(default_factory=list)    # declaration tokens: prefixes .. up to '{' or ';'
    owner: "Scope | None" = field(default=None, repr=False)  # lexically enclosing scope


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


MEMBER_PREFIX_WORDS = {"public", "private", "protected", "in", "out", "inout", "derived", "abstract",
                       "variation", "constant", "ref", "end", "individual", "library", "standard"}


def declaration_span(toks: list[Tok], k: int) -> list[Tok]:
    """Tokens of the declaration whose construct keyword is at k: walk back over member prefixes,
    '#kw' keywords and an end multiplicity '[..]'; walk forward to the first '{' or ';' at depth 0."""
    start = k
    while start > 0:
        prev = toks[start - 1]
        if prev.kind == "ident" and prev.text in MEMBER_PREFIX_WORDS:
            start -= 1
            continue
        if prev.kind == "ident":  # '#a::b' keyword
            m = start - 1
            while m >= 2 and toks[m - 1].text == "::" and toks[m - 2].kind == "ident":
                m -= 2
            if m >= 1 and toks[m - 1].text == "#":
                start = m - 1
                continue
        if prev.text == "]":  # 'end [1] ref x'
            m = start - 1
            while m > 0 and toks[m].text != "[":
                m -= 1
            if m > 0 and toks[m - 1].text == "end":
                start = m - 1
                continue
        break
    end = k
    depth = 0
    while end < len(toks):
        s = toks[end].text
        if s in ("(", "["):
            depth += 1
        elif s in (")", "]"):
            depth -= 1
        elif depth == 0 and s in ("{", ";"):
            break
        end += 1
    return toks[start:end]


def index_file(path: Path) -> FileModel:
    text = path.read_text(encoding="utf-8", errors="replace")
    toks = tokenize(text)
    named_comments = set()
    for m in NAMED_COMMENT_RE.finditer(text):
        name = m.group(1)[1:-1] if m.group(1).startswith("'") else m.group(1)
        named_comments.add((text.count("\n", 0, m.start(1)) + 1, name))
    root = Scope("", "")
    fm = FileModel(path, toks, root)
    stack: list[Scope] = [root]
    body_starts: list[int] = [-1]
    pending: Scope | None = None  # scope to push on next '{'
    i = 0
    while i < len(toks):
        t = toks[i]
        if t.text == "{":
            stack.append(pending if pending is not None else Scope(stack[-1].qname, ""))
            body_starts.append(i)
            pending = None
        elif t.text == "}":
            if len(stack) > 1:
                closed_scope = stack.pop()
                start = body_starts.pop()
                if closed_scope.name:
                    closed_scope.body = toks[start + 1:i]
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
        elif (t.kind == "ident" and t.text == "comment" and i + 1 < len(toks)
              and (toks[i + 1].line, toks[i + 1].text) in named_comments):
            stack[-1].members.add(toks[i + 1].text)
            fm.declared.add(toks[i + 1].text)
            i += 2
            continue
        elif (t.kind == "ident" and (t.text not in NOT_A_NAME or (t.text in SOFT_NAMES and i + 1 < len(toks)
                                                                   and toks[i + 1].text in ("{", ";")))
              and _at_statement_start(toks, i)
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
                words = [t.text] + [x.text for x in toks[i + 1:j] if x.kind == "ident"]
                child.decl_kind = next((w for w in words if w in CONSTRUCT_KINDS), child.decl_kind)
                child.is_def = child.is_def or "def" in words
                child.is_metadata_def = child.is_metadata_def or is_metadata_def
                if name:
                    k = j + 1
                    if k < len(toks) and toks[k].text in (":>", "specializes"):
                        k += 1
                        while k < len(toks) and toks[k].kind == "ident":
                            sup, k = parse_qualified(toks, k)
                            child.supers.append(sup)
                            if k < len(toks) and toks[k].text == ",":
                                k += 1
                            else:
                                break
                if not child.decl:
                    child.decl = declaration_span(toks, i)
                    child.owner = scope
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

    # ---- keyword applicability -------------------------------------------------------

    def metadata_defs(self, name: str) -> list[Scope]:
        """All metadata defs declared with this name or short name."""
        if not hasattr(self, "_meta_by_name"):
            self._meta_by_name: dict[str, list[Scope]] = {}
            for s in self._scopes:
                for key, c in s.children.items():
                    if c.is_metadata_def and c not in self._meta_by_name.setdefault(key, []):
                        self._meta_by_name[key].append(c)
        return self._meta_by_name.get(name, [])

    def _parent(self, scope: Scope) -> Scope | None:
        return self._by_qname.get(scope.qname.rpartition("::")[0])

    def keyword_rule(self, scope: Scope, _seen: set[int] | None = None) -> dict:
        """Applicability rule of a metadata def, inheriting from its supertypes:
        {semantic: bool, baseKind: str|None, restrictions: [(kind|None, isDef|None)]}."""
        seen = _seen if _seen is not None else set()
        if id(scope) in seen:
            return {"semantic": False, "baseKind": None, "restrictions": []}
        seen.add(id(scope))
        rule = {"semantic": False, "baseKind": None, "restrictions": []}
        parent = self._parent(scope)
        ctx = parent.qname if parent is not None else ""
        body = scope.body
        for k in range(len(body) - 3):
            # ':>> baseType = X meta ...'  or  ':>> baseType default X meta ...'
            if body[k].text == ":>>" and body[k + 1].text == "baseType" and body[k + 2].text in ("=", "default"):
                if body[k + 3].kind == "ident":
                    base_name, _ = parse_qualified(body, k + 3)
                    base = self.lookup(base_name, ctx)
                    rule["baseKind"] = base.decl_kind if base is not None else None
            # ':>> annotatedElement : SysML::X'  or  ':> annotatedElement : SysML::X'
            if body[k].text in (":>>", ":>") and body[k + 1].text == "annotatedElement" and body[k + 2].text == ":":
                if body[k + 3].kind == "ident":
                    mc, _ = parse_qualified(body, k + 3)
                    rule["restrictions"].append(metaclass_kind(mc.rpartition("::")[2]))
        for sup in scope.supers:
            if sup.rpartition("::")[2] == "SemanticMetadata":
                rule["semantic"] = True
                continue
            sup_scope = self.lookup(sup, ctx) or self._imported_metadata_def(sup)
            if sup_scope is None:
                continue
            inherited = self.keyword_rule(sup_scope, seen)
            rule["semantic"] = rule["semantic"] or inherited["semantic"]
            rule["baseKind"] = rule["baseKind"] or inherited["baseKind"]
            if not rule["restrictions"]:
                rule["restrictions"] = inherited["restrictions"]
        return rule

    def _imported_metadata_def(self, name: str) -> Scope | None:
        """Metadata def named by a supertype reference that lexical lookup cannot resolve because the owning package
        only imports it (UML3IDL::union :> DataTypeKind through 'private import UML3Core::*'). Resolves a
        unique simple name, preferring UML3 libraries, as check_rules.Model.resolve_keyword does (tests n21, n22)."""
        cands = self.metadata_defs(name.rpartition("::")[2])
        chosen = [c for c in cands if c.qname.startswith("UML3")] or cands
        return chosen[0] if len(chosen) == 1 else None

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
    findings.extend(applicability_findings(toks, idx))
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

    # A reserved word cannot be a declared name: 'enum first { ... }' is rejected by CATIA Magic and by the
    # ANTLR validator ("extraneous input 'first'"), because 'first' belongs to the succession syntax. The
    # indexer simply does not read such a token as a name, so without this check the file looks clean (E12).
    # The declaration may start with prefixes and keywords ('abstract ref #templateParameter item subject : T'), so
    # the scan starts at a statement start and walks over prefixes, construct words and '#keyword' applications up
    # to the word that a name terminator follows. That word is a declared name unless it is itself a construct
    # word with no construct word before it, as in the unnamed 'in ref = x' or 'part;'. (E22: a role named
    # 'subject' passed the old check, which started only at a construct word that opened the statement.)
    k = 0
    while k < len(toks):
        if ((toks[k].kind == "ident" and toks[k].text in DECL_SKIP) or toks[k].text == "#") \
                and _at_statement_start(toks, k):
            j = k
            while j < len(toks):
                nxt = toks[j + 1].text if j + 1 < len(toks) else ""
                if (toks[j].kind == "ident" and not toks[j].quoted and toks[j].text in DECL_SKIP
                        and nxt not in NAME_TERMINATORS):
                    j += 1
                elif toks[j].text == "#" and j + 1 < len(toks) and toks[j + 1].kind == "ident":
                    _, j = parse_qualified(toks, j + 1)
                else:
                    break
            if j + 2 < len(toks) and toks[j].text == "<" and toks[j + 1].kind == "ident" and toks[j + 2].text == ">":
                j += 3
            prev = toks[j - 1].text if j >= 1 else ""
            if (j < len(toks) and toks[j].kind == "ident" and not toks[j].quoted and toks[j].text in NOT_A_NAME
                    and toks[j].text not in SOFT_NAMES
                    and j + 1 < len(toks) and toks[j + 1].text in NAME_TERMINATORS
                    and (toks[j].text not in DECL_SKIP or prev in NAMING_WORDS)):
                findings.append(Finding("LINT", toks[j].line,
                                        f"'{toks[j].text}' is a reserved word and cannot be a declared name"))
            k = max(j, k + 1)
            continue
        k += 1
    return findings


# What may follow a declared name, and the construct words after which a declared name comes (a direction such as
# 'in' can be followed by a construct word instead: 'in ref = x' declares no name).
NAME_TERMINATORS = ("{", ";", ":", ":>", "[", "=")
NAMING_WORDS = {"part", "item", "attribute", "port", "action", "calc", "connection", "allocation", "occurrence",
                "state", "constraint", "requirement", "flow", "interface", "view", "viewpoint", "rendering",
                "concern", "case", "analysis", "verification", "metadata", "enum", "def", "snapshot", "timeslice",
                "event", "message", "ref"}


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


def metaclass_kind(metaclass: str) -> tuple[str | None, bool | None]:
    """SysML metaclass name -> (kind, isDef). 'PartDefinition' -> ('part', True); 'Dependency' ->
    ('dependency', None); 'Usage' -> (None, False); 'Element'/'Type' -> (None, None)."""
    if metaclass == "Dependency":
        return "dependency", None
    if metaclass == "Package":
        return "package", None
    for suffix, is_def in (("Definition", True), ("Usage", False)):
        if metaclass.endswith(suffix):
            stem = metaclass[: -len(suffix)]
            if not stem:
                return None, is_def
            kind = {"Calculation": "calc", "Enumeration": "enum", "Reference": None, "Occurrence": "occurrence",
                    "EventOccurrence": "event", "UseCase": "use", "AnalysisCase": "analysis",
                    "VerificationCase": "verification", "Flow": "flow"}.get(stem, stem.lower())
            return kind, is_def
    return None, None


def applicability_findings(toks: list[Tok], idx: "Index") -> list[Finding]:
    """At each '#kw ... construct', check the keyword may annotate that kind of element."""
    findings: list[Finding] = []
    i = 0
    while i < len(toks):
        if toks[i].text != "#" or i + 1 >= len(toks) or toks[i + 1].kind != "ident":
            i += 1
            continue
        # collect a run of '#kw' prefixes
        keywords: list[tuple[str, int]] = []
        j = i
        while j + 1 < len(toks) and toks[j].text == "#" and toks[j + 1].kind == "ident":
            qn, j = parse_qualified(toks, j + 1)
            keywords.append((qn.rpartition("::")[2], toks[i].line))
        construct = toks[j].text if j < len(toks) else ""
        if construct in ("library", "standard"):  # 'library #kw package' has keywords after 'library'
            construct = "package"
        kind = APPLICATION_ALIASES.get(construct, construct)
        is_def = j + 1 < len(toks) and toks[j + 1].text == "def"
        if kind in CONSTRUCT_KINDS or kind in SUBKINDS:
            for kw, line in keywords:
                candidates = idx.metadata_defs(kw)
                if not candidates:
                    continue  # unknown keyword: reported by the KEYWORD check
                problems = []
                for cand in candidates:
                    problem = _rule_violation(idx.keyword_rule(cand), kind, is_def)
                    if problem is None:
                        problems = []
                        break
                    problems.append(problem)
                if problems:
                    target = f"{construct}{' def' if is_def else ''}"
                    findings.append(Finding("APPLICABILITY", line, f"#{kw} cannot be applied to '{target}': {problems[0]}"))
        i = max(j, i + 1)
    return findings


def _rule_violation(rule: dict, kind: str, is_def: bool) -> str | None:
    if rule["semantic"]:
        if kind in NON_TYPE_KINDS:
            return "semantic metadata requires a Type (not a package or dependency)"
        base = rule["baseKind"]
        fam_base, fam_elem = KIND_FAMILY.get(base or ""), KIND_FAMILY.get(kind)
        if fam_base and fam_elem and {fam_base, fam_elem} in DISJOINT_FAMILIES:
            return (f"its baseType is a '{base}' usage ({fam_base}), which is disjoint from a "
                    f"'{kind}' ({fam_elem}) - the implied specialization would make an empty type")
        return None
    for r_kind, r_def in rule["restrictions"]:
        if (r_kind is None or kind in SUBKINDS.get(r_kind, {r_kind})) and (r_def is None or r_def == is_def):
            return None
    if rule["restrictions"]:
        allowed = ", ".join(f"{k or 'any'}{'' if d is None else (' def' if d else ' usage')}" for k, d in rule["restrictions"])
        return f"annotatedElement is restricted to {allowed}"
    return None


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
