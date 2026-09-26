# What belongs in the UML3 language, and what belongs in a library

A specification is judged partly on what it refused to add. This file states the rule UML3 uses to decide
whether a concept becomes a language construct, a library element, or metadata, so that every such decision can
be defended individually rather than by taste. It exists because the coverage maps
([languages](UML3-to-Languages.md), [DDL](UML3-to-DDL.md), [infrastructure](UML3-to-Infrastructure.md)) find
gaps faster than a language should grow.

## The precedent

SysML v2 is the model to follow, and its own clause structure says so
(`formal/26-03-02`, Part 1):

| Clause | Pages | Content |
|---|---|---|
| 7 Language Description | 15–162 | how the language works |
| 8 Metamodel | 163–460 | the abstract syntax — the language proper |
| 9 Model Libraries | 461–691 | Systems, Metadata, Analysis, Cause and Effect, Requirement Derivation, Geometry, Quantities and Units |

A third of the specification is library. Quantities, units, geometry, analysis cases and causal chains are not
language constructs; they are models written *in* the language and shipped *with* it. KerML is smaller still,
and SysML v2 is itself largely an extension of KerML by library and metadata rather than by new syntax. UML3
extends and subsets KerML the same way, so the same division applies.

## The rule

> A concept becomes a **language construct** only if it cannot be expressed as a library element plus metadata
> **without losing meaning that a conforming tool must act on**. Everything else is a library element, and a
> marker on an existing element is metadata.

The test is not "is it important" — units are important and are a library. The test is whether a tool has to
*do something differently* that it cannot learn from a library definition.

### The decision procedure

Ask, in order. The first "yes" decides the layer.

1. **Does it change what is well-formed, in a way a library constraint cannot express?**
   → **language**. A tool must reject models it would otherwise accept, and a library cannot make a tool reject
   what the grammar permits.
2. **Does it change the type system — what may type what?**
   → **language**. Metadata annotates an element; it cannot extend the rules for which types conform to which.
   This is the criterion that puts most functional-programming features in the language (see below).
3. **Does it need concrete syntax a reader would expect to write?**
   → **language**, if the notation cannot be a keyword in front of an existing construct. UML3's whole approach
   is that `#classType item def C` reads as a class, so a great deal fits here without new grammar.
4. **Is it a named thing with structure, specific to a domain?**
   → **library**. A table, a broker, a node, an IDL union: definitions in a package that models import.
5. **Is it a marker or a value on something that already exists?**
   → **metadata**. `#primaryKey`, `#transient`, `@Facets`. This is where most vendor and platform detail goes.
6. Otherwise → **out of scope**, and the coverage map says so with a reason.

### Why this keeps the language small

Steps 4 and 5 absorb nearly everything the coverage maps ask for. Vendor-specific SQL, cloud services, network
devices and framework conventions are all domain structure or markers; none of them changes well-formedness or
typing. They can be added in libraries indefinitely without the language growing at all, which is the point: a
language that grows to meet every platform is a language nobody can implement.

## Applying it

Every row of every coverage map carries a `layer` saying where its fix belongs, and the checker requires one for
any row that is not COVERED. That is the accounting: a gap without a layer is an unanswered design question, and
the maps make the count visible.

### Where functional programming lands, and why it is not all library

Functional programming is the clearest case where the rule sends work into the **language**, and it is worth
stating plainly because it cuts against the general preference for libraries.

* **Function types** — a feature whose type is a function from A to B. Step 2: the type system must admit it.
  A metadata keyword cannot make a type conform where it did not before. KerML has functions and expressions,
  so it may already be possible; that is recorded as a question to settle, not an assumption.
* **Algebraic data types and pattern matching** — step 1 and step 3: exhaustiveness is a well-formedness rule
  over a closed set of cases, and a `match` is notation a reader expects to write.
* **Generic constraints** (Java bounds, Rust trait bounds, C++ concepts) — step 2. The coverage map records
  these as PARTIAL today: parameters exist, constraints on them do not.
* **Purity and immutability** — these are steps 5, not 1 or 2: `#query` already marks an operation that changes
  nothing, and an immutable attribute is a marker. They stay metadata.

So "functional programming belongs in the core" is true of its *type-system* features and false of its
*markers*, and the rule says which is which rather than leaving it to preference.

## What a reviewer should be able to check

1. Every concept in a coverage map that is not COVERED names the layer that would fix it.
2. Every language-layer decision cites the step of the procedure that forced it.
3. The count of language-layer gaps stays small and is argued; the count of library-layer gaps may be large and
   is a work list, not a language problem.
4. A requirement exists for each language-layer decision, with its rationale, in `requirements/`.

Point 4 is not yet satisfied for the rows this file introduces; the requirements are to be written from the
language-layer gaps once the maps are complete.
