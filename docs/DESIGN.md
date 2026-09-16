# UML3: UML-style modeling on SysML v2

## Goal

Make SysML v2 as good as UML for object-oriented analysis, software design and architecture, messaging, and data/database modeling. Everything is done with the extension mechanisms that SysML v2 already defines, so any conforming tool can load the result:

1. **Model libraries.** Abstract base definitions (`Class`, `Operation`, `Entity`, `Topic`...) that give each concept its meaning.
2. **Semantic metadata.** Metadata defs that specialize `Metaobjects::SemanticMetadata`. They work as user-defined keywords (`#entity`), the SysML v2 replacement for UML stereotypes.
3. **Plain metadata.** Metadata for UML properties that SysML v2 has no equivalent for (`#static`, `@GeneralizationSet`, `@Facets`, `#primaryKey`).

We do not change the KerML or SysML grammar or abstract syntax.

## How a keyword works

The library pairs every concept with an abstract collection usage and a keyword whose `baseType` points at that usage:

```sysml
abstract item def Entity :> Class;
abstract item entities : Entity[0..*] nonunique :> classes;

metadata def <entity> EntityMetadata :> SemanticMetadata {
    :>> baseType = entities meta SysML::Usage;
}
```

KerML 9.2.16 says what applying the keyword implies:

| Annotated element | Implied relationship |
|---|---|
| `#entity item def Customer` (a classifier) | `Customer` **subclassifies** `Entity`, the type of `entities` |
| `#entity item c` (a feature) | `c` **subsets** `entities` |

So one keyword covers both the definition ("class") and the instance ("object"). Because a keyworded element really specializes the base, it inherits the base's features, such as the `header` on every `#domainEvent` message. Queries like "all entities" become ordinary specialization queries.

## Naming rules

* Keywords are lowerCamelCase short names. Base definitions are UpperCamelCase.
* A keyword must not be a reserved word. This covers the SysML words (`interface`, `message`, `use`, `event`, `view`, `end`, `flow`...) and also the KerML words (`class`, `datatype`, `feature`, `type`, `composite`, `value`, `sequence`), because tools with a merged KerML/SysML lexer reject those as names. Where the UML name is reserved, add `Type` or turn it into a verb: `#classType`, `#interfaceType`, `#messageType`, `#dbView`, `#uses`. Negative tests `n07` and `n08` enforce this.

## UML → SysML v2 mapping

### Structure (UML3Core)

| UML | SysML v2 native | UML3 addition |
|---|---|---|
| Class | `item def` (or `part def` if structural) | `#classType` → `Class` |
| Active class | `part def` | `#activeClass` |
| Abstract class | `abstract` | — |
| Interface / realization | `item def` of abstract operations; realize with `:>` and redefine with `:>>` | `#interfaceType` |
| DataType | `attribute def` | `#dataType` |
| Enumeration | `enum def` | — |
| Signal / exception | `item def` | `#signal`, `#exceptionType` |
| Property visibility | `public` / `private` / `protected` | — |
| Read-only / derived | `constant` / `derived` | — |
| Multiplicity, ordered, unique | `[m..n] ordered nonunique` | — |
| isStatic, isLeaf, isID | — | `#static`, `#final`, `#id` |
| Operation (in/out/inout, return) | nested `action` / `calc` with directed parameters | `#operation`, `#query` (calc), `#constructor` |
| Association (+ end multiplicities) | `connection def` with two `end` features | `#association` |
| Association class | `connection def` that also has attributes | `#association` |
| Navigability | `ref` feature on the opposite participant | `@Navigable` in the end body |
| Aggregation / composition | composite (`part`/`item`) vs `ref` usage | `#aggregation`, `#composition` |
| Generalization | `:>` | — |
| GeneralizationSet (covering/disjoint) | — | `@GeneralizationSet`, `@InGeneralizationSet` |
| Template / binding | abstract feature + `:>>` redefinition in a specialization | `#template`, `#templateParameter` |
| Dependency «use»/«create»/«call»/«trace» | `dependency from … to …` | `#uses`, `#creates`, `#calls`, `#traces`, `#realizes`, `#instantiates` |
| Instance specification | usages / `individual` / `snapshot` | — |
| State machine, activity, use case | native `state`, `action`, `use case` | — |
| Sequence diagram | `occurrence def` with lifelines, `event occurrence`, `message … from … to …`, `first … then …` | — |

### Types (UML3Types)

`Int8`–`Int64`, `UInt8`–`UInt64`, `Float32`, `Float64`, `Decimal`, `Money`, `Char`, `Text`, `Uuid`, `Uri`, `EmailAddress`, `CurrencyCode`, `JsonText`, `Bytes`, `Date`, `TimeOfDay`, `Timestamp`, `DurationValue`, `MapEntry`. Each one specializes the closest `ScalarValues` type, so standard expressions still work. The `@Facets` metadata records machine limits in XSD / JSON Schema style: `minInclusive`, `maxLength`, `precision`, `scale`, `pattern`, `bitWidth`.

Collection kinds need no new types:

| Collection kind | Multiplicity |
|---|---|
| Set | `[*]` |
| OrderedSet | `[*] ordered` |
| Bag | `[*] nonunique` |
| List | `[*] ordered nonunique` |
| Optional | `[0..1]` |

### Architecture and deployment (UML3Components)

| UML | UML3 |
|---|---|
| Component / subsystem / service | `#component`, `#subsystem`, `#service` (`part def`, specializing `ActiveClass`) |
| Port with provided interface | `ServicePort` specialization that binds `contract`, used as `#provided port p : ApiPort` |
| Port with required interface | `#required port p : ~ApiPort` (conjugated) |
| Assembly / delegation connector | `#assembly connect a.p to b.q`, `#delegation` |
| Artifact, Node, Device, ExecutionEnvironment | `#artifact`, `#node`, `#device`, `#executionEnvironment` |
| Deployment / manifestation | `#deploy allocate artifact to node`, `#manifest allocate component to artifact` |
| Communication path | `#communicationPath connection def` |
| Layers / styles / technology | `#layer package` + `@Layer`, `#boundary`, `@Technology` |

### Messaging (UML3Messaging)

| Concept | UML3 |
|---|---|
| Message schema with envelope | `#messageType`, `#command`, `#domainEvent`, `#queryMessage`, `#reply`, `#documentMessage` (all carry a `MessageHeader`) |
| Encoding | `@Serialization { format = SerializationFormat::avro; schemaRef = …; }` |
| Channels | `#channel`, `#topic` (pub/sub), `#queue` (point-to-point), `#broker` |
| Endpoints | `ProducerPort`, `ConsumerPort`, `RequestReplyPort`; narrow the message type with `:>>` |
| Delivery semantics | `@QualityOfService` (delivery guarantee, ordering, partition key, retention, retries, DLQ), `#idempotent` |
| Wiring | native `flow of T from … to …` tagged `#publishes` / `#subscribes` / `#sends` / `#handles` |

### Data (UML3Data)

| Concept | UML3 |
|---|---|
| Entity / aggregate root / value object | `#entity`, `#aggregateRoot`, `#valueObject` |
| Relationship and cardinality | `#relationship connection def` whose `end` multiplicities give the cardinality; attributes on it turn M:N into a join table |
| Keys and constraints | `#primaryKey` (several = composite key; `@PrimaryKey { generation }`), `#foreignKey` + `@ForeignKey { onDelete, onUpdate, referencedTable, referencedColumn }`, `#unique`, `#indexed`, `@Index` |
| Physical schema | `#database part def`, `#table item def`, `#column attribute` + `@Column { sqlType, columnDefault }`, `#dbView` |
| Governance | `#audited`, `#transient`, `@Sensitivity { classification = "PII"; }` |
| Logical → physical | `#mapsTo dependency from TABLE to Entity` |

## Verification status

| Check | Tool | Status |
|---|---|---|
| Parse, link and validate in a commercial implementation | CATIA Magic SysML v2 test harness (`tools/cameo_check.py`, REST `/load-sysml`) | **All 9 files (5 library + 4 examples) load with 0 errors** (2026-09-16) |
| Keyword semantics (implied specialization/subsetting/inheritance) | CATIA Magic API via `verifyImpliedSpecializations.groovy` | **21/21 hypotheses hold, including 7 negative controls** |
| Validation engine (KerML/SysML constraint suites) | `validateUML3Packages.groovy` | **0 failures on library + examples** |
| Diagram keyword labels | `probeKeywordDisplay.groovy` | semantic keywords render `«#keyword»`; plain metadata is not in the label |
| View contents (expose + filter) | `probeViewContents.groovy` | 9/9 views match predicted includes and excludes |
| Design rules | `tools/check_rules.py` | examples 0 errors; 12 rules each proven to fire |
| Syntax | `sysml-validator` (ANTLR) | Library and examples pass; negative tests fail as expected |
| Name resolution, lint and keyword applicability | `tools/check_names.py` | Library and examples pass; 16 negative tests fail as expected; 0 false positives on 251 official OMG models |
| OMG Pilot Implementation | `tools/pilot-check` | Not run (the local 0.55 build is broken) |

Run everything with `python tools/run_tests.py --cameo`. The harness must be running in CATIA Magic. The runner loads the files in dependency order, **undoes its own loads** (checked with `inspectUML3Roots.groovy`, which includes a positive control), and then stops the harness.

### Errors CATIA Magic found that local tools missed (now covered by LINT)

1. `abstract out item x`: the direction must come first (`RefPrefix = direction? derived? abstract? constant?`).
2. `#foreignKey ref item x`: `ref` must come before the extension keywords (`ref #foreignKey item x`).
3. Integer literals above 2147483647 (`Integer number too large`): use Real exponent form, e.g. `4.294967295E9`.

### Implied specializations verified in CATIA Magic

A clean load only shows the files parse and resolve. `tests/cameo/implied-specializations.json` also checks that the keywords **mean** what the design says, by calling `Type.specializes()` and `Type.getFeature()` on the loaded model (`tools/cameo-scripts/verifyImpliedSpecializations.groovy`). The cases include negative controls, which prove the check can fail. **21/21 hold (2026-09-16)**:

* Definitions: `#service` → `Component`/`ActiveClass`, `#classType` → `Class`, `#aggregateRoot` → `AggregateRoot`/`Entity`, `#domainEvent` → `DomainEvent`/`Signal`, `#association` → `Association`, `#composition` → `Composition`. For `OrderService`, the probe showed an *owned* subclassification to `Service` that is not written anywhere in the source text.
* Features: `#operation action` subsets `operations`, `#query calc` subsets `queries`, `#column attribute` subsets `columns`.
* Inheritance: every `#domainEvent` inherits `header : MessageHeader`.
* Controls (all false, as predicted): `#classType` is not an `Entity`, `#entity` is not an `AggregateRoot`, a domain event is not a `Command`, a plain attribute is not an operation, composition is not aggregation, and a plain class has no `header`.

### Misapplied keywords: CATIA Magic accepts them, so UML3 checks them (`APPLICABILITY`)

The experiment is in `tests/cameo-negative`; predictions were written down before running. Five misapplied keywords were predicted to be rejected. **All five loaded with no builder errors.** `probe-effects.json` then showed (4/4) that Cameo actually builds the inconsistent specializations. For example, `#entity attribute def Money` makes a value type a subtype of the `Entity` class. The load path only reports parsing and linking diagnostics; whether Cameo's separate *Validate Model* suites would catch these has not been tested.

`tools/check_names.py` therefore enforces applicability. The rule is derived from the library, not from a hand-kept table:

* **Semantic keywords.** An error is reported when the `baseType` usage and the annotated element fall in *disjoint* type families according to the Kernel library: `Occurrence` is disjoint from `DataValue`, and `Performance` is disjoint from `Object`. Semantic keywords on packages and dependencies are also rejected. Compatible additions are allowed. For example, the OMG example `#goal constraint` uses a requirement `baseType` on a constraint, which is legal because both are performances. An earlier, stricter sub-kind rule wrongly flagged that case during calibration.
* **Plain metadata.** An error is reported when the element violates the `annotatedElement` restriction, including restrictions inherited through metadata specialization (e.g. `#uses` inherits `SysML::Dependency` from `DependencyKind`).

Negative tests `n12`–`n18` cover these cases. The Cameo probe suite (`run_tests.py --cameo`) records the current Cameo behaviour and will flag it if a future version starts rejecting these models.

### CATIA Magic validation engine vs. UML3 APPLICABILITY

The SysML v2 validation in CATIA Magic is a separate KerML engine (`com.dassault_systemes.modeler.kerml.validation.ValidationService`), not UML *Validate Model*: the UML validation helper reports 0 suites in a SysML v2 project. `tools/cameo-scripts/validateUML3Packages.groovy` runs the engine's active and passive suites (`DassaultSystemesValidationSuite`, `SysMLConstraintsSuite`) on every loaded package. Predictions were committed before the run (`0329c69`); 12 of 15 were correct.

| Case | CATIA Magic validation engine | UML3 `APPLICABILITY` |
|---|---|---|
| Library (5 packages) + examples (4 packages), about 5,900 elements | **0 failures** | 0 findings |
| `#entity attribute def` | `validateDataTypeSpecialization` | caught |
| `#operation attribute` (usage) | **not caught** | caught |
| `#mapsTo item def` | `validateMetadataFeatureAnnotatedElement` | caught |
| `#classType package` | **not caught** | caught |
| `#column item def` | `validateClassSpecialization` | caught |

The two checks overlap but neither replaces the other. Cameo's engine misses keyword misuse on features and on non-types. UML3's checker does not do Cameo's full conformance validation. `run_tests.py --cameo` runs both. The observed engine results are stored in `tests/cameo-negative/validation-predictions.json` next to the original predictions and act as a regression baseline.

### How CATIA Magic displays the keywords

Tested read-only through the functions behind the diagram shape labels (`KeywordProvider`, and `ModelTextCreator` as used by `MetadataLabelWrapper`), found with `javap`. Script: `tools/cameo-scripts/probeKeywordDisplay.groovy`. Predictions were committed first (`9e8a3bc`), and 5 of 6 held.

| Element | Rendered keyword text |
|---|---|
| `#service part def OrderService` | `«part def»` and **`«#service»`** |
| `#classType item def Customer` | `«item def»` and **`«#classType»`** |
| `#operation action cancel` (a nested usage) | `«action»` and **`«#operation»`** |
| `#primaryKey attribute orderId` (**plain** metadata) | `«attribute»` only; **`#primaryKey` is not in the keyword label** |
| `enum def OrderStatus` (control) | `«enum def»` only |

**Semantic keywords show like UML stereotypes (`«#service»`).** Plain metadata keywords (`#primaryKey`, `#foreignKey`, `#unique`, `#id`, `#static`, `#provided`/`#required`, `#publishes`…) are left out of the keyword label. They may still appear in a shape's *metadata compartment*: `MetadataCompartmentDescriptor` exists, but the Collection overload only produced compartment `{ name = value }` text, so this is unconfirmed.

**Design implication, to be decided.** If these data and architecture markers must be visible on diagrams, they would have to become semantic keywords. Each one would then need a `baseType` that is valid on the elements it marks (e.g. both attributes and `ref` items for keys). That changes their meaning, so it needs its own Cameo experiment before it is adopted.

**Experiment E01: the semantic-key pattern works** (`tests/cameo-experiments/e01-*`). Predictions were committed first (`764854c`) and all held. The pattern is a semantic keyword whose `baseType` is a reference usage typed by `Base::Anything`:

```sysml
abstract ref keyFeatures : Base::Anything[0..*] nonunique;
metadata def <pk> PrimaryKeyKeyword :> SemanticMetadata { :>> baseType = keyFeatures meta SysML::Usage; }
```

Results in CATIA Magic:
* The model loads with no errors, and the validation engine reports 0 failures.
* Both `#pk attribute accountId` and `ref #pk item owner` subset `keyFeatures`; the unmarked control does not.
* Both render as **`«#pk»`**; the control has no label.
* The local checker reports 0 findings, because a `ref` base belongs to no disjoint family.

This pattern is therefore available for any marker that must be visible on diagrams. A marker converted this way also becomes queryable as a set (e.g. "all key features" = the `keyFeatures` subsets). **It is not yet adopted in the library; that is a design decision.**

Still open: confirming on an actual diagram whether plain metadata appears in the metadata compartment.

### Marker keywords converted to semantic metadata, and the stacked-keyword deviation

All marker keywords that go on types were converted to the E01 pattern (commit `bc2cb63`). Plain metadata remains only where needed: dependencies and packages (`#uses`…, `#mapsTo`, `#layer`), valued configuration (`@Facets`, `@Index`, `@Column`, `@QualityOfService`…), and, until E04, `@Navigable` (see below). In CATIA Magic, 9/9 files load, the validation engine reports 0 failures, labels are 17/17 (including flows, conjugated ports and body form), and 38/39 predicted specializations held.

The failing case (`#column #primaryKey attribute ACCOUNT_ID` is not in `primaryKeyFeatures`) led to two experiments, with predictions committed before each run:

| Experiment | Case | Result |
|---|---|---|
| E02 | `#column #primaryKey` / `#primaryKey #column` | only the first keyword is applied; the reversed order gives the reverse result |
| E02 | `#unique #indexed` | only `#unique` is applied, so the effect is not keyword-specific |
| E02 | `#column attribute C { @PrimaryKey; }` | body-form second keyword **also** ignored (the prediction was refuted) |
| E03 | `attribute F { @PrimaryKey; }` | single body-form keyword is applied |
| E03 | `attribute G { @Unique; @Indexed; }` | only the first is applied |

**Conclusion.** CATIA Magic 2026x Refresh1 applies the implied specialization of only the **first** semantic metadata on an element. KerML 9.2.16 requires it for each. Labels and validation give no sign of the gap. The usage rule is to order keywords by query importance. `M15` in `tests/cameo/implied-specializations.json` records the observed behaviour (`kermlExpected: true`), so the suite will flag the change when Cameo is fixed. A possible library workaround, not adopted: combined keywords whose base subsets several sets (e.g. `#pkColumn` with a base `:> columns, primaryKeyFeatures`).

### `#navigable` on association ends (experiment E04)

Predictions were committed first (`16401eb`), and all held. A semantic keyword on `end` features, in body form (`end [1] ref customer : Customer { @Navigable; }`) and in prefix form (`end [1] #navigable item customer : Customer;`):
* loads, and the validation engine reports 0 failures;
* the ends join `navigableEnds`, and an unmarked end does not;
* connection usages binding those ends stay typed by their connection def, and the def is still an `Association`;
* both marked ends show `«#navigable»`.

`UML3Core::Navigable` was therefore converted (`b0e277a`). The full run passes with 42/42 specializations, 19/19 labels and 0 validation failures. Every marker keyword in the library is now semantic. Only dependency/package keywords and valued configuration metadata remain plain.

## Design-rules checker (`tools/check_rules.py`)

These are model-level rules for designs that are valid SysML v2 but inconsistent. ERROR findings fail the run; WARNINGs are only reported.

| Rule | Severity | Check |
|---|---|---|
| R01 | ERROR | `#table` has a `#primaryKey` |
| R02 | WARNING | `#entity` / `#aggregateRoot` has an identity (`#primaryKey` or `#id`) |
| R03 | ERROR / WARNING | a `#foreignKey` ref points to an entity/table; a column's `referencedTable` exists (WARNING when missing) |
| R04 | WARNING | associations are binary |
| R05 | WARNING | interface operations are abstract |
| R06 | ERROR | a concrete realization redefines every abstract interface operation |
| R07 | ERROR | `#provided` ports are not conjugated; `#required` ports are |
| R08 | WARNING | `#required` ports of parts are connected |
| R09 | WARNING | message types have payload attributes |
| R10 | WARNING | topics and queues declare `@QualityOfService` |
| R11 | WARNING | `#dbView` sets `queryText` |
| R12 | WARNING | usages stacking several semantic keywords (CATIA Magic applies only the first, E02/E03) |

Evidence: each of `tests/rules/r01`-`r12` produces exactly its rule, and the clean control `r00` produces none. The examples give 0 errors and 5 R12 warnings, all correct.

## UML diagrams as SysML v2 views (`library/UML3Views.sysml`)

View definitions specialize the standard views and filter on UML3 keyword metadata: `PackageDiagram`, `ClassDiagram`, `ComponentDiagram` (interconnection), `DeploymentDiagram`, `EntityRelationshipDiagram`, `MessageSchemaView`, `SequenceDiagram` (sequence view) and `ClassTable` (grid). A usage only exposes content: `view domainClassDiagram : ClassDiagram { expose OnlineStoreDomain::*; }` (see `examples/05`).

**CATIA Magic evaluates the views.** `ViewUsage.getExposedElement()` returns the filtered content. All 9 views matched their predicted includes and excludes. The deployment view, for example, contains exactly the artifact, pod, node and communication path.

**Import leak and fix (E06).** An `expose` is an import with *import all*, so exposing a package also exposes what it imports. Library elements appeared in views (`AggregationKind`; library port and connection bases). A reflective filter `not (as KerML::Element).isLibraryElement` removes them; the E06 predictions, including two at low confidence, all held. Every view def now carries it. Imported *user* elements (e.g. domain interfaces in the component view) remain by design.

**Rendering.** A view in the model is not yet an opened diagram in CATIA Magic. None of the harness operations (load, view evaluation, validation) created a diagram (E07). Opening or creating the diagram for a view is the next step.

## Occurrence vs Item as the base of `Class` (E05)

In the kernel, `Item :> Object :> Occurrence`, `Performance :> Occurrence`, `Object` is disjoint from `Performance`, and `Occurrence` is disjoint from `DataValue`. Predictions were committed first (`c54cf69`).

| Question | Item-based `Class` (current) | Occurrence-based `Class` |
|---|---|---|
| `#classType` on `item def`, `part def`, `connection def` | yes | yes (verified) |
| `#classType` on `action def` (UML: Behavior is a Class) | no: CATIA Magic ERROR `validateBehaviorSpecialization` and UML3 `APPLICABILITY` | yes: 0 validation failures; the behavior class is still an `Action` (verified) |
| `#classType` on `occurrence def` (sessions, lifetimes, time slices) | no (an item is narrower) | yes (verified) |
| `#classType` on `attribute def` | no | no (CATIA Magic `validateDataTypeSpecialization`, UML3 `APPLICABILITY`) |
| An instance can flow, be a port item or be a message payload | yes: every class is an `Item` | only if the class is also an item def; an occurrence-only class is not an `Item` (verified) |
| Protection when an occurrence-only class is used as an `item` | n/a | none in CATIA Magic: `out item msg : OMessage` passes validation, so a UML3 rule would be needed |

**Consequence of switching.** `Class` becomes an `occurrence def`. Kinds that must flow or persist become explicit item defs under it: `Signal`, `MessageType`, `ExceptionType`, `Entity`, `Table`, `Artifact`. `InterfaceType` becomes an occurrence def, so behaviors can realize interfaces; `ServicePort.contract` then changes from `ref item` to `ref occurrence`. A new rule would flag item usages typed by non-item classes. Semantic-keyword applicability widens accordingly (the occurrence family is compatible with both structures and behaviors).

## Decisions (2026-09-16)

1. **Behaviors are used as-is.** `action def`, `state def`, `calc def` and `use case def` get no UML3 keyword or `Class` label. SysML v2 behaviors already are classifiers with features, specialization and instances (performances). KerML's separation of `Object` and `Performance` is kept deliberately: it distinguishes a thing from the execution of a behavior, and CATIA Magic enforces it (`validateBehaviorSpecialization`). UML 2.x "Behavior is a Class" is recorded in the traceability map, not copied. UML 2.x XMI interchange, if needed, becomes a mapping concern.
2. **`Class` stays item/part-based.** The occurrence-based alternative (E05) is not adopted, because its main gain was behaviors as classes, which decision 1 rules out.
3. **Traceability is part of the product.** Every UML 2.x concept has a row in `traceability/uml2-to-uml3.json` with status NATIVE, NATIVE+UML3, UML3, PARTIAL or NOT_ADOPTED, plus rationale. The tests verify every cited element and example.
4. **Attributes.** An attribute of a class is an attribute USAGE, typed directly by a value type. An attribute def is the better choice when the attribute is complex, i.e. insufficiently described by its type alone (e.g. it needs its own nested features, a built-in multiplicity other than the normal one, facets or defaults), or when the value type is reused or published. This is modeler judgment; UML3 deliberately has no rule enforcing it. (The E05 row "`#classType` on `attribute def` is invalid" is about applying a class keyword to a value type, not about class attributes.)

## Harness safety incident and guard (E07)

An audit of the command history found two commands, "General View" and "Multiple add", interleaved with harness loads. The old undo script had undone them together with the loads. E07 showed that none of the harness operations create such commands, so they were probably GUI actions in CATIA Magic during the run. The undo script now undoes only `SysMLv2TestHarness: REST Load SysML` commands. It stops and reports on any other command, and `cameo_check.py` then fails.

## IDL import and export (E08, E09)

The full mapping and tool usage are in [`IDL-MAPPING.md`](IDL-MAPPING.md). Design points:

* **The core is pure Groovy.** It holds no MagicDraw classes, so the same parser, emitter and writer run in local tests and inside CATIA Magic. The Cameo scripts only add the build and the model reading around it. The model reader is duck-typed (`respondsTo`), because the KerML API is not homogeneous across element kinds.
* **Import goes through the SysML v2 text builder** as one command. A build error cancels everything, so a partial import cannot exist, and the guarded undo can remove the import like a harness load.
* **Nothing is lost on export.** IDL details that SysML v2 has no native concept for (sequence bounds, array dimensions, member ids, discriminator/case labels, `oneway`, `@IdlReturn`, other annotations) live in `UML3IDL` metadata.
* **E08 (`const`).** The first mapping used package-level `constant attribute`. The CATIA Magic validation engine reported 4 `validateFeatureConstantIsVariable` errors, because KerML requires a constant feature to be variable. Constants now map to a bound attribute (`attribute N : T = v;`), and `check_rules.py` R14 catches the old form. It flags exactly 4 on the old output and 0 on the new.
* **E09 (export).** The first export from the live model failed. Inside a closure, a bare `call(...)` resolved to `Closure.call`, not to the helper method of the same name. Renaming the helper to `callOn` fixed it. The exported IDL is identical to the canonical original, and the command history is unchanged, which shows export is read-only. `cameo_check.py --idl` now repeats this for every `tests/idl/*.idl` in each `--cameo` run.

## IDL corpora and code generation (E10)

* **Test input from real projects.** The seven IDL projects are git submodules (shallow, pinned commits), not copies. Their tests can be updated deliberately, and licenses stay with the sources. Files the upstream compiler must reject (JacORB `compiler/fail`, ic-hir `tests/fail`) are classified as known-invalid.
* **Invariants and a baseline, not 701 expected outputs.** The check asserts properties that must hold for every file: no crash, a stable canonical round trip, no regression, and generated Java that compiles. It records each file's outcome, so an improvement shows up as a reviewed baseline change.
* **Generators work on the IDL AST.** The same Java and Rust generators serve IDL files and SysML models (`fromModel`), and the canonical IDL writer is a third output of that AST.
* **Java follows the OMG standard; Rust follows practice.** IDL4-Java 1.0 is normative, and its own examples serve as tests. Where the spec contradicts itself, one rule is implemented and the exceptions are recorded in the test data. Rust has no OMG mapping, so the ic-idl conventions are used and the choices are documented (`docs/IDL-CODEGEN.md`).
* **Findings.**
  * Parser: 3 crashes, 1 unstable round trip, 1 missing feature (bounds as expressions).
  * Generators: arrays inside generics, generic array creation, `Object` method names, numeric `wchar` constants, duplicate names, reopened modules, references to the unnamed package.
  * Groovy 5: map pseudo-properties (`Empty`, `properties`, `metaClass`).

  Each was fixed and has a regression test.

## Validator findings (sysml-validator issues found during this work)

* **No name resolution.** Unresolved types, imports and specializations pass.
* **Lexer bug.** An identifier starting with `def` combined with a multiplicity is rejected. `attribute definitionQuery : String[0..1];` fails, but `attribute definitionQuery : String;` and `attribute x : String[0..1];` both pass.
* **Reversed prefix order.** It rejects the legal `out abstract item x` and accepts the illegal `abstract out item x`, which is the reverse of the BNF and of CATIA Magic. The library avoids the conflict by not combining a direction with `abstract`.
* **KerML keywords rejected as SysML names.** `class`, `datatype`, `feature`, `type`, `composite`, `value` and `sequence` are refused. This is arguably stricter than the SysML reserved-word list, but models should avoid these names anyway, for portability.
