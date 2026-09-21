package UML3ImplementationRequirements {
	doc
	/*
	IMPL: requirements on the two implementations of UML-level software modeling and on keeping them compatible.
	SysUML models software in SysML v2 with SysML v2 libraries and semantic keywords; it is the implementation in
	use, and every requirement of the other areas is a SysUML requirement unless it says otherwise. UML3 extends
	and subsets KerML as SysML v2 does, with its own textual syntax, grammar and standard library; it is the next
	step, to be built once SysUML is refined and has a regression corpus deep enough to prove a lossless round
	trip between the two. Graphics follow the SysML v2 graphical notation as it evolves.

	Contents:
	- The two implementations: twoImplementations, uml3Language, uml3Behaviors.
	- Compatibility: conceptAlignment, keywordCorrespondence, losslessRoundTrip, notationOnlyConstructs.
	- Verification and order of work: roundTripRegression, capabilityRegressionCorpus, pilotImplementation.
	- Graphics: graphicalNotation.
	- UseCases: modeling software in SysML v2 today, moving models between the implementations, defining UML3, and
	  presenting UML concepts in SysML v2 tools.
	References: docs/REQUIREMENTS-GUIDE.md; docs/DESIGN.md; KerML 7.3.2.3; SysML 7.27.3; KerML 9.2.16.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;

	requirement <'UML3-IMPL-001'> twoImplementations {
		doc
		/*
		UML-level software modeling shall have two implementations of one set of concepts: SysUML, which models
		software in SysML v2 models with SysML v2 libraries and semantic keywords and no extension of SysML v2, and
		UML3, a language that extends and subsets KerML with its own textual syntax, grammar and standard library.
		*/
		@Rationale { text = "Only SysML v2 exists in tools today, and software has to be modeled next to the systems that contain it now; a KerML-based UML is where the language should go. Naming the two keeps a requirement on one from being read as a promise about the other. SysUML exists; UML3 does not yet."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
		@AppliesTo { implementations = (ImplementationKind::sysUML, ImplementationKind::uml3); }
	}

	requirement <'UML3-IMPL-002'> uml3Language {
		doc
		/*
		UML3 shall extend and subset KerML as SysML v2 does: a textual notation in UML terms (class, interface,
		datatype, operation, association and the other UML3 concepts), with keywords and shortcut symbols for
		inheritance, association, realization, composition, aggregation and dependency, defined in a machine-readable
		grammar (KEBNF, Xtext or ANTLR), and a standard library derived from the KerML semantic library.
		*/
		@Rationale { text = "A language of its own lets software engineers write UML in UML terms without learning the SysML v2 constructs underneath, which is what occasional UML users need. It is the next step: the grammar and the transformation are to be built after SysUML is refined and the capability regression corpus of UML3-IMPL-008 exists (DESIGN issue I-39)."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
		@AppliesTo { implementations = ImplementationKind::uml3; }
	}

	requirement <'UML3-IMPL-003'> conceptAlignment {
		doc
		/*
		UML3 and SysUML shall define the same concepts with the same specialization hierarchy: for each SysUML base
		definition, such as Class, ActiveClass, InterfaceType, DataType, Signal, Component, Entity and MessageType,
		UML3 shall define one counterpart with the same name, supertypes and features. The hierarchies shall be
		aligned by specialization, of the KerML semantic library in UML3 and of the SysML v2 library in SysUML, or by
		metadata where specialization cannot align them, and neither shall require a change to SysML v2.
		*/
		@Rationale { text = "A lossless round trip is only possible if every concept has exactly one counterpart in the same place of the hierarchy. SysUML's Class specializes the SysML v2 Item, a KerML Object, so a UML3 Class that specializes KerML Object directly sits at the same point of the KerML hierarchy."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
		@AppliesTo { implementations = (ImplementationKind::sysUML, ImplementationKind::uml3); }
	}

	requirement <'UML3-IMPL-004'> keywordCorrespondence {
		doc
		/*
		Each keyword of the UML3 textual notation shall correspond to exactly one SysUML semantic keyword that
		implies the same specialization, as the UML3 keyword class corresponds to the SysUML keyword #classType, so
		that a model written in either implementation has one meaning in both.
		*/
		@Rationale { text = "The two implementations realize the same hierarchy by different means: a UML3 keyword implies a library specialization as the SysML v2 keyword part def implies Parts::Part, and a SysUML semantic keyword implies it through its baseType (KerML 9.2.16). One-to-one correspondence is what makes the transformation a renaming rather than a translation."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
		@AppliesTo { implementations = (ImplementationKind::sysUML, ImplementationKind::uml3); }
	}

	requirement <'UML3-IMPL-005'> losslessRoundTrip {
		doc
		/*
		A transformation between UML3 models and SysUML models shall be complete and lossless in both directions:
		every construct of either implementation shall have a counterpart in the other, and transforming a model to
		the other implementation and back shall reproduce the original model element for element, including names,
		short names, keywords, specializations, features, multiplicities, values, documentation, metadata and element
		identifiers.
		*/
		@Rationale { text = "Users must be able to adopt UML3 without abandoning SysUML models and to use most of UML3 inside SysML v2 tools; that only works if nothing is lost in either direction, so compatibility is required at 100 percent, not approximately."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
		@AppliesTo { implementations = (ImplementationKind::sysUML, ImplementationKind::uml3); }
	}

	requirement <'UML3-IMPL-006'> notationOnlyConstructs {
		doc
		/*
		A UML3 construct that exists only in the textual notation, such as a relationship shortcut symbol, shall be
		represented in SysUML by the construct it abbreviates, together with metadata wherever that construct alone
		would lose information the round trip needs, so that all of a UML3 model can be used in SysML v2 through
		SysUML.
		*/
		@Rationale { text = "The notation of UML3 will be richer than SysML v2 syntax, but its meaning is the shared hierarchy; expanding shortcuts keeps SysUML plain SysML v2, and metadata records the choices of form that a faithful round trip must restore."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
		@AppliesTo { implementations = (ImplementationKind::sysUML, ImplementationKind::uml3); }
	}

	requirement <'UML3-IMPL-007'> roundTripRegression {
		doc
		/*
		The round trip shall be verified by an automated regression that transforms every SysUML library, example,
		test and DogFoodUML3 model to UML3 and back, and every UML3 test model to SysUML and back, and reports every
		difference between the original and the result.
		*/
		@Rationale { text = "Lossless is a claim about all models, so only a regression over everything the project has can support it, and it has to run on every change of either implementation."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
		@AppliesTo { implementations = (ImplementationKind::sysUML, ImplementationKind::uml3); }
	}

	requirement <'UML3-IMPL-008'> capabilityRegressionCorpus {
		doc
		/*
		Before the UML3 grammar and the transformation are built, SysUML shall have a capability regression suite
		that covers each capability stated by the requirements with positive and negative cases, locally and in
		CATIA Magic, and that serves as the reference corpus of the round trip.
		*/
		@Rationale { text = "A round trip can only be proven against models that exercise every capability; the current suites check the libraries, examples and experiments, not every requirement. Building the corpus first also refines SysUML before its concepts are copied into UML3."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
		@AppliesTo { implementations = ImplementationKind::sysUML; }
	}

	requirement <'UML3-IMPL-009'> pilotImplementation {
		doc
		/*
		SysUML shall load, validate and pass its checks in the OMG SysML v2 pilot implementation, and the UML3
		grammar and library shall be built and released with the development and release process of that pilot
		implementation.
		*/
		@Rationale { text = "The pilot implementation is the reference for KerML and SysML v2 semantics and is where a standard language is built and published; today SysUML is verified in CATIA Magic, with an ANTLR validator and with its own checkers, but not in the pilot implementation."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
		@AppliesTo { implementations = (ImplementationKind::sysUML, ImplementationKind::uml3); }
	}

	requirement <'UML3-IMPL-010'> graphicalNotation {
		doc
		/*
		SysUML shall present UML concepts as an extension of the SysML v2 graphical notation, following that notation
		as its standard evolves and as SysML v2 tools implement it, and UML3 shall use the same presentation. Whether
		and where UML 2.5.1 symbols are retained within that extension is still to be decided.
		*/
		@Rationale { text = "SysML v2 tools will implement the SysML v2 graphical standard and little else, so a UML notation outside it would not be drawn; an extension within it is what users will actually see. Retaining UML 2.5.1 symbols eases the move for current UML users, but only where the SysML v2 notation allows an extension."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
		@AppliesTo { implementations = (ImplementationKind::sysUML, ImplementationKind::uml3); }
	}

	requirement <'UML3-IMPL-011'> uml3Behaviors {
		doc
		/*
		UML3 shall provide activities, state machines, interactions and use cases through the SysML v2 action,
		state, occurrence and use case constructs and their library definitions, instead of defining counterparts
		of its own, so that a behavior has one meaning in UML3, SysUML and SysML v2. Whether UML3 includes these
		constructs in its own notation or uses them in models that mix UML3 and SysML v2 is still to be decided.
		*/
		@Rationale { text = "SysUML already models behaviors with the native SysML v2 constructs (UML3-CORE-004, UML3-BHV-001), so UML3 behaviors of its own would need a second semantics and would break the lossless round trip of UML3-IMPL-005. UML3 extends KerML rather than SysML v2, so how it reaches the SysML v2 behavior constructs has to be decided."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
		@AppliesTo { implementations = ImplementationKind::uml3; }
	}

	package UseCases {
		doc
		/*
		UseCases: how architects, maintainers and tool vendors use the two implementations.

		Contents:
		- ModelSoftwareInSysMLv2: an architect models software with SysUML in a SysML v2 model today.
		- MoveModelsBetweenImplementations: a maintainer transforms a model between SysUML and UML3 and back.
		- DefineUML3Language: a maintainer defines the UML3 grammar and library, aligned with SysUML.
		- PresentUMLInSysMLv2Tools: a tool vendor draws SysUML and UML3 models with the SysML v2 notation.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def ModelSoftwareInSysMLv2 {
			doc
			/*
			A software architect models the software of a product with SysUML inside the SysML v2 model of the
			system, in any SysML v2 tool, with software elements next to the system elements they run on and the
			requirements they satisfy.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			objective {
				doc /* Software is modeled at UML level in the same SysML v2 model as its system, without extending SysML v2. */
			}
		}

		use case def MoveModelsBetweenImplementations {
			doc
			/*
			A language maintainer transforms a model between SysUML and UML3 in either direction, uses it in the other
			implementation, and transforms it back without losing anything.
			*/
			subject environment : UML3Environment;
			actor maintainer : LanguageMaintainer;
			objective {
				doc /* A model returns from the other implementation unchanged, element for element. */
			}
		}

		use case def DefineUML3Language {
			doc
			/*
			A language maintainer defines the UML3 textual notation, grammar and library once SysUML is refined and
			its capability regression corpus exists, keeping every UML3 concept and keyword aligned with its SysUML
			counterpart, and builds UML3 with the pilot implementation's process.
			*/
			subject environment : UML3Environment;
			actor maintainer : LanguageMaintainer;
			objective {
				doc /* UML3 lets software engineers write UML in UML terms while staying aligned with SysUML. */
			}
		}

		use case def PresentUMLInSysMLv2Tools {
			doc
			/*
			A tool vendor presents SysUML and UML3 models with the SysML v2 graphical notation, extended where the
			notation allows it for UML concepts.
			*/
			subject environment : UML3Environment;
			actor vendor : ToolVendor;
			objective {
				doc /* UML concepts are drawn by the SysML v2 tools that users actually have. */
			}
		}

		#traces dependency from ModelSoftwareInSysMLv2 to 'UML3-IMPL-001', UML3CoreRequirements::'UML3-CORE-001',
			UML3SysMLInteropRequirements::'UML3-SYS-001';
		#traces dependency from MoveModelsBetweenImplementations to 'UML3-IMPL-003', 'UML3-IMPL-004', 'UML3-IMPL-005',
			'UML3-IMPL-006', 'UML3-IMPL-007';
		#traces dependency from DefineUML3Language to 'UML3-IMPL-002', 'UML3-IMPL-003', 'UML3-IMPL-008',
			'UML3-IMPL-009', 'UML3-IMPL-011';
		#traces dependency from PresentUMLInSysMLv2Tools to 'UML3-IMPL-010';
	}
}
