package UML3CoreRequirements {
	doc
	/*
	CORE: requirements on the foundation of SysUML as a language: how it is defined on SysML v2, how its concepts
	get semantics, how it relates to UML 2.x and how it is documented, versioned and exchanged.

	Contents:
	- Definition: sysmlConformance, libraryDefinition, semanticKeywords, nativeSysMLReuse.
	- Traceability and documentation: umlTraceability, elementDocumentation, verifiableReferences.
	- Correct use: keywordApplicability, namingConventions.
	- Tooling and evolution: toolIndependence, conformancePoints, libraryVersioning, modelInterchange.
	- Self-modeling: selfModeling, the effort modeled in SysUML (DogFoodUML3).
	- Realization: the library elements that realize the done requirements.
	References: docs/REQUIREMENTS-GUIDE.md; docs/DESIGN.md.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;

	requirement <'UML3-CORE-001'> sysmlConformance {
		doc
		/*
		A SysUML model shall be a conforming SysML v2 textual model. SysUML shall not require any extension of the
		KerML or SysML v2 abstract syntax, concrete syntax or semantics.
		Verified by: tools/run_tests.py suite syntax-positive; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Any conforming SysML v2 tool can then load, query, validate and exchange SysUML models, and SysUML evolves with SysML v2 instead of forking it."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-CORE-002'> libraryDefinition {
		doc
		/*
		Every SysUML concept that SysML v2 does not provide natively shall be defined as an element of a SysUML model
		library, together with the metadata needed to apply it.
		Verified by: library/UML3Core.sysml; tools/run_tests.py suite names-positive.
		*/
		@Rationale { text = "Libraries are the extension mechanism SysML v2 standardizes; they keep the definition of SysUML itself a model that can be reviewed, versioned and checked."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-CORE-003'> semanticKeywords {
		doc
		/*
		Applying a SysUML keyword to an element shall give the element the semantics of the corresponding library
		element through implied specialization, not only a label. Tools shall be able to query all elements of a
		SysUML concept through the library base.
		Verified by: E01; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "A stereotype that is only a label cannot be reasoned about; implied specialization makes a keyworded class really a Class, with inherited features and constraints."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-CORE-004'> nativeSysMLReuse {
		doc
		/*
		Where SysML v2 or KerML already provides a concept (for example actions, states, use cases, individuals and
		requirements), SysUML shall use the native construct as-is, without an additional SysUML keyword or label, and
		shall document the correspondence to UML 2.x.
		Verified by: traceability/uml2-to-uml3.json; tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "SysUML is not a copy of UML 2.x: duplicating native constructs would create two ways to say the same thing and weaken interoperation with SysML v2 models (decision 2026-09-16)."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-CORE-005'> umlTraceability {
		doc
		/*
		Every UML 2.5.1 concept shall be traced to its SysUML realization with a status (native, native with SysUML
		additions, SysUML, partial, not adopted) and, for partial and not adopted concepts, a rationale.
		Verified by: tools/run_tests.py suite traceability.
		*/
		@Rationale { text = "UML practitioners and tool vendors need to know how each UML concept is expressed in SysUML, and what was deliberately not adopted and why."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-CORE-006'> elementDocumentation {
		doc
		/*
		Every element of the SysUML libraries shall own documentation that describes the element, explains how to use
		it where applicable, gives the rationale for design choices and cites its references. Every package shall
		summarize its contents. Explanations that concern several elements shall be comments about those elements.
		Documentation shall not contain decoration that wastes space on diagrams.
		Verified by: tools/run_tests.py suite docs.
		*/
		@Rationale { text = "SysUML is intended as a standard: users read elements in tools and on diagrams, not source files, so documentation has to be part of the model."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-CORE-007'> verifiableReferences {
		doc
		/*
		References in SysUML documentation to KerML and SysML v2 clauses, UML 2.5.1 concepts, SysUML elements and
		experiments shall be verifiable automatically.
		Verified by: tools/run_tests.py suite docs.
		*/
		@Rationale { text = "Wrong clause numbers in a standard mislead readers; checking them keeps references correct as the specifications evolve."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-CORE-008'> keywordApplicability {
		doc
		/*
		SysUML shall define, for each keyword, the kinds of elements it may be applied to, and SysUML tooling shall
		report a keyword applied to an element whose type family is disjoint from the keyword's base (for example a
		class keyword on a value type, or a structure keyword on a behavior).
		Verified by: tools/run_tests.py suite negative; tools/run_tests.py suite cameo-probes; E05.
		*/
		@Rationale { text = "CATIA Magic builds implied specializations for misapplied keywords without an error, and its validation engine misses some cases, so SysUML cannot rely on tools to catch them."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-CORE-009'> namingConventions {
		doc
		/*
		SysUML keywords shall be lowerCamelCase short names. A keyword whose UML name is a reserved SysML v2 or KerML
		word shall use a Type or verb suffix. SysUML shall not use reserved words as element names.
		Verified by: tools/run_tests.py suite negative; tools/run_tests.py suite syntax-positive.
		*/
		@Rationale { text = "Predictable names make keywords easy to find and avoid parse errors: reserved words such as interface, message, class and datatype cannot be names."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-CORE-010'> toolIndependence {
		doc
		/*
		The SysUML libraries shall load and validate without errors in at least two independent SysML v2
		implementations, one of which shall be a reference or open implementation. Deviations of an implementation
		from KerML or SysML v2 that affect SysUML shall be documented with a workaround.
		Verified by: tools/run_tests.py suite cameo; tools/run_tests.py suite syntax-positive; E02; E03.
		*/
		@Rationale { text = "A standard defined against one tool inherits that tool's deviations; two implementations expose them (for example CATIA Magic applying only the first semantic keyword)."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-CORE-011'> conformancePoints {
		doc
		/*
		SysUML shall define conformance points (for example core, data, messaging, architecture, generation) that an
		implementation can claim independently, and the tests that demonstrate each claim.
		*/
		@Rationale { text = "Tools differ in scope; KerML and SysML v2 define conformance points so that partial implementations can still conform."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-CORE-012'> libraryVersioning {
		doc
		/*
		Each SysUML library shall identify its version, and SysUML shall define compatibility rules so that a model
		states which library versions it conforms to and a tool can detect incompatible combinations.
		*/
		@Rationale { text = "Models outlive tool and library releases; without versions a library change silently changes the meaning of existing models."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-CORE-013'> modelInterchange {
		doc
		/*
		SysUML models shall be exchangeable without loss through the standard SysML v2 interchange formats and the
		Systems Modeling API and Services, including applied keywords, valued metadata and documentation.
		*/
		@Rationale { text = "Model-based software engineering spans several tools; SysUML content must survive every exchange that SysML v2 content survives."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-CORE-014'> selfModeling {
		doc
		/*
		The effort that builds SysUML and UML3 shall itself be modeled in SysUML: the external requirements it
		answers, its two implementations and the transformation between them, its tools, its verification pipeline,
		and the traces from its elements to the requirements they satisfy. The model shall be kept in the folder
		DogFoodUML3 and checked by the same suites as the libraries and examples.
		Verified by: tools/run_tests.py suite dogfood; DogFoodUML3/00-DogFoodUML3.sysml.
		*/
		@Rationale { text = "A modeling language is only credible if its makers use it on a real software system; the effort's own toolchain is such a system, so modeling it exercises SysUML beyond the examples, adds real content to the regression corpus that UML3 will need, and keeps the effort's structure reviewable. The model exists and passes the local suites; loading it in CATIA Magic is still to come."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	package UseCases {
		doc
		/*
		UseCases: how tool vendors and language maintainers use the SysUML core.

		Contents:
		- SupportUML3InTool: a tool vendor adds SysUML support to a SysML v2 tool.
		- EvolveUML3Language: a language maintainer changes a SysUML library without breaking users.
		- ModelTheEffortInSysUML: the maintainers model their own effort, requirements to tools, in SysUML.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def SupportUML3InTool {
			doc
			/*
			A tool vendor makes SysUML available in a SysML v2 tool: the libraries load, keywords give elements their
			SysUML semantics, misapplied keywords are reported, and models exchange with other tools.
			*/
			subject environment : UML3Environment;
			actor vendor : ToolVendor;
			objective {
				doc /* The tool can claim SysUML conformance for the conformance points it implements. */
			}
		}

		use case def EvolveUML3Language {
			doc
			/*
			A language maintainer adds or changes a SysUML concept: defines it in a library with documentation and
			references, traces it to UML 2.x, checks naming and applicability, and publishes a new library version.
			*/
			subject environment : UML3Environment;
			actor maintainer : LanguageMaintainer;
			objective {
				doc /* The change is documented, verified and versioned, and existing models keep their meaning. */
			}
		}

		use case def ModelTheEffortInSysUML {
			doc
			/*
			A language maintainer and a software architect model the SysUML and UML3 effort in SysUML: the external
			requirements it answers, the two implementations, the transformation between them, the tools and the
			verification pipeline, and which requirements each element satisfies. They check the model with the
			same suites as the libraries and use it to plan and review the work.
			*/
			subject environment : UML3Environment;
			actor maintainer : LanguageMaintainer;
			actor architect : SoftwareArchitect;
			objective {
				doc /* The effort's structure and progress are read from a SysUML model that the SysUML checks validate, not from prose. */
			}
		}

		#traces dependency from SupportUML3InTool to 'UML3-CORE-001', 'UML3-CORE-002', 'UML3-CORE-003', 'UML3-CORE-008',
			'UML3-CORE-010', 'UML3-CORE-011', 'UML3-CORE-013';
		#traces dependency from EvolveUML3Language to 'UML3-CORE-002', 'UML3-CORE-004', 'UML3-CORE-005', 'UML3-CORE-006',
			'UML3-CORE-007', 'UML3-CORE-009', 'UML3-CORE-012';
		#traces dependency from ModelTheEffortInSysUML to 'UML3-CORE-014',
			UML3RequirementModelingRequirements::'UML3-REQ-010', UML3ImplementationRequirements::'UML3-IMPL-008';
	}

	package Realization {
		doc
		/*
		Realization: the library elements that realize the done CORE requirements.

		Contents:
		- #realizes dependencies from SysUML library elements to CORE requirements.
		*/
		#realizes dependency from UML3Core to 'UML3-CORE-001';
		#realizes dependency from UML3Core to 'UML3-CORE-002';
		#realizes dependency from UML3Core::classType to 'UML3-CORE-003';
		#realizes dependency from UML3Core::SemanticKeywordDesign to 'UML3-CORE-003';
		#realizes dependency from UML3Core to 'UML3-CORE-004';
		#realizes dependency from UML3Core to 'UML3-CORE-005';
		#realizes dependency from UML3Core to 'UML3-CORE-006';
		#realizes dependency from UML3Core to 'UML3-CORE-007';
		#realizes dependency from UML3Core::MarkerKeywordDesign to 'UML3-CORE-008';
		#realizes dependency from UML3Core to 'UML3-CORE-009';
		#realizes dependency from UML3Core to 'UML3-CORE-010';
	}
}
