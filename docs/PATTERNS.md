# Patterns in UML3: the OMG Structured Patterns Metamodel on SysML v2

Question (2026-09-17): the OMG has a specification for patterns that was written for UML 2. Does UML3, which is
SysML v2 plus the UML3 libraries, give a proper basis to implement and use that standard for software design, and
how do SysML v2 requirements help?

**Answer.** Yes for the model content, with three kinds of work left, none of which extends the language.

* The standard is **SPMS, the Structured Patterns Metamodel Standard**, version 1.4 (formal/26-04-02, January
  2026). Every class of its required Definitions package and of its optional Observations and Relationships
  packages maps onto native SysML v2 constructs and existing UML3 keywords. Experiment E22 writes the Observer
  pattern that way, and CATIA Magic confirmed all five predictions: the probes load and validate, the roles are
  queryable as template parameters, and the tool's evaluation engine evaluates the pattern's requirements, including
  a structural one over the reflective KerML library, with the false controls evaluating to false.
* UML3 can say **more** than SPMS: SPMS roles are bare names, while UML3 roles have types and multiplicities, are
  connected to each other, carry behavior, and are constrained by native requirements. The existing design rule R06
  already checks that the class playing a role implements every operation of the role type.
* Work left: (1) a pattern library (keywords, metadata, a catalog); (2) checker rules for what SysML v2 does not
  check by itself, such as a role bound to a non-conforming type (E22 P4); (3) tooling for SPMS XMI interchange and
  a pattern notation. The interchange also depends on SPMS 1.5 accepting KerML elements, which its revision task
  force is working on (issues SPMS15-1 and SPMS15-2). Structural conformance can live in the model itself: CATIA
  Magic evaluated such a requirement correctly (E22 P5), so UML3's checker rules are needed only for what the model
  cannot state or what a tool without an evaluation engine must still check.

The requirements are in [UML3-Requirements.md](UML3-Requirements.md) under PAT (patterns) and REQ (requirement
modeling), and the probe is `tests/cameo-experiments/e22-pattern-observer.sysml`.

## 1. What the OMG standards say

| Specification | Version | What it is | Relation to UML |
|---|---|---|---|
| **SPMS**, Structured Patterns Metamodel Standard | 1.4, formal/26-04-02, Jan 2026 (1.0 was Oct 2015); XMI `SPMS/20250301` | the OMG patterns standard; started as IPMSS in the Architecture-Driven Modernization task force | a MOF metamodel that specializes and references UML 2.5.1 `Element` and `Property`; its notation (PIN) builds on Diagram Definition 1.1 |
| UML 2.5.1, clause 11.7 Collaborations | formal/17-12-05 | UML's own way to describe a pattern: a `Collaboration` with roles and connectors, applied by a `CollaborationUse` whose role bindings are dependencies | native UML |
| UML Profile for Patterns (part of EDOC) | 1.0, formal/04-02-04, Feb 2004 | business object patterns as UML 1.4 stereotypes on parameterized collaborations | UML 1.4, historical |
| CISQ ASCSM 1.0, ASCQM 1.1 | formal/16-01-04, formal/22-07-01 | software quality and security measures whose weakness catalogs **are SPMS data** (each weakness is a pattern definition) | through SPMS |

SPMS does not use UML collaborations, templates, stereotypes or OCL. It stands beside the model and points into
it through references typed by `Element`.

### SPMS 1.4 in brief

| Package (conformance) | Classes |
|---|---|
| Definitions (**required**) | `PatternDefinition` owns `sections : PatternSection [1..*]`, `roles : Role [1..*]`, `knownUses [0..*]` and refers to `relatedPatts [0..*]`. A `Role` has only a name. A `PatternSection` has a free name (the GoF and Hillside templates are examples) and a `body : Element`. |
| Observations | `PatternInstance` (`instanceOf : PatternDefinition [1]`, `fulfillments : Binding [1..*]`, `observation [0..1]`); `Binding` (`boundTo : Role [1]`, `fulfilledBy : Element [0..*]`); `PatternObservation` (when, observer, tool, `foundVia` formalisms). |
| Formalisms | `FormalizedDefinition` trees of `And`/`Or`/`Not` over `DefinitionTerminal`s that point at fragments of any model, stitched to roles by `VariableToRole`, `PropertyToRole`, `PropertyToVar`; `Assertion` for a claim without a formal model. |
| Relationships | `RelatedPattern` with a `Nature` (example vocabulary: ChildOf, ParentOf, PeerOf, Requires, RequiredBy, VariantOf, CanAlsoBe, MitigatedBy, Mitigates, CompensatedBy, Compensates), `MemberOf` a `Category`, `Perspective`, `KnownUse` (narrative, URI, usage). |
| PIN, Pattern Instance Notation | `PINbox` (Collapsed, Standard, Expanded), `Equality` between roles of different instances, `BindingGlyph` to the fulfilling element; the metamodel is normative, the drawing is not. |

Conformance: a tool supports Definitions and can import and export SPMS XMI; the other packages are optional.
Anti-patterns and variants exist only as relationship natures and extra sections. Role equality, which is how
patterns compose (Decorator from ObjectRecursion and ExtendMethod), exists only in PIN and in prose.

## 2. SysML v2 requirements are the advanced part

UML collaborations and SPMS both leave the *meaning* of a pattern to prose or to external formalisms. SysML v2
requirements give UML3 native constructs for it:

| Pattern concept | SysML v2 construct | In the probe |
|---|---|---|
| intent, problem, forces | concerns (`concern def`) that the pattern addresses; stakeholders who hold them | planned (PAT-005) |
| solution constraints | a `requirement def` whose subject is typed by the pattern definition | `ObserversAreNotified` |
| applying the pattern | the pattern instance **satisfies** the pattern's requirements, and the design decision to use the pattern (REQ-018) | `satisfy requirement notified : ObserversAreNotified by orderObservation` |
| structural conformance of a role player | a requirement whose subject is a metaobject, over the reflective KerML library | `SubjectTypeOwnsNotify`, satisfied by `OrderService meta KerML::Type`: CATIA Magic evaluates it to true, and to false for a missing operation (E22 P5) |
| checking an application | verification cases (REQ-012) and UML3 design rules | R06 on the role types |

So a pattern definition is a small requirement model: a problem stated as concerns, a solution stated as a
structure plus requirements, and each application claims satisfaction and can be verified.

## 3. SPMS mapped onto UML3

| SPMS | UML3 and SysML v2 | Basis |
|---|---|---|
| `PatternDefinition` | an abstract definition whose features are the roles; E22 marks it `#template`, a dedicated `#pattern` keyword is planned | native + UML3 keyword |
| `PatternElement.name` | the declared name | native |
| `Role` | an abstract reference feature marked `#templateParameter`, **with a type and a multiplicity** | native + UML3 keyword |
| role relationships (not in SPMS) | connections, flows and messages between role features; an interaction for the collaboration | native |
| `PatternSection` | a named comment about the pattern definition (`comment intent about ObserverPattern`), or a view for a graphical body | native |
| `PatternInstance` (type level, as in GoF class diagrams) | a specialization of the pattern definition that redefines each role with a design type | native (UML3 template binding, STR-011) |
| `PatternInstance` (instance level, as a UML `CollaborationUse`) | a usage of the pattern definition in a context, each role bound to a feature of the context | native |
| `Binding.fulfilledBy : Element [0..*]` | one redefinition per role; several players of one role by features that subset the role, or by metaobject values (`X meta KerML::Type`) | native |
| `PatternObservation` | valued metadata on the instance (when, observer, tool) | native metadata |
| `FormalizedDefinition` | requirements and constraints in the model; And/Or/Not are native Boolean expressions; `DefinitionTerminal` fragments are the pattern's own structure | native; structural constraints evaluated by CATIA Magic (E22 P5) |
| `PropertyToRole`, `PropertyToVar` (bindings one meta level up) | features of the reflective KerML library (`ownedFeature`, `ownedSpecialization`, ...) | native reflective library, evaluated (E22 P5) |
| `RelatedPattern` + `Nature` | a dependency between pattern definitions with valued metadata (`nature`); communities extend the vocabulary | native metadata |
| `Category`, `MemberOf`, `Perspective` | library packages and metadata; a perspective is a viewpoint | native |
| `KnownUse` | a pattern instance with narrative and URI metadata | native |
| composition by role equality (PIN `Equality`) | binding connectors between the roles of nested instances (`bind a.recurser = b.originalBehavior`) | native |
| PIN notation | views of pattern instances with their bindings; Collapsed, Standard and Expanded correspond to compact and detail views | tooling |
| XMI interchange | a transformation between SPMS XMI and SysML v2 text, like the IDL import and export | tooling; SPMS 1.5 must accept KerML elements |

UML 2.5.1 collaborations map the same way: a `Collaboration` is the pattern definition, a `CollaborationUse` an
instance-level pattern instance, and its OCL constraints `every_role` and `connectors` become UML3 design rules.
That turns the traceability row "Collaboration / CollaborationUse", which is PARTIAL today, into a UML3 construct.

## 4. The Observer pattern in UML3 (E22)

```sysml
abstract #template part def ObserverPattern {
    abstract ref #templateParameter item observable : Subject[1];      // SPMS Role, typed
    abstract ref #templateParameter item observers : Observer[1..*];
    connection notification connect observable to observers;         // not expressible in SPMS
}
comment intent about ObserverPattern /* Intent: ... */                  // SPMS PatternSection

requirement def ObserversAreNotified {                                  // solution constraint
    subject app : ObserverPattern;
    require constraint { size(app.observers) >= 1 }
}

part def OrderObservation :> ObserverPattern {                          // type-level instance
    ref item :>> observable : OrderService;
    ref item :>> observers : Observer[1..*];
    ref item emailObservers : EmailNotifier[0..*] :> observers;         // one role, two players
    ref item auditObservers : AuditLog[0..*] :> observers;
}

part def StoreConfiguration {                                           // instance-level instance
    item orderService : OrderService;
    item mailer : EmailNotifier;
    item audit : AuditLog;
    part orderObservation : ObserverPattern {
        ref item :>> observable = orderService;
        ref item :>> observers = (mailer, audit);
    }
    satisfy requirement notified : ObserversAreNotified by orderObservation;
}
```

Evidence:

* Locally: 0 validator errors, 0 name findings, 0 rule findings. With `notifyObservers` removed from
  `OrderService`, rule R06 reports that the class playing the observable role does not implement the role type.
* In CATIA Magic (E22, predictions recorded before the runs, `tests/cameo-experiments/e22-*`):

| Prediction | Result |
|---|---|
| P1 the probes load | met in run 2; run 1 failed because the probe invoked `->exists` without importing `ControlFunctions` |
| P2 no validation errors | met; one warning (`validateFeatureTypeConformance`) on the metaobject-typed subject of the model-level requirement |
| P3 roles are template parameters | confirmed: the role features subset `UML3Core::templateParameters` |
| P4 a wrong binding is not an error | confirmed: `observable : EmailNotifier` validates, and the role then conforms to both `Subject` and `EmailNotifier`, an intersection of types |
| P5 the requirements are evaluated | confirmed, 4/4: instance level true, three-observer control false, model level true, `notifyAll` control false |

The run is now the suite `cameo-patterns` of `tools/run_tests.py --cameo`, and `cameo_check.py --evaluations` can
evaluate any satisfy requirement usage or assert constraint against an expected verdict.

Two local checks were missing and now exist: a role must not be named `subject`, a SysML v2 keyword (negative test
n24), and a function invoked with `->` must be imported (rule FUNCTION, negative test n25); CATIA Magic found the
second.

## 5. Gaps and how the requirements close them

| # | Gap | Kind | Requirements |
|---|---|---|---|
| G1 | No pattern construct in the libraries: the traceability row for collaborations is PARTIAL | library: `#pattern`, `#patternInstance`, section and observation metadata | PAT-001, PAT-004, PAT-010, PAT-025 |
| G2 | SysML v2 does not reject a role bound to a non-conforming type; it intersects the types (confirmed, E22 P4) | checker rule | PAT-011 |
| G3 | Nothing requires every role of an instance to be bound, or the role connections to exist between the players (UML `every_role`, `connectors`) | checker rules | PAT-012, PAT-014 |
| G4 | Structural constraints inside the model need a tool that evaluates expressions over metaobjects; CATIA Magic does (E22 P5), other tools are unknown | conventions and a pattern library of such requirements | PAT-015 |
| G5 | No catalog: GoF, architecture, integration and data patterns | library content | PAT-017, PAT-018 |
| G6 | No notation for pattern instances | views and CATIA Magic customization | PAT-020, PAT-021 |
| G7 | No SPMS XMI import and export | tooling; depends on SPMS 1.5 | PAT-023, PAT-024 |
| G8 | Pattern detection in existing models or code | tooling | PAT-019 |

## 6. SPMS 1.5 and UML3

The SPMS 1.5 revision task force has two open issues about KerML: SPMS15-1 asks to allow KerML elements wherever
SPMS allows MOF elements, and SPMS15-2 asks to clarify that KerML and SysML v2 elements can be used. UML3 can
inform that work with evidence rather than opinion:

* the mapping in section 3, verified by E22;
* typed roles, role multiplicities and role relationships, which KerML features provide and SPMS lacks;
* binding a role to a KerML feature, which covers both the type-level and the instance-level reading;
* the inconsistencies found between the SPMS 1.4 PDF and its XMI (for example, whether `PatternElement` is
  abstract, where `definitions` is owned, and the multiplicity of `Equality.equivalents`), listed in the research
  notes of this analysis.

## 7. Sources

* SPMS: https://www.omg.org/spec/SPMS/1.4/ (formal/26-04-02), XMI https://www.omg.org/spec/SPMS/20250301/SPMS.xmi,
  issues https://issues.omg.org/issues/spec/SPMS (SPMS15-1, SPMS15-2).
* UML 2.5.1: https://www.omg.org/spec/UML/2.5.1/ (formal/17-12-05), clauses 11.7, 11.8.4, 11.8.5, 9.9.4.
* EDOC Patterns profile: formal/04-02-04. CISQ: https://www.omg.org/spec/ASCSM/, https://www.omg.org/spec/ASCQM/.
* SysML v2: requirements SysML 7.21, verification 7.24, viewpoints 7.26, metadata 7.27; reflective library
  `KerML.kerml`; semantic metadata KerML 9.2.16.
