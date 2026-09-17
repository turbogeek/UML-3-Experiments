# UML3 documentation conventions

UML3 is intended as a standard, so its models document themselves: every element carries its description, usage,
rationale and references *as model elements*. SysML v2 comments are not source-code comments. They are
annotating elements (KerML 7.2.4.2) that tools show on diagrams, navigate and query.
`tools/check_docs.py` enforces these rules on `library/` and `examples/` (suite `docs` in `tools/run_tests.py`).

## Rules

| Code | Rule | Why |
|---|---|---|
| D01 | No banner or separator lines (`=====`, `-----`) in comment text, and no leading ` * ` on comment lines | Diagrams show the body text as a note with little room; decoration wastes it. KerML strips a leading `*` (8.2.3.3.3 notes), but other consumers may not |
| D02 | No unattached `/* */` comment. Use `doc` (owned by the element it documents) or `comment Name about A, B` (named, pointing at the elements it discusses) | A bare comment in a namespace annotates the *namespace* (KerML 7.2.4.2), not the elements written next to it; the link to those elements is lost in the model |
| D03 | No `//` notes or `//* */` block notes | Notes are not model elements, so they are invisible to tools, diagrams and queries |
| D04 | Every named element has an owned `doc`. Library: every definition, usage, feature, enumeration literal and metadata attribute. Examples: every definition and named usage; parameters and enumeration literals may rely on the owner's doc | Users of a standard library read the element, not the file |
| D06 | Every package doc explains the package and ends its description with a `Contents:` section: one line per group of elements, naming the key definitions and keywords | A reader or a tool browsing a library sees what it offers without opening every element |
| D05 | Citations resolve: `KerML n.n.n` / `SysML n.n.n` must be clause numbers of the specifications, `UML 2.5.1 X` a UML metaclass in `traceability/uml2-to-uml3.json`, `UML3Xxx::Name` an element of `library/`, `Enn` an experiment of this repository | References in a standard must be checkable |

## What a doc says

1. **What the element is**, in one sentence first; the first sentence is what diagrams and tooltips show.
2. **How to use it**, when applicable, with a short textual-notation example.
3. **Rationale**, when a choice was made (why an item def and not a part def, why a keyword is semantic metadata).
4. **References**, on a final line: `References: UML 2.5.1 Interface; KerML 7.2.4.2; E04.`

Text is plain, not HTML. Lines stay short: about 100 characters.

```sysml
abstract item def InterfaceType {
	doc
	/*
	UML Interface: a contract of abstract operations and, optionally, abstract attributes.

	Usage: a class realizes an interface by specializing it and redefining its operations:
	  #classType item def OrderService :> CheckoutApi { #operation action :>> placeOrder; }
	Multiple realization is multiple specialization.

	Rationale: SysML v2 'interface def' is a connection between ports, not a UML contract,
	so the contract is an item def.
	References: UML 2.5.1 Interface; UML 2.5.1 InterfaceRealization.
	*/
}
```

## Comments about elements

A `comment … about` explains how several elements work together. Examples are why a group of keywords shares a design,
or why a state machine or activity is built the way it is:

```sysml
comment MarkerKeywordDesign about staticFeatures, finalElements, Static, Final
	/*
	Marker keywords: UML properties with no SysML v2 equivalent. ...
	*/
```

In behavior models (`state def`, `action def`, use cases), put a `comment about` next to the transitions, decisions
or steps whose *why* is not obvious. The comment says what it achieves and why, not what the notation already shows.

## Frequently cited clauses (verified against the specification PDFs)

| Topic | Clause |
|---|---|
| Comments and documentation | KerML 7.2.4.2; SysML 7.4 |
| Specialization, subsetting, redefinition | KerML 7.3.2.3, 7.3.4.4, 7.3.4.5 |
| Disjoining (families that may not be joined) | KerML 7.3.2.5 |
| Data types, classes, associations, connectors | KerML 7.4.2, 7.4.3, 7.4.5, 7.4.6 |
| Metadata and semantic metadata (baseType) | KerML 7.4.13; SysML 7.27, 7.27.3 |
| Metaobjects library (SemanticMetadata) | KerML 9.2.16 |
| Occurrences / Objects / Performances libraries | KerML 9.2.4, 9.2.5, 9.2.6 |
| Dependencies, annotations, packages | SysML 7.3, 7.4, 7.5 |
| Definition and usage | SysML 7.6 |
| Attributes, enumerations, occurrences | SysML 7.7, 7.8, 7.9 |
| Items, parts, ports, connections, interfaces, allocations | SysML 7.10, 7.11, 7.12, 7.13, 7.14, 7.15 |
| Flows and messages | SysML 7.16 |
| Actions, states, calculations, constraints | SysML 7.17, 7.18, 7.19, 7.20 |
| Requirements, cases, analysis, verification, use cases | SysML 7.21, 7.22, 7.23, 7.24, 7.25 |
| Views and viewpoints | SysML 7.26 |
