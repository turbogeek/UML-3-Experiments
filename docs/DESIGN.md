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
| Syntax | `sysml-validator` (ANTLR) | library + examples pass; negative tests fail as expected |
| Name resolution (imports, types, keywords, qualified names) | `tools/check_names.py` | library + examples pass; 6 negative tests fail as expected; 0 false positives on 251 official OMG models |
| Semantic validation (typing conformance, implied specialization from SemanticMetadata, redefinition rules, connection end typing) | OMG Pilot Implementation | **Not yet run** (see below) |

### Known open semantic questions (to confirm with the Pilot Implementation)

1. Operations: can a nested `#operation action` inside an `item def` subset the package-level `operations` without breaking featuring constraints? The official FMEA example does the same thing with occurrences, so we expect it to work.
2. `#assembly connect a to b` subsets `assemblyConnectors`, whose type `AssemblyConnector` declares no ends. We expect the connector ends to come from `Connection`.
3. `#classType part def StripeGateway :> PaymentGateway`: a `part def` specializing `item def`s is legal (`Part :> Item`). We still need to confirm there is no conflict with the implied `Class` specialization.
4. `#column attribute` subsets `columns : Base::DataValue[*]`. Columns typed by attribute defs conform. A column typed by an item would be a semantic error, which is intended.

The local `SysML-v2-Pilot-Implementation` build (0.55) can't be used here. Its jars contain "Unresolved compilation problems" stubs, which means they were compiled with errors. `tools/pilot-check/SysMLCheck.groovy` is a ready-to-use headless checker once a working Pilot build or the `jupyter-sysml-kernel` "all" jar is available.

## Validator findings (sysml-validator issues found during this work)

* **No name resolution.** Unresolved types, imports and specializations pass.
* **Lexer bug.** An identifier starting with `def` combined with a multiplicity is rejected. `attribute definitionQuery : String[0..1];` fails, but `attribute definitionQuery : String;` and `attribute x : String[0..1];` both pass.
* **KerML keywords rejected as SysML names.** `class`, `datatype`, `feature`, `type`, `composite`, `value` and `sequence` are refused. This is arguably stricter than the SysML reserved-word list, but models should avoid these names anyway, for portability.
