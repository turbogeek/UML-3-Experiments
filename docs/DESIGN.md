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
| Parse, link and validate in a commercial implementation | CATIA Magic SysML v2 test harness (`tools/cameo_check.py`, REST `/load-sysml`) | **All 16 files (7 library + 6 examples + 3 CATIA Magic customization) load with 0 errors**, plus the IDL imports and 8 probes; the validation engine reports 0 failures on all 21 packages (2026-09-17) |
| Keyword semantics (implied specialization/subsetting/inheritance) | CATIA Magic API via `verifyImpliedSpecializations.groovy` | **42/42 against the recorded baseline, including negative controls**; probe effects 8/8 (E15) |
| Validation engine (KerML/SysML constraint suites) | `validateUML3Packages.groovy` | **0 failures on library + examples**; probes flagged exactly as predicted (E15) |
| Diagram keyword labels | `probeKeywordDisplay.groovy` | semantic keywords render `«#keyword»`; plain metadata is not in the label |
| View contents (expose + filter) | `probeViewContents.groovy` | 12/12 views match predicted includes and excludes |
| Views as diagrams (display mode, layout, SVG) | `exportViewDiagrams.groovy` + `tools/check_view_svg.py` | **15/15 views** (12 example views, 3 generated by the IDL import): expected display mode, 0 overlapping shapes, every expected element drawn and labeled in the SVG, no excluded element drawn |
| Design rules | `tools/check_rules.py` | examples 0 errors; 14 rules (R01–R12, R14, R15) each proven to fire |
| UML3 palettes in CATIA Magic | `verifyPalettes.groovy` + `tools/check_palettes.py` | **6/6 views** get their UML3 palette; all 45 templated buttons copy the expected element kind and keyword; the UML3 Create View dialog is active; 7 negative controls fail the check |
| Diagram kinds: model vs filters vs palettes | `tools/check_diagram_kinds.py`, `probeDiagramKinds.groovy` | 62 keyword entries over 8 kinds, 12 view filters and 6 palettes agree; 7 drift fixtures fail the check; the tool evaluates the same counts and labels (E18) |
| Syntax | `sysml-validator` (ANTLR) | Library and examples pass; negative tests fail as expected |
| Name resolution, lint and keyword applicability | `tools/check_names.py` | Library, examples and requirements pass; 23 negative tests fail as expected (n21, n22: keyword rules inherited through imports; n23: a reserved word as a declared name, E12); 0 false positives on 251 official OMG models |
| Documentation | `tools/check_docs.py` | 0 findings on D01–D07 in library, examples and requirements |
| Requirements | `tools/check_requirements.py` | 247 requirements and 59 use cases pass form, evidence, realization and trace checks |
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

### Refining a UML3 keyword in an extension library (E15)

The IDL `#union` is a data type, so it first specialized `#dataType` (`UnionMetadata :> DataTypeMetadata`) and bound its own base, `idlUnions`. CATIA Magic's validation engine rejected UML3IDL with `validateFeatureValueOverriding`: `DataTypeMetadata` already binds `baseType`, and KerML forbids a redefinition to override a bound value (KerML 8.3.4.10.2). A `default` base is no way out, because semantic metadata requires `baseType` to be bound.

UML3 uses **keyword categories** instead. `UML3Core::DataTypeKind` is an abstract metadata definition that specializes `SemanticMetadata` and leaves `baseType` unbound. `#dataType` and `#union` both specialize it and bind their own bases, and the class views filter on `@DataTypeKind`, so they select unions without importing UML3IDL. E15 recorded its predictions first, and all six held: the overriding form loads but is flagged, the category form validates clean, the implied specializations hold (Q06-Q09, with a negative control), and the IDL class views draw the union. `check_rules.py` R15 reports the overriding form locally; it fires on the old UML3IDL.

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

**Views as diagrams (E13).** `exportViewDiagrams.groovy` creates the diagram of each view (`Diagrams.createDiagram` with the view's definition, a *SysMLv2:General View*), shows the exposed elements (`DisplayExposedElements`) and exports the diagram to SVG, all in one undoable session. Two findings: CATIA Magic does not draw exposed **dependencies** (they stay in the model and in tables, and `tests/cameo/svg-expectations.json` lists them as `notDrawn`), and the plain SVG export draws text as outlines. With `ExportParams.useSVGTextTag` the SVG has `<text>` elements, so the test can read the names.

**Layout (E14).** Diagrams created through the API place every shape at one spot (190 overlapping pairs in the class diagram); a rendering (`render asTreeDiagram`) sets the display mode but does not lay out. Running the diagram's default layouter (`SysML2DiagramLayouter`) in the same session gives 0 overlapping shapes in every view.

**Compact and detail views (decision 2026-09-17).** The rendering decides what a shape shows. A tree rendering draws compact boxes (name and keyword label); a view without a rendering draws full compartments, including documentation, which dominates the diagram. UML3 therefore has both: `PackageDiagram`, `ClassDiagram`, `DeploymentDiagram`, `EntityRelationshipDiagram` and `MessageSchemaView` render as trees, and `ClassDetailDiagram`, `DeploymentDetailDiagram`, `EntityRelationshipDetailDiagram` and `MessageSchemaDetailView` repeat their filters without a rendering. The IDL importer generates `<file>_views` with a compact and a detail class diagram and a package diagram, so every imported IDL file can be reviewed as diagrams.

**How the test checks a diagram.** For every view in `tests/cameo/svg-expectations.json`, `tools/check_view_svg.py` checks the display mode, that no two sibling shapes overlap, that every expected element is drawn as a shape and appears as a declared-name label in the SVG (`Customer`, `#primaryKey customerId : Uuid`; words in documentation do not count), and that no excluded element is drawn. The expectations reuse the includes and excludes of `view-predictions.json`; negative controls (a missing element, an overlap, an outline SVG) make the check fail. The run undoes its own diagram session by name.

## Tool customization: UML3 palettes in CATIA Magic (E17)

The libraries are tool neutral, so a UML3 model in CATIA Magic is drawn with the generic SysML v2 palette: the
modeler creates an `item def` and then adds `#classType`. `customization/catia-magic/` removes that step. Each UML3
diagram kind becomes a CATIA Magic symbolic view whose palette creates UML3 elements: 6 view definitions, 6 palettes
and 41 templated buttons, plus a UML3 **Create View** dialog. Full description, installation and the palette
contents: [CATIA-MAGIC-CUSTOMIZATION.md](CATIA-MAGIC-CUSTOMIZATION.md).

A button copies a template package's single element, which already carries the keyword
(`package classTemplate { #classType item def; }`), the mechanism CATIA Magic uses for its own derivation buttons.
E17 established three rules for such a view definition, each from a measured surprise:

1. The vendor definition must be the **first** general type, because the tool builds its customization model
   downwards from `DS_Views::CoreViews::Visualization` and keeps a subtype only when its first general is the one
   above it (found in the bytecode of `sysml.dsl.a.g` after the palette silently stayed generic).
2. The definition must own **one** rendering that **redefines** the inherited ones, otherwise it has two renderers
   (`validateViewDefinitionOnlyOneViewRendering`); where both inherited renderings share a name, the redefinition
   names them by qualified name.
3. A view with a palette is always rendered (tree or nested), so **detail views** with full compartments cannot have
   a custom palette; they stay tool neutral.

Local checks run without CATIA Magic against a stub of the vendor library's names
(`tests/catia-magic/ds-customization-stub.sysml`). In CATIA Magic, `verifyPalettes.groovy` reads each view's
visualization, categories, buttons and the keyword of every button's template through the DSL service, and
`tools/check_palettes.py` compares that with `tests/cameo/palette-expectations.json` (7 negative controls).

## One model of the diagram kinds (E18, issue I-35)

The view filters in `UML3Views` and the palettes in `customization/catia-magic` held the same keyword lists twice, in
different order and granularity, with nothing to compare them. `library/UML3DiagramKinds.sysml` now holds that
knowledge once: one part per diagram kind with three lists.

| Role | Question it answers | Used by |
|---|---|---|
| `shows` | which keywords appear as shapes on this diagram kind | the `filter` of every view definition of the kind |
| `creates` | which keywords a tool should let the user create | the buttons of the tool palette |
| `views` | which `UML3Views` definitions render the kind | both, and reports |

The entries are metaobjects (`ClassMetadata meta KerML::Type`), not strings, so a rename cannot leave a stale entry
(the mistake criticized in I-23). Each palette declares its kind with `@PaletteForDiagramKind { kind = ... }`.
`shows` and `creates` are separate because they answer different questions: a class diagram *shows* `#template` but
cannot create it (it marks an existing definition), and *creates* `#operation` and `#query`, which appear inside a
classifier's compartment rather than as shapes.

`tools/check_diagram_kinds.py` compares the model with the 12 view filters and the 6 palettes: 62 keyword entries, 0
differences, and seven fixtures in `tests/diagram-kinds` prove it fails on drift (a filter that misses or adds a
keyword, a palette that misses or adds a button, an unlisted view definition, a palette without the annotation).
E18 confirmed all five predictions in CATIA Magic: the model loads, validates, and evaluates, so `cameo_check`
compares the counts and labels the tool reads back with the file. A palette generator could build its buttons from
`creates` instead of repeating the keywords.

E18 also found that loading the customization twice makes CATIA Magic drop the duplicate-named view definitions from
its customization registry, and every palette silently falls back to the General View palette.

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
5. **Compact and detail views (2026-09-17).** Each diagram kind that shows classifiers comes as a compact view (tree rendering) and a detail view (full compartments); see the views section.
6. **Keyword categories (2026-09-17, E15).** An extension keyword that refines a UML3 semantic keyword specializes the keyword's abstract category, not the keyword. So far only `DataTypeKind` exists (I-32).
7. **Tool customizations live outside the libraries (2026-09-17, E17).** `customization/<tool>/` holds what one tool needs (CATIA Magic palettes and Create View commands). The libraries stay tool neutral, and the customization specializes them.
8. **The diagram kinds are a model, not a list in each tool (2026-09-17, E18).** `UML3DiagramKinds` records per kind what a view shows, what a palette creates and which views render it; filters and palettes are checked against it.

## Harness safety incident and guard (E07)

An audit of the command history found two commands, "General View" and "Multiple add", interleaved with harness loads. The old undo script had undone them together with the loads. E07 showed that none of the harness operations create such commands, so they were probably GUI actions in CATIA Magic during the run. The undo script now undoes only `SysMLv2TestHarness: REST Load SysML` commands. It stops and reports on any other command, and `cameo_check.py` then fails.

**The command history has a maximum size (2026-09-17).** Commands older than the limit can no longer be undone, so a model loaded for review and then buried under many test runs cannot be removed by undo. The undo script therefore takes an exact count (`uml3-undo-limit.txt`, used when a run starts on a project that already holds a UML3 model) or a list of command names (`uml3-undo-only.txt`, used by the diagram step to remove only its own session). `cleanUML3Packages.groovy` removes named root packages in one undoable session when the history cannot. Test runs should start on a clean project (`inspectUML3Roots.groovy` reports `matches=0`).

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

## Documentation as model elements (2026-09-17)

UML3 documentation follows [DOC-CONVENTIONS.md](DOC-CONVENTIONS.md): every element owns a `doc` (what it is, usage,
rationale, references), each package summarizes its contents, explanations that span several elements are named
`comment ... about` annotations, and there are no banners or star decoration, which waste space on diagrams.
`tools/check_docs.py` enforces rules D01-D07, including citations checked against the clause headings of the KerML
and SysML v2 specifications, and `tools/compare_model_tokens.py` proves that a documentation change leaves the model
unchanged. The rewrite found tooling defects, all fixed with regression tests:

* sysml-validator: `comment X about A, B` (a list) and dependency bodies (`dependency d from A to B { doc ... }`)
  were rejected although the SysML v2 grammar allows them (fixed in the validator, parser tests added).
* check_names: `done`/`start` are legal names, named comments are namespace members, named control nodes
  (`merge retry`) are elements, and a `doc` or `comment` body ends a statement (the prefix-order LINT after a comment
  was silently skipped; negative test n20).
* check_traceability: quoted example snippets now match regardless of documentation.

### Open issues found while documenting

The documentation agents were told not to change models, so they reported what they found. These are decisions for
the maintainers; none is fixed yet.

| Id | Where | Issue |
|---|---|---|
| I-01 | UML3Components | `Component :> ActiveClass` makes every component active; UML 2.5.1 components are not active by default |
| I-02 | UML3Components, example 02 | `#layer package` without a body applies `Layer` without values; example 02 adds `@Layer { ... }` as well, giving two annotations |
| I-03 | UML3Views | `ComponentDiagram` filters on `@SysML::ConnectionUsage`, which also matches interface and allocation usages (deployments appear on component diagrams) |
| I-04 | UML3Views | No view selects the messaging flows (`#publishes`, `#subscribes`, `#sends`, `#handles`): flow usages are not connection usages |
| I-05 | UML3Views | The `isLibraryElement` filter also hides user models declared as `library package` (per KerML; not tested in CATIA Magic) |
| I-06 | UML3Components | `CommunicationPath` does not specialize `Association`; `Deployment` and `Manifestation` are the only non-abstract base definitions |
| I-07 | UML3IDL | `Discriminator`, `IdlOneway`, `IdlReturn` are plain metadata, while the design says marker keywords are semantic |
| I-08 | UML3Types | `MapEntry[*]` keeps entries unique, not keys; `Int64`/`UInt64` state no bounds; `Date`, `TimeOfDay`, `DurationValue` clash with names in the Time and ISQ libraries |
| I-09 | UML3Messaging | `#handles` / `#sends` semantics were never defined; documented as the handler side of an exchange, to be confirmed. Header `correlationId` / `causationId` conventions documented, to be confirmed |
| I-10 | UML3Data, UML3Messaging | Semantic keywords such as `#idempotent`, `#audited` on a definition act as labels only (only usages join the sets) |
| I-11 | example 01 | `Places` has two navigable ends but only one mirrored feature; `PaymentDeclined` is never raised; the order-lines composition is modeled twice (feature and `#composition`) |
| I-12 | examples 01, 03 | Orders are identified by `orderNumber : String` in 01 and `orderId : Uuid` in 03; `CapturePayment.amount` has no currency; `PaymentCaptured` is never carried |
| I-13 | example 02 | `ClusterNetwork` ends `[1]..[1]` limit each node to one link; `nodeB` has nothing deployed; layer packages hold parts not tied to `StoreSystem` |
| I-14 | example 04 | `OPEN_ORDERS_V.queryText` filters a column the table does not have; `#primaryKey` plus `@PrimaryKey { ... }` (and `#foreignKey` plus `@ForeignKey`) create two metadata usages whose values contradict; the physical schema is partial |
| I-15 | example 05 | `deploymentDiagram` shows none of the deploy/manifest allocations (they are nested in `productionCluster`) |
| I-16 | example 06 | `RetryPayment` never uses `attempts` (unbounded loop); `OrderLifecycle` has no final state |
| I-17 | check_rules | No rule reports a keyword applied twice to one element (prefix `#k` plus body `@K`), which I-14 shows is an easy mistake |
| I-18 | libraries | UML3 names clash with standard library names: `UML3Types::DurationValue`, `Date`, `TimeOfDay` (Time, ISQ), `Class`, `DataType`, `Association` (metaclasses re-exported by StandardViewDefinitions, which UML3Views imports together with UML3Core), `UML3IDL::Case` (`Cases::Case`) |
| I-19 | IDL import | Enumerator `@value` codes are dropped without a warning; IDL comments are dropped, so imported models do not meet the documentation rules |
| I-20 | IDL export, generators | Unmappable elements are handled inconsistently: generators fail with NOMAP, model export skips them or writes `any` with a warning and an OK result |
| I-21 | generators | `idl2code` deletes its output directory (no protection of hand-written code); generation from a live model covers only the IDL subset; deterministic regeneration is not tested |
| I-22 | requirements | Traceability uses `#realizes` dependencies and textual "Verified by" evidence rather than native `satisfy` and verification cases (tension with UML3-CORE-004); UML3's own tools are not model elements |
| I-23 | UML3Data, UML3Messaging | References held as strings (`@ForeignKey` columns, `@Index` columns, QoS dead-letter channel, partition key) break silently on rename; composite foreign keys cannot be expressed |
| I-24 | rules, views | Rules and view filters select by UML3 keyword, not by semantics: a user keyword whose base specializes Association is not checked by R04; a keyword name visible from two libraries is not reported as ambiguous |
| I-25 | UML3Core | `Association` does not specialize `Class` (association classes); `#final` and `#singleton` are not enforced; GeneralizationSet metadata duplicates KerML `disjoint`/`unions`; `MapEntry` duplicates `Collections::Map` without unique keys |
| I-26 | UML3Data, UML3Components, UML3Messaging | R02 flags conceptual entities without identity; architecture style can only be set through `@Layer`; IDL structs (attribute defs) cannot be message item types without a wrapper; `SerializationFormat` lacks CDR and is not extensible |
| I-27 | scope | No library concepts yet for tests, validation (concerns, acceptance criteria, reviews) or DevOps; no CI pipeline runs `run_tests.py`; a second semantic keyword on a definition is untested (R12 checks usages) |
| I-28 | tooling tests | `check_requirements.py` and `check_traceability.py` have no negative fixtures; the validator's reversed prefix order and `def`-name lexer bug are not in `tests/validator-known-gaps.json` |
| I-29 | actors | Roles used as stand-ins: ML engineer or data scientist, AI governance officer, hardware engineer, data steward, compliance officer or auditor, site reliability engineer, extension author |
| I-30 | decision | UML 2.x XMI interchange: DESIGN treats it as "if needed", requirement UML3-LANG-009 makes it mandatory |
| I-31 | UML3Core | Operations raising exceptions (`#raises`) and array dimensions (`IdlArray`) exist only in UML3IDL, although they are general OO concepts |
| I-32 | UML3Core, UML3Views | Keyword categories exist only for data types (`DataTypeKind`). Extension keywords that refine `#classType`, `#interfaceType`, `#signal`, `#exceptionType` or the association keywords cannot appear in the UML3 views without editing `UML3Views`; decide whether every classifier keyword gets a category (E15) |
| I-33 | UML3Views, CATIA Magic | CATIA Magic does not draw exposed dependencies, so the dependency keywords that `ClassDiagram` selects (`#uses`, `#realizes`...) and the `#mapsTo` dependencies of the data views are not visible on the diagrams (E13) |
| I-34 | UML3Views | Detail views repeat the filters of their compact views instead of inheriting them, so a filter change must be made twice; they do not inherit because the rendering would be inherited too (E14) |
| I-35 | customization | **Addressed 2026-09-17** by `library/UML3DiagramKinds.sysml` and `tools/check_diagram_kinds.py` (E18): the keywords of each diagram kind are modeled once and the view filters and palettes are checked against them. What remains: the palettes themselves are still written by hand rather than generated from the model, and only CATIA Magic has a customization |
| I-36 | customization | **Partly addressed 2026-09-17**: the messaging palette now has `#publishes`, `#subscribes`, `#sends` and `#handles` buttons, whose templates own two parts with UML3Messaging ports, because a flow with undirected ends has no related features; the message schema views select the flow keywords as well. What remains: detail views still cannot carry a UML3 palette (E17 rule 3), which is a CATIA Magic limitation |

## Validator findings (sysml-validator issues found during this work)

* **No name resolution.** Unresolved types, imports and specializations pass.
* **Lexer bug.** An identifier starting with `def` combined with a multiplicity is rejected. `attribute definitionQuery : String[0..1];` fails, but `attribute definitionQuery : String;` and `attribute x : String[0..1];` both pass.
* **Reversed prefix order.** It rejects the legal `out abstract item x` and accepts the illegal `abstract out item x`, which is the reverse of the BNF and of CATIA Magic. The library avoids the conflict by not combining a direction with `abstract`.
* **KerML keywords rejected as SysML names.** `class`, `datatype`, `feature`, `type`, `composite`, `value` and `sequence` are refused. This is arguably stricter than the SysML reserved-word list, but models should avoid these names anyway, for portability.
