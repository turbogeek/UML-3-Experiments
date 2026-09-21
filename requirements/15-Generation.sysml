package UML3GenerationRequirements {
	doc
	/*
	GEN: requirements on generating implementation artifacts from SysUML models: source code in several
	programming languages, database schemas, message schemas and API contracts, and the properties that make
	generated artifacts trustworthy (published mappings, compilable output, diagnostics, and deterministic,
	traceable regeneration that keeps hand-written code).

	Contents:
	- Input and mappings: generationFromModel, languageMappingSpecifications, customizableMappings.
	- Code: javaAndRustGeneration, classAndComponentGeneration, additionalLanguageTargets,
	  compilableGeneratedCode, documentationInGeneratedCode.
	- Schemas and contracts: databaseSchemaGeneration, interfaceContractGeneration.
	- Safe regeneration: unmappableConstructDiagnostics, deterministicRegeneration, generatedArtifactTraceability,
	  handWrittenCodePreservation.
	- UseCases: how developers, data modelers, integration engineers, architects and tool vendors generate artifacts.
	- Realization: the library elements that realize the done requirements.
	References: docs/REQUIREMENTS-GUIDE.md; docs/IDL-CODEGEN.md; docs/IDL-MAPPING.md.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;
	private import UML3IDL::*;

	requirement <'UML3-GEN-001'> generationFromModel {
		doc
		/*
		SysUML generators shall take a SysUML model as their input, read from the textual notation or through the API
		of the modeling tool that holds the model. Generation shall not require the design to be restated first in
		an interface definition language or in source code.
		Verified by: tools/run_tests.py suite cameo; tools/run_tests.py suite idl-codegen; tools/idl/UML3IdlCore.groovy.
		*/
		@Rationale { text = "In model-based software engineering the model is the source of truth; if generators need IDL files or code as their input, the model and the artifacts drift apart."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-GEN-002'> languageMappingSpecifications {
		doc
		/*
		For each generation target, SysUML shall publish a mapping specification that gives, for each supported
		model construct, the generated construct and the naming rules, and that lists the constructs the target
		does not map or maps with loss of information. Where a standard language mapping exists, such as the OMG
		IDL4 to Java Language Mapping 1.0, the SysUML mapping shall conform to it and shall document each deviation
		with its reason.
		Verified by: docs/IDL-CODEGEN.md; docs/IDL-MAPPING.md; tools/run_tests.py suite idl-codegen.
		*/
		@Rationale { text = "A generator without a published mapping can be neither reviewed nor reimplemented by another vendor, and conforming to existing OMG mappings keeps generated code compatible with middleware built on them."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-GEN-003'> javaAndRustGeneration {
		doc
		/*
		SysUML shall generate Java and Rust source code for structured data types, type aliases, sequences and
		arrays, enumerations, discriminated unions, exceptions, interfaces with attributes and operations, and
		constants.
		Verified by: tools/run_tests.py suite idl-codegen; tools/run_tests.py suite idl-corpus.
		*/
		@Rationale { text = "Java is a main enterprise language with a standard OMG mapping and Rust is the main memory-safe systems language; together they implement the data and interface contracts shared by services and devices."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-GEN-004'> classAndComponentGeneration {
		doc
		/*
		SysUML shall generate source code for the structural concepts beyond interface contracts: classes and
		active classes, realizations of interfaces, attributes and operations with their visibility, associations
		with navigability and multiplicity, generalization sets, templates, entities and value objects,
		components and services with their provided and required ports, and message types.
		*/
		@Rationale { text = "Interface contracts are a small part of a software design; without class, association and component generation the object-oriented design in SysUML still has to be coded by hand."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-GEN-005'> additionalLanguageTargets {
		doc
		/*
		SysUML shall define code generation for C++, C#, Python and TypeScript, following an OMG language mapping
		where one exists for the target language.
		*/
		@Rationale { text = "These languages dominate embedded, desktop, data and web software; each additional mapping widens where SysUML models can drive the implementation."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-GEN-006'> compilableGeneratedCode {
		doc
		/*
		Source code generated from any model that a generator accepts shall compile without errors with the
		reference compiler of the target language. A generator that cannot produce compilable code for a
		construct shall refuse the construct instead of emitting code for it.
		Verified by: tools/run_tests.py suite idl-codegen; tools/run_tests.py suite idl-corpus.
		*/
		@Rationale { text = "Code that does not compile moves generator defects to every user; compiling the generated code in the tests, over fixtures and third-party corpora, keeps those defects in the generator where they can be fixed once."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-GEN-007'> unmappableConstructDiagnostics {
		doc
		/*
		A code generator shall refuse each model construct that it cannot map to the target language with an
		error that names the construct and where it occurs. It shall not leave the construct out of the
		generated code silently, and it shall not fail with an internal error.
		Verified by: tools/run_tests.py suite idl-codegen; tools/run_tests.py suite idl-corpus.
		*/
		@Rationale { text = "Silently missing code surfaces late as runtime defects; a named refusal lets the modeler change the model or choose another mapping before the code is used."; }
		@StatusInfo { status = StatusKind::done; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-GEN-008'> deterministicRegeneration {
		doc
		/*
		Generating twice from an unchanged model with the same generator version and options shall produce
		identical artifacts. Generated output shall not depend on timestamps, random values, hash iteration order
		or the order in which a tool happens to return model elements.
		Verified by: tools/run_tests.py suite idl-corpus; tools/run_tests.py suite idl-import; tools/idl/UML3IdlCodegen.groovy.
		*/
		@Rationale { text = "Regeneration that changes unchanged artifacts floods version control with noise, hides the real changes and defeats build caching and reproducible builds."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-GEN-009'> generatedArtifactTraceability {
		doc
		/*
		Each generated artifact shall identify the model elements it was generated from, by qualified name or
		element identifier, and the generator, mapping and version that produced it. It shall be possible to
		find the artifacts affected by a model change and the model element of a generated declaration.
		*/
		@Rationale { text = "Impact analysis, code review and safety or security certification need to follow a model element to the code it produced and back again."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-GEN-010'> handWrittenCodePreservation {
		doc
		/*
		Regeneration shall never overwrite or delete hand-written code. SysUML generation shall keep generated and
		hand-written code apart, either by a generation gap (generated base types that hand-written types extend)
		or by protected regions whose content survives regeneration.
		*/
		@Rationale { text = "Generated code is almost always completed by hand; if regeneration destroys that work, developers stop regenerating and the model goes out of date."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-GEN-011'> customizableMappings {
		doc
		/*
		A generation mapping shall declare its options and their defaults. A model shall be able to select
		mapping options, and to override the generated form of individual concepts with user templates, through
		metadata recorded in the model and without changes to the generator.
		*/
		@Rationale { text = "Organizations have coding conventions and frameworks, standard mappings already define options such as the naming and integer width options of the IDL4 to Java mapping, and recording the choices in the model keeps generation reproducible."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-GEN-012'> documentationInGeneratedCode {
		doc
		/*
		The documentation of a model element shall be carried into the artifacts generated from it, in the
		documentation form of the target (for example Javadoc, Rust documentation comments, Python docstrings,
		SQL comments or schema descriptions) and attached to the declaration generated from the element.
		*/
		@Rationale { text = "Developers read the generated API rather than the model, so documentation that stops at the model boundary is lost exactly where it is needed."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-GEN-013'> databaseSchemaGeneration {
		doc
		/*
		SysUML shall generate SQL data definition statements from UML3Data physical models: databases, tables,
		columns with their SQL types and defaults, primary, foreign and unique keys with referential actions,
		indexes and views. The generated statements shall be accepted by the target database engine.
		*/
		@Rationale { text = "Relational designs are among the most used UML models; generating the schema from the table and column elements keeps the database consistent with its design."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-GEN-014'> interfaceContractGeneration {
		doc
		/*
		SysUML shall generate JSON Schema, Avro and Protocol Buffers schemas for message types and data types
		according to their serialization format, OpenAPI documents for request-reply service contracts, and
		AsyncAPI documents for channels with their message types and quality of service. Each generated document
		shall be valid according to the specification of its format.
		*/
		@Rationale { text = "Services and event streams are integrated through these contract formats, which schema registries and API gateways consume; deriving all of them from one model keeps producers and consumers consistent."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	package UseCases {
		doc
		/*
		UseCases: how practitioners generate implementation artifacts from SysUML models.

		Contents:
		- GenerateImplementationCode: a software developer generates, completes and regenerates code.
		- PublishSchemasAndContracts: a data modeler and an integration engineer generate schemas and contracts.
		- AdaptGenerationToConventions: a tool vendor implements a mapping and an architect tailors it.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def GenerateImplementationCode {
			doc
			/*
			A software developer generates source code for the data types, interfaces, classes and components of a
			SysUML model, compiles it, completes it by hand and regenerates it after the model changes.
			*/
			subject environment : UML3Environment;
			actor developer : SoftwareDeveloper;
			objective {
				doc /* The code compiles, follows the published mapping, keeps the hand-written parts and traces back to the model. */
			}
		}

		use case def PublishSchemasAndContracts {
			doc
			/*
			A data modeler generates the database schema from the physical data model, and an integration engineer
			generates the message schemas, API contracts and IDL files that other teams and middleware consume.
			*/
			subject environment : UML3Environment;
			actor dataModeler : DataModeler;
			actor integrator : IntegrationEngineer;
			objective {
				doc /* Databases, schema registries, gateways and middleware receive valid schemas that match the model. */
			}
		}

		use case def AdaptGenerationToConventions {
			doc
			/*
			A tool vendor implements a SysUML generator from the published mappings, and a software architect selects
			the mapping options and templates that match the conventions of the project.
			*/
			subject environment : UML3Environment;
			actor vendor : ToolVendor;
			actor architect : SoftwareArchitect;
			objective {
				doc /* Generated code follows the project conventions, and another conforming generator gives the same result. */
			}
		}

		#traces dependency from GenerateImplementationCode to 'UML3-GEN-001', 'UML3-GEN-002', 'UML3-GEN-003', 'UML3-GEN-004',
			'UML3-GEN-005', 'UML3-GEN-006', 'UML3-GEN-007', 'UML3-GEN-008', 'UML3-GEN-009', 'UML3-GEN-010', 'UML3-GEN-012';
		#traces dependency from PublishSchemasAndContracts to 'UML3-GEN-001', 'UML3-GEN-008', 'UML3-GEN-009', 'UML3-GEN-012',
			'UML3-GEN-013', 'UML3-GEN-014', UML3LanguageRequirements::'UML3-LANG-002';
		#traces dependency from AdaptGenerationToConventions to 'UML3-GEN-002', 'UML3-GEN-005', 'UML3-GEN-006', 'UML3-GEN-008',
			'UML3-GEN-011', UML3CoreRequirements::'UML3-CORE-011';
	}

	package Realization {
		doc
		/*
		Realization: the library elements that realize the done GEN requirements.

		Contents:
		- #realizes dependencies from SysUML library elements to GEN requirements. The Java and Rust generators
		  (tools/idl) implement the mapping over the UML3Core keywords and the UML3IDL metadata named here.
		*/
		#realizes dependency from UML3IDL to 'UML3-GEN-002';
		#realizes dependency from UML3Core::dataType to 'UML3-GEN-003';
		#realizes dependency from UML3Core::interfaceType to 'UML3-GEN-003';
		#realizes dependency from UML3Core::exceptionType to 'UML3-GEN-003';
		#realizes dependency from UML3Core::operation to 'UML3-GEN-003';
		#realizes dependency from UML3IDL::union to 'UML3-GEN-003';
		#realizes dependency from UML3IDL::IdlSequence to 'UML3-GEN-003';
		#realizes dependency from UML3IDL::IdlArray to 'UML3-GEN-003';
		#realizes dependency from UML3IDL to 'UML3-GEN-006';
		#realizes dependency from UML3IDL to 'UML3-GEN-007';
	}
}
