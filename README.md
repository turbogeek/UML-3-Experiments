# UML-3-Experiments

**Goal:** give SysML v2 the modeling power UML offers for software work: object-oriented analysis and design, software and deployment architecture, messaging/event-driven design, and data/database modeling.

The approach uses only the extension mechanisms SysML v2 already standardizes:

* **Model libraries** of abstract base definitions (`Class`, `Operation`, `Component`, `DomainEvent`, `Entity`, `Table`...).
* **Semantic metadata keywords** (`#entity`, `#service`, `#primaryKey`...), the SysML v2 replacement for UML stereotypes. A keyword makes the element really specialize its library base (KerML 9.2.16), so models stay queryable and CATIA Magic shows the keyword as a `«#keyword»` label.
* **Plain metadata** for values such as `@Facets`, `@Index`, `@QualityOfService` and `@ForeignKey { onDelete }`.

The KerML/SysML grammar is not changed, so UML3 models are ordinary SysML v2.

**Design principle: UML3 is not a copy of UML 2.x.** Where SysML v2 or KerML already has the concept, the native element is **used as-is, without a UML3 label**. Examples: `action def` for activities and behaviors, `state def` for state machines, `use case def`, `individual`/`snapshot` for instance specifications. UML3 adds library elements and keywords only where SysML v2 has no equivalent or where a KerML capability improves on UML. Every UML 2.x concept is traced to its UML3 realization in [`docs/UML2-to-UML3-Traceability.md`](docs/UML2-to-UML3-Traceability.md), which is generated from `traceability/uml2-to-uml3.json` and verified by the tests.

```sysml
package Shop {
    private import ScalarValues::*;
    private import UML3Core::*;
    private import UML3Types::*;
    private import UML3Data::*;

    #entity item def Customer {                 // Customer :> UML3Data::Entity :> UML3Core::Class
        #primaryKey attribute customerId : Uuid;  // shown as «#primaryKey»; member of primaryKeyFeatures
        #unique attribute email : EmailAddress;
        #operation action changeEmail { in newEmail : EmailAddress; }
    }
}
```

## Capabilities

| Library | What it adds |
|---|---|
| `library/UML3Core.sysml` | Classes, active classes, interfaces and realization, data types, signals and exceptions; operations, queries and constructors; associations, association classes, aggregation, composition and navigability (`#navigable` on ends); generalization sets; templates; dependency kinds (`#uses`, `#creates`, `#calls`, `#traces`...); markers `#static`, `#final`, `#id`, `#singleton` |
| `library/UML3Types.sysml` | Sized and formatted software types (`Int8`–`UInt64`, `Float32/64`, `Decimal`, `Money`, `Uuid`, `EmailAddress`, `Timestamp`, `Bytes`...), `@Facets` (range, length, precision, pattern), `MapEntry`; collection kinds via native multiplicity |
| `library/UML3Components.sysml` | Components, subsystems, services; `#provided` / `#required` (conjugated) ports bound to interface contracts; assembly and delegation connectors; layers, boundaries, technology tags; artifacts, nodes, devices, execution environments, deployment, manifestation, communication paths |
| `library/UML3Messaging.sysml` | Message schemas with a standard header (`#command`, `#domainEvent`, `#queryMessage`, `#reply`, `#documentMessage`); topics, queues, brokers; producer / consumer / request-reply ports; serialization format and QoS (delivery, ordering, partitioning, retention, DLQ); `#publishes`, `#subscribes`, `#sends`, `#handles`, `#idempotent`; interactions (sequence diagrams) using native messages |
| `library/UML3Views.sysml` | UML diagram kinds as SysML v2 views: `ClassDiagram`, `PackageDiagram`, `ComponentDiagram`, `DeploymentDiagram`, `EntityRelationshipDiagram`, `MessageSchemaView`, `SequenceDiagram`, `ClassTable`, plus detail forms with full compartments (`ClassDetailDiagram`, `DeploymentDetailDiagram`, `EntityRelationshipDetailDiagram`, `MessageSchemaDetailView`); they filter on UML3 keywords and keyword categories and hide leaked library elements |
| `library/UML3Data.sysml` | Logical models (`#entity`, `#aggregateRoot`, `#valueObject`, `#relationship` with cardinality); keys and constraints (`#primaryKey`, `#foreignKey` + referential actions, `#unique`, `#indexed`, `@Index`); physical schemas (`#database`, `#table`, `#column` + `@Column`, `#dbView`); governance (`#audited`, `#transient`, `@Sensitivity`); logical-to-physical `#mapsTo` |
| `library/UML3IDL.sysml` + `tools/idl/` | OMG IDL 4.2 **import and export** (Groovy, inside CATIA Magic or on the command line): modules, structs, typedefs, sequences, arrays, bounded strings, fixed, enums, unions (`#union`, `@Discriminator`, `@Case`), exceptions, interfaces with operations, `oneway` and `raises`, constants and common annotations. IDL basic types `Octet`, `WChar`, `WString`, `LongDouble`, `Any`. Mapping: [`docs/IDL-MAPPING.md`](docs/IDL-MAPPING.md). **Code generation** from IDL or from the model: Java per the OMG IDL4 to Java 1.0 mapping and Rust ([`docs/IDL-CODEGEN.md`](docs/IDL-CODEGEN.md)) |

`examples/` models one online store: class model, architecture and deployment, messaging, database, native behaviors (activity, state machine, use cases, instances; example 06), and a set of views (diagrams) over them. `tools/check_rules.py` checks 14 design rules (R01–R12, R14, R15), e.g. tables need primary keys, interface realizations must be complete, and required ports must be connected. The full UML → SysML v2 mapping and design rationale are in [`docs/DESIGN.md`](docs/DESIGN.md).

### Documentation and requirements

* **Documentation is part of the model.** Every library and example element owns a `doc` (what it is, usage, rationale, references), every package summarizes its contents, and explanations spanning several elements are named `comment ... about` annotations, so tools and diagrams show them. There are no banners or star decoration. Rules and checker: [`docs/DOC-CONVENTIONS.md`](docs/DOC-CONVENTIONS.md), `tools/check_docs.py` (citations are checked against the KerML and SysML v2 clause headings).
* **Requirements and use cases for UML3** are written in SysML v2 in `requirements/`: 247 numbered "shall" requirements in 19 areas (core, structure, data types, behavior, extensibility, verification, validation, views, architecture, data, messaging, security, testing, DevOps, generation, reports, languages, AI, SysML v2 interoperation), each with rationale, status, priority, verification method, evidence and realizing elements, plus 59 use cases with actors. Status today: 67 done, 43 implemented with verification incomplete (tbc), 126 open, 11 to be decided. Guide: [`docs/REQUIREMENTS-GUIDE.md`](docs/REQUIREMENTS-GUIDE.md); generated catalog: [`docs/UML3-Requirements.md`](docs/UML3-Requirements.md).

### Keyword naming rules
* Keywords are lowerCamelCase.
* SysML reserved words and KerML keywords can't be keyword names. Where the UML name is taken, a `Type` suffix or a verb is used: `#classType`, `#interfaceType`, `#messageType`, `#dbView`, `#uses`.
* Semantic keywords must not go on packages or dependencies, or on elements whose type family is disjoint from the keyword's base (data vs. occurrence, structure vs. behavior). The checker reports this as `APPLICABILITY`.

## Verification

Everything is tested repeatably. Results go to `logs/` (git-ignored) so they can be inspected.

```bash
python tools/run_tests.py            # local checks
python tools/run_tests.py --cameo    # plus CATIA Magic (SysMLv2 test harness must be running)
```

| Suite | Tool | Current result |
|---|---|---|
| Syntax | `sysml-validator` (ANTLR) | library and examples pass |
| UML 2.x traceability | `tools/check_traceability.py` | 91 concepts: 49 NATIVE, 15 NATIVE+UML3, 14 UML3, 8 PARTIAL, 5 NOT_ADOPTED; all cited metaclasses, UML3 elements, views and examples verified |
| Names, lint, keyword applicability | `tools/check_names.py` | library, examples and requirements pass; 20 negative tests fail as expected |
| Design rules | `tools/check_rules.py` | examples: 0 errors (5 true R12 warnings); each of 14 rules proven to fire; clean control stays clean |
| Documentation | `tools/check_docs.py` | library, examples and requirements: 0 findings on rules D01–D07; one fixture per rule plus a clean control; documentation-only rewrites proven model-identical (`tools/compare_model_tokens.py`) |
| Requirements and use cases | `tools/check_requirements.py` | 247 requirements, 59 use cases: form, evidence, realization and traces resolve; every requirement is traced by a use case |
| Checker calibration | `check_names.py` on 251 official OMG models | 0 false positives |
| Load, link, validate | CATIA Magic via REST harness (`tools/cameo_check.py`) | 13/13 files load (7 libraries, 6 examples); validation engine reports 0 failures, including the IDL imports; 8 probes flagged exactly as predicted (2026-09-17) |
| View contents (expose + filter) | CATIA Magic `exposedElement` | 12/12 views match predicted includes and excludes |
| Views as diagrams | CATIA Magic diagrams exported to SVG (`exportViewDiagrams.groovy`, `tools/check_view_svg.py`) | 15/15 views (12 example views, 3 generated per IDL file): expected display mode, laid out with 0 overlapping shapes, every expected element drawn and labeled in the SVG, no excluded element |
| Misapplied-keyword probes | CATIA Magic | recorded behaviour; Cameo misses 2 of 5 cases that UML3 catches |
| Keyword labels | CATIA Magic label functions | 19/19 render `«#keyword»` |
| IDL import/export | `tools/idl/`, `run_tests.py` suite `idl-import` and `cameo_check.py --idl` | fixture imports as expected, 5 unsupported constructs rejected with clear messages; in CATIA Magic: 0 build errors, 0 validation failures, export from the model identical to the canonical original |
| IDL corpora (701 third-party files, `external/idl` submodules) | `tools/idl_corpus_check.py` | 394 imported with stable round trips, 0 crashes; generated Java compiles for 304, generated Rust compiles for 266; per-file baseline |
| IDL code generation | `tools/idl/idl2code.groovy`, suite `idl-codegen` | 34/34 OMG IDL4-Java naming examples (2 spec inconsistencies documented), 53/53 spec Java declarations, Java compiled with javac, Rust with rustc 1.98.1 |
| Keyword semantics (implied specialization) | CATIA Magic API | 42/42 against the recorded baseline (1 case is a known Cameo deviation, see Known issues) |

Every Cameo run loads files in dependency order and undoes only its own harness-load commands. It stops and fails if any other command is on the undo stack, and cleanup is confirmed by an inspection with a positive control. The harness is then shut down. Experiments record their predictions in git before they run (`tests/cameo*/`).

## Known issues and open work

* **Stacked semantic keywords: CATIA Magic applies only the first one.** Confirmed by experiments E02 and E03 (predictions committed before each run; 8/9 and 3/3 held). Of the semantic keywords on one element (prefix or body form), only the **first** gets its implied specialization. The rest still show as labels, and the validation engine does not report the gap. KerML says every keyword applies, so this is a CATIA Magic deviation.
  **Usage rule:** put the keyword whose meaning matters most for queries first (e.g. `#primaryKey #column` when key membership matters). The regression baseline (`M15`) records the current behaviour and will flag it when Cameo is fixed.
* **ANTLR validator gaps:** example 06 (native behaviors) is exempt from the ANTLR syntax suite, because the validator also rejects the official OMG training models that use the same constructs. CATIA Magic loads it with 0 errors and 0 validation failures (`tests/validator-known-gaps.json`).
* **Views as diagrams:** the test run creates, lays out and exports each view's diagram, then undoes it. CATIA Magic does not draw exposed dependencies (I-33), and diagrams created without the layouter stack all shapes at one spot (E14).
* Validator issues found: the ANTLR `sysml-validator` does not resolve names, reverses the `direction`/`abstract` prefix order, and rejects `def`-prefixed names that have a multiplicity. Details are in `docs/DESIGN.md`.
* **IDL v1 scope:** valuetypes, maps, anonymous nested sequences, shift operators in constants, types nested in interfaces, and IDL CCM constructs are rejected on import. Export writes canonical IDL (qualified names, resolved constants), not the original text.
* **Open design issues** found while documenting and writing the requirements are listed as I-01 to I-34 in [`docs/DESIGN.md`](docs/DESIGN.md); they are maintainer decisions and none is fixed yet.
* The OMG Pilot Implementation check (`tools/pilot-check/`) is not operational, because the local Pilot build is broken.

## Layout

| Path | Contents |
|---|---|
| `library/` | The seven UML3 libraries |
| `requirements/` | UML3 requirements (19 area files), actors and use cases, in SysML v2 |
| `examples/` | Online-store models using every keyword |
| `tests/negative/` | Models that must fail locally (`EXPECT:` header) |
| `tests/cameo/` | Cameo hypotheses: implied specializations, label expectations |
| `tests/cameo-negative/` | Misapplied-keyword probes, validation-engine baseline |
| `tests/cameo-experiments/` | Design experiments with recorded predictions |
| `tools/check_names.py` | Name resolution, lint, keyword-applicability checker |
| `tools/check_rules.py`, `tests/rules/` | Design-rules checker and per-rule tests |
| `traceability/uml2-to-uml3.json`, `tools/check_traceability.py` | UML 2.x -> UML3 traceability (source + verifier + doc generator) |
| `docs/UML2-to-UML3-Traceability.md` | Generated traceability document |
| `tools/run_tests.py` | Regression harness |
| `tools/idl/`, `tests/idl/` | IDL importer/exporter core and CLI; IDL fixtures, expected SysML, unsupported-construct tests |
| `docs/IDL-MAPPING.md` | IDL ↔ UML3 mapping and tool usage |
| `docs/IDL-CODEGEN.md`, `tools/idl/UML3IdlCodegen.groovy` | Java / Rust generation |
| `external/idl/`, `tests/idl/corpus/` | IDL corpora (git submodules), expectations, per-file baseline |
| `tools/cameo_check.py`, `tools/cameo-scripts/` | CATIA Magic REST runner and Groovy scripts (synced to the harness) |
| `tools/check_groovy.groovy` | Pre-flight check for scripts that run inside MagicDraw |
| `docs/DESIGN.md` | Design, mapping, verification history, findings and open issues |
| `docs/DOC-CONVENTIONS.md`, `tools/check_docs.py`, `tests/docs/` | Documentation rules, checker and fixtures |
| `docs/REQUIREMENTS-GUIDE.md`, `tools/check_requirements.py`, `docs/UML3-Requirements.md` | Requirements rules, checker and generated catalog |

## Requirements

* Sibling checkouts of `SysML-v2-Release` and `sysml-validator` (with `validator-cli/target/sysml-validator.jar` built). Override their locations with `SYSML_RELEASE` and `SYSML_VALIDATOR_JAR`.
* Python 3, a JDK 17+ (the Java generator test compiles in-process), and Groovy for the local tools.
* The IDL corpora: `git submodule update --init --depth 1`. Optional: a Rust toolchain (`winget install Rustlang.Rustup`) so the tests also compile the generated Rust; without it Rust is only generated and checked against expected lines.
* For `--cameo`: CATIA Magic / MSoSA 2026x with the SysML v2 plugin and `start-v2language-test-harness.groovy` running (REST on port 8770).
