package DogFoodImplementations {
	doc
	/*
	DogFoodImplementations: the two implementations of UML-level software modeling and the transformation that
	is to connect them (UML3ImplementationRequirements).

	Contents:
	- ModelFile, ModelLanguage: a model as a file, and the notation it is written in.
	- TransformationReport: the result of comparing a model with its round-tripped copy.
	- ModelTransformation, TransformationPort: the contract of the transformation and the port that carries it.
	- SysMLLibrary, GrammarFile: the artifacts the implementations consist of.
	- SysUMLImplementation, UML3Implementation, RoundTripTransformation: the three components.
	- ModelingLanguages: the subsystem that holds them.
	- KeywordCorrespondence: one row of the table that pairs a UML3 keyword with its SysUML keyword.
	References: requirements/22-Implementations.sysml; docs/UML3-Keywords.md.
	*/
	private import ScalarValues::*;
	private import UML3Core::*;
	private import UML3Components::*;

	enum def ModelLanguage {
		doc /* The notation a model file is written in. */
		enum sysmlV2 {
			doc /* SysML v2 textual notation, used by SysUML models. */
		}
		enum uml3 {
			doc /* The UML3 textual notation, an extension of the KerML textual notation (planned). */
		}
	}

	#classType item def ModelFile {
		doc /* A model kept in one file of the repository. */
		attribute path : String {
			doc /* The path of the file, relative to the repository root. */
		}
		attribute notation : ModelLanguage {
			doc /* The notation the file is written in. */
		}
	}

	#dataType attribute def TransformationReport {
		doc /* The result of comparing a model with the copy that went to the other implementation and back. */
		attribute identical : Boolean {
			doc /* True when the copy equals the original element for element. */
		}
		attribute differenceCount : Integer {
			doc /* The number of elements that differ; zero when identical. */
		}
	}

	#interfaceType item def ModelTransformation {
		doc /* The contract of the transformation between SysUML and UML3 models (UML3-IMPL-005). */
		abstract #operation action toUML3 {
			doc /* Transforms a SysUML model into the equivalent UML3 model. */
			in source : ModelFile;
			out result : ModelFile;
		}
		abstract #operation action toSysUML {
			doc /* Transforms a UML3 model into the equivalent SysUML model. */
			in source : ModelFile;
			out result : ModelFile;
		}
		abstract #operation action compare {
			doc /* Compares an original model with its round-tripped copy. */
			in original : ModelFile;
			in roundTripped : ModelFile;
			out report : TransformationReport;
		}
	}

	port def TransformationPort :> ServicePort {
		doc /* The port for the ModelTransformation contract. */
		ref item :>> contract : ModelTransformation;
	}

	#artifact item def SysMLLibrary {
		doc /* A SysUML library file, such as library/UML3Core.sysml. */
	}

	#artifact item def GrammarFile {
		doc /* The machine-readable grammar of the UML3 textual notation (planned; KEBNF, Xtext or ANTLR). */
	}

	#component part def SysUMLImplementation {
		doc
		/*
		SysUML: UML-level software modeling in SysML v2 with SysML v2 libraries and semantic keywords, the
		implementation in use.
		*/
		@Technology { technologyName = "SysML v2"; technologyVersion = "2.0"; }
		item libraries : SysMLLibrary[1..*] {
			doc /* The SysUML libraries: UML3Core, UML3Types, UML3Components, UML3Messaging, UML3Data, UML3IDL, UML3Views, UML3DiagramKinds. */
		}
	}

	#component part def UML3Implementation {
		doc
		/*
		UML3: a language that extends and subsets KerML with its own textual syntax, grammar and standard library;
		the next step (UML3-IMPL-002), not built yet.
		*/
		@Technology { technologyName = "KerML"; technologyVersion = "1.0"; }
		item grammar : GrammarFile {
			doc /* The grammar of the UML3 textual notation. */
		}
		item libraries : SysMLLibrary[1..*] {
			doc /* The UML3 standard library, derived from the KerML semantic library and aligned with SysUML (UML3-IMPL-003). */
		}
	}

	#service part def RoundTripTransformation {
		doc /* The lossless transformation between SysUML and UML3 models (UML3-IMPL-005), not built yet. */
		#provided port transformation : TransformationPort {
			doc /* Provides ModelTransformation to the tools that move models between the implementations. */
		}
	}

	#subsystem part def ModelingLanguages {
		doc /* The two implementations and the transformation between them. */
		part sysUML : SysUMLImplementation {
			doc /* The implementation in use. */
		}
		part uml3 : UML3Implementation {
			doc /* The next step. */
		}
		part transformation : RoundTripTransformation {
			doc /* Connects the two implementations. */
		}
	}

	#classType item def KeywordCorrespondence {
		doc
		/*
		One row of the table that pairs each UML3 keyword with the SysUML semantic keyword implying the same
		specialization, such as class with #classType (UML3-IMPL-004).
		*/
		attribute uml3Keyword : String {
			doc /* The keyword of the UML3 textual notation. */
		}
		attribute sysUMLKeyword : String {
			doc /* The SysUML semantic keyword, as written after '#'. */
		}
		attribute concept : String {
			doc /* The library definition both keywords imply, such as UML3Core::Class. */
		}
	}
}
