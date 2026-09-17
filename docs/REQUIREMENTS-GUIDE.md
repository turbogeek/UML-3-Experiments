# UML3 requirements and use cases: authoring guide

UML3 states its requirements the way the SysML v2 requirements were stated for KerML and SysML v2: numbered
"shall" statements grouped by area, each with rationale, priority and verification. They are written in SysML v2
itself (`requirements/*.sysml`), so they can be traced, queried and checked. `tools/check_requirements.py` validates
them and generates [UML3-Requirements.md](UML3-Requirements.md).

## Areas

| Code | Package | Scope (what belongs here) | Not here |
|---|---|---|---|
| CORE | UML3CoreRequirements | Language foundation: conformance to KerML/SysML v2, library-and-metadata definition, semantic keywords, reuse of native SysML v2, UML 2.x traceability, documentation, naming, conformance levels, library versioning, interchange of UML3 models | Individual modeling constructs |
| STR | UML3StructureRequirements | Classes, interfaces and realization, attributes and operations, associations, aggregation, composition, navigability, generalization sets, templates, packages and visibility, instances | Components and deployment (ARCH), data types (DT) |
| DT | UML3DataTypeRequirements | Software primitive types, sizes and encodings, facets (ranges, lengths, precision, patterns), enumerations, collections and maps, optionality and null, temporal, binary and decimal values, units | Persistent data design (DATA) |
| BHV | UML3BehaviorRequirements | Operations and methods, activities, state machines, events and signals, exceptions, concurrency, time, executable semantics, behavior of active classes | Message schemas (MSG), test behavior (TEST) |
| EXT | UML3ExtensibilityRequirements | User keywords and profiles, valued metadata (tagged values), user libraries, applicability rules, domain-specific extensions built on UML3 | |
| VER | UML3VerificationRequirements | Verifying models: well-formedness and design rules, consistency, completeness, requirement-to-verification traceability, verification of UML3 tooling and conformance tests | Testing the software itself (TEST) |
| VAL | UML3ValidationRequirements | Validating that a design meets stakeholder needs: use cases, stakeholder concerns, acceptance criteria, scenario walkthroughs and simulation, reviews | |
| VIEW | UML3ViewRequirements | Diagrams as views (class, package, component, deployment, sequence, state, activity, use case, ER, message schema), tables and matrices, viewpoints, layout independence | Documents and reports (RPT) |
| ARCH | UML3ArchitectureRequirements | Components, services, ports and contracts, connectors, layers and boundaries, architecture styles and decisions, deployment nodes, artifacts and environments, technology tags | Pipelines and operations (OPS) |
| DATA | UML3DataModelingRequirements | Conceptual, logical and physical data models, keys and constraints, relationships and cardinality, mapping between levels, schema evolution, data governance | Value types (DT), security classification rules (SEC) |
| MSG | UML3MessagingRequirements | Message and event schemas, headers, topics and queues, producers and consumers, interaction sequences, quality of service, serialization formats, API contracts (sync and async) | |
| SEC | UML3SecurityRequirements | Threat modeling, trust boundaries, data classification and privacy, authentication and authorization, secrets, secure communication, compliance traceability | |
| TEST | UML3TestingRequirements | Modeling software tests: test cases, suites, fixtures and test data, test doubles, coverage of requirements and design elements, test generation, results | Verification of the model itself (VER) |
| OPS | UML3DevOpsRequirements | Build and CI/CD pipelines, environments, infrastructure as code, release and versioning, configuration, observability, operations runbooks | Deployment topology (ARCH) |
| GEN | UML3GenerationRequirements | Generation of code (Java, Rust, C++, Python, TypeScript...), schemas (SQL DDL, JSON Schema, Avro, Protobuf, IDL, OpenAPI, AsyncAPI), configuration and other artifacts; templates, round trip, regeneration safety | Documents and reports (RPT), language import (LANG) |
| RPT | UML3ReportRequirements | Generated documentation, specifications, traceability matrices, metrics and review reports, publication formats | |
| LANG | UML3LanguageRequirements | Legacy and new languages and formats: import and export (IDL, UML 2.x XMI, database catalogs, source code), reverse engineering, mapping rules per language, coexistence of hand-written and generated code | Pure generation (GEN) |
| AI | UML3AIRequirements | AI-assisted modeling (drafting, review, explanation, validation loops), modeling AI/ML systems (models, datasets, pipelines, agents, prompts), provenance and review of AI-produced model content, guardrails | |
| SYS | UML3SysMLInteropRequirements | Using UML3 inside SysML v2 system models and with other KerML-based languages: shared elements, allocation of software to hardware, shared requirements and verification, SysML v2 API and services | |

## Requirement form

```sysml
requirement <'UML3-CORE-001'> sysmlConformance {
	doc
	/*
	A UML3 model shall be a conforming SysML v2 textual model: it shall not require any extension of the KerML or
	SysML v2 abstract syntax, concrete syntax or semantics.
	Verified by: tools/run_tests.py suite syntax-positive; tools/run_tests.py suite cameo.
	*/
	@Rationale { text = "Any conforming SysML v2 tool can then load, query, validate and exchange UML3 models."; }
	@StatusInfo { status = StatusKind::done; }
	@Priority { level = PriorityKind::mandatory; }
	@VerificationMethod { kind = VerificationMethodKind::test; }
}
```

* **ID**: short name `UML3-<AREA>-<nnn>`, numbered from 001 in each area and never reused.
* **Name**: lowerCamelCase, saying what is required.
* **Statement** (the `doc`): one or more sentences, each with "shall". Say what is required, not how. The first sentence can stand alone.
* **Rationale**: `@Rationale { text = "..."; }` (ModelingMetadata). It says why the requirement exists.
* **Status**: `@StatusInfo { status = StatusKind::... }`. `done` means implemented and verified. `open` means accepted but not implemented. `tbd` means the requirement itself is still being decided. `tbc` means implemented but its verification is not complete.
* **Priority**: `@Priority { level = PriorityKind::mandatory | optional; }`, like the mandatory and optional requirements of the SysML v2 request for proposals.
* **Verification**: `@VerificationMethod { kind = VerificationMethodKind::inspect | analyze | demo | test; }` (VerificationCases).
* **Evidence**: a `done` or `tbc` requirement has a final `Verified by:` line in its doc. It names `tools/run_tests.py suite <name>` entries, repository files or experiments (`E04`). The checker verifies that each one exists.
* **Realization**: a `done` requirement is realized by at least one model element. Declare that in the area file's `Realization` package: `#realizes dependency from UML3Core::ClassMetadata to 'UML3-STR-001';`.

## Use cases

The actors (`part def`, one per role) and the use case subject `UML3Environment` are in `requirements/00-Actors.sysml` (package `UML3Actors`). Each area file has a nested package `UseCases` with the area's `use case def`s. Each use case has:
- a `doc`, a `subject` and at least one `actor`;
- an `objective` saying what the actor gets;
- `#traces` dependencies to the requirements it needs.

Every requirement should be traced by at least one use case; the checker reports untraced requirements.

## Checks (tools/check_requirements.py, suite `requirements`)

| Check | Rule |
|---|---|
| Form | Every requirement has an ID in the scheme, unique, in the area of its package; a statement with "shall"; a rationale, status, priority and verification method |
| Evidence | A `done` or `tbc` requirement has a `Verified by:` line, and every entry resolves |
| Realization | A `done` requirement has at least one `#realizes` dependency, and the client resolves |
| Use cases | Every use case has a doc, a subject, an actor and an objective, and traces at least one existing requirement |
| Coverage | A requirement that no use case traces is reported (warning) |
| Documentation | `tools/check_docs.py` rules D01-D06 apply to all files in `requirements/` |
