package UML3RequirementModelingRequirements {
	doc
	/*
	REQ: requirements on stating the requirements of a software system inside a UML3 model, with the native
	SysML v2 requirement constructs: requirement definitions and usages with typed subjects, measurable
	constraints, requirement kinds and parameters, decomposition, derivation, refinement, satisfaction by design
	elements, allocation, verification objectives, requirement metadata and priority, requirement views and
	coverage queries, and interchange with requirement tools.
	UML3 adds as little as possible here: a UML3 model states requirements exactly as a SysML v2 model does, so
	that software, systems and test engineers share one requirement language. Validating requirements with
	stakeholders is in UML3ValidationRequirements (VAL), checking the model itself in
	UML3VerificationRequirements (VER), and requirements shared with a system model in
	UML3SysMLInteropRequirements (SYS). Patterns build on these constructs (UML3PatternRequirements, PAT).

	Contents:
	- Stating requirements: nativeRequirementModeling, designElementSubjects, softwareRequirementKinds,
	  qualityRequirementKinds, measurableConditions, parameterizedRequirements, requirementDecomposition.
	- Relating requirements: requirementDerivation, requirementRefinement, satisfactionBinding,
	  allocationToDesign, verificationObjectives, verificationMethodMetadata.
	- Requirement metadata: nativeRequirementMetadata, requirementPriority.
	- Views and queries: requirementViews, requirementCoverageQueries, designDecisionRequirements.
	- Interchange: requirementInterchange.
	- UseCases: how product owners, architects, test and systems engineers work with software requirements.
	References: docs/REQUIREMENTS-GUIDE.md; SysML 7.21; SysML 7.24; SysML 7.25; SysML 7.27.
	*/

	private import ModelingMetadata::*;
	private import VerificationCases::*;
	private import UML3Requirements::*;
	private import UML3Core::*;

	requirement <'UML3-REQ-001'> nativeRequirementModeling {
		doc
		/*
		A UML3 model shall state the requirements of a software system with the native SysML v2 requirement
		definitions and usages, including their subject, actors, stakeholders, assumed and required constraints
		and nested requirements. UML3 shall add no keyword, metaclass or library definition that a requirement
		needs in order to be stated.
		Verified by: tools/run_tests.py suite requirements; requirements/01-Core.sysml; tools/run_tests.py suite cameo-patterns.
		*/
		@Rationale { text = "Software, systems and test engineers then share one requirement language, and every SysML v2 tool can check, trace and report the requirements of a UML3 model. The UML3 requirements are themselves such a model, and E22 showed CATIA Magic evaluating native requirement definitions satisfied by UML3 design elements; the UML3 requirements themselves are not yet loaded into CATIA Magic, so verification is to be completed."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-REQ-002'> designElementSubjects {
		doc
		/*
		The subject of a software requirement shall be typed by the UML3 definition that the requirement
		constrains, for example a #component, #service, #interfaceType, #messageType or #entity definition, so
		that the requirement applies to each design element that satisfies it and a tool can evaluate it for that
		element.
		*/
		@Rationale { text = "A requirement with an untyped subject cannot be checked against the design. With a typed subject, satisfying a requirement is a typed binding that a tool can check and a query can follow."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-REQ-003'> softwareRequirementKinds {
		doc
		/*
		Functional, interface, performance and design-constraint requirements of software shall specialize the
		SysML v2 library definitions FunctionalRequirementCheck, InterfaceRequirementCheck,
		PerformanceRequirementCheck and DesignConstraintCheck, so that the kind of a requirement is a
		specialization that queries and views can select rather than a naming convention.
		*/
		@Rationale { text = "The library kinds exist in SysML v2 already; using them keeps UML3 requirements compatible with system requirements and lets a view list all interface requirements without parsing names."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-REQ-004'> qualityRequirementKinds {
		doc
		/*
		UML3 shall provide, in a library and without new keywords, requirement definitions for the product
		quality characteristics of ISO/IEC 25010, such as performance efficiency, reliability, security and
		maintainability, each specializing RequirementCheck or one of its library kinds.
		*/
		@Rationale { text = "Quality requirements are most of what distinguishes one software architecture from another, and a shared vocabulary makes them comparable across models; which edition of ISO/IEC 25010 to follow and how deep to model it is still open."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-REQ-005'> measurableConditions {
		doc
		/*
		A requirement whose satisfaction can be computed shall state its condition as a required constraint over
		typed attributes of its subject, using quantities with units where the property is a physical quantity
		such as a duration, a data rate or a size, and shall state the conditions it relies on as assumed
		constraints, for example a response time of at most 200 ms assuming at most 1000 requests per second.
		*/
		@Rationale { text = "A requirement stated only in prose cannot be evaluated by a tool; a constraint over typed attributes can be checked against an analysis or a test result, and the assumption records the conditions under which the check is valid."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-REQ-006'> parameterizedRequirements {
		doc
		/*
		A requirement definition shall be reusable with parameters: its attributes, such as a threshold or a
		limit, shall be redefined with values by each requirement usage, so that a catalog requirement such as a
		latency budget is stated once and applied to many subjects with different values.
		*/
		@Rationale { text = "Software systems repeat the same kinds of requirements for many services; stating each one from scratch invites inconsistent wording and makes the family impossible to query."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-REQ-007'> requirementDecomposition {
		doc
		/*
		A requirement shall be decomposable into nested requirement usages whose conjunction is the parent
		requirement, and a requirement usage without its own constraint shall serve as a group that organizes
		requirements without adding a condition.
		*/
		@Rationale { text = "Stakeholder-level requirements are too coarse to satisfy with one design element; decomposition keeps the parent satisfied exactly when all its parts are, which is the SysML v2 semantics of nested requirements."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-REQ-008'> requirementDerivation {
		doc
		/*
		A requirement derived from another shall be related to it with the SysML v2 RequirementDerivation
		library, a #derivation connection from the #original requirement to its #derive requirements, and not
		with a UML3 dependency.
		*/
		@Rationale { text = "Software requirements are mostly derived from system or business requirements; the native derivation connection is what SysML v2 tools follow when they report the impact of a changed requirement."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-REQ-009'> requirementRefinement {
		doc
		/*
		A model element that states a requirement more precisely, for example an interface definition that
		details an interface requirement or an interaction that details a functional requirement, shall be
		related to the requirement with the native #refinement dependency of ModelingMetadata.
		*/
		@Rationale { text = "Refinement is how a textual requirement becomes precise enough to implement; recording it keeps the refined model element reviewable against the requirement it claims to state."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-REQ-010'> satisfactionBinding {
		doc
		/*
		When a UML3 design element satisfies a requirement, the satisfy relationship shall bind the subject of
		the requirement to that element, and tooling shall report each satisfy relationship whose satisfying
		element does not conform to the type of the subject.
		*/
		@Rationale { text = "SysML v2 satisfaction asserts that the requirement holds for the bound subject; binding an element of the wrong type makes the assertion meaningless, and nothing but a check catches it before review."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-REQ-011'> allocationToDesign {
		doc
		/*
		A requirement shall be allocatable to the components, services and nodes responsible for it with native
		allocations, and tooling shall report each requirement that is neither allocated nor satisfied.
		*/
		@Rationale { text = "Allocation assigns responsibility before the design exists in detail, and satisfaction claims it afterwards; a requirement with neither has no owner in the design."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::analyze; }
	}

	requirement <'UML3-REQ-012'> verificationObjectives {
		doc
		/*
		A test, analysis or check that verifies software requirements shall be modeled as a verification case
		whose objective verifies those requirements, and its result shall be recorded as a
		VerificationCases::VerdictKind value.
		*/
		@Rationale { text = "The native verification case is what makes verification coverage computable in SysML v2; tests described outside the model cannot be rolled up into the verification status of the software or of the system that contains it."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-REQ-013'> verificationMethodMetadata {
		doc
		/*
		Each requirement shall record how it is to be verified with the native VerificationMethod metadata of
		the VerificationCases library, with the kinds inspect, analyze, demo and test.
		Verified by: tools/run_tests.py suite requirements; tools/check_requirements.py.
		*/
		@Rationale { text = "The verification method decides who verifies a requirement and with what evidence, long before a verification case exists. The UML3 requirements use it and the requirements suite checks every one of them."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-REQ-014'> nativeRequirementMetadata {
		doc
		/*
		The status, rationale, risk and open issues of a requirement shall be recorded with the native
		ModelingMetadata definitions StatusInfo, Rationale, Risk and Issue, and UML3 shall not duplicate any of
		them.
		Verified by: tools/run_tests.py suite requirements.
		*/
		@Rationale { text = "A second vocabulary for the same facts would split the reports of mixed system and software models. The UML3 requirements record status and rationale this way and the requirements suite checks them."; }
		@StatusInfo { status = StatusKind::tbc; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-REQ-015'> requirementPriority {
		doc
		/*
		UML3 shall provide requirement priority as a metadata definition in a UML3 library, because the SysML v2
		ModelingMetadata library defines status, rationale, risk and issues but no priority.
		*/
		@Rationale { text = "Priority drives what is built first and what may be dropped. The UML3 requirements already use UML3Requirements::Priority, but it sits in the requirements model rather than in a library that user models can import."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-REQ-016'> requirementViews {
		doc
		/*
		UML3 shall provide views of requirements: a requirement table with identifier, statement, status,
		priority, verification method, satisfying elements and verifying cases, and a requirement diagram that
		shows requirements with their decomposition, derivation, satisfaction and verification relationships.
		*/
		@Rationale { text = "Stakeholders review requirements as tables and impact as diagrams; without views the requirement model is readable only as text."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::demo; }
	}

	requirement <'UML3-REQ-017'> requirementCoverageQueries {
		doc
		/*
		Tooling shall answer from the model alone which requirements a design element satisfies, which design
		elements satisfy a requirement, and which requirements are not satisfied, not allocated or not
		verified.
		*/
		@Rationale { text = "These are the questions of every design review and every change impact analysis; answering them from the model instead of a spreadsheet keeps the answers current."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::mandatory; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	requirement <'UML3-REQ-018'> designDecisionRequirements {
		doc
		/*
		A design decision, such as the choice of an architecture style or of a pattern, shall be recordable as a
		design-constraint requirement with its rationale and the stakeholder concerns it addresses, satisfied by
		the design elements that implement it.
		*/
		@Rationale { text = "Decisions are the most expensive part of a design to rediscover. As requirements they can be traced, reviewed and checked like any other, and a pattern application becomes evidence that a decision was carried out."; }
		@StatusInfo { status = StatusKind::open; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::inspect; }
	}

	requirement <'UML3-REQ-019'> requirementInterchange {
		doc
		/*
		UML3 shall exchange requirements with requirement management tools through the SysML v2 API and the
		OMG Requirements Interchange Format (ReqIF), keeping identifiers, statements, attributes and the
		derivation, satisfaction and verification relationships.
		*/
		@Rationale { text = "Many organizations keep their requirements in a requirement management tool; round trip keeps the model and that tool from drifting apart. Which ReqIF attributes map to which SysML v2 features is still to be decided."; }
		@StatusInfo { status = StatusKind::tbd; }
		@Priority { level = PriorityKind::optional; }
		@VerificationMethod { kind = VerificationMethodKind::test; }
	}

	package UseCases {
		doc
		/*
		UseCases: how product owners, architects, test and systems engineers work with software requirements.

		Contents:
		- SpecifySoftwareRequirements: a product owner and an architect state requirements with typed subjects,
		  measurable conditions, kinds, parameters, decomposition, metadata and priority.
		- TraceRequirementsToDesign: an architect relates requirements to the design by refinement, satisfaction
		  and allocation, records design decisions, and reviews the coverage.
		- VerifySoftwareRequirements: a test engineer verifies requirements with verification cases and records
		  verdicts.
		- DeriveSoftwareRequirements: a systems engineer and an architect derive software requirements from system
		  requirements and exchange them with requirement tools.
		- Traces: #traces dependencies from each use case to the requirements it needs.
		*/
		private import UML3Actors::*;

		use case def SpecifySoftwareRequirements {
			doc
			/*
			A product owner and a software architect state the requirements of a software system in the model:
			each requirement has a subject typed by the design definition it constrains, a kind, a measurable
			condition where one can be stated, a rationale, a status, a priority and a verification method, and
			coarse requirements are decomposed into nested ones.
			*/
			subject environment : UML3Environment;
			actor owner : ProductOwner;
			actor architect : SoftwareArchitect;
			objective {
				doc /* Every requirement is stated precisely enough to be satisfied by a design element and verified by a named method. */
			}
		}

		use case def TraceRequirementsToDesign {
			doc
			/*
			A software architect relates each requirement to the design: model elements that state it more
			precisely refine it, the design elements that meet it satisfy it with their subject bound, the
			components responsible for it are allocated to it, and design decisions are recorded as requirements;
			the architect then reviews the requirements that nothing satisfies or allocates.
			*/
			subject environment : UML3Environment;
			actor architect : SoftwareArchitect;
			objective {
				doc /* Every requirement has an owner in the design, and every satisfy relationship binds an element of the right type. */
			}
		}

		use case def VerifySoftwareRequirements {
			doc
			/*
			A test engineer models the tests, analyses and checks that verify the requirements as verification
			cases, runs them and records their verdicts, and reviews the requirements that no verification case
			verifies.
			*/
			subject environment : UML3Environment;
			actor tester : TestEngineer;
			objective {
				doc /* The verification status of each requirement is recorded in the model with its evidence. */
			}
		}

		use case def DeriveSoftwareRequirements {
			doc
			/*
			A systems engineer and a software architect derive the software requirements from the requirements of
			the system that contains the software, relate them with derivation connections, and exchange them
			with the requirement management tool of the program.
			*/
			subject environment : UML3Environment;
			actor systemsEngineer : SystemsEngineer;
			actor architect : SoftwareArchitect;
			objective {
				doc /* A change to a system requirement shows which software requirements and design elements it affects. */
			}
		}

		#traces dependency from SpecifySoftwareRequirements to 'UML3-REQ-001', 'UML3-REQ-002', 'UML3-REQ-003',
			'UML3-REQ-004', 'UML3-REQ-005', 'UML3-REQ-006', 'UML3-REQ-007', 'UML3-REQ-013', 'UML3-REQ-014',
			'UML3-REQ-015';
		#traces dependency from TraceRequirementsToDesign to 'UML3-REQ-009', 'UML3-REQ-010', 'UML3-REQ-011',
			'UML3-REQ-016', 'UML3-REQ-017', 'UML3-REQ-018', UML3SysMLInteropRequirements::'UML3-SYS-008';
		#traces dependency from VerifySoftwareRequirements to 'UML3-REQ-012', 'UML3-REQ-013', 'UML3-REQ-017',
			UML3VerificationRequirements::'UML3-VER-007', UML3SysMLInteropRequirements::'UML3-SYS-009';
		#traces dependency from DeriveSoftwareRequirements to 'UML3-REQ-008', 'UML3-REQ-019',
			UML3SysMLInteropRequirements::'UML3-SYS-008';
	}
}
