# UML3 specification: outline and sources

The document architecture for a UML3 specification answering `ad/2026-04-01`, and where each part would come
from. [OMG-DOCUMENT-CONVENTIONS.md](OMG-DOCUMENT-CONVENTIONS.md) says what makes such a document conforming;
this file says what goes in it.

Clauses 1 to 6 are the fixed OMG skeleton. The technical content starts at Clause 7, and the annexes may be
issued as separate volumes, as SysML v2 issues its Transformation part separately from its Language part.

## Clauses

| Clause | Title | Source in this repository | State |
|---|---|---|---|
| 1 | Scope | to write | — |
| 2 | Conformance | `requirements/` (305 requirements, each with a verification method) | derivable |
| 3 | Normative References | KerML, SysML v2 (`formal/26-03-02`), UML 2.5.1, IDL 4.2 | to write |
| 4 | Terms and Definitions | may be one sentence, as in SysML v2 | to write |
| 5 | Symbols | points at the notation clause | to write |
| 6 | Introduction | `README.md`, `docs/DESIGN.md` | derivable |
| 7 | UML metamodel | `DogFoodUML3/DomainMetamodel/` (5 files: Foundation, Structure, Surface, SysUMLRealization) | partial |
| 8 | UML3 Language | `samples/uml3/OnlineStore.uml3` — a sketch only | **the gap** |
| 9 | UML3 extension of SysML v2 | `library/` (8 packages), `docs/UML3-Keywords.md` | exists |

### Clause 7, UML metamodel

The abstract syntax: what a UML3 Class, Association, Operation *is*. Not to be confused with metadata — the
SysML v2 semantic metadata keywords (`#classType`, `#association`) are how SysUML *realizes* these concepts in
Clause 9, not the concepts themselves. `DogFoodUML3/DomainMetamodel` already separates the two: it models the
concepts, and `04-SysUMLRealization.sysml` states a `#realizes` dependency from each realizing element to the
concept it realizes. It is currently framed as the shared domain model of the two implementations, so promoting
it to a normative metamodel clause is a matter of completeness and status, not of restructuring.

### Clause 8, UML3 Language

This is the clause with the least behind it, and it is the heart of what the RFP asks for — "an extension to
KerML text syntax that provides a way to express UML content in a text format using familiar UML terms".
There is no grammar yet: `samples/uml3/OnlineStore.uml3` is a sketch that no tool reads, recorded as issue I-39
and deliberately deferred until SysUML was further refined. A specification cannot ship without this clause, so
it is the critical path.

### Clause 9, UML3 extension of SysML v2

The part that exists and is tested: 8 library packages, the keyword catalog, and the diagram kinds, all loading
into CATIA Magic with 0 errors and checked by 21 suites.

## Annexes

Each may be a separate volume.

| Annex | Title | Source in this repository | State |
|---|---|---|---|
| A | UML 2.5.1 to UML3 mapping | `traceability/uml2-to-uml3.json` → `docs/UML2-to-UML3-Traceability.md`, 91 concepts | **generated already** |
| B | SysML v2 to UML3 mapping | `DogFoodUML3/DomainMetamodel/04-SysUMLRealization.sysml` (`#realizes` per concept) | derivable |
| C | AADL to UML3 mapping | nothing | **new work** |
| D | UML3 to IDL | `docs/IDL-MAPPING.md`, `docs/IDL-CODEGEN.md`, `tools/idl/`, `tests/idl/` | exists, with a round trip proven in CATIA Magic |
| E | Requirements Satisfaction | `requirements/` (24 files, 305 requirements), `tools/check_requirements.py` | exists, machine-checked |
| F | Example models | `examples/` (6), `samples/uml3/` (3) | exists |
| G | Tutorials | **a different repository**: `SysMLv2CheatSheet/TutorialContent/` (TutorialLabs, TutorialPresentation, LabOutputs) | exists, elsewhere |

Annex A is the proof that this is worth automating: it is already generated from JSON, so the same data can be
rendered into an OMG annex without being rewritten. Annex E is the same story from `requirements/`.

Annex G is the case the user made for separate volumes — the tutorial material lives in another repository and
has its own build, so binding it into one document would couple two repositories that are better left apart.

## What this says about sequencing

1. **Annex A is the pilot.** Already generated, all tables, and small. It proves the OMG renderer end to end.
2. **Annexes D, E, F follow**, because their content exists and is machine-checked.
3. **Clause 9** is next: it exists, but needs specification prose around the library rather than the design notes
   it has now.
4. **Clause 7** needs the domain metamodel promoted and completed.
5. **Clause 8 is the critical path** and the only part that is genuinely absent. Nothing else can ship without it,
   and no amount of document tooling substitutes for it.
6. **Annex C (AADL)** is new work with no groundwork at all; it is the one item here that has not been started in
   any form.
