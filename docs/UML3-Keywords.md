# UML3 keywords

Generated from `library/*.sysml` by `tools/check_keywords.py`; do not edit by hand.

Every keyword has two spellings, and they mean exactly the same thing:

```sysml
#classType item def Customer;   // the keyword: what diagrams show («#classType»)
#cls item def Customer;         // the terse id: the same definition, fewer keystrokes
```

A terse id exists only where it saves at least three characters; the other keywords are already short (`#id`, `#uses`, `#table`). Both names also work in the body form (`@classType { ... }`), in view filters and in queries. `tools/check_rules.py` R16 keeps the two slots in this order.

## UML3Core

| Keyword | Terse id | Base | Meaning |
|---|---|---|---|
| `#classType` | `#cls` | `classes` | the element is a UML3 Class (a definition specializes Class, a usage subsets classes) |
| `#activeClass` | `#acls` | `activeClasses` | the element is a UML3 ActiveClass; apply to part definitions and usages |
| `#interfaceType` | `#ifc` | `interfaceTypes` | the element is a UML3 InterfaceType (a contract of abstract operations) |
| `#dataType` | `#dt` | `dataTypes` | the element is a UML3 DataType; apply to attribute definitions and usages only |
| `#signal` | `#sig` | `signals` | the element is a UML3 Signal (an asynchronous stimulus) |
| `#exceptionType` | `#exc` | `exceptionTypes` | the element is a UML3 ExceptionType raised by operations |
| `#operation` | `#op` | `operations` | the action is a UML3 Operation of its owning class or interface |
| `#query` |  | `queries` | the calc is a side-effect-free UML3 Query operation |
| `#constructor` | `#ctor` | `constructors` | the action creates and initializes an instance of its owning class |
| `#association` | `#asc` | `associations` | the connection is a UML3 Association |
| `#aggregation` | `#agg` | `aggregations` | the connection is a shared aggregation (hollow diamond) |
| `#composition` | `#cps` | `compositions` | the connection is a composite aggregation (filled diamond) |
| `#static` | `#stc` | `staticFeatures` | the feature belongs to the classifier, not to each instance |
| `#final` |  | `finalElements` | the classifier may not be specialized, or the feature may not be redefined |
| `#id` |  | `identifierFeatures` | the attribute takes part in the identity of instances of its owner |
| `#navigable` | `#nav` | `navigableEnds` | the association end can be navigated from the opposite end |
| `#singleton` | `#sgl` | `singletonElements` | the class has at most one instance at runtime |
| `#template` | `#tpl` | `templateElements` | a templateable classifier, the UML3 form of a generic type |
| `#templateParameter` | `#tplParam` | `templateParameters` | an abstract feature that stands for a template parameter; bind it with ':>>' |
| `#uses` |  | (DependencyKind) | the client requires the supplier for its full implementation or operation |
| `#realizes` | `#rlz` | (DependencyKind) | the client realizes the supplier's specification where specialization is not appropriate, for example a component realizing a specification owned by another team |
| `#creates` | `#crt` | (DependencyKind) | the client creates instances of the supplier |
| `#calls` |  | (DependencyKind) | an operation of the client calls an operation of the supplier |
| `#traces` | `#trc` | (DependencyKind) | a historical or refinement link between elements that describe the same concept at different levels of abstraction |
| `#instantiates` | `#inst` | (DependencyKind) | operations of the client create instances of the supplier |

## UML3Components

| Keyword | Terse id | Base | Meaning |
|---|---|---|---|
| `#component` | `#cmp` | `components` | the element is a UML3 Component; a usage subsets components |
| `#subsystem` | `#subsys` | `subsystems` | the element is a UML3 Subsystem, a component that groups other components |
| `#service` | `#svc` | `services` | the element is a UML3 Service, a deployable component with a network API |
| `#servicePort` | `#svcPort` | `servicePorts` | a port def specializes ServicePort, a port usage subsets servicePorts |
| `#assembly` | `#asm` | `assemblyConnectors` | the connection is an AssemblyConnector from a required to a provided port |
| `#delegation` | `#dlg` | `delegationConnectors` | the connection is a DelegationConnector (component port to part port) |
| `#artifact` | `#art` | `artifacts` | the element is a UML3 Artifact |
| `#node` |  | `nodes` | the element is a UML3 Node, a computational resource |
| `#device` | `#dev` | `devices` | the element is a UML3 Device, a physical computational resource |
| `#executionEnvironment` | `#execEnv` | `executionEnvironments` | the element is a UML3 ExecutionEnvironment, a software host |
| `#communicationPath` | `#commPath` | `communicationPaths` | the connection is a UML3 CommunicationPath between nodes |
| `#deploy` | `#dpl` | `deployments` | the allocation is a UML3 Deployment of an artifact to the node that hosts it |
| `#manifest` | `#mfst` | `manifestations` | the allocation is a UML3 Manifestation of a component in an artifact |
| `#provided` | `#prv` | `providedPorts` | the port offers its contract to others (UML provided interface / lollipop) |
| `#required` | `#req` | `requiredPorts` | the port needs its contract from others (UML required interface / socket) |
| `#layer` |  | (plain metadata) | Plain metadata that marks a package (or component) as an architectural layer |
| `#boundary` | `#bnd` | `boundaryElements` | a hexagonal or clean-architecture boundary element (adapter, port, gateway) |

## UML3Data

| Keyword | Terse id | Base | Meaning |
|---|---|---|---|
| `#entity` | `#ent` | `entities` | the item is a UML3 Entity (a definition specializes Entity, a usage subsets entities) |
| `#aggregateRoot` | `#aggRoot` | `aggregateRoots` | the item is the AggregateRoot of a domain-driven design aggregate |
| `#valueObject` | `#valObj` | `valueObjects` | the attribute def or attribute is a ValueObject; not valid on items |
| `#relationship` | `#rel` | `relationships` | the connection is an entity Relationship whose end multiplicities give the cardinality |
| `#table` |  | `tables` | the item is a relational Table, which needs a #primaryKey column (check_rules.py R01) |
| `#dbView` | `#dbv` | `databaseViews` | the item is a DatabaseView and should set queryText (check_rules.py R11) |
| `#column` | `#col` | `columns` | the attribute is a column of its table and subsets columns |
| `#database` | `#db` | `databases` | the part is a deployed Database that contains tables |
| `#primaryKey` | `#pk` | `primaryKeyFeatures` | the attribute or ref item is the primary key of its entity or table, or part of it; several #primaryKey features form a composite key |
| `#foreignKey` | `#fk` | `foreignKeyFeatures` | the feature refers to another entity or table |
| `#unique` | `#unq` | `uniqueFeatures` | no two instances of the owner have the same value of the feature (a UNIQUE constraint) |
| `#indexed` | `#idx` | `indexedFeatures` | the database keeps a single-column index on the feature |
| `#transient` | `#trns` | `transientFeatures` | the attribute is not persisted; its value is derived, computed or held only at runtime |
| `#audited` | `#aud` | `auditedElements` | changes to the element are recorded in an audit trail |
| `#mapsTo` |  | (plain metadata) | the dependency links a physical element (the client) to the logical element (the supplier) that it implements, such as a table to its entity |

## UML3Messaging

| Keyword | Terse id | Base | Meaning |
|---|---|---|---|
| `#idempotent` | `#idem` | `idempotentElements` | handling the same message more than once has the same effect as handling it once |
| `#messageType` | `#msg` | `messageTypes` | the item is a UML3 MessageType (a definition specializes MessageType, a usage subsets messageTypes) |
| `#command` | `#cmd` | `commands` | the item is a Command, a request for one handler to act |
| `#domainEvent` | `#evt` | `domainEvents` | the item is a DomainEvent, a fact that has happened |
| `#queryMessage` | `#qmsg` | `queryMessages` | the item is a QueryMessage, a request for information |
| `#reply` |  | `replies` | the item is a Reply to a command or query message |
| `#documentMessage` | `#docMsg` | `documentMessages` | the item is a DocumentMessage, data transferred without intent |
| `#channel` | `#chan` | `channels` | the part is a UML3 Channel |
| `#topic` |  | `topics` | the part is a publish/subscribe Topic |
| `#queue` |  | `queues` | the part is a point-to-point Queue |
| `#broker` | `#brk` | `messageBrokers` | the part is a MessageBroker that hosts channels |
| `#publishes` | `#pub` | `publishingFlows` | the flow carries messages from a producer into a channel, usually a #topic |
| `#subscribes` | `#sbs` | `subscribingFlows` | the flow carries messages from a channel, usually a #topic, to a consumer that subscribed to it |
| `#sends` |  | `sendingFlows` | the flow carries a command, query or request from its sender to a #queue or directly to its handler (point-to-point or request/reply) |
| `#handles` | `#hdl` | `handlingFlows` | the flow is on the handler's side of a point-to-point or request/reply exchange: it delivers a sent message from a queue to its handler, or returns the handler's Reply to the requester |

## UML3IDL

| Keyword | Terse id | Base | Meaning |
|---|---|---|---|
| `#union` |  | `idlUnions` | an IDL Union (a definition specializes Union, a usage subsets idlUnions) |
| `#raises` |  | (DependencyKind) | the client operation can raise the supplier #exceptionType |

74 keywords, 59 with a terse id.
