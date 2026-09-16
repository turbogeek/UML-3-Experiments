# UML-3-Experiments

**Goal:** give SysML v2 the modeling power UML offers for software work: object-oriented analysis and design, software and deployment architecture, messaging/event-driven design, and data/database modeling.

The approach uses only the extension mechanisms SysML v2 already standardizes:

* **Model libraries** of abstract base definitions (`Class`, `Operation`, `Component`, `DomainEvent`, `Entity`, `Table`...).
* **Semantic metadata keywords** (`#entity`, `#service`, `#primaryKey`...), the SysML v2 replacement for UML stereotypes. A keyword makes the element really specialize its library base (KerML 9.2.16), so models stay queryable and CATIA Magic shows the keyword as a `«#keyword»` label.
* **Plain metadata** for values such as `@Facets`, `@Index`, `@QualityOfService` and `@ForeignKey { onDelete }`.

The KerML/SysML grammar is not changed, so UML3 models are ordinary SysML v2.

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
| `library/UML3Data.sysml` | Logical models (`#entity`, `#aggregateRoot`, `#valueObject`, `#relationship` with cardinality); keys and constraints (`#primaryKey`, `#foreignKey` + referential actions, `#unique`, `#indexed`, `@Index`); physical schemas (`#database`, `#table`, `#column` + `@Column`, `#dbView`); governance (`#audited`, `#transient`, `@Sensitivity`); logical-to-physical `#mapsTo` |

`examples/` models one online store four ways: class model, architecture and deployment, messaging, and database. The full UML → SysML v2 mapping and design rationale are in [`docs/DESIGN.md`](docs/DESIGN.md).

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
| Names, lint, keyword applicability | `tools/check_names.py` | library and examples pass; 19 negative tests fail as expected |
| Checker calibration | `check_names.py` on 251 official OMG models | 0 false positives |
| Load, link, validate | CATIA Magic via REST harness (`tools/cameo_check.py`) | 9/9 files load; validation engine reports 0 failures |
| Misapplied-keyword probes | CATIA Magic | recorded behaviour; Cameo misses 2 of 5 cases that UML3 catches |
| Keyword labels | CATIA Magic label functions | 19/19 render `«#keyword»` |
| Keyword semantics (implied specialization) | CATIA Magic API | 42/42 against the recorded baseline (1 case is a known Cameo deviation, see Known issues) |

Every Cameo run loads files in dependency order, undoes its own loads (confirmed by an inspection with a positive control) and then shuts the harness down. Experiments record their predictions in git before they run (`tests/cameo*/`).

## Known issues and open work

* **Stacked semantic keywords: CATIA Magic applies only the first one.** Confirmed by experiments E02 and E03 (predictions committed before each run; 8/9 and 3/3 held). Of the semantic keywords on one element (prefix or body form), only the **first** gets its implied specialization. The rest still show as labels, and the validation engine does not report the gap. KerML says every keyword applies, so this is a CATIA Magic deviation.
  **Usage rule:** put the keyword whose meaning matters most for queries first (e.g. `#primaryKey #column` when key membership matters). The regression baseline (`M15`) records the current behaviour and will flag it when Cameo is fixed.
* Validator issues found: the ANTLR `sysml-validator` does not resolve names, reverses the `direction`/`abstract` prefix order, and rejects `def`-prefixed names that have a multiplicity. Details are in `docs/DESIGN.md`.
* The OMG Pilot Implementation check (`tools/pilot-check/`) is not operational, because the local Pilot build is broken.

## Layout

| Path | Contents |
|---|---|
| `library/` | The five UML3 libraries |
| `examples/` | Online-store models using every keyword |
| `tests/negative/` | Models that must fail locally (`EXPECT:` header) |
| `tests/cameo/` | Cameo hypotheses: implied specializations, label expectations |
| `tests/cameo-negative/` | Misapplied-keyword probes, validation-engine baseline |
| `tests/cameo-experiments/` | Design experiments with recorded predictions |
| `tools/check_names.py` | Name resolution, lint, keyword-applicability checker |
| `tools/run_tests.py` | Regression harness |
| `tools/cameo_check.py`, `tools/cameo-scripts/` | CATIA Magic REST runner and Groovy scripts (synced to the harness) |
| `tools/check_groovy.groovy` | Pre-flight check for scripts that run inside MagicDraw |
| `docs/DESIGN.md` | Design, mapping, verification history and findings |

## Requirements

* Sibling checkouts of `SysML-v2-Release` and `sysml-validator` (with `validator-cli/target/sysml-validator.jar` built). Override their locations with `SYSML_RELEASE` and `SYSML_VALIDATOR_JAR`.
* Python 3, Java 17+, and Groovy for the local tools.
* For `--cameo`: CATIA Magic / MSoSA 2026x with the SysML v2 plugin and `start-v2language-test-harness.groovy` running (REST on port 8770).
