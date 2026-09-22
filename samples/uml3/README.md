# UML3 sample: an online store, in both implementations

The same model twice:

* [`OnlineStore.uml3`](OnlineStore.uml3) — in the **UML3** notation, the language that extends and subsets KerML
  (UML3-IMPL-002). It is a **sketch for discussion**: UML3 has no grammar yet (issue I-39 in
  [DESIGN.md](../../docs/DESIGN.md)), and no tool reads this file.
* [`OnlineStore.sysml`](OnlineStore.sysml) — in **SysUML**, the implementation that exists. The validator, the
  checkers and CATIA Magic read this one, so it is the authority for what the model means.

The point of the pair is the correspondence: every construct on the left has exactly one counterpart on the right,
which is what a lossless round trip between the implementations needs (UML3-IMPL-005), and both denote the same
concept of the domain metamodel (`DogFoodUML3/DomainMetamodel`, UML3-IMPL-012).

## Construct by construct

| UML3 notation | Domain metamodel concept | SysUML |
|---|---|---|
| `package X { ... }` | `Package` | `package X { ... }` |
| `import UML3::*;` | (the standard library) | `private import UML3Core::*;` and its siblings |
| `class Customer` | `Class` | `#classType item def Customer` |
| `class PreferredCustomer extends Customer` | `Generalization` | `#classType item def PreferredCustomer :> Customer` |
| `datatype Money` | `DataType` | `#dataType attribute def Money` |
| `attribute amount : Decimal { precision 19; scale 4; }` | `Attribute`, `ScalarType` with `FacetValue` | `attribute amount : Decimal { @Facets { precision = 19; scale = 4; } }` |
| `enumeration OrderStatus { created; ... }` | `Enumeration`, `EnumerationLiteral` | `enum def OrderStatus { enum created { ... } ... }` |
| `exception OrderAlreadyShipped` | `ExceptionType` | `#exceptionType item def OrderAlreadyShipped` |
| `id attribute customerId : Uuid` | `Attribute.isIdentifying` | `#id attribute customerId : Uuid` |
| `unique attribute email : EmailAddress` | (uniqueness of a data attribute) | `#unique attribute email : EmailAddress` |
| `operation changeEmail(in newEmail : EmailAddress)` | `Operation`, `Parameter` | `#operation action changeEmail { in newEmail : EmailAddress; }` |
| `query operation isPaid() : Boolean` | `Operation.isQuery` | `#query calc isPaid { return paid : Boolean; }` |
| `operation cancel(...) raises OrderAlreadyShipped` | `Operation.raisedExceptions` | `#raises dependency from Order::cancel to OrderAlreadyShipped;` |
| `interface PaymentService` | `InterfaceType` | `#interfaceType item def PaymentService` with `abstract` operations |
| `class CardPayment realizes PaymentService` | `InterfaceRealization` | `#classType item def CardPayment :> PaymentService` plus `action :>> authorize;` per operation |
| `association Places { navigable end customer : Customer [1]; ... }` | `Association`, `AssociationEnd.isNavigable` | `#association connection def Places { end [1] ref customer : Customer { @navigable; } ... }` |
| `composition Contains { ... }` | `AssociationEnd.aggregation = compositeAggregation` | `#composition connection def Contains { ... }`, and the composite feature `item lines : OrderLine[1..*]` |
| `dependency CardPayment ..> Order uses;` | `Dependency.kind = usage` | `#uses dependency from CardPayment to Order;` |

## What the sketch is trying out

* **UML words as keywords.** `class`, `datatype`, `enumeration`, `interface`, `exception`, `association`,
  `composition`: a UML user writes UML terms and never sees the SysML v2 constructs underneath. In SysUML the same
  concepts are semantic keywords on SysML v2 definitions, which is why each pair in the table is a renaming rather
  than a translation (UML3-IMPL-004).
* **Modifiers in front of the feature.** `id`, `unique`, `query` read as UML property and operation modifiers; SysUML
  writes them as keywords (`#id`, `#unique`, `#query`).
* **Two forms for relationships.** A keyword form with named ends, and the shortcut form that the file shows as a
  comment (`Customer [1] -- [0..*] Order as Places;`, `Order [1] *-- [1..*] OrderLine as Contains;`,
  `CardPayment ..> Order uses;`). The request for proposals asks for both.
* **Nothing that SysML v2 cannot carry.** Every construct maps to plain SysML v2, so a UML3 model stays usable in
  SysML v2 tools through its SysUML form (UML3-IMPL-006).

## Open points this sample raises

1. **Realization syntax.** `realizes` is a keyword here, while SysUML expresses realization as specialization plus
   redefinition of every abstract operation. UML3 has to decide whether `realizes` is its own relationship or
   shorthand for that specialization.
2. **Raised exceptions.** UML3 writes `raises` on the operation; SysUML has no place on the operation for it and uses
   a `#raises` dependency. The round trip has to put it back on the operation.
3. **Query operations.** SysUML uses `#query calc` (a calculation) and `#operation action` (an action); UML3 writes
   both as `operation`, with `query` as a modifier. The transformation picks the construct from the modifier.
4. **Composition twice.** The sample states composition both as a composite feature (`item lines`) and as a
   `#composition` connection, as example 01 does. UML3 should say which one its `composition` keyword produces.
5. **The standard library.** `import UML3::*;` assumes one library package; the SysUML side imports several
   (`UML3Core`, `UML3Types`, `UML3Data`, `UML3IDL`). The UML3 library layout is still open (UML3-IMPL-003).
