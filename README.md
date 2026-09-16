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
| `library/UML3Views.sysml` | UML diagram kinds as SysML v2 views: `ClassDiagram`, `PackageDiagram`, `ComponentDiagram`, `DeploymentDiagram`, `EntityRelationshipDiagram`, `MessageSchemaView`, `SequenceDiagram`, `ClassTable`; they filter on UML3 keywords and hide leaked library elements |
| `library/UML3Data.sysml` | Logical models (`#entity`, `#aggregateRoot`, `#valueObject`, `#relationship` with cardinality); keys and constraints (`#primaryKey`, `#foreignKey` + referential actions, `#unique`, `#indexed`, `@Index`); physical schemas (`#database`, `#table`, `#column` + `@Column`, `#dbView`); governance (`#audited`, `#transient`, `@Sensitivity`); logical-to-physical `#mapsTo` |
| `library/UML3IDL.sysml` + `tools/idl/` | OMG IDL 4.2 **import and export** (Groovy, inside CATIA Magic or on the command line): modules, structs, typedefs, sequences, arrays, bounded strings, fixed, enums, unions (`#union`, `@Discriminator`, `@Case`), exceptions, interfaces with operations, `oneway` and `raises`, constants and common annotations. IDL basic types `Octet`, `WChar`, `WString`, `LongDouble`, `Any`. Mapping: [`docs/IDL-MAPPING.md`](docs/IDL-MAPPING.md). **Code generation** from IDL or from the model: Java per the OMG IDL4 to Java 1.0 mapping and Rust ([`docs/IDL-CODEGEN.md`](docs/IDL-CODEGEN.md)) |

`examples/` models one online store: class model, architecture and deployment, messaging, database, native behaviors (activity, state machine, use cases, instances; example 06), and a set of views (diagrams) over them. `tools/check_rules.py` checks 12 design rules, e.g. tables need primary keys, interface realizations must be complete, and required ports must be connected. The full UML → SysML v2 mapping and design rationale are in [`docs/DESIGN.md`](docs/DESIGN.md).

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
| Names, lint, keyword applicability | `tools/check_names.py` | library and examples pass; 19 negative tests fail as expected |
| Design rules | `tools/check_rules.py` | examples: 0 errors (5 true R12 warnings); each of 12 rules proven to fire; clean control stays clean |
| Checker calibration | `check_names.py` on 251 official OMG models | 0 false positives |
| Load, link, validate | CATIA Magic via REST harness (`tools/cameo_check.py`) | 13/13 files load (7 libraries, 6 examples); validation engine reports 0 failures, including the IDL import |
| View contents (expose + filter) | CATIA Magic `exposedElement` | 9/9 views match predicted includes and excludes |
| Misapplied-keyword probes | CATIA Magic | recorded behaviour; Cameo misses 2 of 5 cases that UML3 catches |
| Keyword labels | CATIA Magic label functions | 19/19 render `«#keyword»` |
| IDL import/export | `tools/idl/`, `run_tests.py` suite `idl-import` and `cameo_check.py --idl` | fixture imports as expected, 5 unsupported constructs rejected with clear messages; in CATIA Magic: 0 build errors, 0 validation failures, export from the model identical to the canonical original |
| IDL corpora (701 third-party files, `external/idl` submodules) | `tools/idl_corpus_check.py` | 394 imported with stable round trips, 0 crashes; generated Java compiles for 304, Rust generated for 266; per-file baseline |
| IDL code generation | `tools/idl/idl2code.groovy`, suite `idl-codegen` | 34/34 OMG IDL4-Java naming examples (2 spec inconsistencies documented), 53/53 spec Java declarations, Java compiled with javac; Rust checked against expected lines (not compiled: no rustc installed) |
| Keyword semantics (implied specialization) | CATIA Magic API | 42/42 against the recorded baseline (1 case is a known Cameo deviation, see Known issues) |

Every Cameo run loads files in dependency order and undoes only its own harness-load commands. It stops and fails if any other command is on the undo stack, and cleanup is confirmed by an inspection with a positive control. The harness is then shut down. Experiments record their predictions in git before they run (`tests/cameo*/`).

## Known issues and open work

* **Stacked semantic keywords: CATIA Magic applies only the first one.** Confirmed by experiments E02 and E03 (predictions committed before each run; 8/9 and 3/3 held). Of the semantic keywords on one element (prefix or body form), only the **first** gets its implied specialization. The rest still show as labels, and the validation engine does not report the gap. KerML says every keyword applies, so this is a CATIA Magic deviation.
  **Usage rule:** put the keyword whose meaning matters most for queries first (e.g. `#primaryKey #column` when key membership matters). The regression baseline (`M15`) records the current behaviour and will flag it when Cameo is fixed.
* **ANTLR validator gaps:** example 06 (native behaviors) is exempt from the ANTLR syntax suite, because the validator also rejects the official OMG training models that use the same constructs. CATIA Magic loads it with 0 errors and 0 validation failures (`tests/validator-known-gaps.json`).
* **Views are model elements, not yet opened diagrams:** CATIA Magic evaluates their content, but creating or opening the diagram for a view is still to be done.
* Validator issues found: the ANTLR `sysml-validator` does not resolve names, reverses the `direction`/`abstract` prefix order, and rejects `def`-prefixed names that have a multiplicity. Details are in `docs/DESIGN.md`.
* **Rust output is not compiled yet:** no Rust toolchain is installed on the test machine. The tests compile it automatically when `rustc` is on `PATH`.
* **IDL v1 scope:** valuetypes, maps, anonymous nested sequences, shift operators in constants, types nested in interfaces, and IDL CCM constructs are rejected on import. Export writes canonical IDL (qualified names, resolved constants), not the original text.
* The OMG Pilot Implementation check (`tools/pilot-check/`) is not operational, because the local Pilot build is broken.

## Layout

| Path | Contents |
|---|---|
| `library/` | The seven UML3 libraries |
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
| `docs/DESIGN.md` | Design, mapping, verification history and findings |

## Requirements

* Sibling checkouts of `SysML-v2-Release` and `sysml-validator` (with `validator-cli/target/sysml-validator.jar` built). Override their locations with `SYSML_RELEASE` and `SYSML_VALIDATOR_JAR`.
* Python 3, a JDK 17+ (the Java generator test compiles in-process), and Groovy for the local tools.
* The IDL corpora: `git submodule update --init --depth 1`. Optional: `rustc` on `PATH` to also compile the generated Rust.
* For `--cameo`: CATIA Magic / MSoSA 2026x with the SysML v2 plugin and `start-v2language-test-harness.groovy` running (REST on port 8770).
