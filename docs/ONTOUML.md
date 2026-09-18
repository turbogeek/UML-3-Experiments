# OntoUML as a modeling aid for UML3 (research brief)

Status: research brief of 2026-09-18, queued for a decision (issue I-38 in [DESIGN.md](DESIGN.md)). Nothing here
is adopted in the libraries.

## Summary

* **What it is.** OntoUML is a profile of UML class diagrams grounded in the Unified Foundational Ontology (UFO),
  started in Giancarlo Guizzardi's 2005 thesis and revised as OntoUML 2 (Guizzardi et al., Data & Knowledge
  Engineering 134, 2021). Its stereotypes say *what kind of thing* a class describes: 21 class stereotypes (kind,
  subkind, role, phase, category, mixin, roleMixin, phaseMixin, relator, mode, quality, collective, quantity,
  type, event, situation, historicalRole, historicalRoleMixin, abstract, datatype, enumeration) and 19 relation
  stereotypes (mediation, characterization, material, componentOf, memberOf, participation, creation, ...), each
  with meta-properties such as rigidity, sortality, identity and existential dependence, and constraints stated
  in OCL.
* **"Emerging standard" is only half right.** UFO, the ontology, is at ISO draft stage as ISO/IEC DIS 21838-5 in
  JTC 1/SC 32 (DIS ballot closed 2026-09-01; the result was not yet visible). OntoUML, the language, is not
  standardized by any body: its current definition is an open vocabulary (OWL, v1.1.1), a JSON schema (v1.0.2)
  and a metamodel maintained by the research community. The OMG has no OntoUML or UFO specification; its 2011
  SIMF request for proposals is still listed as pending. KerML and SysML v2 make no commitment to UFO.
* **What makes it an aid to modeling.** Syntax verification of taxonomies (every role or phase belongs to exactly
  one kind, a rigid type never specializes an anti-rigid one), 20 catalogued anti-patterns with refactoring
  plans, relator-based relationships, relational schema generation, transformation to OWL (gUFO), simulation with
  Alloy, and a catalog of 202 published models. Controlled studies (Verdonck et al. 2019, 2020) report better model
  quality at no extra effort; the evidence comes mostly from the UFO community and none measures software design
  outcomes.
* **Fit with UML3.** The best fit is the **relator**: a SysML v2 `connection def` is a part definition that is
  also a KerML association structure whose ends stay constant while its other features may change, which is
  close to what OntoUML means by a relator. The meta-types (kind, role, phase, ...) are properties of a type that
  are *not* inherited by its subtypes, so they must be **plain metadata read by checker rules**, not semantic
  keywords. OntoUML's modal notion of rigidity does not match KerML's four-dimensional semantics, so UML3 should
  give the keywords a practical reading ("this classification can or cannot change during an object's life") and
  not claim formal UFO conformance.

## What SysML v2 already provides

| OntoUML notion | SysML v2 / KerML | Fit |
|---|---|---|
| types, specialization, abstract types | definitions, `:>`, `abstract` | full |
| data values vs objects (datatype, enumeration) | attribute and enum definitions vs item and part definitions; UML3 `#dataType`, `#valueObject` | full |
| relator with mediations | `connection def` (association structure): constant ends, variable other features | strong |
| existential dependence of a relator on its relata | not enforced | gap: constraint or rule |
| characterization (a mode or quality inheres in its bearer) | composite features | partial |
| componentOf, essential and inseparable parts | `part` vs `ref`, `constant`, multiplicity | partial |
| roles as types played in a relation | every feature is a role-like type; role *types* in taxonomies still need a keyword | partial |
| phases | time slices of the same individual, state definitions; rigidity cannot be stated | partial |
| disjoint and complete generalization sets | KerML has disjoining and unions, SysML textual notation does not; UML3 uses `@GeneralizationSet` | partial, rule needed |
| events and situations | occurrences, actions, snapshots, HappensBefore | partial / weak |
| kind, subkind, role, phase, category, mixin | nothing: KerML has no rigidity, sortality or identity principle | keywords + rules |
| collective, quantity (amount of matter) | nothing; KerML `portion` is a temporal or spatial portion of the same occurrence | keywords |

`event`, `abstract` and `end` are SysML v2 reserved words, so OntoUML's «event» and «abstract» need other keyword
names in UML3 (for example `#eventType`).

## Ranked opportunities

| # | Opportunity | Benefit | Risk |
|---|---|---|---|
| 1 | **Relator-based relationships**: `#relator connection def` with role-typed ends, for relationships that have state and history (enrollment, employment, order line) | high: replaces association-class ambiguity, maps to join tables, needs little new machinery | low-medium: R04 (binary only) needs an exemption; dependence on the relata needs a rule |
| 2 | **Meta-type metadata for domain and data models** (UML3Data): #kind, #subkind, #role, #phase, #category, #mixin, #roleMixin, #phaseMixin, with rigidity, sortality and the natures a type may have | high: makes identity and lifecycle explicit; prerequisite for 3 to 6 | medium: learning curve; keep it to domain and data models |
| 3 | **OntoUML 2 constraint checks** in `check_rules.py`: one ultimate sortal per sortal, no rigid-under-anti-rigid, phase partitions complete and disjoint, relators mediate at least two individuals; a UML3 rule that keys (#primaryKey, #id) are declared only on kinds | high for the cost; deterministic | low: works only on annotated models |
| 4 | **Anti-pattern warnings** (RelOver, RelRig, RepRel, MultDep, FreeRole, DepPhase, UndefPhase, ...) with refactoring hints; they fit PAT-018 (anti-patterns) | medium-high | medium: heuristics, keep them as warnings |
| 5 | **Kind-based logical-to-physical mapping** (table per kind, roles and phases as discriminators, generated checks) | medium-high | medium: a larger generator |
| 6 | **Exports** to OntoUML JSON, Tonto text or gUFO Turtle; the OntoUML catalog as a regression corpus | medium: independent verification, a route to OWL | medium: mapping upkeep; catalog models are for noncommercial research and each has its own license |
| 7 | **UFO-B events** tied to `#domainEvent` | medium | high: more research, approximated semantics |
| 8 | Alloy-style simulation | low | high cost, no direct SysML v2 path |

## Sketch (validated with the ANTLR validator, check_names and check_rules; not yet in CATIA Magic)

```sysml
metadata def <kind> KindMetadata :> OntoType {      // plain metadata: read by rules, not inherited
    :>> rigidity = Rigidity::rigid;
    :>> sortality = Sortality::ultimateSortal;
}
metadata def <relator> rltr :> SemanticMetadata {   // semantic: a relator is a UML3 Relationship
    :>> baseType = relators meta SysML::Usage;
}

#entity #kind item def Person { #primaryKey attribute personId : String; }
#role item def Student :> Person;
#relator connection def Enrollment {
    end [0..*] ref student : Student;
    end [1..*] ref university : University;
    attribute status : EnrollmentStatus;             // the relator's own, changeable state
}
```

The draft of the sketch also found two UML3 rules at work: `event` is reserved (the nature literals had to be
renamed), and R16 rejected terse ids that saved fewer than three characters.

## Decision needed

Which opportunities become requirements. The recommendation is to start with 1 to 3 as `tbd` requirements in the
data modeling (DATA) and verification (VER) areas, and to run a CATIA Magic experiment on the sketch before
adopting any keyword.

## Main sources

* OntoUML Vocabulary, Schema and Metamodel: https://github.com/OntoUML; https://dev.ontouml.org/ontouml-vocabulary/
* Guizzardi et al., "Types and taxonomic structures in conceptual modeling: a novel ontological theory and
  engineering support", Data & Knowledge Engineering 134 (2021).
* Almeida, Ferreira Pires, Guizzardi and Wagner, "An analysis of the semantic foundation of KerML and SysML v2",
  ER 2024: the main prior work relating UFO and SysML v2.
* ISO/IEC DIS 21838-5, Top-level ontologies, Part 5: UFO: https://committee.iso.org/standard/89915.html
* OMG public schedule (SIMF RFP ad/2011-12-10, pending): https://www.omg.org/public_schedule/
* gUFO: https://nemo-ufes.github.io/gufo/; Tonto: https://github.com/nemo-ufes/Tonto;
  anti-patterns: https://ontouml.readthedocs.io/en/latest/anti-patterns/
* Verdonck et al., controlled experiments on ontology-driven conceptual modeling (2019, 2020).
