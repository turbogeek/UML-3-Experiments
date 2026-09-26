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

### Clause 6, Introduction: the commentary the specification opens with

A reader meeting UML3 for the first time needs to know why it exists and why it is shaped as it is, before any
construct is defined. Clause 6 carries that argument, in this order.

**Why a new version of UML.** `ad/2026-04-01` states the problem: UML is being left out of the development
cycle, it has not been updated in a decade while the languages it describes are revised every year or two, and
it is stranded on infrastructure that SysML v2 has left behind. A UML model can no longer be traced to the
system model it belongs to, and it has no text form that a person, a pipeline or a generative tool can write
comfortably. UML3 answers those three: a modern concept set, a textual notation, and the KerML infrastructure
that makes traceability to SysML v2 ordinary rather than heroic.

**What UML3 is built on.** UML3 extends and subsets KerML, as SysML v2 does. It is not a profile of SysML v2 and
not a rewrite of UML 2.x. Concepts native to KerML or SysML v2 are used unchanged and carry no UML3 label; the
traceability annex records that decision concept by concept, including the concepts deliberately not carried
forward and why.

**Why so little of it is language.** The capability a modeller sees comes mostly from libraries, not from
grammar. This follows SysML v2, where clause 9 — a third of the specification — is model libraries: quantities,
units, geometry, analysis cases and causal chains are models written *in* the language and shipped *with* it.
UML3 applies the same rule, stated in [UML3-LAYERING.md](UML3-LAYERING.md): a concept becomes a language
construct only if it cannot be expressed as a library element plus metadata without losing meaning a conforming
tool must act on. Everything else is a library element, and a marker on an existing element is metadata.

The reason is practical rather than aesthetic. A language that grows a construct for every platform it wants to
serve becomes one nobody can implement completely, and every implementation then supports a different subset. A
language that grows *libraries* can serve an unbounded number of platforms while the part a tool must implement
stays fixed. That is what makes conformance meaningful.

**The evidence that it works.** The coverage annexes examine what implementation languages, databases and
deployment platforms actually require. Of 63 concepts UML3 does not yet fully express, 57 are answered by a
library or a marker, 1 is out of scope, and 5 need the language itself to grow. Those 5 are all type-system
features — function-valued features, constraints on template parameters, discriminated unions with a payload per
case, ownership and mutability of references, type aliases — because metadata can annotate an element but cannot
extend the rules for which types conform to which. Each has a requirement stating why the language must carry
it. The same rule sends purity and immutability the other way: `#query` already marks an operation that changes
nothing, and that is a marker.

**What the language must provide so the libraries can exist.** A library architecture is only honest if a
library can carry meaning. UML3 therefore requires that an extension library declare where its keywords apply
(UML3-EXT-004), state its own constraints as model elements (UML3-EXT-006), carry values and not only markers
(UML3-EXT-003), be versioned (UML3-EXT-008), and give the constructs it defines an execution semantics
(UML3-BHV-017). Without that last one a domain library is documentation, and the 32 gaps assigned to the library
layer would be assigned on a false premise.

**What UML3 does not attempt.** It does not define a notation for every diagram a tool might draw: diagram kinds
are view definitions over model content, so a new kind of diagram is a library element too. It does not model
the internals of a target platform, only what a model must say to generate for it. And it does not replace
SysML v2 for systems: the point of sharing KerML is that a software design and the system that contains it are
the same model.

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
