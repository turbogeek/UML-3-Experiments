# UML3 requirements

Generated from `requirements/*.sysml` by `tools/check_requirements.py --write`; do not edit. Rules: [REQUIREMENTS-GUIDE.md](REQUIREMENTS-GUIDE.md).

## Summary

| Area | Requirements | done | tbc | open | tbd | mandatory | optional |
|---|---|---|---|---|---|---|---|
| [CORE](#core) Core language | 13 | 9 | 1 | 2 | 1 | 12 | 1 |
| [STR](#str) Structure | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [DT](#dt) Data types | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [BHV](#bhv) Behavior | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [EXT](#ext) Extensibility | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [VER](#ver) Verification | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [VAL](#val) Validation | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [VIEW](#view) Views and diagrams | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [ARCH](#arch) Software architecture and deployment | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [DATA](#data) Data modeling | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [MSG](#msg) Messaging and interaction | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [SEC](#sec) Security | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [TEST](#test) Testing | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [OPS](#ops) DevOps | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [GEN](#gen) Generation of code and artifacts | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [RPT](#rpt) Reports and documentation | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [LANG](#lang) Legacy and new languages | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [AI](#ai) Artificial intelligence | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [SYS](#sys) SysML v2 and KerML interoperation | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| **Total** | **13** | 9 | 1 | 2 | 1 | | |

## CORE

**Core language** (`UML3CoreRequirements`)

| ID | Requirement | Priority | Status | Verification | Realized by | Use cases |
|---|---|---|---|---|---|---|
| UML3-CORE-001 | **sysmlConformance**: A UML3 model shall be a conforming SysML v2 textual model. UML3 shall not require any extension of the KerML or SysML v2 abstract syntax, concrete syntax or semantics.<br>*Rationale:* Any conforming SysML v2 tool can then load, query, validate and exchange UML3 models, and UML3 evolves with SysML v2 instead of forking it.<br>*Verified by:* tools/run_tests.py suite syntax-positive; tools/run_tests.py suite cameo | mandatory | done | test | `UML3Core` | SupportUML3InTool |
| UML3-CORE-002 | **libraryDefinition**: Every UML3 concept that SysML v2 does not provide natively shall be defined as an element of a UML3 model library, together with the metadata needed to apply it.<br>*Rationale:* Libraries are the extension mechanism SysML v2 standardizes; they keep the definition of UML3 itself a model that can be reviewed, versioned and checked.<br>*Verified by:* library/UML3Core.sysml; tools/run_tests.py suite names-positive | mandatory | done | inspect | `UML3Core` | EvolveUML3Language, SupportUML3InTool |
| UML3-CORE-003 | **semanticKeywords**: Applying a UML3 keyword to an element shall give the element the semantics of the corresponding library element through implied specialization, not only a label. Tools shall be able to query all elements of a UML3 concept through the library base.<br>*Rationale:* A stereotype that is only a label cannot be reasoned about; implied specialization makes a keyworded class really a Class, with inherited features and constraints.<br>*Verified by:* E01; tools/run_tests.py suite cameo | mandatory | done | test | `UML3Core::ClassMetadata`, `UML3Core::SemanticKeywordDesign` | SupportUML3InTool |
| UML3-CORE-004 | **nativeSysMLReuse**: Where SysML v2 or KerML already provides a concept (for example actions, states, use cases, individuals and requirements), UML3 shall use the native construct as-is, without an additional UML3 keyword or label, and shall document the correspondence to UML 2.x.<br>*Rationale:* UML3 is not a copy of UML 2.x: duplicating native constructs would create two ways to say the same thing and weaken interoperation with SysML v2 models (decision 2026-09-16).<br>*Verified by:* traceability/uml2-to-uml3.json; tools/run_tests.py suite traceability | mandatory | done | inspect | `UML3Core` | EvolveUML3Language |
| UML3-CORE-005 | **umlTraceability**: Every UML 2.5.1 concept shall be traced to its UML3 realization with a status (native, native with UML3 additions, UML3, partial, not adopted) and, for partial and not adopted concepts, a rationale.<br>*Rationale:* UML practitioners and tool vendors need to know how each UML concept is expressed in UML3, and what was deliberately not adopted and why.<br>*Verified by:* tools/run_tests.py suite traceability | mandatory | done | analyze | `UML3Core` | EvolveUML3Language |
| UML3-CORE-006 | **elementDocumentation**: Every element of the UML3 libraries shall own documentation that describes the element, explains how to use it where applicable, gives the rationale for design choices and cites its references. Every package shall summarize its contents. Explanations that concern several elements shall be comments about those elements. Documentation shall not contain decoration that wastes space on diagrams.<br>*Rationale:* UML3 is intended as a standard: users read elements in tools and on diagrams, not source files, so documentation has to be part of the model.<br>*Verified by:* tools/run_tests.py suite docs | mandatory | done | analyze | `UML3Core` | EvolveUML3Language |
| UML3-CORE-007 | **verifiableReferences**: References in UML3 documentation to KerML and SysML v2 clauses, UML 2.5.1 concepts, UML3 elements and experiments shall be verifiable automatically.<br>*Rationale:* Wrong clause numbers in a standard mislead readers; checking them keeps references correct as the specifications evolve.<br>*Verified by:* tools/run_tests.py suite docs | optional | done | test | `UML3Core` | EvolveUML3Language |
| UML3-CORE-008 | **keywordApplicability**: UML3 shall define, for each keyword, the kinds of elements it may be applied to, and UML3 tooling shall report a keyword applied to an element whose type family is disjoint from the keyword's base (for example a class keyword on a value type, or a structure keyword on a behavior).<br>*Rationale:* CATIA Magic builds implied specializations for misapplied keywords without an error, and its validation engine misses some cases, so UML3 cannot rely on tools to catch them.<br>*Verified by:* tools/run_tests.py suite negative; tools/run_tests.py suite cameo-probes; E05 | mandatory | done | test | `UML3Core::MarkerKeywordDesign` | SupportUML3InTool |
| UML3-CORE-009 | **namingConventions**: UML3 keywords shall be lowerCamelCase short names. A keyword whose UML name is a reserved SysML v2 or KerML word shall use a Type or verb suffix. UML3 shall not use reserved words as element names.<br>*Rationale:* Predictable names make keywords easy to find and avoid parse errors: reserved words such as interface, message, class and datatype cannot be names.<br>*Verified by:* tools/run_tests.py suite negative; tools/run_tests.py suite syntax-positive | mandatory | done | test | `UML3Core` | EvolveUML3Language |
| UML3-CORE-010 | **toolIndependence**: The UML3 libraries shall load and validate without errors in at least two independent SysML v2 implementations, one of which shall be a reference or open implementation. Deviations of an implementation from KerML or SysML v2 that affect UML3 shall be documented with a workaround.<br>*Rationale:* A standard defined against one tool inherits that tool's deviations; two implementations expose them (for example CATIA Magic applying only the first semantic keyword).<br>*Verified by:* tools/run_tests.py suite cameo; tools/run_tests.py suite syntax-positive; E02; E03 | mandatory | tbc | test | `UML3Core` | SupportUML3InTool |
| UML3-CORE-011 | **conformancePoints**: UML3 shall define conformance points (for example core, data, messaging, architecture, generation) that an implementation can claim independently, and the tests that demonstrate each claim.<br>*Rationale:* Tools differ in scope; KerML and SysML v2 define conformance points so that partial implementations can still conform. | mandatory | open | inspect |  | SupportUML3InTool |
| UML3-CORE-012 | **libraryVersioning**: Each UML3 library shall identify its version, and UML3 shall define compatibility rules so that a model states which library versions it conforms to and a tool can detect incompatible combinations.<br>*Rationale:* Models outlive tool and library releases; without versions a library change silently changes the meaning of existing models. | mandatory | open | inspect |  | EvolveUML3Language |
| UML3-CORE-013 | **modelInterchange**: UML3 models shall be exchangeable without loss through the standard SysML v2 interchange formats and the Systems Modeling API and Services, including applied keywords, valued metadata and documentation.<br>*Rationale:* Model-based software engineering spans several tools; UML3 content must survive every exchange that SysML v2 content survives. | mandatory | tbd | test |  | SupportUML3InTool |

## Use cases

| Use case | Actors | Objective | Requirements |
|---|---|---|---|
| **EvolveUML3Language** (UseCases)<br>A language maintainer adds or changes a UML3 concept: defines it in a library with documentation and | maintainer | The change is documented, verified and versioned, and existing models keep their meaning. | UML3-CORE-002, UML3-CORE-004, UML3-CORE-005, UML3-CORE-006, UML3-CORE-007, UML3-CORE-009, UML3-CORE-012 |
| **SupportUML3InTool** (UseCases)<br>A tool vendor makes UML3 available in a SysML v2 tool: the libraries load, keywords give elements their | vendor | The tool can claim UML3 conformance for the conformance points it implements. | UML3-CORE-001, UML3-CORE-002, UML3-CORE-003, UML3-CORE-008, UML3-CORE-010, UML3-CORE-011, UML3-CORE-013 |
