"""
UML3 design-rules checker: modeling rules that are valid SysML v2 but poor or inconsistent designs.

It reuses the index of check_names.py (declarations, keywords, bodies) and reports:

  ID   Severity  Rule
  R01  ERROR     #table has at least one #primaryKey column
  R02  WARNING   #entity / #aggregateRoot has an identity (#primaryKey or #id)
  R03  ERROR     #foreignKey ref points to an #entity / #aggregateRoot / #table;
                 a #foreignKey column's @ForeignKey referencedTable names an existing #table
       WARNING   a #foreignKey column without referencedTable
  R04  WARNING   #association / #relationship / #aggregation / #composition is binary (2 ends)
  R05  WARNING   operations of an #interfaceType are abstract
  R06  ERROR     a concrete definition realizing an #interfaceType redefines (:>>) every abstract operation
  R07  ERROR     #provided ports are not conjugated; #required ports are conjugated (~)
  R08  WARNING   every #required port of a part is connected inside the owning definition
  R09  WARNING   message types (#command, #domainEvent, ...) declare at least one payload attribute
  R10  WARNING   #topic / #queue definitions declare @QualityOfService
  R11  WARNING   #dbView definitions set queryText
  R12  WARNING   a usage with 2+ UML3 semantic keywords: CATIA Magic 2026x applies only the first
                 keyword's implied specialization (experiments E02/E03)
  R14  ERROR     'constant' on a package-level usage (KerML: constant features must be variable; CATIA Magic E08)
  R15  ERROR     a redefinition gives a value to a feature whose value is already bound (not 'default') in a
                 general type, e.g. a keyword metadata def that specializes #dataType and rebinds baseType
                 (KerML validateFeatureValueOverriding; CATIA Magic E15)

Keywords are normalized to the qualified name of the library metadata def they resolve to, so
'#primaryKey' (prefix, short name) and '@PrimaryKey' (body, declared name) are the same keyword.

Usage:
  python check_rules.py --stdlib <sysml.library> --index library --check examples [--report r.json]
Exit code: 0 = no ERROR findings (warnings allowed), 1 = ERROR findings, 2 = tool error.
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_names as cn  # noqa: E402

KW = {  # rule vocabulary -> qualified metadata def names
    "table": "UML3Data::TableMetadata", "dbView": "UML3Data::DatabaseViewMetadata",
    "entity": "UML3Data::EntityMetadata", "aggregateRoot": "UML3Data::AggregateRootMetadata",
    "primaryKey": "UML3Data::PrimaryKey", "foreignKey": "UML3Data::ForeignKey",
    "id": "UML3Core::Identifier",
    "association": "UML3Core::AssociationMetadata", "aggregation": "UML3Core::AggregationMetadata",
    "composition": "UML3Core::CompositionMetadata", "relationship": "UML3Data::RelationshipMetadata",
    "interfaceType": "UML3Core::InterfaceTypeMetadata",
    "operation": "UML3Core::OperationMetadata", "query": "UML3Core::QueryMetadata",
    "provided": "UML3Components::Provided", "required": "UML3Components::Required",
    "messageType": "UML3Messaging::MessageTypeMetadata", "command": "UML3Messaging::CommandMetadata",
    "domainEvent": "UML3Messaging::DomainEventMetadata", "queryMessage": "UML3Messaging::QueryMessageMetadata",
    "reply": "UML3Messaging::ReplyMetadata", "documentMessage": "UML3Messaging::DocumentMessageMetadata",
    "topic": "UML3Messaging::TopicMetadata", "queue": "UML3Messaging::QueueMetadata",
    "qos": "UML3Messaging::QualityOfService",
}
MESSAGE_KWS = {KW[k] for k in ("messageType", "command", "domainEvent", "queryMessage", "reply", "documentMessage")}
ASSOCIATION_KWS = {KW[k] for k in ("association", "aggregation", "composition", "relationship")}
IDENTITY_TARGET_KWS = {KW[k] for k in ("entity", "aggregateRoot", "table")}


@dataclass
class Finding:
    rule: str
    severity: str
    file: str
    line: int
    element: str
    message: str


@dataclass
class Element:
    scope: cn.Scope
    file: str
    keywords: set[str] = field(default_factory=set)   # qualified metadata def names
    semantic_keywords: list[str] = field(default_factory=list)
    typed_by: list[str] = field(default_factory=list)
    conjugated: bool = False
    abstract: bool = False
    is_end: bool = False
    is_ref: bool = False
    redefined: set[str] = field(default_factory=set)  # names redefined (:>>) in the body
    line: int = 0


class Model:
    def __init__(self, idx: cn.Index, files: dict[int, str]):
        self.idx = idx
        self.files = files  # id(scope) -> file path, for scopes declared in checked files
        self._elements: dict[int, Element] = {}

    # -- keyword resolution ------------------------------------------------------------
    def resolve_keyword(self, name: str) -> str | None:
        cands = self.idx.metadata_defs(name.rpartition("::")[2])
        uml3 = [c for c in cands if c.qname.startswith("UML3")]
        chosen = uml3 or cands
        return chosen[0].qname if chosen else None

    def element(self, scope: cn.Scope) -> Element:
        if id(scope) in self._elements:
            return self._elements[id(scope)]
        e = Element(scope, self.files.get(id(scope), ""))
        decl = scope.decl
        e.line = decl[0].line if decl else 0
        words = [t.text for t in decl]
        e.abstract = "abstract" in words
        e.is_end = "end" in words
        e.is_ref = "ref" in words
        k = 0
        while k < len(decl):
            t = decl[k]
            if t.text == "#" and k + 1 < len(decl) and decl[k + 1].kind == "ident":
                qn, k = cn.parse_qualified(decl, k + 1)
                self._add_keyword(e, qn)
                continue
            if t.text == ":" and k + 1 < len(decl):
                j = k + 1
                if decl[j].text == "~":
                    e.conjugated = True
                    j += 1
                if j < len(decl) and decl[j].kind == "ident":
                    qn, k = cn.parse_qualified(decl, j)
                    e.typed_by.append(qn)
                    continue
            k += 1
        depth = 0
        body = scope.body
        for k, t in enumerate(body):
            if t.text == "{":
                depth += 1
            elif t.text == "}":
                depth -= 1
            # '@M' applies metadata only at a statement start; inside expressions (e.g. 'filter @M or @N;')
            # it is a metadata test and must not count as a keyword of this element
            elif depth == 0 and t.text == "@" and k + 1 < len(body) and body[k + 1].kind == "ident" and \
                    (k == 0 or body[k - 1].text in ("{", ";", "}", "doc")):
                qn, _ = cn.parse_qualified(body, k + 1)
                self._add_keyword(e, qn)
            elif depth == 0 and t.text == ":>>" and k + 1 < len(body) and body[k + 1].kind == "ident":
                e.redefined.add(body[k + 1].text)
        self._elements[id(scope)] = e
        return e

    def _add_keyword(self, e: Element, name: str) -> None:
        q = self.resolve_keyword(name)
        if q is None:
            return
        if q not in e.keywords:
            e.keywords.add(q)
            meta = self.idx.metadata_defs(q.rpartition("::")[2])
            if meta and self.idx.keyword_rule(meta[0])["semantic"] and q.startswith("UML3"):
                e.semantic_keywords.append(q)

    def keyword_label(self, qualified: str) -> str:
        """Short name users write ('column') for a metadata def ('UML3Data::ColumnMetadata')."""
        meta = self.idx._by_qname.get(qualified)
        owner = self.idx._by_qname.get(qualified.rpartition("::")[0])
        if meta is not None and owner is not None:
            for key, c in owner.children.items():
                if c is meta and key != meta.name:
                    return key
        return qualified.rpartition("::")[2]

    # -- structure helpers -------------------------------------------------------------
    def members(self, scope: cn.Scope) -> list[cn.Scope]:
        seen, out = set(), []
        for key, c in scope.children.items():
            if key == c.name and id(c) not in seen:
                seen.add(id(c))
                out.append(c)
        return out

    def resolve_type(self, name: str, near: cn.Scope) -> cn.Scope | None:
        ctx = near.owner.qname if near.owner is not None else ""
        found = self.idx.lookup(name, ctx)
        if found is not None:
            return found
        simple = name.rpartition("::")[2]
        matches = [s for s in self.idx._scopes if s.name == simple and s.is_def]
        return matches[0] if len(matches) == 1 else None

    def supers_closure(self, scope: cn.Scope) -> list[cn.Scope]:
        out, stack, seen = [], [scope], {id(scope)}
        while stack:
            s = stack.pop()
            for sup in s.supers:
                t = self.resolve_type(sup, s)
                if t is not None and id(t) not in seen:
                    seen.add(id(t))
                    out.append(t)
                    stack.append(t)
        return out


def check(model: Model, scopes: list[cn.Scope]) -> list[Finding]:
    out: list[Finding] = []

    def add(rule, sev, e: Element, msg):
        out.append(Finding(rule, sev, e.file, e.line, e.scope.qname, msg))

    table_names = {s.name for s in model.idx._scopes if s.is_def and KW["table"] in model.element(s).keywords}

    for s in scopes:
        e = model.element(s)
        kws = e.keywords
        mems = [model.element(m) for m in model.members(s)]

        if s.is_def and KW["table"] in kws and not any(KW["primaryKey"] in m.keywords for m in mems):
            add("R01", "ERROR", e, "#table has no #primaryKey column")

        if s.is_def and kws & {KW["entity"], KW["aggregateRoot"]} and \
                not any(m.keywords & {KW["primaryKey"], KW["id"]} for m in mems):
            add("R02", "WARNING", e, "entity has no identity (#primaryKey or #id)")

        if KW["foreignKey"] in kws and not s.is_def:
            if e.is_ref and e.typed_by:
                target = model.resolve_type(e.typed_by[0], s)
                if target is None:
                    add("R03", "WARNING", e, f"#foreignKey target '{e.typed_by[0]}' could not be resolved")
                elif not (model.element(target).keywords & IDENTITY_TARGET_KWS or
                          any(model.element(t).keywords & IDENTITY_TARGET_KWS for t in model.supers_closure(target))):
                    add("R03", "ERROR", e, f"#foreignKey refers to '{target.name}', which is not an #entity, "
                                           "#aggregateRoot or #table")
            else:
                ref_table = _string_value(s.body, "referencedTable")
                if ref_table is None:
                    add("R03", "WARNING", e, "#foreignKey column has no @ForeignKey { referencedTable = ...; }")
                elif ref_table not in table_names:
                    add("R03", "ERROR", e, f"@ForeignKey referencedTable '{ref_table}' is not a #table")

        if s.is_def and kws & ASSOCIATION_KWS:
            ends = sum(1 for m in mems if m.is_end)
            if ends != 2:
                add("R04", "WARNING", e, f"association has {ends} ends (expected a binary association)")

        if s.is_def and KW["interfaceType"] in kws:
            for m in mems:
                if m.keywords & {KW["operation"], KW["query"]} and not m.abstract:
                    add("R05", "WARNING", m, f"operation '{m.scope.name}' of #interfaceType '{s.name}' is not abstract")

        if s.is_def and not e.abstract and KW["interfaceType"] not in kws:
            closure = model.supers_closure(s)
            interfaces = [t for t in closure if KW["interfaceType"] in model.element(t).keywords]
            if interfaces:
                redefined = set(e.redefined)
                for t in closure:
                    if t not in interfaces:
                        redefined |= model.element(t).redefined
                for itf in interfaces:
                    for op in model.members(itf):
                        ope = model.element(op)
                        if ope.abstract and ope.keywords & {KW["operation"], KW["query"]} and op.name not in redefined:
                            add("R06", "ERROR", e, f"does not redefine abstract operation '{op.name}' of "
                                                   f"#interfaceType '{itf.name}'")

        if not s.is_def and KW["provided"] in kws and e.conjugated:
            add("R07", "ERROR", e, "#provided port must not be conjugated (~)")
        if not s.is_def and KW["required"] in kws and not e.conjugated:
            add("R07", "ERROR", e, "#required port must be typed by a conjugated port def (~)")

        if s.is_def:
            body_text = [t.text for t in s.body]
            for part in model.members(s):
                pe = model.element(part)
                if part.decl_kind not in ("part", "item") or not pe.typed_by:
                    continue
                part_def = model.resolve_type(pe.typed_by[0], part)
                if part_def is None:
                    continue
                for definition in [part_def] + model.supers_closure(part_def):
                    for pm in model.members(definition):
                        if KW["required"] in model.element(pm).keywords and \
                                not _chain_connected(body_text, part.name, pm.name):
                            add("R08", "WARNING", pe, f"#required port '{part.name}.{pm.name}' is not connected in "
                                                      f"'{s.name}'")

        if s.is_def and kws & MESSAGE_KWS and not any(m.scope.decl_kind == "attribute" for m in mems):
            add("R09", "WARNING", e, "message type declares no payload attributes")

        if s.is_def and kws & {KW["topic"], KW["queue"]} and KW["qos"] not in kws:
            add("R10", "WARNING", e, "channel has no @QualityOfService")

        if s.is_def and KW["dbView"] in kws and "queryText" not in e.redefined:
            add("R11", "WARNING", e, "#dbView does not set queryText")

        if not s.is_def and "constant" in [t.text for t in s.decl] and s.owner is not None and \
                (s.owner.decl_kind == "package" or s.owner.qname == ""):
            add("R14", "ERROR", e, "'constant' on a package-level usage: KerML requires constant features to be variable "
                                   "(owned by an occurrence); use a bound value 'attribute x : T = v;' (CATIA Magic E08)")

        if not s.is_def and len(e.semantic_keywords) >= 2:
            names = ", ".join("#" + model.keyword_label(q) for q in e.semantic_keywords)
            add("R12", "WARNING", e, f"{names}: CATIA Magic 2026x applies only the first semantic keyword's "
                                     "implied specialization (E02/E03); order keywords by query importance")

        overriding = _valued_redefinitions(s)
        if overriding:
            generals = [t for t in (model.resolve_type(n, s) for n in e.typed_by) if t is not None]
            generals += [g for t in list(generals) for g in model.supers_closure(t)] + model.supers_closure(s)
            for name in sorted(overriding):
                owner = next((g for g in generals if _valued_features(model, g).get(name) is False), None)
                if owner is not None:
                    hint = " specialize a keyword category such as UML3Core::DataTypeKind instead;" \
                        if name == "baseType" else ""
                    add("R15", "ERROR", e, f"redefines '{name}', whose value is already bound (not 'default') in "
                                           f"'{owner.qname}':{hint} KerML validateFeatureValueOverriding forbids "
                                           "overriding it (CATIA Magic E15)")
    return out


def _valued_redefinitions(scope: cn.Scope) -> dict[str, bool]:
    """Features the body redefines with a value (':>> f = v', ':>> f default v', 'attribute g :>> f := v'):
    name -> True when the value is a default."""
    out: dict[str, bool] = {}
    body, depth = scope.body, 0
    for k, t in enumerate(body):
        if t.text == "{":
            depth += 1
        elif t.text == "}":
            depth -= 1
        elif depth == 0 and t.text in (":>>", "redefines") and k + 1 < len(body) and body[k + 1].kind == "ident":
            j = k + 2
            while j < len(body) and body[j].text not in (";", "{", "}"):
                if body[j].text in ("=", "default"):
                    out[body[k + 1].text] = body[j].text == "default"
                    break
                j += 1
    return out


def _valued_features(model: Model, scope: cn.Scope) -> dict[str, bool]:
    """Features of a definition that have a value, owned or redefined: name -> True when the value is a default."""
    values = _valued_redefinitions(scope)
    for m in model.members(scope):
        words = [t.text for t in m.decl]
        if "=" in words or "default" in words:
            values.setdefault(m.name, "default" in words)
    return values


def _string_value(body: list[cn.Tok], feature: str) -> str | None:
    for k in range(len(body) - 2):
        if body[k].text == feature and body[k + 1].text == "=" and body[k + 2].kind == "string":
            return body[k + 2].text.strip('"')
    return None


def _chain_connected(body_text: list[str], part: str, port: str) -> bool:
    for k in range(len(body_text) - 2):
        if body_text[k] == part and body_text[k + 1] == "." and body_text[k + 2] == port:
            window = body_text[max(0, k - 12):k]
            if "connect" in window or "to" in window or "interface" in window or "bind" in window:
                return True
    return False


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--stdlib", required=True)
    ap.add_argument("--index", nargs="*", default=[])
    ap.add_argument("--check", nargs="+", required=True)
    ap.add_argument("--report")
    args = ap.parse_args(argv)
    started = time.time()

    idx = cn.Index()
    for f in cn.collect([args.stdlib], (".sysml", ".kerml")):
        idx.add(cn.index_file(f))
    extra = [cn.index_file(f) for f in cn.collect(args.index, (".sysml",))]
    checked = [cn.index_file(f) for f in cn.collect(args.check, (".sysml",))]
    for fm in extra + checked:
        idx.add(fm)
    idx.finalize()
    if "UML3Core" not in idx.roots:
        print("TOOL ERROR: UML3 library not indexed - pass --index library", file=sys.stderr)
        return 2

    files: dict[int, str] = {}
    scopes: list[cn.Scope] = []
    for fm in checked:
        stack = list(fm.root.children.items())
        seen: set[int] = set()
        while stack:
            key, s = stack.pop()
            if key != s.name or id(s) in seen:
                continue
            seen.add(id(s))
            files[id(s)] = str(fm.path)
            scopes.append(s)
            stack.extend(s.children.items())
    model = Model(idx, files)
    findings = sorted(check(model, scopes), key=lambda f: (f.file, f.line, f.rule))

    errors = [f for f in findings if f.severity == "ERROR"]
    for f in findings:
        print(f"{f.severity:<7} {f.rule}  {Path(f.file).name}:{f.line}  {f.element}: {f.message}")
    print(f"SUMMARY files={len(checked)} elements={len(scopes)} errors={len(errors)} "
          f"warnings={len(findings) - len(errors)}")
    if args.report:
        Path(args.report).parent.mkdir(parents=True, exist_ok=True)
        Path(args.report).write_text(json.dumps({
            "tool": "check_rules.py", "elements": len(scopes), "errors": len(errors),
            "warnings": len(findings) - len(errors), "elapsedSeconds": round(time.time() - started, 2),
            "findings": [f.__dict__ for f in findings]}, indent=2), encoding="utf-8")
    return 1 if errors else 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except Exception as exc:
        import traceback
        Path("logs").mkdir(exist_ok=True)
        Path("logs/check-rules-error.log").write_text(traceback.format_exc(), encoding="utf-8")
        print(f"TOOL ERROR: {exc!r} (see logs/check-rules-error.log)", file=sys.stderr)
        sys.exit(2)
