package UML3LanguageRequirements {
	doc
	/*
	LANG: requirements on bringing existing and new languages and formats into UML3 and back again: import and
	export of interface definitions (OMG IDL), UML 2.x models, database catalogs and source code, reverse
	engineering, the published mapping for each language, and the coexistence of hand-written code with the model.

	Contents:
	- OMG IDL: idlImport, idlExport, idlRoundTrip, idlFullConformance.
	- Mapping rules: languageMappingDocuments, languageDetailPreservation, unsupportedConstructReporting,
	  importSourceInformation.
	- Other languages and formats: umlXmiInterchange, databaseCatalogReverseEngineering,
	  legacySourceReverseEngineering, modernSourceReverseEngineering.
	- Code and model together: handWrittenCodeSynchronization, mixedLanguageSystems.
	- UseCases: how integration engineers, architects, developers and data modelers bring existing assets into UML3.
	- Realization: the library elements that realize the done requirements.
	References: docs/REQUIREMENTS-GUIDE.md; docs/IDL-MAPPING.md; docs/UML2-to-UML3-Traceability.md.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;
	private import UML3IDL::*;

	requirement <'UML3-LANG-001'> idlImport {
		doc
		/*
		UML3 shall import OMG IDL 4.2 files into UML3 models, covering modules, structures with inheritance,
		typedefs, sequences, arrays, bounded strings, fixed-point types, enumerations, unions, exceptions,
		interfaces with attributes and operations (including oneway operations and raises clauses), constants and
		annotations. The imported model shall load and validate without errors in a SysML v2 tool.
		Verified by: tools/run_tests.py suite idl-import; tools/run_tests.py suite idl-corpus; tools/run_tests.py suite cameo; E08.
		*/
		@Rationale { text = "IDL defines the data and service contracts of DDS, CORBA and many embedded and defense systems; importing it makes those contracts part of the UML3 design instead of a separate artifact."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-LANG-002'> idlExport {
		doc
		/*
		UML3 shall export the elements of a UML3 model that follow the IDL mapping to OMG IDL 4.2 text in a
		canonical form, with fully qualified type names and resolved constant values, and the export shall read
		the model without changing it.
		Verified by: tools/run_tests.py suite cameo; E09.
		*/
		@Rationale { text = "Middleware, IDL compilers and partner organizations consume IDL files, so a model that is the source of the contracts has to produce them."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-LANG-003'> idlRoundTrip {
		doc
		/*
		Importing an IDL file and exporting the resulting model shall reproduce the canonical form of the
		original file, with no declaration, annotation, bound, enumerator value or constant value lost or changed.
		Verified by: tools/run_tests.py suite cameo; tools/run_tests.py suite idl-corpus.
		*/
		@Rationale { text = "Only a lossless round trip allows the model, rather than the IDL text, to become the maintained source of an interface contract."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-LANG-004'> idlFullConformance {
		doc
		/*
		The IDL importer shall support the complete OMG IDL 4.2 grammar, including value types, maps, bitsets and
		bitmasks, types declared inside interfaces, anonymous nested sequences, components and homes, and
		specifications split over included files. It shall reject each file that the specification defines as
		invalid.
		*/
		@Rationale { text = "Real IDL uses these constructs: in the 701-file test corpus 160 files use a construct outside the current import scope, and 25 of 39 files known to be invalid are still accepted."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-LANG-005'> languageMappingDocuments {
		doc
		/*
		For each language or format that UML3 imports or exports, UML3 shall publish a mapping that gives, for
		each construct of the language, its UML3 representation and the metadata that preserves its details, and
		that lists the unsupported constructs with the message an importer reports for each of them.
		Verified by: docs/IDL-MAPPING.md; tools/run_tests.py suite idl-import.
		*/
		@Rationale { text = "Users and tool vendors need to know how a language is represented before they trust an import, and a second tool can only produce the same model from the same file when the mapping is published."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-LANG-006'> languageDetailPreservation {
		doc
		/*
		Details of a source language that have no UML3 or SysML v2 concept shall be kept as metadata on the
		imported elements, so that an export can reproduce them. For OMG IDL these include sequence bounds, array
		dimensions, member identifiers, union discriminators and case labels, enumerator values, interface
		qualifiers, oneway operations, return parameters and all other annotations. An importer shall report each
		detail it cannot keep with a message that names the detail and its source line.
		Verified by: library/UML3IDL.sysml; tools/run_tests.py suite idl-import; tools/run_tests.py suite cameo.
		*/
		@Rationale { text = "Without such metadata every import loses information and every export has to guess it; metadata keeps the model language-neutral while nothing of the source is lost."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-LANG-007'> unsupportedConstructReporting {
		doc
		/*
		An importer shall report each construct of the source language that it does not support with a message
		that names the construct and its source line. It shall not fail with an internal error on any input,
		valid or invalid.
		Verified by: tools/run_tests.py suite idl-import; tools/run_tests.py suite idl-corpus.
		*/
		@Rationale { text = "A silent partial import produces a model that looks complete but is not; a named message tells the user exactly what to change or what is lost."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-LANG-008'> importSourceInformation {
		doc
		/*
		Every imported or reverse-engineered element shall record the source file and the location it came from,
		and the documentation comments of its source declaration shall become the documentation of the element.
		*/
		@Rationale { text = "Reviewers and maintainers have to find the source of an imported element, and imported models have to meet the same documentation rules as models written directly in UML3."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-LANG-009'> umlXmiInterchange {
		doc
		/*
		UML3 shall import UML 2.x models from XMI, including applied stereotypes and their tagged values, into
		UML3 models according to the UML 2.x to UML3 traceability map. It shall export UML3 models to UML 2.x XMI
		and report each element whose UML3 realization is partial or not adopted.
		*/
		@Rationale { text = "Organizations hold large UML 2.x models in XMI; UML3 can replace UML only if those models migrate without being redrawn and exchange with UML tools continues during the transition."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-LANG-010'> databaseCatalogReverseEngineering {
		doc
		/*
		UML3 shall reverse-engineer the catalog of a relational database, with its schemas, tables, columns with
		SQL types, nullability and defaults, primary, foreign and unique keys with referential actions, indexes
		and views, into a UML3Data physical model.
		*/
		@Rationale { text = "Most software extends an existing database whose catalog is the only complete and current description of the data, and modeling it again by hand is slow and error-prone."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-LANG-011'> legacySourceReverseEngineering {
		doc
		/*
		UML3 shall reverse-engineer the structure of source code in COBOL, C, C++ and Java into UML3 models: types
		and records with their attributes and operations, modules or packages, inheritance and the dependencies
		between them.
		*/
		@Rationale { text = "Modernizing legacy systems starts with understanding their structure, which is often documented only in the code itself."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-LANG-012'> modernSourceReverseEngineering {
		doc
		/*
		UML3 shall reverse-engineer the structure of source code in Rust, Go, Kotlin and TypeScript into UML3
		models, including traits and interfaces, modules and the dependencies between them.
		*/
		@Rationale { text = "New services are written in these languages; which of them UML3 supports first, and whether compiler front ends or language servers read the code, is still to be decided."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-LANG-013'> handWrittenCodeSynchronization {
		doc
		/*
		When code generated from a UML3 model has been changed by hand, UML3 tooling shall report the differences
		between the code and the model per model element, and shall let the user update the model from the code
		or the code from the model without losing hand-written implementation.
		*/
		@Rationale { text = "Teams change signatures and types in code under time pressure; detecting and reconciling that drift keeps the model usable as documentation and as the source of further generation."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-LANG-014'> mixedLanguageSystems {
		doc
		/*
		A UML3 model shall state the implementation language of each component, artifact or package, and a
		contract modeled once, such as an interface, a message type or a data type, shall be usable by components
		implemented in different languages, each checked and generated with the mapping of its own language.
		*/
		@Rationale { text = "Most systems combine languages, for example C++ devices, Java services and TypeScript clients that share IDL or JSON contracts, and the model is where those shared contracts meet."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	package UseCases {
		doc
		/*
		UseCases: how practitioners bring existing languages, models, databases and code into UML3.

		Contents:
		- ImportInterfaceDefinitions: an integration engineer moves IDL contracts into the model and exports them.
		- MigrateUML2ModelsFromXMI: an architect migrates UML 2.x models, a tool vendor implements the migration.
		- ReverseEngineerExistingSystem: a developer and a data modeler recover and maintain the design of a system.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def ImportInterfaceDefinitions {
			doc
			/*
			An integration engineer imports the IDL contracts of an existing DDS or CORBA system into a UML3 model,
			reviews what could not be imported, maintains the contracts in the model and exports canonical IDL for
			the middleware tool chain.
			*/
			subject environment : UML3Environment;
			actor integrator : IntegrationEngineer;
			objective {
				doc /* The contracts live in the model without loss, and the exported IDL is accepted by the existing tool chain. */
			}
		}

		use case def MigrateUML2ModelsFromXMI {
			doc
			/*
			A software architect migrates the UML 2.x models of an existing system into UML3 through XMI, using the
			UML 2.x to UML3 traceability map, and a tool vendor implements that migration.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			actor vendor : ToolVendor;
			objective {
				doc /* The existing design is available in UML3 without redrawing, and each concept UML3 represents differently is reported. */
			}
		}

		use case def ReverseEngineerExistingSystem {
			doc
			/*
			A software developer and a data modeler recover the design of an existing system from its source code
			and its database catalog, and keep the recovered model and the hand-written code aligned as the system
			evolves.
			*/
			subject environment : UML3Environment;
			actor developer : SoftwareDeveloper;
			actor dataModeler : DataModeler;
			objective {
				doc /* An accurate, documented model of the existing system that stays aligned with its code and database. */
			}
		}

		#traces dependency from ImportInterfaceDefinitions to 'UML3-LANG-001', 'UML3-LANG-002', 'UML3-LANG-003', 'UML3-LANG-004',
			'UML3-LANG-005', 'UML3-LANG-006', 'UML3-LANG-007', 'UML3-LANG-008', UML3GenerationRequirements::'UML3-GEN-003';
		#traces dependency from MigrateUML2ModelsFromXMI to 'UML3-LANG-005', 'UML3-LANG-007', 'UML3-LANG-008', 'UML3-LANG-009',
			UML3CoreRequirements::'UML3-CORE-005';
		#traces dependency from ReverseEngineerExistingSystem to 'UML3-LANG-005', 'UML3-LANG-007', 'UML3-LANG-008', 'UML3-LANG-010',
			'UML3-LANG-011', 'UML3-LANG-012', 'UML3-LANG-013', 'UML3-LANG-014';
	}

	package Realization {
		doc
		/*
		Realization: the library elements that realize the done LANG requirements.

		Contents:
		- #realizes dependencies from UML3IDL elements to LANG requirements. The importer and exporter
		  (tools/idl, tools/cameo-scripts) implement the mapping with these elements.
		*/
		#realizes dependency from UML3IDL::IdlFile to 'UML3-LANG-001';
		#realizes dependency from UML3IDL::UnionMetadata to 'UML3-LANG-001';
		#realizes dependency from UML3IDL::Discriminator to 'UML3-LANG-001';
		#realizes dependency from UML3IDL::Case to 'UML3-LANG-001';
		#realizes dependency from UML3IDL::RaisesDependency to 'UML3-LANG-001';
		#realizes dependency from UML3IDL::IdlOneway to 'UML3-LANG-001';
		#realizes dependency from UML3IDL::IdlReturn to 'UML3-LANG-002';
		#realizes dependency from UML3IDL::IdlMemberId to 'UML3-LANG-002';
		#realizes dependency from UML3IDL::IdlAnnotation to 'UML3-LANG-002';
		#realizes dependency from UML3IDL to 'UML3-LANG-005';
		#realizes dependency from UML3IDL to 'UML3-LANG-007';
	}
}
